# Mobile - Integrasi Change Password dari Halaman Profile

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Change Password dari Halaman Profile**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Change Password dari Halaman Profile
- Dependency: Endpoint change password backend tersedia

## Objective Card
Mengintegrasikan alur ganti sandi end-to-end dari halaman Profile pada aplikasi mobile, meliputi form `old/new/confirm password`, validasi konfirmasi sandi, penanganan error yang jelas, dan logout paksa setelah sandi berhasil diubah sesuai kebijakan keamanan.

## Ringkasan Implementasi

### 1) Integrasi Endpoint Change Password
Status: Selesai

Perubahan utama:
- Endpoint backend `PUT /api/mobile/password` sudah tersedia dan dilindungi middleware token.
- Mobile memanggil endpoint tersebut lewat `AuthService.changePassword(...)`.
- Payload request sudah mengikuti kontrak:
  - `old_password`
  - `new_password`
  - `new_password_confirmation`

File terkait:
- [backend/src/routes/authRoutes.js](../../backend/src/routes/authRoutes.js)
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)

### 2) Form Old/New/Confirm Password di Halaman Profile
Status: Selesai

Perubahan utama:
- Dialog "Ubah Katasandi" pada `ProfileView` kini memiliki 3 input:
  - Sandi Lama
  - Sandi Baru
  - Konfirmasi Sandi Baru
- Ditambahkan kontrol show/hide password pada ketiga field.

File terkait:
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)

### 3) Validasi Kecocokan Konfirmasi Password
Status: Selesai

Perubahan utama:
- Validasi di sisi mobile sebelum hit API:
  - Semua field wajib diisi
  - Sandi baru minimal 6 karakter
  - Sandi baru tidak boleh sama dengan sandi lama
  - Konfirmasi sandi baru harus cocok dengan sandi baru
- Validasi server juga aktif untuk `new_password_confirmation`.

File terkait:
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)

### 4) Logout Paksa Setelah Password Diganti
Status: Selesai

Perubahan utama:
- Backend mengembalikan `data.force_logout = true` saat ganti sandi berhasil.
- Mobile membaca flag tersebut dan menjalankan pembersihan sesi lokal + redirect ke login.
- Bila flag tidak tersedia, mobile tetap fallback ke `logout()` biasa.

File terkait:
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)

### 5) Alur Aman Saat Password Berhasil Diubah
Status: Selesai

Perubahan utama:
- Backend memverifikasi sandi lama dengan `bcrypt.compare`.
- Backend menolak sandi baru yang sama dengan sandi lama.
- Backend melakukan hash ulang sandi baru sebelum update database.
- Response sukses konsisten: `status`, `message`, `data`.

File terkait:
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)

### 6) Error Lama/Salah Password Tampil Jelas
Status: Selesai

Perubahan utama:
- Jika sandi lama salah, backend mengirim error field-level `errors.old_password`.
- Mobile memetakan `ValidationApiException.fieldErrors` ke pesan form agar user tahu letak kesalahan secara spesifik.
- Untuk error lain dari API, pesan tetap ditampilkan jelas pada dialog.

File terkait:
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)

### 7) Dependency Endpoint Change Password Backend
Status: Terpenuhi

Perubahan utama:
- Route `PUT /api/mobile/password` tersedia pada backend.
- Route diproteksi `authenticateToken`.

File terkait:
- [backend/src/routes/authRoutes.js](../../backend/src/routes/authRoutes.js)
- [backend/src/middleware/authenticateToken.js](../../backend/src/middleware/authenticateToken.js)

## Mapping Definition of Done (DoD)

### DoD 1: Integrasi endpoint change password
Status: Tercapai

Bukti:
- Mobile memanggil `PUT /api/mobile/password` dengan payload `old/new/confirm`.

### DoD 2: Form old/new/confirm password
Status: Tercapai

Bukti:
- Dialog profile menampilkan 3 kolom sandi sesuai requirement.

### DoD 3: Validasi kecocokan konfirmasi password
Status: Tercapai

Bukti:
- Validasi local di UI + validasi backend aktif untuk konfirmasi sandi.

### DoD 4: Logout paksa setelah password diganti (opsional kebijakan)
Status: Tercapai

Bukti:
- Backend mengirim `force_logout`; mobile clear session dan redirect ke `/login`.

### DoD 5: Password berhasil diubah dengan alur aman
Status: Tercapai

Bukti:
- Verifikasi sandi lama, hash sandi baru, dan update DB dilakukan di backend.

### DoD 6: Error lama/salah password tampil jelas
Status: Tercapai

Bukti:
- Field error `old_password` ditampilkan langsung ke user di form dialog.

### DoD 7: Dependency endpoint change password backend tersedia
Status: Tercapai

Bukti:
- Route backend `PUT /api/mobile/password` sudah ada dan terproteksi.

## Kontrak API (Ringkas)

### Request
`PUT /api/mobile/password`
```json
{
  "old_password": "string",
  "new_password": "string",
  "new_password_confirmation": "string"
}
```

### Success Response
```json
{
  "status": true,
  "message": "Sandi berhasil diubah.",
  "data": {
    "force_logout": true
  }
}
```

### Error Response (contoh sandi lama salah)
```json
{
  "status": false,
  "message": "Sandi lama Anda salah.",
  "errors": {
    "old_password": ["Sandi lama Anda salah."]
  }
}
```

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh checklist utama card change password dari halaman profile sudah terpenuhi pada folder `backend` dan `mobile`.
