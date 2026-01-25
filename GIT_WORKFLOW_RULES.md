# 📋 Git Workflow Rules & Conflict Prevention Guide

**Project**: Clinic AI Booking  
**Purpose**: Quy tắc chi tiết để mỗi team member làm 2-3 chức năng mà không bị conflict Git  
**Last Updated**: 2026-01-22

---

## 📊 Bảng Phân Công Công Việc

### Backend (NestJS)

| # | Feature | Module | Files | Người phụ trách | Status |
|---|---------|--------|-------|-----------------|--------|
| 1 | ✅ **Auth** | `auth/` | auth.controller.ts, auth.service.ts, auth.module.ts | **[Người A]** | Done |
| 2 | ✅ **Appointments** | `appointments/` | appointments.controller.ts, appointments.service.ts | **[Người A]** | Done |
| 3 | ✅ **AI Triage** | `ai/` | ai.controller.ts, ai.service.ts | **[Người A]** | Done |
| 4 | **Doctors Management** | `doctors/` | doctors.controller.ts, doctors.service.ts, doctors.module.ts | **[Người B]** | In Progress |
| 5 | **Patients Management** | `patients/` | patients.controller.ts, patients.service.ts, patients.module.ts | **[Người B]** | In Progress |
| 6 | **Specialties Management** | `specialties/` | specialties.controller.ts, specialties.service.ts | **[Người B]** | In Progress |
| 7 | **Slots Management** | `slots/` | slots.controller.ts, slots.service.ts, slots.module.ts | **[Người C]** | To Do |
| 8 | **Clinics Management** | `clinics/` | clinics.controller.ts, clinics.service.ts, clinics.module.ts | **[Người C]** | To Do |
| 9 | **Users Management** | `users/` | users.controller.ts, users.service.ts, users.module.ts | **[Người C]** | To Do |
| 10 | **Admin Panel** | `admin/` | admin.controller.ts, admin.service.ts, admin.module.ts | **[Người D]** | To Do |
| 11 | **Notifications** | `notifications/` | notifications.controller.ts, notifications.service.ts | **[Người D]** | To Do |
| 12 | **Integration Testing** | `test/` | Các file .spec.ts | **[Người D]** | To Do |

### Mobile (Flutter)

| # | Feature | Folder | Files | Người phụ trách | Status |
|---|---------|--------|-------|-----------------|--------|
| 1 | ✅ **Auth & Login** | `features/auth/` | login_screen.dart, auth_service.dart | **[Người E]** | Done |
| 2 | ✅ **Home & Booking** | `features/booking/` | home_screen.dart, booking_service.dart | **[Người E]** | Done |
| 3 | **Doctor Search** | `features/doctor_portal/` | doctor_list_screen.dart, doctor_detail_screen.dart | **[Người F]** | In Progress |
| 4 | **AI Triage Form** | `features/ai_triage/` | triage_form_screen.dart, triage_service.dart | **[Người F]** | In Progress |
| 5 | **Admin Portal** | `features/admin_portal/` | admin_dashboard_screen.dart, admin_service.dart | **[Người G]** | To Do |
| 6 | **Appointment Details** | `features/appointments/` | appointment_detail_screen.dart, appointment_service.dart | **[Người G]** | To Do |
| 7 | **Profile Management** | `features/profile/` | profile_screen.dart, edit_profile_screen.dart | **[Người G]** | To Do |

---

## 🔐 Quy Tắc Cơ Bản Để Tránh Conflict

### 1️⃣ **Quy Tắc Ownership - Mỗi Module Một Chủ**

```
✅ ĐƯỢC PHÉP:
- Người A có toàn quyền sửa files trong /modules/auth/
- Người B có toàn quyền sửa files trong /modules/doctors/
- Người C có toàn quyền sửa files trong /modules/slots/ và /modules/clinics/

❌ KHÔNG ĐƯỢC PHÉP:
- Hai người sửa cùng một file trong cùng một module
- Sửa files của người khác mà không thông báo
- Sửa file dùng chung mà không coordination
```

### 2️⃣ **Files Dùng Chung - TUYỆT ĐỐI KHÔNG SỬA KHÔNG COORDINATION**

#### 📄 Files Shared trong Backend:

