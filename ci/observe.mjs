import { requestJson } from './http.mjs';
import { deployHandler } from './hercules.mjs';

export default async function ({ core }) {
  const herculesApi = 'https://hercules-ci.com/api/v1';
  const deadline = Date.now() + 175 * 60 * 1000;
  const { host, revision } = JSON.parse(process.env.REQUEST);

  while (Date.now() < deadline) {
    const job = await requestJson(`${herculesApi}/jobs/${process.env.JOB}`, {
      retryDelay: () => 10000,
    });

    if (
      job.id !== process.env.JOB
      || job.rerunOf !== process.env.ROOT_JOB
      || job.projectId !== process.env.PROJECT
      || job.ownerName !== 'brsvh'
      || job.repoName !== 'fleet'
      || job.source.ref !== 'refs/heads/main'
      || job.source.revision !== revision
      || job.jobType !== 'OnPush'
      || job.jobName !== deployHandler(host)
    ) {
      throw new Error('The Hercules job does not match this deployment');
    }

    if (job.isCancelled) {
      throw new Error('The approved Hercules deployment was cancelled');
    }

    if (job.jobPhase === 'Done') {
      if (job.jobStatus !== 'Success' || job.effectsStatus !== 'Success') {
        throw new Error(`Hercules deployment failed: job ${job.index}`);
      }

      core.info(`Hercules deployment completed: job ${job.index}`);
      return;
    }

    await new Promise((resolve) => setTimeout(resolve, 15000));
  }

  throw new Error('Timed out observing the Hercules deployment');
}
