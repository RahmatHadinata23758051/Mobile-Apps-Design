<p align="center">
  <a href="https://flutter.dev" target="_blank">
    <img src="https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png" width="320" alt="Flutter Logo">
  </a>
</p>

<p align="center">
  <a href="https://github.com/SatriaDivo/Mobile-HERA-v2.0"><img src="https://img.shields.io/github/stars/SatriaDivo/Mobile-HERA-v2.0?style=flat&logo=github" alt="GitHub Stars"></a>
  <a href="https://github.com/SatriaDivo/Mobile-HERA-v2.0"><img src="https://img.shields.io/github/last-commit/SatriaDivo/Mobile-HERA-v2.0?style=flat" alt="Last Commit"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-Mobile-blue?logo=flutter" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-SDK%20%5E3.7.0-0175C2?logo=dart" alt="Dart SDK"></a>
  <img src="https://img.shields.io/badge/license-not%20specified-lightgrey" alt="License">
</p>

## About Mobile HERA

Mobile HERA v2.0 adalah aplikasi Flutter untuk ekosistem Internet of Things (IoT) HERA. Aplikasi ini dibuat agar proses operasional lapangan lebih cepat, aman, dan terintegrasi dengan backend.

Fitur inti yang tersedia saat ini:

- Login, register, bootstrap sesi, dan logout berbasis bearer token.
- Monitoring data sensor terbaru dan histori sensor.
- Pengujian lokasi dan histori pengujian lokasi.
- Manajemen profil pengguna (update profil dan ubah kata sandi).
- Realtime update sensor melalui Socket.IO.

## Getting Started

Project ini dapat dijalankan sebagai aplikasi Flutter standar.

Prasyarat:

- Flutter SDK terpasang.
- Android Studio / VS Code + Flutter extension.
- Emulator/device aktif.
- Backend HERA dapat diakses dari emulator/device.

Langkah menjalankan:

```bash
flutter pub get
flutter analyze
flutter run
```

## Configuration

Konfigurasi endpoint backend berada di `lib/core/network/backend_endpoints.dart` dan dibaca dari `String.fromEnvironment`.

Agar host backend tidak hardcoded di source code, gunakan file `.env`:

```bash
cp .env.example .env
```

Lalu isi nilai endpoint di `.env` sesuai environment kamu.

Default fallback di code saat variabel tidak diisi:

- `API_BASE_URL=http://localhost:8000`
- `WS_BASE_URL` mengikuti `API_BASE_URL` jika tidak diisi.
- `AUTH_BASE_URL` mengikuti `API_BASE_URL` jika tidak diisi.

Path auth yang dapat dioverride:

- `AUTH_LOGIN_PATH` (default `/api/mobile/login`)
- `AUTH_REGISTER_PATH` (default `/api/mobile/register`)
- `AUTH_ME_PATH` (default `/api/mobile/me`)
- `AUTH_PROFILE_PATH` (default `/api/mobile/profile`)
- `AUTH_LOGOUT_PATH` (default `/api/mobile/logout`)
- `AUTH_CHANGE_PASSWORD_PATH` (default `/api/mobile/password`)

Jalankan app menggunakan file `.env`:

```bash
flutter run --dart-define-from-file=.env
```

## Learning Mobile HERA

Dokumentasi implementasi dan integrasi tersedia di folder `dokumentasi/`, termasuk:

- `dokumentasi/backend_mobile_integration_docs.md`
- `dokumentasi/catatan_mobile_developer.md`
- `dokumentasi/TRELLO_MOBILE_KOMPAT_LARAVEL_VPS.md`
- `dokumentasi/STRUKTUR_ARSITEKTUR_MOBILE.md`

## Contributing

Terima kasih sudah berkontribusi untuk Mobile HERA v2.0.

Panduan kontribusi singkat:

- Buat branch fitur/perbaikan dari branch utama.
- Pastikan `flutter analyze` dan `flutter test` berjalan tanpa error.
- Buat commit message yang jelas dan deskriptif.
- Kirim Pull Request dengan ringkasan perubahan dan dampaknya.

## Code of Conduct

Agar kolaborasi tetap sehat, semua kontributor diharapkan:

- Menjaga komunikasi yang sopan dan profesional.
- Memberikan review secara konstruktif.
- Menghargai keputusan teknis berdasarkan diskusi tim.

## Security Vulnerabilities

Jika menemukan kerentanan keamanan, jangan publish secara terbuka di issue tracker.
Silakan laporkan langsung ke maintainer project terlebih dahulu agar bisa ditangani secara aman.

## License

Lisensi project ini saat ini belum didefinisikan secara eksplisit (`not specified`).
