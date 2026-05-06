# Laporan Perubahan Mobile HERA v2.0

Tanggal laporan: 16 April 2026  
Project: Mobile HERA v2.0  
Scope: Folder `mobile` (stabilisasi analyzer, konfigurasi environment, konektivitas Android, build rilis)

## Ringkasan

Perubahan pada sesi ini berfokus pada:

- pembersihan warning analyzer di `profile_view.dart`,
- standardisasi konfigurasi environment berbasis `.env`,
- perbaikan koneksi Android ke backend HTTP (cleartext + permission internet),
- peningkatan versi aplikasi ke `2.0.0+1`,
- validasi build APK release.

Hasil akhir:

- `flutter analyze` -> **No issues found**.
- `flutter build apk --release --dart-define-from-file=.env` -> **berhasil**.

---

## Detail Perubahan

## 1) Pembersihan Analyzer (Profile)

### File terdampak
- `lib/screens/profile_view.dart`

### Perubahan utama
- Perbaikan lint `use_build_context_synchronously` pada alur async.
- Penyesuaian context modal agar tidak terjadi shadowing context.
- Migrasi API deprecated `withOpacity` ke `withValues`.

### Dampak
- Analyzer bersih untuk issue yang sebelumnya muncul di layar profile.

### Commit
- `9b1e3f3` (mobile path dalam monorepo)

---

## 2) Standardisasi Konfigurasi Environment

### File terdampak
- `.gitignore`
- `.env.example`
- `README.md`
- `lib/core/network/backend_endpoints.dart`
- `dokumentasi/MOBILE_QA_REGRESSION_CARD8_COMMANDS.md`
- `dokumentasi/TRELLO_MOBILE_KOMPAT_LARAVEL_VPS.md`
- `dokumentasi/catatan_mobile_developer.md`

### Perubahan utama
- Menambahkan `.env` ke ignore list Git.
- Menyediakan `.env.example` sebagai template variabel runtime.
- README diperbarui dengan panduan `--dart-define-from-file=.env`.
- Endpoint backend disiapkan untuk mengambil konfigurasi dari `String.fromEnvironment`.

### Dampak
- Konfigurasi endpoint lebih fleksibel per environment.
- Kredensial/host sensitif lebih mudah dipisahkan dari source code.

### Commit
- `117d22c` (mobile path dalam monorepo)

---

## 3) Perbaikan Konektivitas Android + Build Stabilization

### File terdampak
- `android/app/src/main/AndroidManifest.xml`
- `android/build.gradle.kts`
- `lib/core/services/auth_service.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `macos/Flutter/GeneratedPluginRegistrant.swift` (auto-generated update dari dependency resolution)

### Perubahan utama
- Menambahkan permission:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_NETWORK_STATE`
- Mengaktifkan `android:usesCleartextTraffic="true"` untuk akses backend `http://`.
- Menambahkan suppress compile warning Java options lama (`-Xlint:-options`) pada subproject Java compile.
- Menambahkan debug log detail pada proses login (`AuthService.login`) saat terjadi `DioException`.
- Versi aplikasi dinaikkan dari `1.0.0+1` menjadi `2.0.0+1`.
- Dependency lock diperbarui melalui `flutter pub upgrade` (non-major resolvable update).

### Dampak
- Error koneksi login pada Android akibat blokir traffic HTTP dapat diminimalkan.
- Build log lebih bersih dari warning Java 8 legacy plugin.
- Pelacakan error login lebih cepat lewat log debug.

### Commit
- `1ba3901` (mobile path dalam monorepo)  
- Publish ke remote mobile-root: `463da0b`

---

## Validasi Eksekusi

## Analisis statik
- Command: `flutter analyze`
- Hasil: `No issues found`

## Build release APK
- Command: `flutter build apk --release --dart-define-from-file=.env`
- Hasil: sukses
- Output: `build/app/outputs/flutter-apk/app-release.apk`
- Ukuran output terakhir: sekitar `51.6MB`

---

## Catatan Operasional

- File `.env` bersifat lokal dan tidak dipush.
- Untuk menjalankan aplikasi dengan endpoint sesuai environment:

```bash
flutter run --dart-define-from-file=.env
```

- Untuk build release:

```bash
flutter build apk --release --dart-define-from-file=.env
```

---

## Status Akhir

- Perubahan utama sesi ini: **Done**
- Analyzer: **Clean**
- Build APK release: **Success**
- Versi aplikasi: **2.0.0+1**
