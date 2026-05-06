# Mobile - Upgrade & Validasi Kompatibilitas API 33-36

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Upgrade & Validasi Kompatibilitas API 33-36**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Upgrade & Validasi Kompatibilitas API 33-36

## Objective Card
Memastikan konfigurasi Android build toolchain pada proyek Flutter mobile kompatibel untuk rentang **Android API 33 sampai API 36** melalui audit konfigurasi, upgrade versi Gradle/AGP, validasi SDK lokal, dan verifikasi build nyata.

## Ringkasan Implementasi

### 1) Audit konfigurasi Gradle Android di `mobile/android`
Status: Selesai

Perubahan utama:
- Struktur dan isi konfigurasi Android berhasil diaudit menyeluruh meliputi plugin management, wrapper Gradle, app module, dan gradle properties.
- Audit dilakukan untuk memastikan jalur upgrade aman sebelum perubahan versi dilakukan.

File terkait:
- `mobile/android/settings.gradle.kts`
- `mobile/android/gradle/wrapper/gradle-wrapper.properties`
- `mobile/android/app/build.gradle.kts`
- `mobile/android/gradle.properties`

### 2) Identifikasi warning kompatibilitas AGP 8.7.0 untuk compileSdk 36
Status: Selesai

Perubahan utama:
- Saat verifikasi awal build, ditemukan warning bahwa **AGP 8.7.0** diuji sampai `compileSdk 35`.
- Karena proyek menggunakan `compileSdk 36`, dilakukan upgrade AGP agar sesuai jalur kompatibilitas terbaru.

File terkait:
- `mobile/android/settings.gradle.kts`

### 3) Upgrade Android Gradle Plugin ke 8.10.1 di `settings.gradle.kts`
Status: Selesai

Perubahan utama:
- Versi plugin `com.android.application` berhasil ditingkatkan dari `8.7.0` ke `8.10.1`.
- Upgrade ini menstabilkan dukungan untuk target SDK terbaru yang dipakai proyek.

File terkait:
- `mobile/android/settings.gradle.kts`

### 4) Upgrade Gradle Wrapper ke 8.11.1 di `gradle-wrapper.properties`
Status: Selesai

Perubahan utama:
- `distributionUrl` diperbarui menjadi `gradle-8.11.1-all.zip`.
- Versi wrapper diselaraskan dengan AGP baru agar build chain tetap kompatibel.

File terkait:
- `mobile/android/gradle/wrapper/gradle-wrapper.properties`

### 5) Verifikasi app module tetap pakai referensi SDK dari Flutter
Status: Selesai

Perubahan utama:
- Konfigurasi `compileSdk`, `targetSdk`, dan `minSdk` pada app module tetap menggunakan:
  - `flutter.compileSdkVersion`
  - `flutter.targetSdkVersion`
  - `flutter.minSdkVersion`
- Tidak ada hardcode SDK yang berpotensi drift terhadap versi Flutter SDK.

File terkait:
- `mobile/android/app/build.gradle.kts`

### 6) Verifikasi nilai Flutter SDK (compileSdk 36, targetSdk 36, minSdk 24)
Status: Selesai

Perubahan utama:
- Nilai default Flutter Gradle extension terkonfirmasi:
  - `compileSdkVersion = 36`
  - `targetSdkVersion = 36`
  - `minSdkVersion = 24`

File terkait:
- `C:/Users/ACER/dev/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`

### 7) Verifikasi Android SDK lokal tersedia untuk API 33-36
Status: Selesai

Perubahan utama:
- Platform SDK lokal sudah tersedia untuk:
  - `android-33`
  - `android-34`
  - `android-35`
  - `android-36`
- Build-tools untuk rentang SDK ini juga tersedia.

Lingkungan terkait:
- `C:/Users/ACER/AppData/Local/Android/sdk/platforms`
- `C:/Users/ACER/AppData/Local/Android/sdk/build-tools`

### 8) Build verifikasi `:app:assembleDebug` menghasilkan BUILD SUCCESSFUL
Status: Selesai

Perubahan utama:
- Verifikasi build dijalankan pada konfigurasi baru.
- Hasil build berhasil tanpa error kompilasi.

Command verifikasi:
- `./gradlew.bat :app:assembleDebug`

### 9) Konfirmasi warning AGP lama untuk API 36 sudah tidak muncul lagi
Status: Selesai

Perubahan utama:
- Setelah upgrade AGP + Gradle wrapper, warning lama tentang AGP 8.7.0 terhadap API 36 tidak muncul pada verifikasi build terbaru.

## Mapping Definition of Done (DoD)

### DoD 1: Toolchain Android kompatibel untuk API 33-36
Status: Tercapai

Bukti:
- AGP dan Gradle wrapper telah di-upgrade ke kombinasi yang kompatibel.

### DoD 2: Konfigurasi SDK app tetap konsisten dengan Flutter
Status: Tercapai

Bukti:
- App module tetap menggunakan referensi SDK dari Flutter, bukan hardcode manual.

### DoD 3: Build Android berhasil pada konfigurasi baru
Status: Tercapai

Bukti:
- Perintah `:app:assembleDebug` menghasilkan `BUILD SUCCESSFUL`.

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh checklist kompatibilitas Android API 33-36 sudah terpenuhi end-to-end dan tervalidasi melalui build nyata.
