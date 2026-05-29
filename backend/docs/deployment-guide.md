# Hướng dẫn cài đặt và triển khai

Tài liệu này mô tả các bước cài đặt, chạy trong môi trường phát triển và triển khai sản phẩm cho backend và mobile của dự án.

**Tệp tham khảo**
- [backend/prisma/schema.prisma](backend/prisma/schema.prisma)
- [docker-compose.yml](docker-compose.yml)
- [backend/prisma/seed.ts](backend/prisma/seed.ts)
- [backend/docs/report-tables.md](backend/docs/report-tables.md)
- [backend/docs/appointment-sequence.md](backend/docs/appointment-sequence.md)

**Tổng quan ngắn**
- Backend: NestJS + Prisma (MySQL). API prefix mặc định là `/api` (xem `backend/src/main.ts`).
- Mobile: Flutter client (cấu hình `API_BASE_URL` để trỏ tới backend).

**Yêu cầu**
- Node.js 18+ và npm/yarn
- pnpm optional (tuỳ repo) hoặc npm
- Java & Android SDK, Xcode (nếu chạy mobile trên iOS)
- Flutter SDK cho mobile
- MySQL 8+ (hoặc tương thích)
- Docker & Docker Compose (tuỳ chọn triển khai bằng container)

**Biến môi trường quan trọng (backend)**
- `DATABASE_URL` — kết nối MySQL (ví dụ: `mysql://user:pass@host:3306/dbname`)
- `JWT_SECRET` — khoá bí mật cho JWT
- `PORT` — port backend (mặc định 3000)
- `NODE_ENV` — `development` | `production`
- `VNPAY_*` hoặc `PAYMENT_*` — thông tin gateway thanh toán (sandbox/production)
- `FCM_SERVER_KEY` — nếu gửi push notification qua FCM

Đặt biến môi trường trong file `.env` tại `backend/` (không commit file chứa secret).

Cài đặt và chạy môi trường phát triển (backend)

1. Cài dependencies

```bash
cd backend
npm install
# hoặc: yarn install
```

2. Tạo/migrate database và seed (dev)

```bash
# sinh Prisma client
npx prisma generate
# chạy migration (nếu dùng migrations)
npx prisma migrate dev --name init
# seed dữ liệu (nếu có)
node prisma/seed.js || ts-node prisma/seed.ts
```

3. Chạy backend

```bash
# chế độ phát triển (hot-reload)
npm run start:dev
# hoặc chạy production build
npm run build
npm run start:prod
```

Cài đặt và chạy mobile (dev)

```bash
cd mobile
flutter pub get
# chỉnh API base URL trong config hoặc file môi trường của mobile
flutter run
```

Chạy bằng Docker Compose (ví dụ nhanh)

```bash
# ở root project
docker-compose up --build
```

File `docker-compose.yml` có thể chứa dịch vụ `db` (MySQL), `backend` và `mobile` hoặc chỉ `backend`. Kiểm tra và cập nhật biến môi trường trong compose.

Migrate & Seed khi triển khai

- Trước khi chạy backend lần đầu trong môi trường mới, chạy `npx prisma migrate deploy` (production) để áp migrations đã tạo.
- Không chạy `migrate dev` trong production.
- Chỉ seed dữ liệu khởi tạo nếu cần; đảm bảo seed idempotent.

Triển khai Production — checklist ngắn

- Secrets: lưu `DATABASE_URL`, `JWT_SECRET`, `PAYMENT_*`, `FCM_SERVER_KEY` trong secret manager (Vault, AWS Secrets Manager, GitHub Secrets, hoặc k8s secrets).
- TLS/HTTPS: cấu hình reverse proxy (Nginx, Traefik) hoặc load balancer để cung cấp HTTPS.
- Reverse proxy: chuyển tiếp requests tới backend (port nội bộ), bật HTTP/2 nếu cần.
- CORS: cấu hình nguồn tin cậy cho mobile/web.
- Scale: Backend nên là stateless; sử dụng multiple replicas và shared DB. Đặt connection pool size hợp lý cho Prisma/MySQL.
- Migrations: chạy `npx prisma migrate deploy` trong pipeline CI/CD trước khi khởi động container backend.
- Health check: endpoints /health hoặc `/api/health` để orchestrator (systemd/ K8s) kiểm tra.

Lưu ý quan trọng & khuyến nghị kỹ thuật

- Giao dịch booking (quan trọng):
  - `AppointmentsService.createAppointment` đang sử dụng `prisma.$transaction` và `updateMany(where available_count > 0 ...)` để tránh overbooking. Khi triển khai, kiểm thử tải đồng thời để đảm bảo không có race condition.
  - Nếu cần mở rộng, cân nhắc thêm layer lock (Redis distributed lock) hoặc giảm thời gian giữ slot tạm bằng cách lock/hold ngắn hạn.

- Kết nối DB & pool:
  - Giới hạn kết nối đồng thời tới MySQL. Prisma tạo client trên mỗi instance process; khi scale nhiều replica, monitor connection count.

- Thanh toán (payments):
  - Đặt callback/callback URL chính xác trong dashboard của payment gateway.
  - Handle callback idempotently (service hiện cập nhật Payment theo `transaction_code`). Kiểm tra tính an toàn với nhiều callback.
  - Sử dụng sandbox để test trước khi chuyển sang production.

- Notification (push/SMS):
  - Xác định credential FCM/SMTP/3rd party và lưu an toàn.
  - Tích hợp queue hoặc worker (Bull/Redis) nếu gửi nhiều push để tránh chặn luồng web request.

- Bảo mật
  - Giữ `JWT_SECRET` mạnh và đổi thường xuyên khi nghi ngờ rò rỉ.
  - Hạn chế thông tin nhạy cảm trong logs.
  - Dùng HTTPS bắt buộc cho production.
  - Thiết lập rate-limiting nếu cần (throttle các API nhạy cảm).

- Logging và monitoring
  - Ghi logs có cấu trúc (JSON) để ship lên ELK/Datadog/Prometheus/Grafana.
  - Thêm metrics: request latency, DB connections, error rate, booking failure rate.

- Backup & Restore
  - Thiết lập backup định kỳ cho MySQL và verify restore procedure.

- CI/CD suggestions
  - Pipeline: linter -> tests -> build -> migrate (deploy) -> deploy
  - Trước migrate, chạy migration dry-run và backup DB.

- Cấu hình môi trường cho mobile
  - Đặt `API_BASE_URL` thành endpoint production (ví dụ `https://api.example.com/api`).
  - Kiểm tra auth flow (JWT) và token refresh nếu mobile cần refresh token.

Một số lệnh hữu ích tóm tắt

```bash
# backend
cd backend
npm install
npx prisma generate
npx prisma migrate deploy
npm run build
npm run start:prod

# docker compose
docker-compose up --build -d

# mobile
cd mobile
flutter pub get
flutter run
```

Tệp tài liệu liên quan
- Bản đồ luồng: [backend/docs/appointment-sequence.md](backend/docs/appointment-sequence.md)
- Bảng mapping: [backend/docs/report-tables.md](backend/docs/report-tables.md)

Nếu bạn muốn, tôi có thể:
- Tạo `backend/.env.example` chứa các biến môi trường mẫu.
- Viết script `deploy.sh` hoặc file `Dockerfile`/`k8s` manifest mẫu.
- Thêm health check endpoint hoặc kiểm thử tải cho flow booking.

---
