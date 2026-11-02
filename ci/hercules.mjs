import { setTimeout as delay } from 'node:timers/promises';
import { requestRejected } from './http.mjs';

export function deployHandler(host) {
  return `deployHost/${host}`;
}

function kind(job) {
  return job.jobType === 'Legacy' ? 'Config' : job.jobType;
}

export function sameTask(job, source) {
  return (
    job.projectId === source.projectId
    && job.ownerName === source.ownerName
    && job.repoName === source.repoName
    && job.source.ref === source.source.ref
    && job.source.revision === source.source.revision
    && kind(job) === kind(source)
    && job.jobName === source.jobName
  );
}

export async function jobHistory(api, revision) {
  const project = '/site/github/account/brsvh/project/fleet';
  const query = new URLSearchParams({
    rev: revision,
    limit: '100',
  });
  const jobs = [];

  for (let page = 0; page < 10; page += 1) {
    const { items } = await api(`${project}/jobs?${query}`);
    jobs.push(...items);

    if (items.length < 100) {
      return jobs;
    }

    query.set('offsetIndex', String(items.at(-1).index));
  }

  throw new Error('Too many jobs to establish the Hercules rerun history');
}

export function jobFamily(source, jobs) {
  const tasks = jobs.filter((job) => sameTask(job, source));
  const byId = new Map(
    tasks.map((job) => [
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

  const family = new Map([
    [
      root.id,
      root,
    ],
  ]);

  for (const job of tasks.toSorted((a, b) => a.index - b.index)) {
    if (family.has(job.rerunOf)) {
      family.set(job.id, job);
    }
  }

  if (!family.has(source.id)) {
    throw new Error('The source job is outside its Hercules rerun family');
  }

  return {
    root,
    jobs: [
      ...family.values(),
    ],
  };
}

export async function rerunJob(api, source, jobs) {
  const { root } = jobFamily(source, jobs);
  const before = new Set(jobs.map((job) => job.id));
  let created;

  try {
    created = await api(`/jobs/${source.id}/rerun`, {
      method: 'POST',
    });
  } catch (error) {
    if (requestRejected(error)) {
      throw error;
    }

    // A lost POST response must not cause another rerun request.
    for (let attempt = 0; attempt < 4 && !created; attempt += 1) {
      await delay(3000);
      let history;

      try {
        history = await jobHistory(api, source.source.revision);
      } catch (cause) {
        // A rejected GET says nothing about whether the POST was accepted.
        throw new Error('Rerun response lost and history unavailable', {
          cause,
        });
      }

      const matches = history.filter(
        (job) =>
          !before.has(job.id)
          && sameTask(job, source)
          && job.rerunOf === root.id,
      );

      if (matches.length > 1) {
        throw new Error('Multiple new Hercules reruns; inspect them manually', {
          cause: error,
        });
      }

      [created] = matches;
    }

    if (!created) {
      throw error;
    }
  }

  if (
    before.has(created.id)
    || !sameTask(created, source)
    || created.rerunOf !== root.id
    || created.index <= source.index
    || created.isCancelled
  ) {
    throw new Error('Unexpected Hercules rerun result');
  }

  return {
    job: created,
    root,
  };
}
