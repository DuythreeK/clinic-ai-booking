# Implement Auth Module DTOs, Docker Setup, and Authentication Flow

This plan will address generating the DTOs from `openapi.json`, setting up MySQL using Docker, and implementing the full authentication flow utilizing NestJS and Prisma.

## User Review Required

> [!WARNING]
> This will overwrite your existing `auth.controller.ts`, `auth.service.ts`, and `auth.dto.ts` directly, as their current shapes conflict with the newly provided Prisma schema and OpenAPI expectations.

> [!IMPORTANT]
> The default `@nestjs/common` validation pipe will automatically serialize data, but Prisma returns database records containing JS `BigInt`s (e.g. `userId`). Unless patched, this causes a `TypeError: Do not know how to serialize a BigInt`. To resolve this natively across all endpoints, the plan modifies `main.ts` to monkey-patch `BigInt.prototype.toJSON = function() { return this.toString() }`.

## Proposed Changes

### Docker and Database

Set up the MySQL database container. Note: I assume we want `.env` to be updated with the Docker connection strings. 

#### [NEW] [docker-compose.yml](file:///c:/Users/ADMIN/Desktop/developer/app/clinic-ai-booking/docker-compose.yml)
- A standard docker-compose defining `mysql:8.0`, exposing port 3306 with a default database and credentials `admin:admin`.
- Updates the connection strings under `backend/.env`.

---

### Backend Bootstrapping

#### [MODIFY] [main.ts](file:///c:/Users/ADMIN/Desktop/developer/app/clinic-ai-booking/backend/src/main.ts)
- Add the `BigInt` prototype monkey patch so that whenever `class-transformer` or `express` attempts to `JSON.stringify` a response, `BigInt` acts as a string automatically.

---

### Auth Module Implementation

#### [MODIFY] [auth.dto.ts](file:///c:/Users/ADMIN/Desktop/developer/app/clinic-ai-booking/backend/src/modules/auth/dto/auth.dto.ts)
- Delete all existing DTOs.
- Generate new DTO classes from `openapi.json` (`RegisterRequest`, `LoginRequest`, `RefreshTokenRequest`, `ForgotPasswordRequest`, `ResetPasswordRequest`) using `class-validator` operators.

#### [MODIFY] [auth.controller.ts](file:///c:/Users/ADMIN/Desktop/developer/app/clinic-ai-booking/backend/src/modules/auth/auth.controller.ts)
- Remap HTTP request/responses:
  - `POST /auth/register`
  - `POST /auth/login`
  - `POST /auth/refresh`
  - `POST /auth/forgot-password`
  - `POST /auth/reset-password`
  - `POST /auth/logout`

#### [MODIFY] [auth.service.ts](file:///c:/Users/ADMIN/Desktop/developer/app/clinic-ai-booking/backend/src/modules/auth/auth.service.ts)
- Re-architect queries matching `schema.prisma` logic.
- Register user uses `userId`, `role`, `fullName`, `email`, `phone`, `password_hash`.
- Validates passwords using `bcrypt`.
- Signs JWT using `{ sub: userId, email, role }`.
- Insert token to `tblRefreshTokens` using database `RefreshTokens` model via Prisma.

## Verification Plan

### Automated Tests
- Run `docker-compose up -d` to spin up MySQL.
- Run `npx prisma db push` in the backend directory to apply schemas to MySQL DB.
- Build and start the NestJS server.
- No direct unit test files touched, verify compiler errors are resolved.

### Manual Verification
- A user can optionally test the `/api/v1/auth/register` API via Postman/cUrl to confirm the user gets created correctly in the database without `BigInt` errors.
