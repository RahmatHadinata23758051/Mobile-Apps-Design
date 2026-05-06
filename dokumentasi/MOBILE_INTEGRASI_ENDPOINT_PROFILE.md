# Mobile - Integrasi Endpoint Profile (Get Current User)

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Integrasi Endpoint Profile (Get Current User)**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi Endpoint Profile (Get Current User)
- Priority: P2 (Lanjutan dari Login & Register)
- Dependency: Auth token flow sudah aktif

## Objective Card
Mengintegrasikan layar profil pengguna mobile ke endpoint `/api/mobile/me`, menampilkan data nama, email, dan role secara real-time, serta mengatur state loading, error, dan redirect otomatis jika sesi kedaluwarsa.

## Ringkasan Implementasi

### 1) Integrasi Endpoint profile/me
Status: Selesai

Perubahan utama:
- Penambahan endpoint `GET /api/mobile/me` pada backend Node.js, dilindungi middleware `authenticateToken`.
- Backend mengambil data user dari tabel PostgreSQL berdasarkan ID di dalam JWT token dan mengembalikan `{ status: true, data: { user: {...} } }`.
- Penambahan method `getCurrentUser()` pada `AuthService` yang memanggil endpoint tersebut menggunakan token Bearer yang di-inject otomatis oleh `AuthInterceptor`.

File terkait:
- [backend/server.js](../backend/server.js)
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)

### 2) Mapping Data User ke Model Lokal
Status: Selesai

Perubahan utama:
- Response JSON dari backend (`data.user`) di-parse menjadi `Map<String, dynamic>` di sisi Flutter.
- Data `name`, `email`, dan `role` diekstrak dan dimapping ke variabel state UI (`_userData`) pada `ProfileView`, serta ke `_username` dan `_email` pada `HomeScreen` agar konsisten di seluruh tampilan aplikasi.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)
- [lib/screens/profile_view.dart](lib/screens/profile_view.dart)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart)

### 3) Loading, Empty, dan Error State
Status: Selesai

Perubahan utama:
- `ProfileView` diubah dari `StatelessWidget` menjadi `StatefulWidget` dengan 3 state:
  - **Loading**: `CircularProgressIndicator` tampil saat `_isLoading = true` (pertama kali layar dibuka).
  - **Error**: Ikon error besar, teks pesan kesalahan, dan tombol "Coba Lagi" ditampilkan jika koneksi gagal.
  - **Success**: Data profil ditampilkan secara lengkap setelah berhasil di-fetch.

File terkait:
- [lib/screens/profile_view.dart](lib/screens/profile_view.dart)

### 4) Data Nama, Email, Role Tampil Benar
Status: Selesai

Perubahan utama:
- Kolom `Nama Lengkap`, `Email`, dan `Pekerjaan` (role) diambil langsung dari response backend `/api/mobile/me` dan ditampilkan di `_buildProfileItem()`.
- Role ditampilkan dengan huruf kapital pertama (contoh: `pekerja` → `Pekerja`).
- Tidak ada lagi teks dummy "John Doe" atau "Admin" yang di-hardcode.
- `HomeScreen` juga diperbarui: drawer dan card profil dashboard kini menampilkan data asli dari backend, bukan placeholder.

File terkait:
- [lib/screens/profile_view.dart](lib/screens/profile_view.dart)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart)

### 5) Jika Token Invalid, User Diarahkan Login
Status: Selesai

Perubahan utama:
- Pada `ProfileView`, jika backend mengembalikan HTTP 401, `getCurrentUser()` melempar `UnauthorizedException`.
- Blok `catch` di `_fetchProfile()` menangkapnya, membersihkan sesi lokal via `clearLocalSession()`, lalu menjalankan `Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false)`.
- Mekanisme yang sama juga diterapkan di `HomeScreen` pada method `_loadUserProfile()`.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)
- [lib/screens/profile_view.dart](lib/screens/profile_view.dart)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart)

## Mapping Definition of Done (DoD)

### DoD 1: Data nama, email, role tampil benar
Status: Tercapai

Bukti:
- Halaman profil dan drawer HomeScreen menampilkan data sesuai akun yang login dari database PostgreSQL, bukan nilai hardcoded.

### DoD 2: Jika token invalid, user diarahkan login
Status: Tercapai

Bukti:
- Handling `UnauthorizedException` pada `ProfileView` dan `HomeScreen` membersihkan sesi lalu redirect ke `/login` tanpa crash.

### DoD 3: Dependency - Auth token flow sudah aktif
Status: Tercapai

Bukti:
- Seluruh alur otentikasi (login → simpan token → inject header → handle 401) telah aktif dari tiket Login Bearer Token. Endpoint `/api/mobile/me` dilindungi middleware `authenticateToken`.

## Konfigurasi Run yang Direkomendasikan

```bash
# Terminal Backend
npm start

# Terminal Flutter
flutter run -d chrome
```

## Catatan Teknis Penting
- `HomeScreen` melakukan fetch profil dari backend saat pertama kali dibuka (`_loadUserProfile()`). Jika backend tidak bisa dijangkau, data fallback dari secure storage tetap tampil.
- `ProfileView` selalu fetch data fresh dari backend setiap kali dibuka, memastikan data yang ditampilkan selalu up-to-date.

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh checklist dan DoD untuk tiket ini telah terpenuhi.
- Lanjutan yang direkomendasikan dari backlog: integrasi endpoint sensor data dan real-time monitoring.
