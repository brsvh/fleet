import { deployHandler } from './hercules.mjs';
import { createHash } from 'node:crypto';
import { requestJson } from './http.mjs';

export default async function ({ github, context, core }) {
  const candidate = JSON.parse(process.env.REQUEST);
  const { host, revision, fingerprint, requestId } = candidate;
  const digest = createHash('sha256')
    .update(
      [
        host,
        revision,
        fingerprint,
      ].join('\n'),
    )
    .digest('hex');

  const storePath = /^\/nix\/store\/[a-z0-9]{32}-[^/\s]+$/;

  if (
    candidate.schemaVersion !== 1
    || !/^[a-z0-9-]+$/.test(host)
    || !/^[0-9a-f]{40}$/.test(revision)
    || !/^[0-9a-f]{64}$/.test(fingerprint)
    || requestId !== digest
    || !storePath.test(candidate.systemPath)
    || !storePath.test(candidate.deployPath)
    || context.ref !== 'refs/heads/main'
    || context.sha !== revision
  ) {
    throw new Error('Invalid deployment request');
  }

  const { data: main } = await github.rest.git.getRef({
    ...context.repo,
    ref: 'heads/main',
  });

  if (main.object.sha !== revision) {
    throw new Error('Superseded main revision');
  }

  const herculesApi = 'https://hercules-ci.com/api/v1';
  const projectApi = herculesApi + '/site/github/account/brsvh/project/fleet';

  const deadline = Date.now() + 5 * 60 * 1000;
  let source;

  while (true) {
    const query = new URLSearchParams({
      ref: 'refs/heads/main',
      rev: revision,
      handler: 'OnPush',
      success: 'true',
      limit: '100',
    });
    const ready = [];

    while (true) {
      const { items } = await requestJson(`${projectApi}/jobs?${query}`);

      ready.push(
        ...items.filter(
          (job) =>
            job.ownerName === 'brsvh'
            && job.repoName === 'fleet'
            && job.source.ref === 'refs/heads/main'
            && job.source.revision === revision
            && !job.isCancelled
            && job.jobPhase === 'Done'
            && job.jobStatus === 'Success',
        ),
      );

      if (items.length < 100) {
        break;
      }

      query.set('offsetIndex', String(items.at(-1).index));
    }

    source = ready.find((job) => job.jobName === deployHandler(host));

    if (source && ready.some((job) => job.jobName === 'checkAll')) {
      break;
    }

    if (Date.now() >= deadline) {
      throw new Error('Deployment preparation has not succeeded');
    }

    await new Promise((resolve) => setTimeout(resolve, 5000));
  }

  core.setOutput('host', host);
  core.setOutput('project', source.projectId);
  core.setOutput('source-job', source.id);

  await core.summary
    .addHeading(`Deploy ${host}`)
    .addCodeBlock(
      JSON.stringify(
        {
          revision,
          requestId,
          fingerprint,
          system: candidate.systemPath,
          profile: candidate.deployPath,
          job: source.index,
        },
        null,
        2,
      ),
      'json',
    )
    .addCodeBlock(String(candidate.summary ?? ''), 'text')
    .write();
}
