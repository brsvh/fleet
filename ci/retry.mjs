import { setTimeout as delay } from 'node:timers/promises';
import { stripVTControlCharacters } from 'node:util';
import { requestJson } from './http.mjs';
import { jobFamily, jobHistory, rerunJob, sameTask } from './hercules.mjs';

export default async function ({ github, context, core }) {
  const { payload } = context;
  const revision = payload.sha;
  const jobBase = 'https://hercules-ci.com/github/brsvh/fleet/jobs/';
  const target = payload.target_url;

  if (
    context.eventName !== 'status'
    || context.ref !== 'refs/heads/main'
    || context.repo.owner !== 'brsvh'
    || context.repo.repo !== 'fleet'
    || typeof payload.context !== 'string'
    || !payload.context.startsWith('ci/hercules/')
    || ![
      'failure',
      'error',
    ].includes(payload.state)
    || !/^[0-9a-f]{40}$/.test(revision)
    || typeof target !== 'string'
    || !target.startsWith(jobBase)
    || !/^[1-9][0-9]*$/.test(target.slice(jobBase.length))
  ) {
    throw new Error('Invalid Hercules evaluation status');
  }

  const token = process.env.HERCULES_CI_API_TOKEN;

  if (!token) {
    throw new Error('Configure HERCULES_CI_API_TOKEN in ci-retry');
  }

  const herculesApi = 'https://hercules-ci.com/api/v1';
  const interval = 60000;
  const limit = 5;

  const api = (path, options) =>
    requestJson(`${herculesApi}${path}`, {
      token,
      ...options,
      attempts: 3,
      retryDelay: () => interval,
    });

  const history = () => jobHistory(api, revision);

  function eligible(job) {
    return (
      job?.ownerName === 'brsvh'
      && job.repoName === 'fleet'
      && /^[0-9a-f-]{36}$/.test(job.id)
      && job.source.revision === revision
      && [
        'refs/heads/main',
        'refs/heads/develop',
      ].includes(job.source.ref)
      && (([
        'Config',
        'Legacy',
      ].includes(job.jobType)
        && job.jobName === null)
        || (job.jobType === 'OnPush'
          && /^(check|deploy)[A-Z][A-Za-z0-9]*$/.test(job.jobName)
          && (!job.jobName.startsWith('deploy')
            || job.source.ref === 'refs/heads/main')))
    );
  }

  function failed(job) {
    return (
      eligible(job)
      && !job.isCancelled
      && job.jobPhase === 'Done'
      && job.jobStatus === 'Failure'
      && job.evaluationStatus === 'Failure'
    );
  }

  async function skip(reason) {
    core.info(reason);
    await core.summary.addHeading('No automatic retry').addRaw(reason).write();
  }

  let jobs = await history();
  const index = Number(target.slice(jobBase.length));
  const source = jobs.find((job) => job.index === index);

  if (!failed(source)) {
    await skip('The job is not a failed repository evaluation.');
    return;
  }

  async function current() {
    const { data } = await github.rest.git.getRef({
      ...context.repo,
      ref: source.source.ref.slice('refs/'.length),
    });

    return data.object.sha === revision;
  }

  function budget(history) {
    const { root, jobs: family } = jobFamily(source, history);

    if (
      history.some(
        (job) =>
          sameTask(job, source)
          && (job.index > source.index
            || (!job.isCancelled && job.jobPhase !== 'Done')),
      )
    ) {
      return null;
    }

    // Once deployment preparation has evaluated, a rerun may consume approval.
    // Leave those retries to the approved deployment workflow or its operator.
    if (source.jobName === null || source.jobName.startsWith('deploy')) {
      if (
        history.some(
          (job) =>
            job.projectId === source.projectId
            && job.source.ref === source.source.ref
            && job.source.revision === revision
            && job.jobType === 'OnPush'
            && /^deploy[A-Z]/.test(job.jobName)
            && job.evaluationStatus === 'Success'
            && (source.jobName === null || job.jobName === source.jobName),
        )
      ) {
        return null;
      }
    }

    return {
      root,
      attempts: family.length - 1,
    };
  }

  if (!(await current())) {
    await skip('The branch has moved to another revision.');
    return;
  }

  let remaining = budget(jobs);

  if (!remaining || remaining.attempts >= limit) {
    await skip(
      'Retry blocked by task history, deployment stage or five-retry limit.',
    );
    return;
  }

  const evaluation = await api(`/jobs/${source.id}/evaluation`);
  const attributes = evaluation.attributes;
  const message = attributes?.[0]?.value?.Error?.errorMessage;

  const input =
    typeof message === 'string'
      ? stripVTControlCharacters(message).match(
          /while fetching the input '([^']+)'/,
        )?.[1]
      : null;
  const repository = 'git+https://github.com/brsvh/fleet.git';
  const url = input?.startsWith(`${repository}?`) ? new URL(input) : null;

  if (
    attributes?.length !== 1
    || attributes[0].path.length !== 0
    || !url
    || url.searchParams.get('rev') !== revision
    || url.searchParams.get('ref') !== source.source.ref
    || !stripVTControlCharacters(message).includes(
      'Failed to fetch git repository',
    )
    || Object.keys(evaluation.derivations).length !== 0
    || evaluation.evaluationDependencies.length !== 0
    || evaluation.ifdAttributes.length !== 0
  ) {
    await skip('The failure is outside the initial repository fetch.');
    return;
  }

  const logId = evaluation.evaluationLog;

  if (!/^[0-9a-f-]{36}$/.test(logId)) {
    throw new Error('Missing evaluation log');
  }

  const log = await api(
    `/jobs/${source.id}/evaluation/log/lines?logId=${logId}`,
  );

  if (!log.done || log.id !== logId) {
    throw new Error('The evaluation log is incomplete');
  }

  const text = stripVTControlCharacters(
    log.lines.map((line) => line.t).join('\n'),
  );
  const permanent = [
    /authentication failed|permission denied|access denied/i,
    /could not read (?:username|password)|repository .*not found/i,
    /requested URL returned error: (?:400|401|403|404|410)\b/i,
    /curl (?:51|60)\b|SSL (?:certificate problem|peer certificate)/i,
    /certificate (?:verify|verification) failed|certificate has expired/i,
    /certificate is not yet valid|unable to get local issuer certificate/i,
    /couldn't find remote ref|not our ref|hash mismatch/i,
    /no space left on device|disk quota exceeded/i,
  ];
  const transient = [
    [
      'HTTP/2 stream interrupted',
      /curl 92\b|HTTP\/2 stream .*reset/i,
    ],
    [
      'TLS connection interrupted',
      /\b(?:TLS|SSL)[^\r\n]*\bunexpected EOF while reading\b/i,
    ],
    [
      'Git transfer interrupted',
      /early EOF|unexpected disconnect/i,
    ],
    [
      'Connection reset',
      /connection reset|recv failure|send failure/i,
    ],
    [
      'Connection timed out',
      /timed? out|curl 28\b/i,
    ],
    [
      'Temporary DNS failure',
      /could not resolve (?:host|proxy)|temporary failure in name resolution/i,
    ],
    [
      'Temporary HTTP failure',
      /returned error: (?:408|429|5\d\d)\b/i,
    ],
  ];
  const reason = transient.find(([, pattern]) => pattern.test(text))?.[0];

  if (!reason || permanent.some((pattern) => pattern.test(text))) {
    await skip('No recognized transient source-fetch failure was found.');
    return;
  }

  core.info(`${reason}; waiting one minute before retrying.`);
  await delay(interval);
  jobs = await history();
  remaining = budget(jobs);

  if (
    !(await current())
    || !failed(jobs.find((job) => job.id === source.id))
    || !remaining
    || remaining.attempts >= limit
  ) {
    await skip('The job was superseded, cancelled or has no retries left.');
    return;
  }

  const { job: created } = await rerunJob(api, source, jobs);

  await core.summary
    .addHeading(`Source fetch retry ${remaining.attempts + 1}/${limit}`)
    .addRaw(`${reason}. Revision: ${revision}.\n\n`)
    .addLink('Original job', jobBase + remaining.root.index)
    .addRaw('\n\n')
    .addLink(`Hercules job ${created.index}`, jobBase + created.index)
    .write();
}
