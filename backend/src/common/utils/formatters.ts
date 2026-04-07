export function toNumberId(value: bigint | number | string | null | undefined) {
  if (value === null || value === undefined) {
    return null;
  }
  return Number(value);
}

export function formatDateOnly(value: Date | string | null | undefined) {
  if (!value) {
    return null;
  }
  const date = value instanceof Date ? value : new Date(value);
  return date.toISOString().slice(0, 10);
}

export function formatTimeOnly(value: Date | string | null | undefined) {
  if (!value) {
    return null;
  }
  const date = value instanceof Date ? value : new Date(value);
  return date.toISOString().slice(11, 16);
}
