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
    concatStringsSep
    elem
    escapeShellArg
    escapeShellArgs
    filter
    hasAttr
    length
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    optionalString
    optionals
    types
    unique
    ;

  inherit (pkgs)
    coreutils
    gawk
    runCommand
    systemd
    util-linux
    writeScript
    writeShellScript
    writeText
    ;

  cfg = config.services.inn;

  upstreamType = types.submodule {
    options = {
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
  };

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

  marks = writeText "pullnews.marks" (
    concatStringsSep "\n" (
      mapAttrsToList (_: makeMarks) cfg.upstreams
    )
  );

  backfillGroups = writeText "inn-backfill-groups" (
    concatStringsSep "\n" groups + "\n"
  );

  active = writeText "active" (
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

  newsgroups = writeText "newsgroups" (
    concatStringsSep "\n" (
      map (
        group: "${group}\tLocal pullnews mirror"
      ) activeGroups
    )
    + "\n"
  );

  activeTimes = writeText "active.times" (
    concatStringsSep "\n" (
      map (group: "${group} 0 ${cfg.user}") (
        activeGroups
      )
    )
    + "\n"
  );

  perlWithTls =
    pkgs.perl.withPackages
      (perlPackages: [
        perlPackages.IOSocketSSL
        perlPackages.TimeDate
      ]);

  pullnewsStatus = writeScript "inn-pullnews-status" ''
    #!${perlWithTls}/bin/perl

    use strict;
    use warnings;

    use Net::NNTP;

    my ($marks_path) = @ARGV;
    die "usage: $0 MARKS_PATH\n" if !defined $marks_path;

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

    my $failed = 0;

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

  recentMarksInitializer = writeScript "inn-recent-marks-initialize" ''
    #!${perlWithTls}/bin/perl

    use strict;
    use warnings;

    use Date::Parse qw(str2time);
    use Net::NNTP;

    my ($source_path, $destination_path, $lookback_days) = @ARGV;
    die "usage: $0 SOURCE DESTINATION LOOKBACK_DAYS\n"
      if !defined $lookback_days;
    die "LOOKBACK_DAYS must be a positive integer\n"
      if $lookback_days !~ /^[1-9][0-9]*$/;

    my $cutoff = time - $lookback_days * 24 * 60 * 60;
    my $block_size = 1000;

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

    open my $source_handle, '<', $source_path
      or die "cannot open marks template $source_path: $!\n";

    my @servers;
    my $server;
    while (my $line = <$source_handle>) {
        next if $line =~ /^\s*(?:#|$)/;

        if ($line !~ /^\s/) {
            chomp $line;
            my ($endpoint, $username, $password) = split /\s+/, $line, 3;
            $server = {
                config_line => $line,
                endpoint => $endpoint,
                groups => [],
                username => $username,
                password => defined $password ? resolve_password($password) : undef,
            };
            push @servers, $server;
            next;
        }

        die "group appears before a server in $source_path\n"
          if !defined $server;
        my ($group) = split /\s+/, $line =~ s/^\s+//r;
        push @{$server->{groups}}, {
            group => $group,
        };
    }

    close $source_handle or die "cannot close $source_path: $!\n";

    for my $entry (@servers) {
        my ($host, $port, $tls_mode) =
          $entry->{endpoint} =~ /\A([^:]+)(?::([0-9]+))?(?:_(TLS|STARTTLS))?\z/;
        die "invalid upstream endpoint $entry->{endpoint}\n"
          if !defined $host;

        $port //= $tls_mode && $tls_mode eq 'TLS' ? 563 : 119;
        my %arguments = (
            Port => $port,
            Timeout => 60,
        );
        $arguments{SSL} = 1 if $tls_mode && $tls_mode eq 'TLS';

        my $nntp = Net::NNTP->new($host, %arguments)
          or die "cannot connect to $host:$port\n";

        if ($tls_mode && $tls_mode eq 'STARTTLS' && !$nntp->starttls()) {
            die "STARTTLS failed for $host:$port\n";
        }

        if (defined $entry->{username}
            && !$nntp->authinfo($entry->{username}, $entry->{password})) {
            die "authentication failed for $host:$port\n";
        }

        for my $group_entry (@{$entry->{groups}}) {
            my ($count, $first, $last) = $nntp->group($group_entry->{group});
            die "$host: group $group_entry->{group} is unavailable\n"
              if !defined $last;

            if ($count == 0) {
                $group_entry->{high} = $last;
                next;
            }

            my $upper = $last;
            my $oldest_recent;
            my $parsed_any = 0;

            while ($upper >= $first) {
                my $lower = $upper - $block_size + 1;
                $lower = $first if $lower < $first;

                my $dates = $nntp->xhdr('Date', $lower, $upper);
                if (!defined $dates) {
                    my $overview = $nntp->xover($lower, $upper);
                    die "$host: cannot read dates for $group_entry->{group}\n"
                      if !defined $overview;
                    $dates = {
                        map {
                            $_ => $overview->{$_}[2]
                        } keys %{$overview}
                    };
                }

                my $block_parsed = 0;
                my $block_recent = 0;
                for my $number (keys %{$dates}) {
                    my $timestamp = str2time($dates->{$number});
                    next if !defined $timestamp;
                    $block_parsed = 1;
                    $parsed_any = 1;
                    next if $timestamp < $cutoff;
                    $block_recent = 1;
                    $oldest_recent = $number
                      if !defined $oldest_recent || $number < $oldest_recent;
                }

                if ($block_parsed && !$block_recent) {
                    last;
                }

                $upper = $lower - 1;
            }

            die "$host: no parseable dates for $group_entry->{group}\n"
              if !$parsed_any;

            my $high = defined $oldest_recent ? $oldest_recent - 1 : $last;
            $high = 0 if $high < 0;
            $group_entry->{high} = $high;
        }

        $nntp->quit();
    }

    my $temporary_path = "$destination_path.new.$$";
    open my $destination_handle, '>', $temporary_path
      or die "cannot create $temporary_path: $!\n";
    chmod 0600, $temporary_path
      or die "cannot chmod $temporary_path: $!\n";

    print {$destination_handle} "# Format: (date is epoch seconds)\n";
    print {$destination_handle} "# hostname[:port][_tlsmode] [username password]\n";
    print {$destination_handle} "#     group date high\n";
    my $checked = time;
    for my $entry (@servers) {
        print {$destination_handle} "$entry->{config_line}\n";
        for my $group_entry (@{$entry->{groups}}) {
            print {$destination_handle} join(
                ' ',
                '   ',
                $group_entry->{group},
                $checked,
                $group_entry->{high},
            ), "\n";
        }
    }

    close $destination_handle
      or die "cannot close $temporary_path: $!\n";
    rename $temporary_path, $destination_path
      or die "cannot replace $destination_path: $!\n";
  '';

  stateDirectory = cfg.stateDirectory;
  databaseDirectory = "${stateDirectory}/db";
  spoolDirectory = "${stateDirectory}/spool";
  backfillCursorPath = "${stateDirectory}/pullnews-backfill.cursor";
  backfillMarksPath = "${stateDirectory}/pullnews-backfill.marks";
  legacyBackfillMarksPath = "${stateDirectory}/pullnews.marks";
  recentMarksPath = "${stateDirectory}/pullnews-recent.marks";
  recentBootstrapMarksPath = "${recentMarksPath}.bootstrap";
  pullnewsLockPath = "${stateDirectory}/pullnews.lock";

  innConf = writeText "inn.conf" ''
    mta:                         "${coreutils}/bin/false -oi -oem %s"
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
    runCommand "inn-user-configuration" { }
      ''
        cp -r ${cfg.package}/etc $out
        chmod -R u+w $out
        cp ${innConf} $out/inn.conf
        substituteInPlace $out/inn.conf \
          --replace-fail '@CONFIGURATION@' "$out"
        cp ${writeText "incoming.conf" ''
          streaming: true
          max-connections: 2

          peer pullnews {
              hostname: "localhost, ${cfg.bindAddress}"
              patterns: "*"
          }
        ''} $out/incoming.conf
        cp ${writeText "readers.conf" ''
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
        cp ${writeText "newsfeeds" ''
          ME:::
        ''} $out/newsfeeds
        cp ${writeText "storage.conf" ''
          method tradspool {
              newsgroups: *
              class: 0
          }
        ''} $out/storage.conf
        cp ${writeText "expire.ctl" ''
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

  makePullnewsCommand =
    {
      marksPath,
      maxArticlesPerGroup,
      maxRunSeconds,
    }:
    escapeShellArgs (
      [
        "${cfg.package}/bin/pullnews"
        "-b"
        "1"
        "-k"
        "500"
      ]
      ++ optionals (maxArticlesPerGroup != null) [
        "-M"
        (toString maxArticlesPerGroup)
      ]
      ++ [
        "-N"
        "60"
        "-O"
        "-q"
        "-s"
        "${cfg.bindAddress}:${toString cfg.port}"
      ]
      ++ optionals (maxRunSeconds != null) [
        "-S"
        (toString maxRunSeconds)
      ]
      ++ [
        "-t"
        "2"
        "-T"
        "30"
      ]
      ++ [
        "-c"
        marksPath
      ]
    );

  backfillPullnewsCommand = makePullnewsCommand {
    inherit (cfg.backfill)
      maxArticlesPerGroup
      ;

    marksPath = backfillMarksPath;
    maxRunSeconds = null;
  };

  recentPullnewsCommand = makePullnewsCommand {
    inherit (cfg.recent)
      maxArticlesPerGroup
      maxRunSeconds
      ;

    marksPath = recentMarksPath;
  };

  backfillPullnews = writeShellScript "inn-news-backfill" ''
    set -euo pipefail

    trap 'exit 0' INT

    exec 9>${escapeShellArg pullnewsLockPath}
    ${util-linux}/bin/flock 9

    if ! test -e ${escapeShellArg backfillMarksPath}; then
      if test -e ${escapeShellArg legacyBackfillMarksPath}; then
        ${coreutils}/bin/install -m 0600 \
          ${escapeShellArg legacyBackfillMarksPath} \
          ${escapeShellArg backfillMarksPath}
      else
        ${coreutils}/bin/install -m 0600 \
          ${marks} \
          ${escapeShellArg backfillMarksPath}
      fi
    fi

    mapfile -t backfill_groups < ${backfillGroups}
    group_count="''${#backfill_groups[@]}"
    cursor=0

    if (( group_count == 0 )); then
      exit 0
    fi

    if test -r ${escapeShellArg backfillCursorPath}; then
      read -r cursor < ${escapeShellArg backfillCursorPath} || cursor=0
    fi

    case "$cursor" in
      ""|*[!0-9]*) cursor=0 ;;
    esac
    cursor=$((cursor % group_count))

    started=$SECONDS
    visited=0
    while (( visited < group_count )); do
      elapsed=$((SECONDS - started))
      remaining=$((${toString cfg.backfill.maxRunSeconds} - elapsed))
      if (( remaining <= 0 )); then
        break
      fi

      group="''${backfill_groups[$cursor]}"
      cursor=$(((cursor + 1) % group_count))
      ${coreutils}/bin/printf '%s\n' "$cursor" \
        > ${escapeShellArg "${backfillCursorPath}.new"}
      ${coreutils}/bin/mv \
        ${escapeShellArg "${backfillCursorPath}.new"} \
        ${escapeShellArg backfillCursorPath}

      ${backfillPullnewsCommand} \
        -g "$group" \
        -S "$remaining"
      visited=$((visited + 1))
    done
  '';

  recentPullnews = writeShellScript "inn-news-recent" ''
    set -euo pipefail

    cleanup_bootstrap() {
      ${coreutils}/bin/rm -f -- \
        ${escapeShellArg recentBootstrapMarksPath} \
        ${escapeShellArg "${recentBootstrapMarksPath}.new"}.* \
        ${escapeShellArg "${recentBootstrapMarksPath}.pid"}
    }

    exec 9>${escapeShellArg pullnewsLockPath}
    if ! ${util-linux}/bin/flock --nonblock 9; then
      ${systemd}/bin/systemctl --user kill \
        --kill-whom=all \
        --signal=SIGINT \
        inn-news-backfill.service \
        2>/dev/null || true
      ${util-linux}/bin/flock 9
    fi

    if ! test -e ${escapeShellArg recentMarksPath}; then
      cleanup_bootstrap
      trap cleanup_bootstrap EXIT

      ${recentMarksInitializer} \
        ${marks} \
        ${escapeShellArg recentBootstrapMarksPath} \
        ${toString cfg.recent.lookbackDays}

      if ! ${gawk}/bin/awk '
        /^[[:space:]]+[^#[:space:]]/ && $2 == 0 { failed = 1 }
        END { exit failed }
      ' ${escapeShellArg recentBootstrapMarksPath}; then
        echo "recent marks initialization did not check every group" >&2
        exit 1
      fi

      ${coreutils}/bin/mv \
        ${escapeShellArg recentBootstrapMarksPath} \
        ${escapeShellArg recentMarksPath}
      trap - EXIT
      cleanup_bootstrap
    fi

    exec ${recentPullnewsCommand}
  '';

  makePullnewsService =
    {
      description,
      execStart,
      extraAfter ? [ ],
    }:
    {
      Service = {
        CPUWeight = 20;
        Environment = innEnvironment;
        ExecStart = execStart;
        IOWeight = 20;
        KillSignal = "SIGINT";
        LoadCredential = credentials;
        Nice = 10;
        TimeoutStartSec = "30m";
        Type = "oneshot";
        UMask = "0077";
      };

      Unit = {
        After = [
          "inn.service"
          "network.target"
        ]
        ++ extraAfter
        ++ credentialUnits;
        Description = description;
        Requires = [
          "inn.service"
        ]
        ++ credentialUnits;
      };
    };

  makePullnewsTimer =
    {
      description,
      onBootSec,
      syncInterval,
      unit,
    }:
    {
      Install = {
        WantedBy = [
          "timers.target"
        ];
      };

      Timer = {
        AccuracySec = "30s";
        OnBootSec = onBootSec;
        OnUnitInactiveSec = syncInterval;
        Persistent = true;
        Unit = unit;
      };

      Unit = {
        Description = description;
      };
    };

  preStart = writeShellScript "inn-pre-start" ''
    set -euo pipefail

    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg databaseDirectory}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/archive"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/articles"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/incoming"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/outgoing"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/overview"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${stateDirectory}/log"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${stateDirectory}/run"}
    ${coreutils}/bin/install -d -m 0770 ${escapeShellArg "${stateDirectory}/tmp"}

    if ! test -e ${escapeShellArg "${databaseDirectory}/active"}; then
      ${coreutils}/bin/install -m 0644 ${active} ${escapeShellArg "${databaseDirectory}/active"}
      ${coreutils}/bin/install -m 0644 ${activeTimes} ${escapeShellArg "${databaseDirectory}/active.times"}
      ${coreutils}/bin/install -m 0644 ${newsgroups} ${escapeShellArg "${databaseDirectory}/newsgroups"}
    fi

    if ! test -e ${escapeShellArg "${databaseDirectory}/history"}; then
      ${coreutils}/bin/install -m 0644 /dev/null ${escapeShellArg "${databaseDirectory}/history"}
      ${cfg.package}/bin/makedbz -i -o -s 6000000
    fi

    if ! test -e ${escapeShellArg backfillMarksPath}; then
      if test -e ${escapeShellArg legacyBackfillMarksPath}; then
        ${coreutils}/bin/install -m 0600 \
          ${escapeShellArg legacyBackfillMarksPath} \
          ${escapeShellArg backfillMarksPath}
      else
        ${coreutils}/bin/install -m 0600 \
          ${marks} \
          ${escapeShellArg backfillMarksPath}
      fi
    fi

    ${cfg.package}/bin/innconfval -C
  '';

in
{
  options = {
    services = {
      inn = {
        enable = mkEnableOption "a private user-level INN archive";

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

        backfill = {
          maxArticlesPerGroup = mkOption {
            default = 1000;

            description = ''
              Maximum number of article numbers processed before rotating to the next backfill group.
            '';

            type = types.ints.positive;
          };

          maxRunSeconds = mkOption {
            default = 600;

            description = ''
              Maximum duration in seconds of one rotating backfill pass.
            '';

            type = types.ints.positive;
          };

          syncInterval = mkOption {
            default = "15m";

            description = ''
              Delay between completed rotating backfill passes.
            '';

            type = types.str;
          };
        };

        recent = {
          enable = mkEnableOption "a recent-news pull channel";

          lookbackDays = mkOption {
            default = 7;

            description = ''
              Number of days included when the recent-news marks are initialized.
            '';

            type = types.ints.positive;
          };

          maxArticlesPerGroup = mkOption {
            default = 1000;

            description = ''
              Maximum number of article numbers processed per group in one recent-news pull.
            '';

            type = types.ints.positive;
          };

          maxRunSeconds = mkOption {
            default = null;

            description = ''
              Maximum duration in seconds of one recent-news pull.
            '';

            type = with types; nullOr ints.positive;
          };

          syncInterval = mkOption {
            default = "5m";

            description = ''
              Delay between completed recent-news pulls.
            '';

            type = types.str;
          };
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

          inn-news-backfill-check = {
            Service = {
              Environment = innEnvironment;
              ExecStart = concatStringsSep " " [
                "${pullnewsStatus}"
                backfillMarksPath
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
              Description = "Check INN backfill completion";
              Requires = [
                "inn.service"
              ]
              ++ credentialUnits;
            };
          };

          inn-news-backfill = makePullnewsService {
            description = "Rotate through private INN backfill groups";
            execStart = backfillPullnews;
            extraAfter = optional cfg.recent.enable "inn-news-recent.service";
          };
        }
        // optionalAttrs cfg.recent.enable {
          inn-news-recent = makePullnewsService {
            description = "Pull recent private INN news";
            execStart = recentPullnews;
          };
        };

        timers = {
          inn-news-backfill = makePullnewsTimer {
            description = "Periodically rotate private INN backfill groups";
            onBootSec = "10m";
            inherit (cfg.backfill) syncInterval;

            unit = "inn-news-backfill.service";
          };
        }
        // optionalAttrs cfg.recent.enable {
          inn-news-recent = makePullnewsTimer {
            description = "Periodically update recent private INN news";
            onBootSec = "2m";
            inherit (cfg.recent) syncInterval;

            unit = "inn-news-recent.service";
          };
        };
      };
    };
  };
}
