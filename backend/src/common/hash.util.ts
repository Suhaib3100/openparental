import { createHash, randomBytes, timingSafeEqual } from 'crypto';

/** SHA-256 hex. Used for high-entropy tokens (refresh / device secrets) where
 *  bcrypt's 72-byte truncation would silently weaken the hash. */
export function sha256(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

/** Constant-time string compare (both inputs are hex digests of equal length). */
export function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

/** URL-safe random token. */
export function randomToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

/** Short, human-typeable pairing code, e.g. "7F3K-9Q2M". */
export function pairingCode(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I/O/0/1
  const pick = () =>
    Array.from({ length: 4 }, () => alphabet[randomBytes(1)[0] % alphabet.length]).join('');
  return `${pick()}-${pick()}`;
}
