import { deployHandler } from './hercules.mjs';
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';
import { requestJson, requestRejected } from './http.mjs';

const candidate = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const command = process.argv[3];
const { host, revision, fingerprint, requestId } = candidate;

const secrets = JSON.parse(
  fs.readFileSync(process.env.HERCULES_CI_SECRETS_JSON, 'utf8'),
);
const gitToken = secrets.git?.data.token;
const hciToken = secrets['hercules-ci']?.data.token;

const projectId = process.env.HERCULES_CI_PROJECT_ID;
const repository = 'brsvh/fleet';
const githubApi = `https://api.github.com/repos/${repository}`;
const herculesApi = 'https://hercules-ci.com/api/v1';
const stateApi = `${herculesApi}/projects/${projectId}/state`;
const jobApi =
  `${herculesApi}/site/github/account/brsvh` + '/project/fleet/jobs';

const approvalName = `fleet-approval-${host}.json`;
const deployedName = `fleet-deployed-${host}.json`;
const requestName = `fleet-request-${host}.json`;
const runName = `Deploy ${host}`;
const uuid = /^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/;

if (!gitToken || !hciToken || !uuid.test(projectId)) {
  throw new Error('Missing deployment credentials or project identity');
}

const github = (path, options) =>
  requestJson(`${githubApi}/${path}`, {
    token: gitToken,
    ...options,
  });

const getState = (name) =>
  requestJson(`${stateApi}/${name}/data`, {
    token: hciToken,
    accept: 'application/octet-stream',
    missing: true,
  });

const putState = (name, body) =>
  requestJson(`${stateApi}/${name}/data`, {
    token: hciToken,
    method: 'PUT',
    body,
    noContent: true,
  });

function sameRequest(record) {
  return (
    record?.schemaVersion === 1
    && record.requestId === requestId
    && record.host === host
    && record.revision === revision
    && record.fingerprint === fingerprint
  );
}

async function currentMain() {
  const main = await github('git/ref/heads/main');

  if (main.object.sha !== revision) {
    throw new Error('Superseded main revision');
  }
}

function inspect() {
  const output = execFileSync(
    command,
    [
      'inspect',
    ],
    {
      encoding: 'utf8',
      stdio: [
        'ignore',
        'pipe',
        'inherit',
      ],
    },
  );

  const [runningSystem, systemProfile, ...units] = output.trim().split('\n');

  if (
    !runningSystem?.startsWith('/nix/store/')
    || !systemProfile?.startsWith('/nix/store/')
  ) {
    throw new Error('Could not determine the remote system paths');
  }

  return {
    runningSystem,
    systemProfile,
    failedServices: units
      .map((line) => line.trim().split(/\s+/)[0])
      .filter(Boolean)
      .sort(),
  };
}

function matchesSystem(observed) {
  return (
    observed.runningSystem === candidate.systemPath
    && [
      candidate.systemPath,
      candidate.deployPath,
    ].includes(observed.systemProfile)
  );
}

async function saveDeployment(observed, approval, origin) {
  await putState(deployedName, {
    ...candidate,
    ...observed,
    origin,
    approval: approval && {
      runId: approval.runId,
      attempt: approval.attempt,
      sourceJobId: approval.sourceJobId,
    },
    verifiedAt: new Date().toISOString(),
  });
}

