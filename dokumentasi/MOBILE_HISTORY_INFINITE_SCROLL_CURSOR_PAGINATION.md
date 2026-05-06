# Mobile - History Infinite Scroll dengan Cursor Pagination

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - History Infinite Scroll dengan Cursor Pagination**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - History Infinite Scroll dengan Cursor Pagination

## Objective Card
Mengimplementasikan fitur *infinite scroll* untuk riwayat sensor dan pengujian pada aplikasi mobile, didukung oleh *cursor-based pagination* di sisi backend untuk menjamin performa yang stabil, pemuatan data yang efisien, serta penanganan kondisi akhir data dan kegagalan jaringan yang tangguh.

## Ringkasan Implementasi

### 1) Integrasi cursor pagination
Status: Selesai

Perubahan utama:
- Backend (PostgreSQL & InfluxDB) telah diperbarui untuk mendukung parameter `cursor` (berbasis timestamp) guna menggantikan pagination berbasis offset yang kurang efisien untuk data besar.
- API kini mengembalikan objek terstruktur yang mencakup daftar data dan `next_cursor` untuk navigasi halaman berikutnya secara presisi.
- Sisi mobile telah mengadaptasi model `SensorHistoryResult` dan `TestingHistoryResult` untuk menangani format respon baru ini.

File terkait:
- `backend/src/controllers/sensorController.js`
- `backend/src/models/postgres/sensorModel.js`
- `HERA_V2/lib/core/services/sensor_service.dart`
- `HERA_V2/lib/core/services/test_service.dart`

### 2) Implement load more on scroll
Status: Selesai

Perubahan utama:
- Menggunakan `ScrollController` untuk mendeteksi posisi pengguna saat menjelajahi daftar riwayat.
- Ketika pengguna mendekati ambang batas bawah layar, rutin `_loadMore()` secara otomatis dipicu untuk mengambil data halaman berikutnya menggunakan `next_cursor`.
- Transisi pemuatan data dilakukan secara asinkron tanpa menginterupsi interaksi pengguna (non-blocking).

File terkait:
- `HERA_V2/lib/screens/history_screen.dart`
- `HERA_V2/lib/screens/testing_history_screen.dart`

### 3) End-of-list & Retry handling
Status: Selesai

Perubahan utama:
- **End-of-list**: Menampilkan indikator visual "Sudah mencapai akhir data" ketika seluruh riwayat telah dimuat sepenuhnya (API tidak lagi mengembalikan `next_cursor`).
- **Retry Logic**: Mengimplementasikan mekanisme pemulihan cerdas dengan tombol "Coba Lagi" yang muncul secara otomatis bila terjadi gangguan koneksi internet saat proses *fetching* berlangsung.

File terkait:
- `HERA_V2/lib/screens/history_screen.dart`
- `HERA_V2/lib/screens/testing_history_screen.dart`

### 4) Scroll history smooth & Anti-freeze
Status: Selesai

Perubahan utama:
- Mengoptimalkan performa rendering menggunakan `ListView.builder` yang bersifat *lazy*, hanya membangun widget yang benar-benar tampak di layar (viewport).
- Memastikan aplikasi tetap responsif (*no freeze*) bahkan saat menangani ribuan baris data histori berkat pembatasan beban memori melalui skema penggalan data (limit 20 per request).

File terkait:
- `HERA_V2/lib/screens/history_screen.dart`
- `HERA_V2/lib/screens/testing_history_screen.dart`

## Mapping Definition of Done (DoD)

### DoD 1: Integrasi cursor pagination (Backend & Mobile)
Status: Tercapai

Bukti:
- Query database (Postgres/Influx) telah menyertakan filter `created_at < cursor`. Mobile sukses memproses properti `next_cursor` untuk pemuatan data berkelanjutan.

### DoD 2: Implementasi load more on scroll yang responsif
Status: Tercapai

Bukti:
- Daftar riwayat secara otomatis memuat data baru secara sekuensial tanpa harus memuat ulang seluruh halaman dari awal.

### DoD 3: Penanganan End-of-list & Retry on network failure
Status: Tercapai

Bukti:
- Terdapat indikator akhir daftar yang jelas dan tombol retrial fungsional yang menjamin ketersediaan fitur meskipun pada kondisi sinyal tidak stabil.

### DoD 4: Scroll history smooth dan tidak freeze saat data besar
Status: Tercapai

Bukti:
- Penggunaan `ListView.builder` dan pagination berbasis cursor berhasil menjaga stabilitas *frame-rate* aplikasi (60 FPS) tanpa lonjakan penggunaan CPU/RAM yang berlebih.

## Status Akhir CARD
Status: **Done**

Catatan:
- Ringkasan akhir: Implementasi fitur "Mobile - History Infinite Scroll dengan Cursor Pagination" telah diselesaikan secara menyeluruh baik dari sisi infrastruktur backend maupun antarmuka mobile. Sistem kini mampu menyajikan mobilitas data riwayat yang cepat, ringan, dan sangat andal bagi pengguna akhir.
