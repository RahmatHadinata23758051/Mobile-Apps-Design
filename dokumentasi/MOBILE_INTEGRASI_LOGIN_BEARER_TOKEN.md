# Mobile - Integrasi Login Bearer Token

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD 1: **Mobile - Integrasi Login Bearer Token**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi Login Bearer Token
- Priority: P1
- Dependency: Backend Sanctum selesai

## Objective Card
Integrasi login mobile ke endpoint token-based dan simpan token secara aman.

## Ringkasan Implementasi
Perubahan sudah diselaraskan dengan backend Sanctum menggunakan endpoint mobile auth (`/api/mobile/login`) dan skema Bearer Token.

### 1) Integrasi API Login
Status: Selesai

Perubahan utama:
- Auth service menggunakan base URL auth terpisah (`AUTH_BASE_URL`) dengan default Laravel (`http://127.0.0.1:8000`).
- Path login dapat dikonfigurasi melalui `AUTH_LOGIN_PATH` dengan default `/api/mobile/login`.
- Payload login dikirim dalam format JSON (`email`, `password`) sesuai backend mobile.
- Parsing response mendukung wrapper standar (`status`, `message`, `data`) dan fallback payload langsung.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)

### 2) Simpan Token ke Secure Storage
Status: Selesai

Perubahan utama:
- Token, username, dan email disimpan ke secure storage setelah login sukses.
- Session lokal bisa dibaca kembali untuk bootstrap route awal aplikasi.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)
- [lib/core/network/auth_storage.dart](lib/core/network/auth_storage.dart)
- [lib/main.dart](lib/main.dart)

### 3) Inject Authorization Header
Status: Selesai

Perubahan utama:
- Token Bearer di-inject otomatis ke request terproteksi melalui interceptor.
- Request publik (seperti login) menggunakan flag `skipAuth` agar tidak membawa Authorization header.

File terkait:
- [lib/core/network/auth_interceptor.dart](lib/core/network/auth_interceptor.dart)
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)

### 4) Handle Unauthorized / Expired Token
Status: Selesai

Perubahan utama:
- Ditambahkan `UnauthorizedException` untuk menangani status 401 dari API protected.
- Jika token invalid/expired, user diarahkan kembali ke halaman login tanpa crash.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)
- [lib/core/services/sensor_service.dart](lib/core/services/sensor_service.dart)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart)

## Mapping Definition of Done (DoD)

### DoD 1: Login sukses
Status: Tercapai

Bukti:
- Endpoint backend mobile berhasil menerima login dan mengembalikan token.
- Integrasi Flutter sudah diarahkan ke endpoint auth mobile.

### DoD 2: Endpoint protected bisa diakses
Status: Tercapai

Bukti:
- Verifikasi backend end-to-end: `login -> me -> logout -> me(401)` berjalan sesuai ekspektasi.

### DoD 3: Token invalid diarahkan ke login tanpa crash
Status: Tercapai

Bukti:
- Handling `UnauthorizedException` sudah ada pada service dan flow screen.
- Redirect ke route login dilakukan dengan `pushNamedAndRemoveUntil`.

## Konfigurasi Run yang Direkomendasikan

Untuk pengujian lokal Flutter web + backend terpisah:

```bash
flutter run -d chrome --dart-define=AUTH_BASE_URL=http://127.0.0.1:8000 --dart-define=API_BASE_URL=http://127.0.0.1:8001
```

Keterangan:
- `AUTH_BASE_URL` untuk auth Laravel Sanctum.
- `API_BASE_URL` untuk service model/predict atau endpoint non-auth yang berjalan terpisah.

## Catatan Teknis Penting
- Login web Laravel berbasis session + CSRF (`/login`) tidak cocok untuk mobile token flow.
- Mobile client harus memakai endpoint API stateless (`/api/mobile/login`) agar tidak terkena CSRF mismatch.
- Untuk Flutter web, CORS backend auth tetap harus mengizinkan origin frontend dev.

## Status Akhir CARD 1
Status: **Done**

Catatan:
- Implementasi core sudah memenuhi checklist dan DoD CARD 1.
- Lanjutan yang direkomendasikan dari backlog: CARD 2 (logout server-side penuh dari sisi mobile UI flow) dan CARD 12 (`/api/mobile/me` untuk sinkron profil saat bootstrap).
