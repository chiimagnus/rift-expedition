export interface PageSlice<T> {
  page: number;
  totalPages: number;
  start: number;
  end: number;
  items: T[];
}

export function pageSlice<T>(items: readonly T[], page: number, pageSize: number): PageSlice<T> {
  if (pageSize <= 0) {
    throw new Error("pageSize must be positive");
  }
  const totalPages = Math.max(1, Math.ceil(items.length / pageSize));
  const safePage = clamp(Math.trunc(page), 0, totalPages - 1);
  const start = safePage * pageSize;
  const end = Math.min(items.length, start + pageSize);
  return {
    page: safePage,
    totalPages,
    start,
    end,
    items: items.slice(start, end),
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}
