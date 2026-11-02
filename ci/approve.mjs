import { deployHandler } from './hercules.mjs';
import { requestJson } from './http.mjs';

export default async function ({ github, context, core }) {
  const candidate = JSON.parse(process.env.REQUEST);
  const { host, revision } = candidate;

  const token = process.env.HERCULES_CI_API_TOKEN;
  const sourceId = process.env.SOURCE_JOB;
  const projectId = process.env.PROJECT;
  const attempt = Number(process.env.GITHUB_RUN_ATTEMPT);
  const environment = `deploy-${host}`;

  if (!token) {
    throw new Error('Configure HERCULES_CI_API_TOKEN in this environment');
  }

  const { data: main } = await github.rest.git.getRef({
    ...context.repo,
    ref: 'heads/main',
  });

  const { data: config } = await github.rest.repos.getEnvironment({
    ...context.repo,
    environment_name: environment,
  });

  const { data: reviews } = await github.rest.actions.getReviewsForRun({
    ...context.repo,
    run_id: context.runId,
  });

  if (
    main.object.sha !== revision
    || context.sha !== revision
    || !config.protection_rules?.some(
      (rule) => rule.type === 'required_reviewers' && rule.reviewers?.length,
    )
    || !reviews.some(
      (review) =>
        review.state === 'approved'
        && review.environments.some((item) => item.name === environment),
    )
  ) {
    throw new Error('Current main deployment has not been approved');
  }

  const herculesApi = 'https://hercules-ci.com/api/v1';
  const projectApi = 'site/github/account/brsvh/project/fleet';

  const api = (path, options) =>
    requestJson(`${herculesApi}/${path}`, {
      token,
      ...options,
    });

  const source = await api(`jobs/${sourceId}`);

  if (
    source.projectId !== projectId
    || source.ownerName !== 'brsvh'
    || source.repoName !== 'fleet'
    || source.jobName !== deployHandler(host)
    || source.source.ref !== 'refs/heads/main'
    || source.source.revision !== revision
    || source.isCancelled
    || source.jobPhase !== 'Done'
    || source.jobStatus !== 'Success'
  ) {
    throw new Error('Invalid original Hercules job');
  }

  const state =
    `projects/${projectId}/state/` + `fleet-approval-${host}.json/data`;
  const approval = {
    schemaVersion: 1,
    host,
    revision,
    fingerprint: candidate.fingerprint,
    requestId: candidate.requestId,
    systemPath: candidate.systemPath,
    deployPath: candidate.deployPath,
    sourceJobId: sourceId,
    runId: context.runId,
    attempt,
  };

  await api(state, {
    method: 'PUT',
    body: approval,
    noContent: true,
  });
  const saved = await api(state, {
    accept: 'application/octet-stream',
  });

  if (
    saved.requestId !== approval.requestId
    || saved.runId !== context.runId
    || saved.attempt !== attempt
  ) {
    throw new Error('Approval record could not be confirmed');
  }

  const query = new URLSearchParams({
    ref: 'refs/heads/main',
    rev: revision,
    handler: 'OnPush',
    name: deployHandler(host),
    limit: '100',
  });
  const jobsPath = `${projectApi}/jobs?${query}`;
  const before = new Set((await api(jobsPath)).items.map((job) => job.id));
  let created;

  try {
    created = await api(`jobs/${sourceId}/rerun`, {
      method: 'POST',
    });
  } catch (error) {
    // The server may have accepted a request whose response was lost.
    for (let retry = 0; retry < 4 && !created; retry += 1) {
      await new Promise((resolve) => setTimeout(resolve, 3000));
      created = (await api(jobsPath)).items.find(
        (job) => !before.has(job.id) && job.rerunOf === sourceId,
      );
    }

    if (!created) {
      throw error;
    }
  }

  if (
    created.rerunOf !== sourceId
    || created.projectId !== projectId
    || created.source.revision !== revision
    || created.source.ref !== 'refs/heads/main'
  ) {
    throw new Error('Unexpected Hercules rerun result');
  }

  core.setOutput('job', created.id);

  const jobUrl =
    'https://hercules-ci.com/github/brsvh/fleet/jobs/' + created.index;

  await core.summary
    .addHeading(`Approved ${host}`)
    .addLink(`Hercules job ${created.index}`, jobUrl)
    .write();
}
