# Mobile - Update Profile User

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Update Profile User**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Update Profile User
- Dependency: Endpoint update profile backend tersedia

## Objective Card
Mengintegrasikan alur update profil pengguna dari halaman Profile, mencakup form edit + validasi input, error handling yang jelas, refresh data setelah update sukses, serta memastikan perubahan data langsung terlihat di halaman profile.

## Ringkasan Implementasi

### 1) Integrasi Endpoint Update Profile
Status: Selesai

Perubahan utama:
- Mobile tetap menggunakan endpoint update profile berbasis token:
  - `PUT /api/mobile/me`
- Method `updateProfile(...)` pada `AuthService` disempurnakan untuk:
  - memvalidasi response wrapper (`status/message/data`)
  - mengembalikan data user hasil update agar UI dapat sinkron lebih cepat
  - tetap menyimpan session terbaru ke secure storage

File terkait:
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)
- [lib/core/network/backend_endpoints.dart](../lib/core/network/backend_endpoints.dart)

### 2) Form Edit + Validasi Input di Halaman Profile
Status: Selesai

Perubahan utama:
- Dialog "Edit Profil" pada `ProfileView` kini memiliki validasi lokal sebelum request:
  - nama tidak boleh kosong
  - email tidak boleh kosong
  - format email wajib valid (regex)
- Jika validasi gagal, pesan ditampilkan langsung di dalam dialog (inline error), bukan hanya snackbar.

File terkait:
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)

### 3) Validasi Input di Backend Lebih Ketat
Status: Selesai

Perubahan utama:
- Controller backend `updateProfile` disempurnakan:
  - normalisasi `name` dan `email` (`trim`, `email` lower-case)
  - validasi format email
  - pengecekan duplikasi email lintas akun tetap dipertahankan
- Hal ini memastikan user hanya bisa mengubah data profil yang diizinkan dan valid.

File terkait:
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)

### 4) Refresh Data Profile Setelah Update Sukses
Status: Selesai

Perubahan utama:
- Setelah update sukses:
  - state lokal `_userData` diperbarui langsung dari response update (optimistic sync)
  - lalu `_fetchProfile()` dipanggil untuk refresh data final dari backend
- Hasilnya, perubahan profil langsung terlihat tanpa perlu buka ulang halaman.

File terkait:
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)

### 5) Error Handling Jika Update Gagal
Status: Selesai

Perubahan utama:
- Error validasi backend (`errors.name`, `errors.email`) dipetakan ke `ValidationApiException` dan ditampilkan jelas di form.
- Error umum API tetap ditampilkan secara user-friendly melalui pesan di dialog.
- Alur unauthorized tetap aman melalui `UnauthorizedException`.

File terkait:
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)

### 6) User Bisa Ubah Data Profil yang Diizinkan
Status: Selesai

Perubahan utama:
- Field yang dapat diubah user dibatasi pada:
  - `name`
  - `email`
- Tidak ada field sensitif lain yang diekspos pada form update.

File terkait:
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)
- [backend/src/controllers/authController.js](../../backend/src/controllers/authController.js)

### 7) Perubahan Langsung Terlihat di Halaman Profile
Status: Selesai

Perubahan utama:
- Setelah update berhasil, nilai nama/email di profile card langsung menampilkan data terbaru.
- Session lokal juga disinkronkan agar drawer/home menggunakan data yang konsisten pada render berikutnya.

File terkait:
- [lib/screens/profile_view.dart](../lib/screens/profile_view.dart)
- [lib/core/services/auth_service.dart](../lib/core/services/auth_service.dart)

## Mapping Definition of Done (DoD)

### DoD 1: Integrasi endpoint update profile
Status: Tercapai

Bukti:
- `AuthService.updateProfile()` memanggil endpoint `PUT /api/mobile/me` dan menangani wrapper response API.

### DoD 2: Form edit + validasi input
Status: Tercapai

Bukti:
- Form edit profil memvalidasi required field + format email sebelum request.

### DoD 3: Refresh data profile setelah update sukses
Status: Tercapai

Bukti:
- State profile diupdate langsung dan `_fetchProfile()` dipanggil ulang setelah sukses.

### DoD 4: Error handling jika update gagal
Status: Tercapai

Bukti:
- Error field-level dan error umum backend ditampilkan jelas pada dialog edit.

### DoD 5: User bisa ubah data profil yang diizinkan
Status: Tercapai

Bukti:
- Hanya `name` dan `email` yang diproses pada endpoint update profile.

### DoD 6: Perubahan langsung terlihat di halaman profile
Status: Tercapai

Bukti:
- UI profile merefleksikan perubahan segera setelah update sukses.

### DoD 7: Dependency endpoint update profile backend tersedia
Status: Tercapai

Bukti:
- Endpoint backend update profile tersedia dan terhubung dengan mobile service.

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh checklist utama card Update Profile User sudah terpenuhi pada folder `backend` dan `mobile`.
