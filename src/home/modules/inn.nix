{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    all
    concatLists
    concatMapStringsSep
    concatStringsSep
    elem
    escapeShellArg
    filter
    hasAttr
    length
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalString
    types
    unique
    ;

  cfg = config.services.inn;

  upstreamType = types.submodule (
    { name, ... }:
    {
      options = {
        agentDirectory = mkOption {
          default = name;

          description = ''
            Directory name used for this upstream in the Gnus Agent cache.
          '';

          type = types.str;
        };

        endpoint = mkOption {
          description = ''
            Upstream endpoint in pullnews host, port, and TLS-mode syntax.
          '';

          type = types.str;
        };

        groups = mkOption {
          default = [ ];

          description = ''
            Newsgroups mirrored from this upstream.
          '';

          type = with types; listOf str;
        };

        passwordCredential = mkOption {
          default = null;

          description = ''
            systemd credential filename containing the upstream password.
          '';

          type = with types; nullOr str;
        };

        username = mkOption {
          default = null;

          description = ''
            Username used to authenticate to this upstream.
          '';

          type = with types; nullOr str;
        };
      };
    }
  );

  subscribedGroups = concatLists (
    mapAttrsToList (_: upstream: upstream.groups) (
      cfg.upstreams
    )
  );

  groups = unique subscribedGroups;

  internalGroups = [
    "control"
    "control.cancel"
    "control.checkgroups"
    "control.newgroup"
    "control.rmgroup"
    "junk"
  ];

  activeGroups = internalGroups ++ groups;

  passwordCredentials =
    filter (credential: credential != null)
      (
        mapAttrsToList (
          _: upstream: upstream.passwordCredential
        ) cfg.upstreams
      );

  makeMarks =
    upstream:
    let
      authentication =
        optionalString (upstream.username != null)
          " ${upstream.username} @credential:${upstream.passwordCredential}";
    in
    ''
      ${upstream.endpoint}${authentication}
      ${concatStringsSep "\n" (
        map (group: "    ${group}") upstream.groups
      )}
    '';

  marks = pkgs.writeText "pullnews.marks" (
    concatStringsSep "\n" (
      mapAttrsToList (_: makeMarks) cfg.upstreams
    )
  );

  active = pkgs.writeText "active" (
    concatStringsSep "\n" (
      map (
        group:
        "${group} 0000000000 0000000001 ${
          if elem group groups then "y" else "n"
        }"
      ) activeGroups
    )
    + "\n"
  );

  newsgroups = pkgs.writeText "newsgroups" (
    concatStringsSep "\n" (
      map (
        group: "${group}\tLocal pullnews mirror"
      ) activeGroups
    )
    + "\n"
  );

  activeTimes = pkgs.writeText "active.times" (
    concatStringsSep "\n" (
      map (group: "${group} 0 ${cfg.user}") (
        activeGroups
      )
    )
    + "\n"
  );

  groupMap = pkgs.writeText "inn-agent-groups.tsv" (
    concatMapStringsSep ""
      (
        upstream:
        concatMapStringsSep "" (
          group: "${upstream.agentDirectory}\t${group}\n"
        ) upstream.groups
      )
      (
        mapAttrsToList (
          _: upstream: upstream
        ) cfg.upstreams
      )
  );

  perlWithTls =
    pkgs.perl.withPackages
      (perlPackages: [
        perlPackages.IOSocketSSL
      ]);

  agentBatch = pkgs.writeScript "inn-agent-batch" ''
    #!${pkgs.perl}/bin/perl

    use strict;
    use warnings;

    use File::Spec;

    my ($agent_root, $group_map) = @ARGV;
    die "usage: $0 AGENT_ROOT GROUP_MAP\n"
      if !defined $agent_root || !defined $group_map;

    open my $map_handle, '<', $group_map
      or die "cannot open group map $group_map: $!\n";

    binmode STDOUT;

    my $articles = 0;
    while (my $mapping = <$map_handle>) {
        chomp $mapping;
        next if !length $mapping;

        my ($source, $group) = split /\t/, $mapping, 2;
        die "invalid group mapping: $mapping\n"
          if !defined $source || !defined $group;

        my $directory = File::Spec->catdir(
            $agent_root,
            'nntp',
            $source,
            split(/\./, $group),
        );
        next if !-d $directory;

        opendir my $directory_handle, $directory
          or die "cannot open $directory: $!\n";
        my @article_numbers = sort { $a <=> $b }
          grep { /\A[0-9]+\z/ && -f File::Spec->catfile($directory, $_) }
          readdir $directory_handle;
        closedir $directory_handle
          or die "cannot close $directory: $!\n";

        for my $article_number (@article_numbers) {
            my $path = File::Spec->catfile($directory, $article_number);
            open my $article_handle, '<:raw', $path
              or die "cannot open $path: $!\n";
            local $/;
            my $article = <$article_handle>;
            close $article_handle
              or die "cannot close $path: $!\n";

            die "missing Message-ID header in $path\n"
              if $article !~ /^Message-ID:/mi;
            die "missing Newsgroups header in $path\n"
              if $article !~ /^Newsgroups:/mi;

            $article .= "\n" if $article !~ /\n\z/;
            print '#! rnews ', length($article), "\n", $article;

            ++$articles;
            warn "prepared $articles Agent articles\n"
              if $articles % 10000 == 0;
        }
    }

    close $map_handle or die "cannot close $group_map: $!\n";
    warn "prepared $articles Agent articles in total\n";
  '';

  pullnewsStatus = pkgs.writeScript "inn-pullnews-status" ''
    #!${perlWithTls}/bin/perl

    use strict;
    use warnings;

    use Net::NNTP;

    my ($marks_path, $agent_marker) = @ARGV;
    die "usage: $0 MARKS_PATH AGENT_MARKER\n"
      if !defined $marks_path || !defined $agent_marker;

    sub resolve_password {
        my ($password) = @_;

        return substr($password, 1) if $password =~ /^@@/;
        return $password if $password !~ /^@(.*)$/;

        my $path = $1;
        if ($path =~ /^credential:(.+)$/) {
            my $credential = $1;
            my $directory = $ENV{'CREDENTIALS_DIRECTORY'};
            die "CREDENTIALS_DIRECTORY is unset\n"
              if !defined $directory || !length $directory;
            die "invalid credential name\n"
              if $credential =~ m{/} || $credential eq '.' || $credential eq '..';
            $path = "$directory/$credential";
        }

        open my $password_handle, '<', $path
          or die "cannot open password file $path: $!\n";
        my $password_value = <$password_handle>;
        close $password_handle
          or die "cannot close password file $path: $!\n";
        die "password file $path is empty\n" if !defined $password_value;
        chomp $password_value;
        die "password file $path contains more than one line\n"
          if $password_value =~ /[\r\n]/;
        return $password_value;
    }

    open my $marks_handle, '<', $marks_path
      or die "cannot open marks file $marks_path: $!\n";

    my @servers;
    my $server;
    while (my $line = <$marks_handle>) {
        next if $line =~ /^\s*(?:#|$)/;

        if ($line !~ /^\s/) {
            chomp $line;
            my ($endpoint, $username, $password) = split /\s+/, $line, 3;
            $server = {
                endpoint => $endpoint,
                groups => [],
                username => $username,
                password => defined $password ? resolve_password($password) : undef,
            };
            push @servers, $server;
            next;
        }

        die "group appears before a server in $marks_path\n" if !defined $server;
        my ($group, $date, $high) = split /\s+/, $line =~ s/^\s+//r;
        push @{$server->{groups}}, {
            group => $group,
            high => $high,
        };
    }

    close $marks_handle or die "cannot close $marks_path: $!\n";

    my $failed = !-e $agent_marker;
    warn "Agent import is incomplete: $agent_marker is absent\n" if $failed;

    for my $entry (@servers) {
        my ($host, $port, $tls_mode) =
          $entry->{endpoint} =~ /\A([^:]+)(?::([0-9]+))?(?:_(TLS|STARTTLS))?\z/;
        if (!defined $host) {
            warn "invalid upstream endpoint $entry->{endpoint}\n";
            $failed = 1;
            next;
        }

        $port //= $tls_mode && $tls_mode eq 'TLS' ? 563 : 119;
        my %arguments = (
            Port => $port,
            Timeout => 30,
        );
        $arguments{SSL} = 1 if $tls_mode && $tls_mode eq 'TLS';

        my $nntp = Net::NNTP->new($host, %arguments);
        if (!$nntp) {
            warn "cannot connect to $host:$port\n";
            $failed = 1;
            next;
        }

        if ($tls_mode && $tls_mode eq 'STARTTLS' && !$nntp->starttls()) {
            warn "STARTTLS failed for $host:$port\n";
            $failed = 1;
            $nntp->quit();
            next;
        }

        if (defined $entry->{username}
            && !$nntp->authinfo($entry->{username}, $entry->{password})) {
            warn "authentication failed for $host:$port\n";
            $failed = 1;
            $nntp->quit();
            next;
        }

        for my $group_entry (@{$entry->{groups}}) {
            my ($count, $first, $last) = $nntp->group($group_entry->{group});
            if (!defined $last) {
                warn "$host: group $group_entry->{group} is unavailable\n";
                $failed = 1;
                next;
            }

            my $marked = $group_entry->{high} // ($first - 1);
            my $pending = $last > $marked ? $last - $marked : 0;
            print join(
                "\t",
                $host,
                $group_entry->{group},
                "marked=$marked",
                "upstream=$last",
                "pending=$pending",
            ), "\n";
            $failed = 1 if $pending != 0;
        }

        $nntp->quit();
    }

    exit($failed ? 1 : 0);
  '';

  stateDirectory = cfg.stateDirectory;
  databaseDirectory = "${stateDirectory}/db";
  importDirectory = "${stateDirectory}/import";
  spoolDirectory = "${stateDirectory}/spool";

  innConf = pkgs.writeText "inn.conf" ''
    mta:                         "${pkgs.coreutils}/bin/false -oi -oem %s"
    organization:                "${cfg.organization}"
    ovmethod:                    tradindexed
    hismethod:                   hisv6
    domain:                      ${cfg.domain}
    pathhost:                    ${cfg.pathHost}
    pathnews:                    ${stateDirectory}
    runasuser:                   ${cfg.user}
    runasgroup:                  ${cfg.group}
    server:                      ${cfg.bindAddress}
    artcutoff:                   0
    bindaddress:                 ${cfg.bindAddress}
    docancels:                   none
    maxartsize:                  0
    pgpverify:                   false
    port:                        ${toString cfg.port}
    doinnwatch:                  false
    htmlstatus:                  false
    logstatus:                   false
    patharchive:                 ${spoolDirectory}/archive
    patharticles:                ${spoolDirectory}/articles
    pathbin:                     ${cfg.package}/bin
    pathcontrol:                 ${cfg.package}/bin/control
    pathdb:                      ${databaseDirectory}
    pathetc:                     @CONFIGURATION@
    pathfilter:                  ${cfg.package}/bin/filter
    pathhttp:                    ${cfg.package}/http
    pathincoming:                ${spoolDirectory}/incoming
    pathlog:                     ${stateDirectory}/log
    pathoutgoing:                ${spoolDirectory}/outgoing
    pathoverview:                ${spoolDirectory}/overview
    pathrun:                     ${stateDirectory}/run
    pathspool:                   ${spoolDirectory}
    pathtmp:                     ${stateDirectory}/tmp
  '';

  configuration =
    pkgs.runCommand "inn-user-configuration" { }
      ''
        cp -r ${cfg.package}/etc $out
        chmod -R u+w $out
        cp ${innConf} $out/inn.conf
        substituteInPlace $out/inn.conf \
          --replace-fail '@CONFIGURATION@' "$out"
        cp ${pkgs.writeText "incoming.conf" ''
          streaming: true
          max-connections: 2

          peer pullnews {
              hostname: "localhost, ${cfg.bindAddress}"
              patterns: "*"
          }
        ''} $out/incoming.conf
        cp ${pkgs.writeText "readers.conf" ''
          auth "localhost" {
              hosts: "localhost, ${cfg.bindAddress}"
              default: "<localhost>"
          }

          access "localhost" {
              users: "<localhost>"
              read: "*,!control,!control.*,!junk"
              post: "!*"
          }
        ''} $out/readers.conf
        cp ${pkgs.writeText "newsfeeds" ''
          ME:::
        ''} $out/newsfeeds
        cp ${pkgs.writeText "storage.conf" ''
          method tradspool {
              newsgroups: *
              class: 0
          }
        ''} $out/storage.conf
        cp ${pkgs.writeText "expire.ctl" ''
          /remember/:never
          *:A:never:never:never
        ''} $out/expire.ctl
      '';

  innEnvironment = [
    "INNCONF=${configuration}/inn.conf"
  ];

  credentials = mapAttrsToList (
    name: path: "${name}:${path}"
  ) cfg.credentials;

  credentialUnits = optional (
    cfg.credentialService != null
  ) cfg.credentialService;

  preStart = pkgs.writeShellScript "inn-pre-start" ''
    set -euo pipefail

    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg databaseDirectory}
    ${pkgs.coreutils}/bin/install -d -m 0770 ${escapeShellArg importDirectory}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/archive"}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/articles"}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/incoming"}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/outgoing"}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/overview"}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${stateDirectory}/log"}
    ${pkgs.coreutils}/bin/install -d -m 0750 ${escapeShellArg "${stateDirectory}/run"}
    ${pkgs.coreutils}/bin/install -d -m 0770 ${escapeShellArg "${stateDirectory}/tmp"}

    if ! test -e ${escapeShellArg "${databaseDirectory}/active"}; then
      ${pkgs.coreutils}/bin/install -m 0644 ${active} ${escapeShellArg "${databaseDirectory}/active"}
      ${pkgs.coreutils}/bin/install -m 0644 ${activeTimes} ${escapeShellArg "${databaseDirectory}/active.times"}
      ${pkgs.coreutils}/bin/install -m 0644 ${newsgroups} ${escapeShellArg "${databaseDirectory}/newsgroups"}
    fi

    if ! test -e ${escapeShellArg "${databaseDirectory}/history"}; then
      ${pkgs.coreutils}/bin/install -m 0644 /dev/null ${escapeShellArg "${databaseDirectory}/history"}
      ${cfg.package}/bin/makedbz -i -o -s 6000000
    fi

    if ! test -e ${escapeShellArg "${stateDirectory}/pullnews.marks"}; then
      ${pkgs.coreutils}/bin/install -m 0600 ${marks} ${escapeShellArg "${stateDirectory}/pullnews.marks"}
    fi

    ${cfg.package}/bin/innconfval -C
  '';

  agentImport = pkgs.writeShellScript "inn-agent-import" ''
    set -euo pipefail

    ${agentBatch} \
      ${escapeShellArg cfg.agentDirectory} \
      ${groupMap} \
      | ${cfg.package}/bin/rnews \
        -N \
        -r ${escapeShellArg cfg.bindAddress} \
        -P ${toString cfg.port}
    ${pkgs.coreutils}/bin/install -m 0644 \
      /dev/null \
      ${escapeShellArg "${importDirectory}/agent-complete"}
  '';
