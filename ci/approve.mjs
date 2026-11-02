import {
  deployHandler,
  jobFamily,
  jobHistory,
  rerunJob,
  sameTask,
} from './hercules.mjs';
import { requestJson, requestRejected } from './http.mjs';

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

  const api = (path, options) =>
    requestJson(`${herculesApi}${path}`, {
      token,
      ...options,
    });

  const source = await api(`/jobs/${sourceId}`);

  if (
    source.jobType !== 'OnPush'
    || source.projectId !== projectId
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

  const jobs = await jobHistory(api, revision);
  const { root, jobs: family } = jobFamily(source, jobs);
  const tasks = jobs.filter((job) => sameTask(job, source));

  if (
    tasks.some(
      (job) =>
        (job.index > source.index
          && !family.some((member) => member.id === job.id))
        || job.jobPhase !== 'Done',
    )
  ) {
    throw new Error(
      'A newer or active deployment task exists; inspect it first',
    );
  }

  const latest = tasks.toSorted((a, b) => b.index - a.index)[0];
  const state =
    `/projects/${projectId}/state/` + `fleet-approval-${host}.json/data`;
  const requested = await api(
    `/projects/${projectId}/state/fleet-request-${host}.json/data`,
    {
      accept: 'application/octet-stream',
    },
  );

  if (
    requested.requestId !== candidate.requestId
    || requested.host !== host
    || requested.revision !== revision
    || requested.fingerprint !== candidate.fingerprint
    || requested.runId !== context.runId
  ) {
    throw new Error('The workflow is not the recorded deployment request');
  }

  const previous = await api(state, {
    accept: 'application/octet-stream',
    missing: true,
  });
  const sameApproval =
    previous?.requestId === candidate.requestId
    && previous.runId === context.runId;

  if (sameApproval && previous.attempt > attempt) {
    throw new Error('A newer approval attempt exists');
  }

  let executedJobId = sameApproval ? previous.jobId : null;

  if (sameApproval && previous.rerunStatus === 'pending') {
    const from = family.find((job) => job.id === previous.rerunSourceJobId);
    const following = from
      ? family.filter((job) => job.index > from.index)
      : [];

    if (following.length !== 1) {
      throw new Error('Could not confirm the previous rerun; inspect Hercules');
    }

    executedJobId = following[0].id;
  }

  let created;

  if (
    latest.id === executedJobId
    && !latest.isCancelled
    && latest.jobStatus === 'Success'
    && latest.effectsStatus === 'Success'
  ) {
    // A workflow retry may only be recovering its observer or lost response.
    created = latest;
  } else {
    if (
      latest.id !== source.id
      && !latest.isCancelled
      && latest.jobStatus !== 'Failure'
    ) {
      throw new Error('A newer deployment task succeeded; inspect it first');
    }

    const { data: current } = await github.rest.git.getRef({
      ...context.repo,
      ref: 'heads/main',
    });

    if (current.object.sha !== revision) {
      throw new Error('Superseded main revision');
    }

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
      rerunSourceJobId: latest.id,
      rerunStatus: 'pending',
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
      !Object.entries(approval).every(([key, value]) => saved[key] === value)
    ) {
      throw new Error('Approval record could not be confirmed');
    }

    try {
      ({ job: created } = await rerunJob(api, latest, jobs));
    } catch (error) {
      if (requestRejected(error)) {
        await api(state, {
          method: 'PUT',
          body: {
            ...approval,
            rerunStatus: 'rejected',
          },
          noContent: true,
        });
      }

      throw error;
    }

    await api(state, {
      method: 'PUT',
      body: {
        ...approval,
        rerunStatus: 'confirmed',
        jobId: created.id,
      },
      noContent: true,
    });
  }

  core.setOutput('job', created.id);
  core.setOutput('root-job', root.id);

  const jobUrl =
    'https://hercules-ci.com/github/brsvh/fleet/jobs/' + created.index;

  await core.summary
    .addHeading(`Approved ${host}`)
    .addLink(`Hercules job ${created.index}`, jobUrl)
    .write();
}
