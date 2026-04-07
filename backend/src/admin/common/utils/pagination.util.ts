import { PaginationQueryDto } from '../dto/pagination-query.dto';

export interface PaginationResult {
  page: number;
  limit: number;
  skip: number;
  take: number;
}

export function resolvePagination(query: PaginationQueryDto): PaginationResult {
  const page = query.page ?? 1;
  const limit = query.limit ?? 20;

  return {
    page,
    limit,
    skip: (page - 1) * limit,
    take: limit,
  };
}
