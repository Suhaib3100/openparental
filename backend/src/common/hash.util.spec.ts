import { pairingCode, randomToken, safeEqual, sha256 } from './hash.util';

describe('hash.util', () => {
  it('sha256 is deterministic and 64 hex chars', () => {
    expect(sha256('abc')).toBe(sha256('abc'));
    expect(sha256('abc')).toMatch(/^[0-9a-f]{64}$/);
    expect(sha256('abc')).not.toBe(sha256('abd'));
  });

  it('safeEqual matches equal digests and rejects others', () => {
    const a = sha256('secret');
    expect(safeEqual(a, sha256('secret'))).toBe(true);
    expect(safeEqual(a, sha256('nope'))).toBe(false);
    expect(safeEqual(a, 'short')).toBe(false); // different length, no throw
  });

  it('pairingCode matches the human-typeable format', () => {
    for (let i = 0; i < 50; i++) {
      expect(pairingCode()).toMatch(/^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/);
    }
  });

  it('randomToken is url-safe and unique', () => {
    const a = randomToken();
    const b = randomToken();
    expect(a).not.toBe(b);
    expect(a).toMatch(/^[A-Za-z0-9_-]+$/);
  });
});
