# Trello Backlog Mobile Apps - HERA 2.0

Dokumen ini berisi daftar kartu Trello untuk tim Mobile berdasarkan kebutuhan integrasi backend HERA 2.0.

## Saran List Board Trello
1. Backlog
2. Ready
3. In Progress
4. Blocked
5. Review QA
6. Done

## CARD 1
Title: Mobile - Integrasi Login Bearer Token  
Labels: mobile, auth, p1  
Priority: P1  
Due: Sprint 1  
Description: Integrasi login mobile ke endpoint token-based dan simpan token secara aman.  
Checklist:
- Integrasi API login
- Simpan token ke secure storage
- Inject Authorization header
- Handle unauthorized/expired token
Definition of Done:
- Login sukses
- Endpoint protected bisa diakses
- Token invalid diarahkan ke login tanpa crash
Dependency: Backend Sanctum selesai

## CARD 2
Title: Mobile - Integrasi Logout dan Clear Session  
Labels: mobile, auth, p1  
Priority: P1  
Due: Sprint 1  
Description: Logout ke server dan bersihkan session lokal user.  
Checklist:
- Integrasi API logout
- Hapus token secure storage
- Reset state user
Definition of Done:
- Setelah logout user tidak bisa akses halaman protected
- Token lama tidak digunakan lagi
Dependency: Endpoint logout backend tersedia

## CARD 3
Title: Mobile - Adaptasi Parsing Response API Standar  
Labels: mobile, api-contract, p1  
Priority: P1  
Due: Sprint 1  
Description: Sesuaikan parser mobile ke format response standar backend.  
Checklist:
- Buat model wrapper response
- Refactor parser latest/alerts/history
- Tangani null-safe parsing
- Mapping error message ke UI
Definition of Done:
- Tidak ada crash parsing
- Error API tampil konsisten di UI
Dependency: Backend standard response aktif

## CARD 4
Title: Mobile - Integrasi Endpoint Latest untuk Dashboard/Monitoring Init  
Labels: mobile, dashboard, p1  
Priority: P1  
Due: Sprint 1  
Description: Ambil data awal dashboard sebelum realtime berjalan.  
Checklist:
- Integrasi endpoint latest
- Mapping ke chart/list
- Loading/empty/error state
Definition of Done:
- Dashboard menampilkan initial data dengan benar

## CARD 5
Title: Mobile - Integrasi Alerts Board  
Labels: mobile, alerts, p1  
Priority: P1  
Due: Sprint 1  
Description: Menampilkan data warning dan danger terbaru.  
Checklist:
- Integrasi endpoint alerts
- Indikator status (warna/icon)
- Empty state bila tidak ada alert
Definition of Done:
- Alert terbaru tampil sesuai status

## CARD 6
Title: Mobile - History Infinite Scroll dengan Cursor Pagination  
Labels: mobile, performance, p2  
Priority: P2  
Due: Sprint 2  
Description: Load history bertahap agar ringan di device low-end.  
Checklist:
- Integrasi cursor pagination
- Implement load more on scroll
- End-of-list handling
- Retry on network failure
Definition of Done:
- Scroll history smooth
- Tidak freeze saat data besar
Dependency: Backend history pakai cursor paginate

## CARD 7
Title: Mobile - Integrasi WebSocket Realtime Sensor  
Labels: mobile, realtime, p2  
Priority: P2  
Due: Sprint 2  
Description: Menerima update sensor realtime tanpa polling berlebihan.  
Checklist:
- Setup pusher client
- Subscribe channel sensor-monitoring
- Listen event SensorDataUpdated
- Reconnect strategy saat koneksi putus
Definition of Done:
- Data realtime masuk konsisten
- Reconnect berhasil tanpa duplikasi berlebih

## CARD 8
Title: Mobile - Local Cache SQLite untuk Sensor  
Labels: mobile, cache, p2  
Priority: P2  
Due: Sprint 2  
Description: Cache data penting untuk fallback dan peningkatan performa.  
Checklist:
- Definisikan tabel lokal sensor
- Simpan latest/history yang sudah diakses
- Tampilkan cache saat offline/jaringan buruk
Definition of Done:
- App tetap menampilkan data terakhir saat network gagal

