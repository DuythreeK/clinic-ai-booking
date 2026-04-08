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

export function formatCurrencyVnd(
  value: number | string | bigint | null | undefined,
  suffix = 'đ',
) {
  if (value === null || value === undefined) {
    return null;
  }

  const amount = Number(value);
  if (Number.isNaN(amount)) {
    return null;
  }

  return `${amount.toLocaleString('vi-VN')}${suffix}`;
}

export function splitfull_name(full_name: string | null | undefined) {
  const normalized = (full_name ?? '').trim();
  if (!normalized) {
    return { firstName: '', lastName: '' };
  }

  const parts = normalized.split(/\s+/);
  if (parts.length === 1) {
    return { firstName: normalized, lastName: '' };
  }

  return {
    firstName: parts.slice(0, -1).join(' '),
    lastName: parts[parts.length - 1],
  };
}
