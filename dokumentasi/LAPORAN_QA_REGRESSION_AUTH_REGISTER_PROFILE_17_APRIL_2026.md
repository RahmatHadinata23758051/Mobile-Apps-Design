# Laporan QA Regression - Auth Register dan Profile

Tanggal eksekusi: 17 April 2026  
Project: Mobile HERA v2.0  
Card Trello: **Mobile - QA Regression Auth Register dan Profile**  
Environment backend: `http://103.217.145.187:8000`

## Scope Skenario

- Test register sukses/gagal
- Test login setelah register
- Test fetch profile
- Test update profile
- Test change password + relogin
- Verifikasi seluruh skenario critical pass
- Verifikasi tidak ada blocker P1 pada fitur auth/profile

## Metode Uji

Eksekusi dilakukan langsung ke endpoint backend VPS menggunakan request HTTP otomatis (PowerShell + `curl.exe`) dengan akun uji dinamis (timestamp) agar tidak bentrok data.

Catatan penting kontrak backend:
- Endpoint register membutuhkan `password_confirmation`.
- Payload yang konsisten terbaca oleh backend pada pengujian ini: `application/x-www-form-urlencoded`.

## Hasil Eksekusi

Base URL: `http://103.217.145.187:8000`  
Test user: `qa_authreg_1776389338@example.com`

| Skenario | Endpoint | Status | Hasil |
|---|---|---:|---|
| Register sukses | `POST /api/mobile/register` | `201` | PASS |
| Register gagal (invalid payload) | `POST /api/mobile/register` | `422` | PASS |
| Login setelah register | `POST /api/mobile/login` | `200` | PASS |
| Fetch profile | `GET /api/mobile/profile` | `200` | PASS |
| Update profile | `PUT /api/mobile/me` | `200` | PASS |
| Change password | `PUT /api/mobile/password` | `200` | PASS |
| Relogin setelah ganti password | `POST /api/mobile/login` | `200` | PASS |

## Ringkasan Acceptance Criteria

- [x] Test register sukses/gagal  
- [x] Test login setelah register  
- [x] Test fetch profile  
- [x] Test update profile  
- [x] Test change password + relogin  
- [x] Semua skenario critical pass  
- [x] Tidak ada blocker P1 di fitur auth/profile

## Kesimpulan

Regresi QA untuk alur **auth/register/profile** dinyatakan **LULUS** pada environment VPS saat ini.

- `CRITICAL_PASS=True`
- `P1_BLOCKER=NO`