## CARD 9
Title: Mobile - QA Regression Integrasi API dan Realtime  
Labels: mobile, qa, p1  
Priority: P1  
Due: Sprint 2  
Description: Pengujian end-to-end seluruh flow kritikal mobile.  
Checklist:
- Test login/logout
- Test latest/alerts/history
- Test token expired/unauthorized
- Test websocket connect/disconnect/reconnect
- Test low-memory behavior
Definition of Done:
- Seluruh test critical pass
- Tidak ada blocker P1 sebelum release

## CARD 10
Title: Mobile - Integrasi Register Akun  
Labels: mobile, auth, register, p1  
Priority: P1  
Due: Sprint 1  
Description: Implement fitur pendaftaran akun baru dari mobile app ke backend API.  
Checklist:
- Integrasi endpoint register
- Validasi input form (nama, email, password, konfirmasi password)
- Tampilkan error field-level dari backend
- Setelah register sukses, arahkan ke login atau auto-login (sesuai keputusan tim)
Definition of Done:
- User baru bisa daftar dengan data valid
- Error validasi tampil jelas di UI
- Tidak ada crash saat register gagal
Dependency: Endpoint register backend tersedia dan terdokumentasi

## CARD 11
Title: Mobile - UX Validasi Register dan Keamanan Input  
Labels: mobile, ux, validation, security, p2  
Priority: P2  
Due: Sprint 1  
Description: Meningkatkan kualitas form register agar aman dan nyaman dipakai.  
Checklist:
- Password minimum policy (panjang/karakter) sesuai backend
- Toggle show/hide password
- Disable tombol submit saat request berjalan
- Prevent double submit
Definition of Done:
- Form register terasa responsif
- Tidak ada submit ganda
- Input sensitif ditangani aman di sisi UI

## CARD 12
Title: Mobile - Integrasi Endpoint Profile (Get Current User)  
Labels: mobile, profile, api, p1  
Priority: P1  
Due: Sprint 1  
Description: Ambil data profil user login untuk ditampilkan di halaman Profile.  
Checklist:
- Integrasi endpoint profile/me
- Mapping data user ke model lokal
- Loading, empty, dan error state
Definition of Done:
- Data nama, email, role tampil benar
- Jika token invalid, user diarahkan login
Dependency: Auth token flow sudah aktif

## CARD 13
Title: Mobile - Update Profile User  
Labels: mobile, profile, edit, p2  
Priority: P2  
Due: Sprint 2  
Description: Fitur edit profil dasar (contoh: nama) dari mobile app.  
Checklist:
- Integrasi endpoint update profile
- Form edit + validasi input
- Refresh data profile setelah update sukses
- Error handling jika update gagal
Definition of Done:
- User bisa ubah data profil yang diizinkan
- Perubahan langsung terlihat di halaman profile
Dependency: Endpoint update profile backend tersedia

## CARD 14
Title: Mobile - Change Password dari Halaman Profile  
Labels: mobile, profile, security, p2  
Priority: P2  
Due: Sprint 2  
Description: Fitur ubah password untuk user yang sudah login.  
Checklist:
- Integrasi endpoint change password
- Form old/new/confirm password
- Validasi kecocokan konfirmasi password
- Logout paksa setelah password diganti (opsional sesuai kebijakan)
Definition of Done:
- Password berhasil diubah dengan alur aman
- Error lama/salah password tampil jelas
Dependency: Endpoint change password backend tersedia

## CARD 15
Title: Mobile - QA Regression Auth Register dan Profile  
Labels: mobile, qa, auth, profile, p1  
Priority: P1  
Due: Sprint 2  
Description: Pengujian end-to-end flow register, login, profile, update profile, change password.  
Checklist:
- Test register sukses/gagal
- Test login setelah register
- Test fetch profile
- Test update profile
- Test change password + relogin
Definition of Done:
- Semua skenario critical pass
- Tidak ada blocker P1 di fitur auth/profile

## Catatan Dependency ke Tim Backend
- Sanctum auth untuk mobile wajib tersedia (login/logout/protected route).
- Format response API perlu konsisten agar parser mobile stabil.
- Endpoint history sebaiknya cursor-based pagination.
- Endpoint register/profile/update/change-password harus terdokumentasi jelas.
