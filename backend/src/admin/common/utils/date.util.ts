export function parseDateOnly(value: string): Date {
  return new Date(`${value}T00:00:00.000Z`);
}

export function parseTimeOnly(value: string): Date {
  return new Date(`1970-01-01T${value}:00.000Z`);
}

export function isTimeAfter(startTime: string, endTime: string): boolean {
  return parseTimeOnly(endTime).getTime() > parseTimeOnly(startTime).getTime();
}

export function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10).replace(/-/g, '');
}
