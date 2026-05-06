# Mobile - Integrasi Logout dan Clear Session

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Integrasi Logout dan Clear Session**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi Logout dan Clear Session
- Dependency: Endpoint logout backend tersedia

## Objective Card
Mengintegrasikan alur logout end-to-end di mobile: memanggil API logout backend, membersihkan token di secure storage, mereset state user, dan memastikan halaman protected tidak dapat diakses setelah logout.

## Ringkasan Implementasi

### 1) Integrasi API Logout
Status: Selesai

Perubahan utama:
- Menambahkan konstanta endpoint logout pada `AuthService`:
  - `AUTH_LOGOUT_PATH` (default: `/api/mobile/logout`)
- Menambahkan method `logout()` yang melakukan request `POST /api/mobile/logout` menggunakan token Bearer otomatis dari `AuthInterceptor`.
- Jika server mengembalikan `401`, aplikasi melempar `UnauthorizedException` dan tetap melanjutkan pembersihan sesi lokal.

File terkait:
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)
- [lib/core/network/auth_interceptor.dart](../lib/core/network/auth_interceptor.dart)
- [backend/src/routes/authRoutes.js](../../backend/src/routes/authRoutes.js)
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)

### 2) Hapus Token Secure Storage
Status: Selesai

Perubahan utama:
- Token, username, dan email dihapus dari secure storage melalui `AuthStorage.clearSession()`.
- Pada `AuthService.logout()`, `clearSession()` dipanggil di blok `finally`, sehingga token tetap terhapus meskipun request logout ke backend gagal.

File terkait:
- [lib/core/network/auth_storage.dart](../lib/core/network/auth_storage.dart)
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)

### 3) Reset State User
Status: Selesai

Perubahan utama:
- Proses logout di `HomeScreen` diubah untuk:
  - memanggil `AuthService.logout()`
  - mereset state user (`_username`, `_email`)
  - mereset ringkasan data API (`_latestCount`, `_alertsCount`, `_historyCount`)
  - menutup state proses logout (`_isLoggingOut`)
- Navigasi direset ke login menggunakan:
  - `Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)`

File terkait:
- [lib/screens/home_screen.dart](../lib/screens/home_screen.dart)

### 4) Setelah Logout User Tidak Bisa Akses Halaman Protected
Status: Selesai

Perubahan utama:
- Menambahkan komponen guard `ProtectedRoute`.
- `ProtectedRoute` memeriksa session dari secure storage saat halaman akan ditampilkan.
- Jika session tidak ada, user langsung diarahkan ke `/login`.
- Route protected kini dibungkus guard:
  - `/home`
  - `/dashboard`

File terkait:
- [lib/core/widgets/protected_route.dart](../lib/core/widgets/protected_route.dart)
- [lib/main.dart](../lib/main.dart)

### 5) Token Lama Tidak Digunakan Lagi
Status: Selesai (di sisi aplikasi mobile)

Perubahan utama:
- Setelah logout, token lama dihapus dari secure storage.
- Karena token tidak lagi tersimpan, `AuthInterceptor` tidak lagi mengirim header `Authorization` untuk request berikutnya.
- User tanpa session tidak dapat membuka route protected.

File terkait:
- [lib/core/network/auth_storage.dart](../lib/core/network/auth_storage.dart)
- [lib/core/network/auth_interceptor.dart](../lib/core/network/auth_interceptor.dart)
- [lib/core/widgets/protected_route.dart](../lib/core/widgets/protected_route.dart)

### 6) Dependency: Endpoint Logout Backend Tersedia
Status: Terpenuhi

Perubahan utama:
- Endpoint `POST /api/mobile/logout` tersedia di backend.
- Endpoint dilindungi middleware `authenticateToken`.
- Response logout berhasil tetap dipertahankan sesuai kontrak API.

File terkait:
- [backend/src/routes/authRoutes.js](../../backend/src/routes/authRoutes.js)
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)
- [backend/src/middleware/authenticateToken.js](../../backend/src/middleware/authenticateToken.js)

## Mapping Definition of Done (DoD)

### DoD 1: Logout memanggil endpoint backend
Status: Tercapai

Bukti:
- `AuthService.logout()` melakukan `POST` ke `/api/mobile/logout` sebelum redirect ke login.

### DoD 2: Token/session lokal dibersihkan
Status: Tercapai

Bukti:
- `AuthStorage.clearSession()` dipanggil di `finally` pada `AuthService.logout()`.

### DoD 3: Halaman protected tidak bisa diakses setelah logout
Status: Tercapai

Bukti:
- Route `/home` dan `/dashboard` dibungkus `ProtectedRoute` yang memvalidasi session.

## Validasi yang Sudah Dilakukan
- `dart format` untuk file perubahan logout: selesai.
- `dart analyze` untuk file perubahan logout: **No issues found**.

## Catatan Teknis
- Logout backend pada implementasi saat ini bersifat stateless JWT (tanpa token revocation list di server). Pengamanan token lama pada tiket ini diterapkan di sisi aplikasi mobile melalui pembersihan secure storage dan route guard.

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh checklist utama card logout sudah terpenuhi end-to-end pada mobile dan backend endpoint pendukung tersedia.