| File | Mục Đích | Quy Tắc |
|------|----------|--------|
| `app.module.ts` | Import tất cả modules | ⚠️ **CHỈ cộng 1 dòng `import { XxxModule }`** |
| `prisma/schema.prisma` | Database schema | ⚠️ **Mỗi người CHỈ thêm models cho module của mình** |
| `package.json` | Dependencies | ⚠️ **Thỏa thuận trước khi thêm package mới** |
| `tsconfig.json` | Cấu hình TypeScript | ❌ **KHÔNG động đến, để cho leader chỉnh** |
| `.env.example` | Environment variables | ⚠️ **Chỉ thêm khi có variable mới cho module** |

#### 📄 Files Shared trong Mobile:

| File | Mục Đích | Quy Tắc |
|------|----------|--------|
| `main.dart` | Entry point | ⚠️ **CHỈ thêm route & provider, không sửa khác** |
| `router.dart` | Navigation setup | ⚠️ **Mỗi người CHỈ thêm route riêng của mình** |
| `pubspec.yaml` | Dependencies | ⚠️ **Thỏa thuận trước khi thêm package** |
| `core/api/dio_client.dart` | HTTP client | ⚠️ **KHÔNG sửa, nếu cần → issue Discord trước** |

### 3️⃣ **Git Branching Strategy**

```
Cấu trúc branch chính:
├── main/                      (Production - KHÔNG push trực tiếp)
├── develop/                   (Integration - merge từ feature branches)
├── feature/auth-***           (Cho feature A - của Người A)
├── feature/doctors-***        (Cho feature B - của Người B)
├── feature/patients-***       (Cho feature C - của Người C)
├── feature/slots-***          (Cho feature D - của Người D)
└── bugfix/***                 (Hotfixes - chi khi cần)

❌ KHÔNG CÓ:
- Direct commits vào main hay develop
- Push từ main branch của local
```

### 4️⃣ **Git Commit & Push Workflow**

#### Bước 1: Tạo Feature Branch
```bash
# Mỗi người làm feature của mình
git checkout -b feature/doctors-crud-operations

# Naming convention:
# feature/[module-name]-[brief-description]
# Ví dụ:
# feature/doctors-list
# feature/patients-validation
# feature/slots-scheduling
```

#### Bước 2: Commit Message Format
```
Format:
[MODULE] ACTION: Description

Ví dụ hợp lệ:
✅ [doctors] FEAT: Add list doctors endpoint
✅ [patients] FIX: Fix patient validation in DTO
✅ [slots] REFACTOR: Optimize slot query performance
✅ [appointments] DOCS: Update appointment endpoints

❌ Không hợp lệ:
❌ "fix bug"
❌ "update stuff"
❌ "working on features"
❌ "test"

Quy tắc:
- FEAT: Feature mới
- FIX: Bug fix
- REFACTOR: Refactoring code
- DOCS: Documentation
- TEST: Test cases
- CHORE: Dependencies, config
```

#### Bước 3: Push & Pull Request
```bash
# Push lên feature branch (KHÔNG push main/develop)
git push origin feature/doctors-crud-operations

# Tạo Pull Request (PR) trên GitHub:
# - Title: [MODULE] ACTION: Brief Description
# - Description: Ngắn gọn giải thích gì đã làm
# - Assign reviewer (leader hoặc team member)
# - Link issues nếu có

❌ KHÔNG:
git push origin main
git push origin develop
```

#### Bước 4: Code Review & Merge
```
- Chờ 1-2 reviewer approve
- Sau approve: tự merge vào develop
- Sau 2-3 features hoàn thành: tạo release PR từ develop → main
- Leader merge vào main khi ready
```

### 5️⃣ **Quy Tắc Sửa File Dùng Chung**

#### 🔴 Khi cần thêm vào `app.module.ts`:
```typescript
// ❌ KHÔNG được sửa toàn bộ file
// ✅ CHỈ thêm 1 dòng import của module bạn

// app.module.ts - HIỆN TẠI
import { AuthModule } from './modules/auth/auth.module';
import { AppointmentsModule } from './modules/appointments/appointments.module';
import { AiModule } from './modules/ai/ai.module';

@Module({
  imports: [
    AuthModule,
    AppointmentsModule,
    AiModule,
    // ... others
  ],
})
export class AppModule {}

// NẾUPEOPLE B cần thêm DoctorsModule:
// ✅ CHỈ thêm 2 dòng:
import { DoctorsModule } from './modules/doctors/doctors.module';
// ... và thêm vào @Module imports array
DoctorsModule,

// ❌ KHÔNG sửa cấu trúc, comments, hay dòng khác
```

