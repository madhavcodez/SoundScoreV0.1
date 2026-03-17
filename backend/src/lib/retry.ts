export async function withRetry<T>(
  fn: () => Promise<T>,
  options?: {
    maxAttempts?: number;
    backoffMs?: number;
    maxBackoffMs?: number;
    onRetry?: (attempt: number, error: unknown) => void;
  },
): Promise<T> {
  const maxAttempts = options?.maxAttempts ?? 3;
  const baseBackoff = options?.backoffMs ?? 1000;
  const maxBackoff = options?.maxBackoffMs ?? 64000;

  let lastError: unknown;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < maxAttempts - 1) {
        const delay = Math.min(baseBackoff * 2 ** attempt, maxBackoff);
        options?.onRetry?.(attempt + 1, error);
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError;
}
