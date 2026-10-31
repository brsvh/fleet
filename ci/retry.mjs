import { setTimeout as delay } from 'node:timers/promises';
import { requestJson } from './http.mjs';

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
    || payload.context !== 'ci/hercules/evaluation'
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
  const projectApi = '/site/github/account/brsvh/project/fleet';
  const interval = 60000;
  const limit = 5;

  const api = (path, method = 'GET') =>
    requestJson(`${herculesApi}${path}`, {
      token,
      method,
      attempts: 3,
      retryDelay: () => interval,
    });

  async function history() {
    const query = new URLSearchParams({
      rev: revision,
      limit: '100',
    });
    const jobs = [];

    for (let page = 0; page < 10; page += 1) {
      const { items } = await api(`${projectApi}/jobs?${query}`);
      jobs.push(...items);

      if (items.length < 100) {
        return jobs;
      }

      query.set('offsetIndex', String(items.at(-1).index));
    }

    throw new Error('Too many jobs to establish a safe retry budget');
  }

  function configuration(job) {
    return (
      job?.ownerName === 'brsvh'
      && job.repoName === 'fleet'
      && /^[0-9a-f-]{36}$/.test(job.id)
      && job.source.revision === revision
      && [
        'refs/heads/main',
        'refs/heads/develop',
      ].includes(job.source.ref)
      && [
        'Config',
        'Legacy',
      ].includes(job.jobType)
      && job.jobName === null
    );
  }

  function failed(job) {
    return (
      configuration(job)
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
    await skip('The job is not a failed repository configuration fetch.');
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
    const family = history.filter(
      (job) =>
        configuration(job)
        && job.projectId === source.projectId
        && job.source.ref === source.source.ref,
    );
    const byId = new Map(
      family.map((job) => [
        job.id,
        job,
      ]),
    );
    const visited = new Set();
    let root = source;

    while (root.rerunOf) {
      if (visited.has(root.id) || !byId.has(root.rerunOf)) {
        throw new Error('Incomplete or invalid Hercules rerun history');
      }

      visited.add(root.id);
      root = byId.get(root.rerunOf);
    }

    const descendants = new Set([
      root.id,
    ]);

    for (const job of family.toSorted((a, b) => a.index - b.index)) {
      if (descendants.has(job.rerunOf)) {
        descendants.add(job.id);
      }
    }

    // A newer configuration job also covers manual retries of this revision.
    if (family.some((job) => job.index > source.index)) {
      return null;
    }

    return {
      root,
      attempts: descendants.size - 1,
    };
  }

  if (!(await current())) {
    await skip('The branch has moved to another revision.');
    return;
  }

  let remaining = budget(jobs);

  if (!remaining || remaining.attempts >= limit) {
    await skip('A newer job exists or the five-retry budget is exhausted.');
    return;
  }

  const evaluation = await api(`/jobs/${source.id}/evaluation`);
  const attributes = evaluation.attributes;
  const message = attributes?.[0]?.value?.Error?.errorMessage;

  const clean = (text) => text.replace(/\x1b\[[0-9;]*m/g, '');

  const input =
    typeof message === 'string'
      ? clean(message).match(/while fetching the input '([^']+)'/)?.[1]
      : null;
  const repository = 'git+https://github.com/brsvh/fleet.git';
  const url = input?.startsWith(`${repository}?`) ? new URL(input) : null;

  if (
    attributes?.length !== 1
    || attributes[0].path.length !== 0
    || !url
    || url.searchParams.get('rev') !== revision
    || url.searchParams.get('ref') !== source.source.ref
    || !clean(message).includes('Failed to fetch git repository')
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

  const text = clean(log.lines.map((line) => line.t).join('\n'));
  const permanent = [
    /authentication failed|permission denied|access denied/i,
    /could not read (?:username|password)|repository .*not found/i,
    /requested URL returned error: (?:400|401|403|404|410)\b/i,
    /SSL certificate problem|certificate verification failed/i,
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
      /could not resolve (?:host|proxy)/i,
    ],
    [
      'Temporary DNS failure',
      /temporary failure in name resolution/i,
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

  let created;

  try {
    created = await api(`/jobs/${source.id}/rerun`, 'POST');
  } catch (error) {
    // A lost POST response must not cause a second rerun request.
    for (let attempt = 0; attempt < 3 && !created; attempt += 1) {
      await delay(interval);
      created = (await history()).find((job) => job.rerunOf === source.id);
    }

    if (!created) {
      throw error;
    }
  }

  if (
    !configuration(created)
    || created.rerunOf !== source.id
    || created.projectId !== source.projectId
    || created.source.ref !== source.source.ref
  ) {
    throw new Error('Unexpected Hercules rerun result');
  }

  await core.summary
    .addHeading(`Source fetch retry ${remaining.attempts + 1}/${limit}`)
    .addRaw(`${reason}. Revision: ${revision}.\n\n`)
    .addLink('Original job', jobBase + remaining.root.index)
    .addRaw('\n\n')
    .addLink(`Hercules job ${created.index}`, jobBase + created.index)
    .write();
}