#### 🔴 Khi cần thêm vào `prisma/schema.prisma`:
```prisma
// ✅ Mỗi người CHỈ thêm models cho module của mình
// ❌ KHÔNG sửa models của người khác

// Người B thêm Doctor model:
model Doctor {
  id        Int     @id @default(autoincrement())
  name      String
  email     String  @unique
  // ...
}

// Người C thêm Slot model:
model Slot {
  id        Int     @id @default(autoincrement())
  doctorId  Int
  doctor    Doctor  @relation(fields: [doctorId], references: [id])
  // ...
}

// ❌ Người C KHÔNG được sửa Doctor model của Người B
```

#### 🔴 Khi cần thêm ENV variables:
```bash
# .env.example
DATABASE_URL="..."
JWT_SECRET="..."
JWT_REFRESH_SECRET="..."

# Nếu cần ENV mới cho module:
# 1. Thêm vào .env.example:
DOCTORS_API_KEY="your-api-key"

# 2. Comment giải thích:
# Doctors Module config
DOCTORS_API_KEY="your-api-key"

# ❌ KHÔNG thêm tùy tiện mà không documentation
```

---

## 🎯 Checklist Trước Khi Push Code

### ✅ Checklist cho mỗi commit:

- [ ] Branch đúng: `feature/[module-name]-***`
- [ ] KHÔNG push vào `main` hay `develop`
- [ ] Commit message theo format: `[MODULE] ACTION: Description`
- [ ] Code đã test locally: `npm run test` (backend) hoặc `flutter test` (mobile)
- [ ] KHÔNG có console.log hoặc debug code
- [ ] KHÔNG sửa files của người khác mà không thông báo
- [ ] KHÔNG thêm dependencies mà không coordination
- [ ] Chỉ sửa files trong module của bạn
- [ ] Nếu sửa file shared → ghi lại trong PR description
- [ ] ESLint/Prettier passed: `npm run lint`

### ✅ Checklist trước tạo PR:

- [ ] Feature hoàn thành & test đầy đủ
- [ ] Rebase mới nhất từ `develop`: `git rebase origin/develop`
- [ ] Conflict đã resolve (nếu có)
- [ ] Title PR: `[MODULE] ACTION: Description`
- [ ] Description rõ ràng về gì đã làm
- [ ] Có screenshot/video nếu là UI changes
- [ ] Assign reviewer
- [ ] Self-review code trước submit

---

## 🚨 Conflict Resolution Guide

### Nếu có conflict khi rebase/merge:

```bash
# 1. Pull latest develop
git fetch origin
git rebase origin/develop

# 2. VS Code sẽ show conflict markers
# Ở editor, chọn "Accept Current Change" hoặc "Accept Incoming Change"

# 3. Hoặc edit thủ công:
# <<<<<<< HEAD
# Mã của bạn
# =======
# Mã từ develop
# >>>>>>> origin/develop

# 4. Xóa conflict markers và keep cả hai nếu cần

# 5. Stage & continue
git add .
git rebase --continue

# 6. Push lại
git push origin feature/branch-name -f
```

### Common Conflict Scenarios:

#### Scenario 1: Conflict trong `app.module.ts`
```
❌ PROBLEM:
- Người A thêm AuthModule
- Người B thêm DoctorsModule
- Cùng lúc push → conflict

✅ SOLUTION:
git rebase origin/develop
# VS Code hiện conflict
# Chọn "Accept Both" → import cả 2
# Resolve xong → git add . → git rebase --continue
```

#### Scenario 2: Conflict trong `prisma/schema.prisma`
```
❌ PROBLEM:
- Người A thêm Appointment model
- Người B thêm Doctor model
- Rebase → conflict

✅ SOLUTION:
# Edit thủ công: giữ lại cả 2 models
model Doctor { ... }
model Appointment { ... }
# Git add & rebase --continue
```

#### Scenario 3: Conflict trong `package.json`
```
❌ PROBLEM:
- Người A thêm package X
- Người B thêm package Y
- Git conflict

✅ SOLUTION:
# 1. Chọn "Accept Both"
# 2. Hoặc:
npm install  # Install dependencies mới
git add package-lock.json package.json
git rebase --continue
```

