import { setTimeout as delay } from 'node:timers/promises';

export async function requestJson(url, options = {}) {
  const {
    token,
    method = 'GET',
    body,
    accept = 'application/json',
    noContent = false,
    missing = false,
    attempts = 5,
    retryDelay = (attempt) => 1000 * 2 ** attempt,
  } = options;
  const retryable = method === 'GET' || method === 'PUT';

  for (let attempt = 0; ; attempt += 1) {
    let response;

    try {
      response = await fetch(url, {
        method,
        headers: {
          accept,
          ...(token
            ? {
                authorization: `Bearer ${token}`,
              }
            : {}),
          'content-type':
            method === 'PUT' ? 'application/octet-stream' : 'application/json',
          'user-agent': 'fleet-ci',
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        redirect: 'error',
        signal: AbortSignal.timeout(30000),
      });

      if (response.ok) {
        if (noContent) {
          await response.arrayBuffer();
          return null;
        }

        return response.status === 204 ? null : await response.json();
      }
    } catch (error) {
      if (
        error instanceof SyntaxError
        || !retryable
        || attempt === attempts - 1
      ) {
        throw error;
      }

      await delay(retryDelay(attempt));
      continue;
    }

    try {
      await response.body?.cancel();
    } catch {
      // A broken error body must not override its HTTP status.
    }

    if (missing && response.status === 404) {
      return null;
    }

    if (
      !retryable
      || attempt === attempts - 1
      || ![
        408,
        429,
        500,
        502,
        503,
        504,
      ].includes(response.status)
    ) {
      throw new Error(
        `${method} ${new URL(url).pathname}: HTTP ${response.status}`,
      );
    }

    await delay(retryDelay(attempt));
  }
}
