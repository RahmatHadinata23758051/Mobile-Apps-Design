# Trello Backlog Mobile - Penyesuaian Kompatibilitas Laravel VPS (HERA 2.0)

Dokumen ini adalah turunan langsung dari `catatan_mobile_developer.md` untuk kebutuhan eksekusi Trello tim mobile.

Referensi lingkungan:
- Backend: Laravel 11 + Sanctum
- VPS: `http://103.217.145.187:8000`

## Saran List Board Trello
1. Backlog
2. Ready
3. In Progress
4. Blocked
5. Review QA
6. Done

## CARD 1
Title: Mobile - Set Base URL ke VPS Laravel  
Labels: mobile, config, api, p1  
Priority: P1  
Due: Sprint aktif  
Description: Ubah konfigurasi base URL mobile ke endpoint VPS Laravel agar semua request mengarah ke server produksi.  
Checklist:
- Update `API_BASE_URL` default ke `http://103.217.145.187:8000`
- Pastikan `AUTH_BASE_URL` mengikuti host yang sama (atau override sesuai kebutuhan)
- Verifikasi login dan profile endpoint kena host VPS
Definition of Done:
- Semua request auth/sensor/testing tidak lagi ke localhost
- Login dari mobile berhasil hit VPS
Dependency: Akses VPS tersedia

## CARD 2
Title: Mobile - Sinkronisasi Path Endpoint Sensor Sanctum  
Labels: mobile, api-contract, sensor, p1  
Priority: P1  
Due: Sprint aktif  
Description: Sesuaikan path endpoint sensor mobile agar mengikuti kontrak backend Laravel Sanctum dengan prefix `/api/mobile/sensor/*`.  
Checklist:
- Ubah `sensorLatest` ke `/api/mobile/sensor/latest`
- Ubah `sensorAlerts` ke `/api/mobile/sensor/alerts`
- Ubah `sensorHistory` ke `/api/mobile/sensor/history`
- Pastikan call sensor menggunakan Bearer token
Definition of Done:
- Endpoint latest/alerts/history hit route Laravel mobile
- Tidak ada lagi call ke `/sensor/*` legacy
Dependency: Token auth mobile aktif

## CARD 3
Title: Mobile - Adaptasi Query Param Sensor History ke Kontrak Laravel  
Labels: mobile, history, api-contract, p1  
Priority: P1  
Due: Sprint aktif  
Description: Sesuaikan query parameter history dari format lama ke format backend Laravel (`from_date`, `to_date`, `status`, `page`, `limit`).  
Checklist:
- Ganti `from` -> `from_date`
- Ganti `to` -> `to_date`
- Ganti `source` -> `status`
- Ganti pagination `cursor` -> `page`
- Verifikasi parsing meta pagination dari backend
Definition of Done:
- Filter dan pagination history bekerja sesuai parameter backend
- Tidak ada error query parameter mismatch
Dependency: Endpoint `/api/mobile/sensor/history` aktif

## CARD 4
Title: Mobile - Penyesuaian Endpoint dan Parser Profile Laravel  
Labels: mobile, profile, api-contract, p1  
Priority: P1  
Due: Sprint aktif  
Description: Sesuaikan endpoint profile dan parsing response user agar kompatibel dengan format backend Laravel (`GET /api/mobile/profile`, `data` langsung).  
Checklist:
- Ubah path profile dari `/api/mobile/me` ke `/api/mobile/profile`
- Sesuaikan parser `getCurrentUser()` untuk membaca `body['data']` langsung
- Verifikasi mapping `name/email/role`
Definition of Done:
- Data profile tampil benar di halaman profile dan home
- Tidak ada error "data user tidak ditemukan"
Dependency: Endpoint `/api/mobile/profile` tersedia

## CARD 5
Title: Mobile - Feature Toggle untuk Fitur Profile yang Endpoint-nya Belum Tersedia  
Labels: mobile, profile, ux, p2  
Priority: P2  
Due: Sprint aktif  
Description: Siapkan fallback UX untuk menonaktifkan fitur yang belum didukung backend saat ini (misal update profile / change password jika endpoint belum ada).  
Checklist:
- Tambahkan guard/fallback ketika endpoint update profile 404/405
- Tambahkan guard/fallback ketika endpoint change password 404/405
- Tampilkan pesan informatif, bukan crash
Definition of Done:
- User tidak menemui dead-end/crash pada fitur yang belum tersedia
- Pesan status fitur jelas di UI
Dependency: Kejelasan status endpoint dari backend

## CARD 6
Title: Mobile - Validasi Kompatibilitas Testing History Cursor  
Labels: mobile, testing, api-contract, p2  
Priority: P2  
Due: Sprint aktif  
Description: Verifikasi ulang implementasi mobile untuk endpoint testing history dengan format `data.data` + `next_cursor`.  
Checklist:
- Verifikasi parser untuk payload `{ data: { data: [...], next_cursor } }`
- Verifikasi load more dengan `cursor`
- Verifikasi state empty/end of list
Definition of Done:
- Infinite scroll testing history berjalan stabil
- `next_cursor` terbaca dan dipakai konsisten
Dependency: Endpoint `/api/mobile/testing/history` versi terbaru aktif

## CARD 7
Title: Mobile - Verifikasi Integrasi Altitude pada Testing Location  
Labels: mobile, testing, gps, p2  
Priority: P2  
Due: Sprint aktif  
Description: Pastikan field `altitude` yang dikirim mobile sudah benar-benar masuk ke backend tanpa mempengaruhi flow pengujian lain.  
Checklist:
- Verifikasi payload kirim mengandung `altitude`
- Verifikasi request sukses pada endpoint testing location
- Verifikasi fallback jika altitude null
Definition of Done:
- Pengiriman data testing dengan altitude sukses
- Tidak ada regresi pada field sensor lain
Dependency: Backend field `altitude` sudah tersedia

## CARD 8
Title: Mobile - QA Regression Kompatibilitas Laravel VPS  
Labels: mobile, qa, regression, p1  
Priority: P1  
Due: Sprint aktif  
Description: Jalankan pengujian regresi end-to-end seluruh flow mobile yang terpengaruh migrasi kontrak backend Laravel di VPS.  
Checklist:
- Test login/logout/profile
- Test latest/alerts/history (path + query)
- Test testing location + testing history
- Test error handling 401/404/422
Definition of Done:
- Seluruh flow utama pass di VPS
- Tidak ada blocker P1 untuk rilis integrasi Laravel
Dependency: Deploy backend stabil di VPS

## Catatan Prioritas Eksekusi
- Prioritas pertama: CARD 1 sampai CARD 4 (kontrak inti auth/profile/sensor).
- Prioritas kedua: CARD 5 sampai CARD 7 (hardening UX dan verifikasi fitur pendukung).
- Penutup sprint: CARD 8 (regression QA).