in
{
  options = {
    services = {
      inn = {
        enable = mkEnableOption "a private user-level INN archive";

        agentDirectory = mkOption {
          default = "${config.xdg.cacheHome}/emacs/gnus/agent";

          description = ''
            Existing Gnus Agent root imported by the manual import service.
          '';

          type = types.str;
        };

        bindAddress = mkOption {
          default = "127.0.0.1";

          description = ''
            Local IPv4 address on which INN listens.
          '';

          type = types.str;
        };

        credentials = mkOption {
          default = { };

          description = ''
            systemd credential filenames mapped to password source paths.
          '';

          type = with types; attrsOf str;
        };

        credentialService = mkOption {
          default = null;

          description = ''
            User unit that must prepare credential source files before sync.
          '';

          type = with types; nullOr str;
        };

        domain = mkOption {
          default = "local";

          description = ''
            Domain INN uses when the local hostname is not fully qualified.
          '';

          type = types.str;
        };

        expectedGroupCount = mkOption {
          default = null;

          description = ''
            Expected number of subscribed group entries, when checked.
          '';

          type = with types; nullOr ints.unsigned;
        };

        group = mkOption {
          default = "users";

          description = ''
            Primary group of the user running INN.
          '';

          type = types.str;
        };

        organization = mkOption {
          default = "${config.home.username}'s local news archive";

          description = ''
            Organization header value used by INN.
          '';

          type = types.str;
        };

        package = mkOption {
          apply =
            package:
            package.overrideAttrs (
              _: previousAttrs: {
                configureFlags =
                  (previousAttrs.configureFlags or [ ])
                  ++ [
                    "--with-news-user=${cfg.user}"
                    "--with-news-group=${cfg.group}"
                  ];
              }
            );
          default = pkgs.inn;
          defaultText = "pkgs.inn";

          description = ''
            INN package used by the daemon and synchronization tools.
          '';

          type = types.package;
        };

        pathHost = mkOption {
          default = "${config.home.username}.localhost";

          description = ''
            Path identity inserted into accepted articles.
          '';

          type = types.str;
        };

        port = mkOption {
          default = 1119;

          description = ''
            Unprivileged local NNTP port used by INN.
          '';

          type = types.port;
        };

        stateDirectory = mkOption {
          default = "${config.xdg.stateHome}/inn";

          description = ''
            Persistent directory containing articles, overview, and marks.
          '';

          type = types.str;
        };

        syncInterval = mkOption {
          default = "5m";

          description = ''
            Delay between completed pullnews runs.
          '';

          type = types.str;
        };

        upstreams = mkOption {
          default = { };

          description = ''
            Ordered pullnews upstream definitions and subscribed groups.
          '';

          type = with types; attrsOf upstreamType;
        };

        user = mkOption {
          default = config.home.username;

          description = ''
            User account running INN.
          '';

          type = types.str;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.expectedGroupCount == null
          ||
            length subscribedGroups == cfg.expectedGroupCount;
        message = "The INN mirror has an unexpected number of subscribed group entries.";
      }
      {
        assertion =
          length groups == length subscribedGroups;
        message = "The INN mirror must not contain duplicate group entries.";
      }
      {
        assertion =
          all
            (
              upstream:
              (upstream.username == null)
              == (upstream.passwordCredential == null)
            )
            (
              mapAttrsToList (
                _: upstream: upstream
              ) cfg.upstreams
            );
        message = "Each authenticated INN upstream must define both username and passwordCredential.";
      }
      {
        assertion = all (
          credential: hasAttr credential cfg.credentials
        ) passwordCredentials;
        message = "Every INN upstream passwordCredential must exist in services.inn.credentials.";
      }
    ];

    home = {
      packages = [
        cfg.package
      ];
    };

    systemd = {
      user = {
        services = {
          inn = {
            Install = {
              WantedBy = [
                "default.target"
              ];
            };

            Service = {
              Environment = innEnvironment;
              ExecStart = "${cfg.package}/bin/innd -d -4 ${cfg.bindAddress} -P ${toString cfg.port}";
              ExecStartPre = "${preStart}";
              ExecStop = "${cfg.package}/bin/ctlinnd -t 60 shutdown systemd-stop";
              Restart = "on-failure";
              RestartSec = "5s";
              Type = "simple";
              UMask = "0027";
            };

            Unit = {
              After = [
                "network.target"
              ];
              Description = "Private user InterNetNews archive";
            };
          };

          inn-agent-import = {
            Service = {
              Environment = innEnvironment;
              ExecStart = "${agentImport}";
              IOSchedulingClass = "idle";
              Nice = 10;
              TimeoutStartSec = "infinity";
              Type = "oneshot";
              UMask = "0027";
            };

            Unit = {
              After = [
                "inn.service"
              ];
              ConditionPathExists = "!${importDirectory}/agent-complete";
              Description = "Import the retained Gnus Agent cache into INN";
              Requires = [
                "inn.service"
              ];
            };
          };

          inn-bootstrap-check = {
            Service = {
              Environment = innEnvironment;
              ExecStart = concatStringsSep " " [
                "${pullnewsStatus}"
                "${stateDirectory}/pullnews.marks"
                "${importDirectory}/agent-complete"
              ];
              LoadCredential = credentials;
              Nice = 10;
              TimeoutStartSec = "10m";
              Type = "oneshot";
            };

            Unit = {
              After = [
                "inn.service"
              ]
              ++ credentialUnits;
              Description = "Check INN upstream and Agent bootstrap completion";
              Requires = [
                "inn.service"
              ]
              ++ credentialUnits;
            };
          };

          inn-pullnews = {
            Service = {
              CPUWeight = 20;
              Environment = innEnvironment;
              ExecStart = concatStringsSep " " [
                "${cfg.package}/bin/pullnews"
                "-b 1"
                "-k 500"
                "-N 60"
                "-O"
                "-q"
                "-s ${cfg.bindAddress}:${toString cfg.port}"
                "-t 2"
                "-T 30"
                "-c ${stateDirectory}/pullnews.marks"
              ];
              IOWeight = 20;
              LoadCredential = credentials;
              Nice = 10;
              TimeoutStartSec = "infinity";
              Type = "oneshot";
              UMask = "0077";
            };

            Unit = {
              After = [
                "inn.service"
                "network.target"
              ]
              ++ credentialUnits;
              Description = "Pull subscribed news groups into private INN";
              Requires = [
                "inn.service"
              ]
              ++ credentialUnits;
            };
          };
        };

        timers = {
          inn-pullnews = {
            Install = {
              WantedBy = [
                "timers.target"
              ];
            };

            Timer = {
              AccuracySec = "30s";
              OnBootSec = "5m";
              OnUnitInactiveSec = cfg.syncInterval;
              Persistent = true;
              Unit = "inn-pullnews.service";
            };

            Unit = {
              Description = "Periodically update the private INN archive";
            };
          };
        };
      };
    };
  };
}
