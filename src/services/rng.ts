export interface Rng {
  readonly state: number;
  next(): number;
}

export function createRng(seed: number): Rng {
  let state = seed >>> 0;

  return {
    get state() {
      return state >>> 0;
    },
    next() {
      state = (state + 0x6d2b79f5) >>> 0;
      let t = state;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    },
  };
}

export function rollPercent(rng: Rng, displayedPercent: number, doubleRng: boolean): boolean {
  const clamped = Math.max(0, Math.min(100, displayedPercent));
  const roll = doubleRng ? ((rng.next() + rng.next()) / 2) * 100 : rng.next() * 100;
  return roll < clamped;
}
