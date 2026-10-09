{
  branch,
  inputs,
  rev,
  system,
  tag,
  target,
}:
let
  inherit (inputs.nixpkgs.lib)
    toJSON
    ;

  pkgs = inputs.nixpkgs.legacyPackages.${system};

  effects = inputs.hercules-ci-effects.lib.withPkgs pkgs;

  request =
    pkgs.writeText "finish-request.json"
      (toJSON {
        inherit
          branch
          rev
          tag
          ;

        host =
          if target.kind == "host" && target.deploy then
            target.name
          else
            null;
      });

  finish = pkgs.writeText "finish.mjs" ''
    import fs from 'node:fs';
    import { setTimeout as delay } from 'node:timers/promises';

    const { branch, rev, tag, host } = JSON.parse(
      fs.readFileSync(process.argv[2], 'utf8'),
    );
    const secrets = JSON.parse(
      fs.readFileSync(process.env.HERCULES_CI_SECRETS_JSON, 'utf8'),
    );
    const token = secrets.git?.data.token;

    if (!token) {
      throw new Error('Missing GitHub credential');
    }

    const githubApi = 'https://api.github.com/repos/brsvh/fleet';
    const herculesApi = 'https://hercules-ci.com/api/v1';
    const herculesProject =
      herculesApi + '/site/github/account/brsvh/project/fleet';

    const api = async (path, method = 'GET', body) => {
      let response;

      for (let attempt = 1; ; attempt += 1) {
        try {
          response = await fetch(`''${githubApi}/''${path}`, {
            method,
            headers: {
              accept: 'application/vnd.github+json',
              authorization: `Bearer ''${token}`,
              'content-type': 'application/json',
              'user-agent': 'fleet-ci',
            },
            body: body === undefined ? undefined : JSON.stringify(body),
            signal: AbortSignal.timeout(30000),
          });

          break;
        } catch (error) {
          const cause = error.cause;
          // This reset happens before an HTTP request can be sent.
          const disconnectedBeforeTls =
            cause?.code === 'ECONNRESET' &&
            cause.message ===
              'Client network socket disconnected before secure TLS ' +
                'connection was established';

          if (
            (cause?.code !== 'UND_ERR_CONNECT_TIMEOUT' &&
              !disconnectedBeforeTls) ||
            attempt === 3
          ) {
            throw error;
          }

          console.warn(
            `Connection failed (''${cause.code}); ` +
              `retrying (''${attempt}/2)`,
          );
          await delay(2000);
        }
      }

      if (method === 'DELETE' && response.status === 422) {
        return null;
      }

      if (!response.ok) {
        throw new Error(`GitHub request failed (''${response.status})`);
      }

      return response.status === 204 ? null : response.json();
    };

    // Each finishing Effect receives a fresh token after its builds, even when
    // those builds take longer than a GitHub installation token's lifetime.
    await api(`git/refs/tags/''${tag}`, 'DELETE');

    if (branch === 'main' && host) {
      if ((await api('git/ref/heads/main')).object.sha !== rev) {
        console.log('Skipping approval for a superseded main revision');
      } else {
        const query = new URLSearchParams({
          ref: 'refs/heads/main',
          rev,
          handler: 'OnPush',
          name: 'plan',
          limit: '20',
        });
        const response = await fetch(`''${herculesProject}/jobs?''${query}`, {
          signal: AbortSignal.timeout(30000),
        });

        if (!response.ok) {
          throw new Error('Could not verify the planning result');
        }

        const { items } = await response.json();
        const plan = items.find(
          job =>
            job.jobName === 'plan' &&
            job.source.revision === rev &&
            job.source.ref === 'refs/heads/main',
        );

        if (!plan || plan.jobStatus !== 'Success' || plan.isCancelled) {
          throw new Error('The planning job has not succeeded');
        }

        await api('dispatches', 'POST', {
          event_type: 'fleet-deploy',
          client_payload: { rev, hosts: [host] },
        });
        console.log(`Requested deployment approval for ''${host} at ''${rev}`);
      }
    }
  '';
in
effects.mkEffect {
  dontUnpack = true;

  effectScript = ''
    node ${finish} ${request}
  '';

  inputs = with pkgs; [
    nodejs
  ];

  name = "finish-fleet-check";

  secretsMap = {
    git = {
      type = "GitToken";
    };
  };
}
