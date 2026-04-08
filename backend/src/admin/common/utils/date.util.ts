export function parseDateOnly(value: string): Date {
  const dateStr = value.includes('T') ? value.split('T')[0] : value;
  return new Date(`${dateStr}T00:00:00.000Z`);
}

export function parseTimeOnly(value: string): Date {
  const timeStr = value.includes('T') ? value.split('T')[1].slice(0, 5) : value;
  return new Date(`1970-01-01T${timeStr}:00.000Z`);
}

export function isTimeAfter(startTime: string, endTime: string): boolean {
  const start = parseTimeOnly(startTime).getTime();
  const end = parseTimeOnly(endTime).getTime();
  return end > start;
}

export function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10).replace(/-/g, '');
}
