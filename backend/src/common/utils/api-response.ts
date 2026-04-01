export function okResponse<T>(message: string, data: T) {
  return {
    success: true,
    message,
    data,
  };
}

export function paginatedResponse<T>(
  message: string,
  items: T[],
  page: number,
  limit: number,
  totalItems: number,
) {
  return {
    success: true,
    message,
    data: {
      items,
      pagination: {
        page,
        limit,
        totalItems,
        totalPages: Math.max(1, Math.ceil(totalItems / limit)),
      },
    },
  };
}