---

## 📞 Communication Protocol

### 🔔 Khi cần sửa file shared:

**Channel**: Discord / Project Chat

**Message Template**:
```
[⚠️ FILE LOCK] 
Module: [Doctors]
File: prisma/schema.prisma
Action: Adding Doctor & Specialty models
Duration: ~30 minutes
Team: Please don't touch this file until done!

Status: 🟢 STARTED → 🟢 IN PROGRESS → 🟢 DONE
```

### 🔔 Khi pull request:

**Discord Notification**:
```
[🔀 PR READY]
Title: [doctors] FEAT: Add list doctors endpoint
Link: [GitHub PR Link]
Reviewer: @Person X
Changes: Added GET /doctors endpoint with pagination
```

### 🔔 Trước merge major changes:

**Discord Standup**:
```
[📊 STANDUP]
Time: [HH:MM]
What Done: Feature X hoàn thành
What Next: Feature Y
Blockers: None / [Issue]
```

---

## 📋 Daily Workflow Template

### Bắt đầu ngày (Morning):
```bash
# 1. Pull latest
git fetch origin
git checkout develop
git pull origin develop

# 2. Tạo feature branch mới
git checkout -b feature/doctors-list

# 3. Code...
```

### Giữa ngày (Midday):
```bash
# 4. Commit khi xong sub-task
git add .
git commit -m "[doctors] FEAT: Add list doctors endpoint"

# 5. Push (KHÔNG force push nếu không cần)
git push origin feature/doctors-list

# 6. Nếu cần update từ develop:
git fetch origin
git rebase origin/develop
# Nếu có conflict → resolve
git push origin feature/doctors-list -f
```

### Kết thúc ngày (EOD):
```bash
# 7. Push các commits cuối cùng
git push origin feature/doctors-list

# 8. Tạo PR nếu feature xong
# Hoặc comment PR: "WIP - 80% done"

# 9. Notify team
# "Feature X - 80% done, PR ready for review tomorrow"
```

---

## 🎓 Best Practices

### DO ✅
- ✅ Commit nhỏ, thường xuyên (mỗi sub-task)
- ✅ Pull mới nhất trước push
- ✅ Rebase thường để tránh conflict lớn
- ✅ Communicate trước sửa file shared
- ✅ Test code trước push
- ✅ Write descriptive commit messages
- ✅ Code review từ peer trước merge
- ✅ Use feature branches cho mọi feature
- ✅ Document nếu có breaking changes

### DON'T ❌
- ❌ Push trực tiếp vào main/develop
- ❌ Commit `node_modules`, `.env`, build artifacts
- ❌ Sửa code người khác mà không notification
- ❌ Merge PR của bạn (chờ người khác approve)
- ❌ Rebase -f push 3 lần (clean up local thay vì)
- ❌ Commit "WIP", "test", "debug" code
- ❌ Thêm dependencies không team approval
- ❌ Sửa file config (tsconfig, eslintrc) riêng
- ❌ Ignore conflict → cứ merge

---

## 📞 Escalation Path

### Nếu stuck hoặc conflict lớn:

1. **Level 1**: Hỏi team member qua Discord
2. **Level 2**: Gọi/chat với person sở hữu module đó
3. **Level 3**: Gọi leader để resolve conflict
4. **Level 4**: Revert commit + discuss solution

**Tuyệt đối KHÔNG** force push mà không notification!

---

## 🎉 Summary Table

| Situation | Action | Approval |
|-----------|--------|----------|
| Tạo feature branch | Tự do | ✅ |
| Commit vào feature branch | Tự do | ✅ |
| Push feature branch | Tự do | ✅ |
| Tạo PR | Tự do | ✅ |
| Merge PR vào develop | Cần 1 approve | ⚠️ |
| Merge develop → main | Cần leader | 🔴 |
| Push trực tiếp main/develop | BAN | ❌ |
| Sửa file shared | Cần thông báo | ⚠️ |
| Thêm dependencies | Cần team vote | ⚠️ |
| Rebase -f push | Cần context | ⚠️ |

---

**Người tạo**: Project Lead  
**Ngày cập nhật**: 2026-01-22  
**Version**: 1.0  
**Status**: Ready for team adoption 🚀