async function verifyApproval(approval) {
  if (
    !sameRequest(approval)
    || !sameRequest(requested)
    || requested.runId !== approval.runId
    || !uuid.test(approval.sourceJobId)
    || !/^\d+$/.test(String(approval.runId))
    || !Number.isSafeInteger(approval.attempt)
    || approval.attempt < 1
    || approval.systemPath !== candidate.systemPath
    || approval.deployPath !== candidate.deployPath
  ) {
    throw new Error('Invalid deployment approval record');
  }

  const runPath = `actions/runs/${approval.runId}`;
  const environment = `deploy-${host}`;

  const [run, latest, reviews, config, source] = await Promise.all([
    github(`${runPath}/attempts/${approval.attempt}`),
    github(runPath),
    github(`${runPath}/approvals`),
    github(`environments/${environment}`),
    requestJson(`${herculesApi}/jobs/${approval.sourceJobId}`),
  ]);

  if (
    run.head_sha !== revision
    || run.head_branch !== 'main'
    || run.event !== 'repository_dispatch'
    || run.path !== '.github/workflows/deploy.yml'
    || run.display_title !== runName
    || run.run_attempt !== approval.attempt
    || latest.run_attempt !== approval.attempt
    || run.repository.full_name !== repository
    || ![
      'in_progress',
      'completed',
    ].includes(run.status)
    || run.conclusion === 'cancelled'
  ) {
    throw new Error('Approval workflow does not match this deployment');
  }

  if (
    source.projectId !== projectId
    || source.jobType !== 'OnPush'
    || source.jobName !== deployHandler(host)
    || source.isCancelled
    || source.source.ref !== 'refs/heads/main'
    || source.source.revision !== revision
    || source.jobPhase !== 'Done'
    || source.jobStatus !== 'Success'
  ) {
    throw new Error('Approval does not refer to a successful deployment job');
  }

  if (
    !config.protection_rules?.some(
      (rule) => rule.type === 'required_reviewers' && rule.reviewers?.length,
    )
    || !reviews.some(
      (review) =>
        review.state === 'approved'
        && review.environments.some((item) => item.name === environment),
    )
  ) {
    throw new Error('Required environment approval is missing');
  }

  let approvalJob;

  for (let page = 1; ; page += 1) {
    const path = `${runPath}/attempts/${approval.attempt}/jobs`;
    const result = await github(`${path}?per_page=100&page=${page}`);
    approvalJob = result.jobs.find(
      (job) => job.name === `Approve deployment to ${host}`,
    );

    if (approvalJob || result.jobs.length < 100) {
      break;
    }
  }

  if (
    !approvalJob
    || !(
      approvalJob.status === 'in_progress'
      || approvalJob.conclusion === 'success'
    )
  ) {
    throw new Error('The protected approval job did not authorize deployment');
  }

  const query = new URLSearchParams({
    ref: 'refs/heads/main',
    rev: revision,
    handler: 'OnPush',
    name: 'checkAll',
    success: 'true',
    limit: '100',
  });
  const { items } = await requestJson(`${jobApi}?${query}`);

  if (
    !items.some(
      (job) =>
        job.jobName === 'checkAll'
        && job.source.revision === revision
        && job.source.ref === 'refs/heads/main'
        && job.jobStatus === 'Success'
        && job.jobPhase === 'Done'
        && !job.isCancelled,
    )
  ) {
    throw new Error('The aggregate build check has not succeeded');
  }

  await currentMain();
}

async function existingWorkflow() {
  if (sameRequest(requested) && Number.isSafeInteger(requested.runId)) {
    const run = await github(`actions/runs/${requested.runId}`);

    if (
      run.head_sha !== revision
      || run.event !== 'repository_dispatch'
      || run.path !== '.github/workflows/deploy.yml'
      || run.display_title !== runName
    ) {
      throw new Error('The recorded workflow does not match this request');
    }

    return run;
  }

  const matches = [];

  for (let page = 1; ; page += 1) {
    const query = new URLSearchParams({
      event: 'repository_dispatch',
      head_sha: revision,
      per_page: '100',
      page: String(page),
    });
    const result = await github(`actions/workflows/deploy.yml/runs?${query}`);
    matches.push(
      ...result.workflow_runs.filter(
        (run) =>
          run.display_title === runName
          && run.head_sha === revision
          && run.event === 'repository_dispatch'
          && run.path === '.github/workflows/deploy.yml',
      ),
    );

    if (result.workflow_runs.length < 100) {
      break;
    }
  }

  if (matches.length > 1) {
    throw new Error('Multiple deployment workflows; inspect them manually');
  }

  return matches[0];
}

