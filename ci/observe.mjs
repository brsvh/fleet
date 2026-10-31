import { requestJson } from './http.mjs';

export default async function ({ core }) {
  const herculesApi = 'https://hercules-ci.com/api/v1';
  const deadline = Date.now() + 175 * 60 * 1000;

  while (Date.now() < deadline) {
    const job = await requestJson(`${herculesApi}/jobs/${process.env.JOB}`, {
      retryDelay: () => 10000,
    });

    if (job.rerunOf !== process.env.SOURCE_JOB || job.isCancelled) {
      throw new Error('The approved Hercules release was cancelled');
    }

    if (job.jobPhase === 'Done') {
      if (job.jobStatus !== 'Success' || job.effectsStatus !== 'Success') {
        throw new Error(`Hercules release failed: job ${job.index}`);
      }

      core.info(`Hercules release completed: job ${job.index}`);
      return;
    }

    await new Promise((resolve) => setTimeout(resolve, 15000));
  }

  throw new Error('Timed out observing the Hercules release');
}
