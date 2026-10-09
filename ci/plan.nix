{
  branch,
  inputs,
  rev,
  system,
  targets,
}:
let
  inherit (inputs.nixpkgs.lib)
    toJSON
    ;

  pkgs = inputs.nixpkgs.legacyPackages.${system};

  effects = inputs.hercules-ci-effects.lib.withPkgs pkgs;

  targetMetadata = pkgs.writeText "ci-targets.json" (
    toJSON targets
  );

  plan = pkgs.writeText "plan.mjs" ''
    import fs from 'node:fs';
    import { randomUUID } from 'node:crypto';
    import { setTimeout as delay } from 'node:timers/promises';

    const [repository, branch, rev, targetsPath] = process.argv.slice(2);
    const targets = JSON.parse(fs.readFileSync(targetsPath, 'utf8'));
    const secrets = JSON.parse(
      fs.readFileSync(process.env.HERCULES_CI_SECRETS_JSON, 'utf8'),
    );
    const safeSha = /^[0-9a-f]{40}$/;

    if (
      repository !== 'brsvh/fleet' ||
      !['main', 'develop'].includes(branch) ||
      !safeSha.test(rev)
    ) {
      throw new Error('Invalid planning request');
    }

    const gitToken = secrets.git?.data.token;

    if (!gitToken) {
      throw new Error('Missing CI credentials');
    }

    const githubApi = `https://api.github.com/repos/''${repository}`;
    const herculesApi = 'https://hercules-ci.com/api/v1';
    const herculesProject =
      herculesApi + '/site/github/account/brsvh/project/fleet';

    async function api(url, token, method = 'GET', body) {
      let response;

      for (let attempt = 1; ; attempt += 1) {
        try {
          response = await fetch(url, {
            method,
            headers: {
              accept: 'application/json',
              ...(token ? { authorization: `Bearer ''${token}` } : {}),
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

      if (!response.ok) {
        throw new Error(
          `''${method} ''${new URL(url).pathname} ` +
            `returned ''${response.status}`,
        );
      }

      return response.status === 204 ? null : response.json();
    }

    const github = (path, method, body) =>
      api(`''${githubApi}/''${path}`, gitToken, method, body);

    const hercules = query =>
      api(`''${herculesProject}/jobs?''${new URLSearchParams(query)}`, null);

    const current = async (name, token = gitToken) =>
      (await api(`''${githubApi}/git/ref/heads/''${name}`, token)).object.sha;

    function affected(paths) {
      const selected = new Set();

      for (const path of paths) {
        const matched = Object.entries(targets).filter(([, target]) =>
          target.paths.some(prefix =>
            prefix.endsWith('/') ? path.startsWith(prefix) : path === prefix,
          ),
        );

        if (matched.length) {
          const names = matched.map(([name]) => name);
          console.log(`Changed ''${path}: ''${names.join(', ')}`);

          for (const name of names) {
            selected.add(name);
          }
        } else if (
          (!path.includes('/') && /\.(md|org)$/i.test(path)) ||
          /^(README|COPYING|LICENSE)(\.(md|org|rst|txt))?$/i.test(path)
        ) {
          console.log(`Changed ''${path}: no build checks`);
          continue;
        } else {
          // Shared flake code and unknown paths must not miss any target.
          console.log(`Changed ''${path}: all targets (shared or unknown)`);

          for (const name of Object.keys(targets)) {
            selected.add(name);
          }
        }
      }

      return selected;
    }

    const comparisons = new Map();

    async function changedSince(base) {
      if (!base) {
        return new Set(Object.keys(targets));
      }

      if (!safeSha.test(base)) {
        throw new Error('Invalid comparison revision');
      }

      if (base === rev) {
        return new Set();
      }

      if (!comparisons.has(base)) {
        const diff = await github(`compare/''${base}...''${rev}?per_page=100`);
        // GitHub includes at most 300 changed files. Never under-select
        // a large change or a comparison that is not an ancestor of
        // the current revision.
        const uncertain =
          !Array.isArray(diff.files) ||
          diff.files.length >= 300 ||
          (branch === 'main' && diff.merge_base_commit.sha !== base);
        comparisons.set(
          base,
          uncertain
            ? new Set(Object.keys(targets))
            : affected(
                diff.files.flatMap(file =>
                  [file.filename, file.previous_filename].filter(Boolean),
                ),
              ),
        );
      }

      return comparisons.get(base);
    }

    async function lastSuccess(name, ref) {
      const query = {
        handler: 'OnPush',
        name,
        success: 'true',
        limit: '100',
      };

      if (ref) {
        query.ref = ref;
      }

      while (true) {
        const { items } = await hercules(query);

        for (const job of items) {
          if (
            job.jobName !== name ||
            job.jobStatus !== 'Success' ||
            job.jobPhase !== 'Done' ||
            job.isCancelled
          ) {
            continue;
          }

          if (ref && job.source.ref !== ref) {
            continue;
          }

          if (!ref && !job.source.ref.startsWith(`refs/tags/ci/''${name}/`)) {
            continue;
          }

          if (safeSha.test(job.source.revision)) {
            return job.source.revision;
          }
        }

        if (items.length < 100) {
          return null;
        }

        query.offsetIndex = String(items.at(-1).index);
      }
    }

    if ((await current(branch)) !== rev) {
      throw new Error('Superseded branch revision');
    }

    const base =
      branch === 'main'
        ? await lastSuccess('plan', 'refs/heads/main')
        : await current('main');
    const selected = new Set(await changedSince(base));

    if (branch === 'main') {
      for (const [name, target] of Object.entries(targets)) {
        if (target.kind !== 'host' || !target.deploy) {
          continue;
        }

        const deployed = await lastSuccess(`deploy/''${target.name}`);

        if ((await changedSince(deployed)).has(name)) {
          selected.add(name);
        }
      }
    }

    const requestId = randomUUID();
    const requests = [];

    for (const target of [...selected].sort()) {
      if (!/^[a-z0-9-]+$/.test(target)) {
        throw new Error('Invalid CI target');
      }

      const tag = `ci/check/''${branch}/''${target}/''${rev}/''${requestId}`;
      await github('git/refs', 'POST', {
        ref: `refs/tags/''${tag}`,
        sha: rev,
      });
      requests.push({ tag, target, handler: targets[target].handler });
      console.log(`Requested ''${targets[target].handler} at ''${rev}`);
    }

    const pending = new Map(
      requests.map(request => [request.tag, request]),
    );
    const deadline = Date.now() + 5 * 60 * 60 * 1000;
    let nextHeadCheck = 0;

    while (pending.size) {
      if (Date.now() >= deadline) {
        throw new Error('Timed out waiting for Hercules builds');
      }

      // Public reads remain usable after the short-lived GitToken expires.
      if (Date.now() >= nextHeadCheck) {
        if ((await current(branch, null)) !== rev) {
          throw new Error('Superseded branch revision');
        }

        nextHeadCheck = Date.now() + 10 * 60 * 1000;
      }

      for (const [tag, request] of pending) {
        const { items } = await hercules({
          ref: `refs/tags/''${tag}`,
          rev,
          limit: '20',
        });
        const jobs = items.filter(
          job =>
            job.source.revision === rev &&
            job.source.ref === `refs/tags/''${tag}`,
        );

        if (
          jobs.some(
            job =>
              job.jobType === 'Config' &&
              (job.jobStatus === 'Failure' || job.isCancelled),
          )
        ) {
          throw new Error(
            `Configuration evaluation failed for ''${request.target}`,
          );
        }

        const job = jobs.find(
          job =>
            job.jobType === 'OnPush' && job.jobName === request.handler,
        );

        if (!job) {
          continue;
        }

        if (
          job.isCancelled ||
          job.evaluationStatus === 'Failure' ||
          job.derivationStatus === 'Failure'
        ) {
          throw new Error(
            `Hercules check failed: ''${request.handler}, ` +
              `job ''${job.index}`,
          );
        }

        // Wait for builds, not finishing Effects: Hercules serializes those
        // Effects behind this planning job.
        if (
          job.evaluationStatus === 'Success' &&
          job.derivationStatus === 'Success'
        ) {
          console.log(`Built ''${request.handler}, job ''${job.index}`);
          pending.delete(tag);
        }
      }

      if (pending.size) {
        await new Promise(resolve => setTimeout(resolve, 30000));
      }
    }

    if ((await current(branch, null)) !== rev) {
      throw new Error('Superseded branch revision');
    }
  '';
in
effects.mkEffect {
  dontUnpack = true;

  effectScript = ''
    node ${plan} brsvh/fleet ${branch} ${rev} ${targetMetadata}
  '';

  inputs = with pkgs; [
    nodejs
  ];

  name = "plan-fleet-ci";

  secretsMap = {
    git = {
      type = "GitToken";
    };
  };
}