async function requestApproval(previous) {
  let run = await existingWorkflow();
  let dispatchError;

  if (
    !run
    && (!sameRequest(requested) || requested.dispatchStatus === 'rejected')
  ) {
    let summary = 'No previous verified deployment is recorded.';

    if (previous) {
      summary =
        `System: ${previous.systemPath}\n` + `     -> ${candidate.systemPath}`;

      try {
        const diff = execFileSync(
          'nix',
          [
            'store',
            'diff-closures',
            previous.systemPath,
            candidate.systemPath,
          ],
          {
            encoding: 'utf8',
            timeout: 30000,
            stdio: [
              'ignore',
              'pipe',
              'pipe',
            ],
          },
        );

        summary += `\n\n${diff}`;
      } catch {
        summary += '\nClosure details are unavailable; see the paths above.';
      }
    }

    await currentMain();
    // Persist uncertainty before POST, including across Effect reruns.
    await putState(requestName, {
      ...candidate,
      dispatchStatus: 'pending',
    });

    try {
      await github('dispatches', {
        method: 'POST',
        noContent: true,
        body: {
          event_type: 'fleet-deploy',
          client_payload: {
            ...candidate,
            summary: summary.slice(0, 8000),
          },
        },
      });
    } catch (error) {
      if (requestRejected(error)) {
        await putState(requestName, {
          ...candidate,
          dispatchStatus: 'rejected',
        });
        throw error;
      }

      dispatchError = error;
      // Dispatch may have succeeded even when its response was lost.
      console.error(`Deployment dispatch response was not received: ${error}`);
    }
  }

  for (let attempt = 0; attempt < 12 && !run; attempt += 1) {
    await delay(5000);
    run = await existingWorkflow();
  }

  if (!run) {
    throw new Error(
      'Could not confirm the deployment workflow; '
        + 'inspect GitHub before retry',
      {
        cause: dispatchError,
      },
    );
  }

  if (!sameRequest(requested) || requested.runId !== run.id) {
    await putState(requestName, {
      ...(sameRequest(requested) ? requested : {}),
      ...candidate,
      dispatchStatus: 'confirmed',
      runId: run.id,
    });
  }

  console.log(`Approval workflow: ${run.html_url}; status: ${run.status}`);
}

await currentMain();

const [approval, previous, requested] = await Promise.all([
  getState(approvalName),
  getState(deployedName),
  getState(requestName),
]);

if (sameRequest(approval)) {
  await verifyApproval(approval);

  const before = inspect();
  const failedBefore = Array.isArray(requested.failedServicesBefore)
    ? requested.failedServicesBefore
    : before.failedServices;

  await putState(requestName, {
    ...candidate,
    runId: approval.runId,
    failedServicesBefore: failedBefore,
  });

  if (!matchesSystem(before)) {
    await currentMain();

    execFileSync(
      command,
      [
        'activate',
      ],
      {
        stdio: 'inherit',
      },
    );
  }

  const after = inspect();
  console.log(JSON.stringify(after));

  const newFailures = after.failedServices.filter(
    (unit) => !failedBefore.includes(unit),
  );

  if (!matchesSystem(after) || newFailures.length) {
    throw new Error(
      `Deployment verification failed; new failed units: ${newFailures}`,
    );
  }

  await saveDeployment(after, approval, 'deployment');

  console.log(`Verified deployment of ${revision} on ${host}`);
} else if (
  previous?.schemaVersion === 1
  && previous.host === host
  && previous.fingerprint === fingerprint
) {
  console.log(`No deployment change for ${host}`);
} else if (sameRequest(requested) && requested.dispatchStatus !== 'rejected') {
  await requestApproval(previous);
} else {
  let observed;

  if (!previous) {
    try {
      observed = inspect();
    } catch {
      console.log('Existing deployment could not be inspected.');
    }
  }

  if (observed && matchesSystem(observed)) {
    await saveDeployment(observed, null, 'observed');
    console.log(`Initialized ${host} from its running system`);
  } else {
    await requestApproval(previous);
  }
}
