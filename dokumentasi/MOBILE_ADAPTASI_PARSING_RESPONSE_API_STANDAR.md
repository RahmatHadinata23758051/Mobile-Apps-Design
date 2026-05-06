# Mobile - Adaptasi Parsing Response API Standar

Dokumen ini mencatat implementasi task Trello "Mobile - Adaptasi Parsing Response API Standar" pada project HERA V2.

## Ringkasan Status
- Wrapper response API: Selesai
- Refactor parser latest/alerts/history: Selesai
- Null-safe parsing: Selesai
- Mapping error message ke UI: Selesai
- Pencegahan crash parsing: Selesai untuk flow yang sudah diintegrasikan
- Konsistensi error API di UI: Selesai untuk login dan ringkasan sensor

## Tujuan Perubahan
1. Menyamakan cara aplikasi membaca response backend dengan format standar: `status`, `message`, `data`.
2. Mengurangi risiko crash akibat payload null/format tidak konsisten.
3. Menyatukan pola handling error agar user selalu mendapat pesan yang jelas.

## Daftar Perubahan dan Penjelasan

### 1) `lib/core/network/api_response.dart`
**Perubahan:**
- Menambahkan model wrapper generic `ApiResponse<T>`.
- Menambahkan factory `fromJson` untuk parse `status`, `message`, dan `data`.

**Penjelasan:**
- File ini menjadi fondasi parser standar untuk semua endpoint.
- Dengan generic type, data response bisa dipetakan fleksibel tanpa duplikasi parser di banyak tempat.

---

### 2) `lib/core/models/sensor_reading.dart`
**Perubahan:**
- Menambahkan model `SensorReading`.
- Menambahkan helper parsing aman: `_toInt`, `_toDouble`, `_toDateTime`.

**Penjelasan:**
- Model ini memastikan data sensor dibaca aman walaupun tipe dari backend bisa campuran (`String`/`num`/`null`).
- Parsing aman ini menutup celah crash karena cast langsung.

---

### 3) `lib/core/models/sensor_history_result.dart`
**Perubahan:**
- Menambahkan model `SensorHistoryResult` dengan `items` dan `nextCursor`.

**Penjelasan:**
- Dipakai untuk mendukung response history yang bisa berbentuk cursor pagination.
- Menjaga struktur data history tetap konsisten di layer service/UI.

---

### 4) `lib/core/services/sensor_service.dart`
**Perubahan:**
- Menambahkan service baru untuk endpoint:
  - `fetchLatest()` -> `/sensor/latest`
  - `fetchAlerts()` -> `/sensor/alerts`
  - `fetchHistory()` -> `/sensor/history`
- Menambahkan parser response yang tahan beberapa bentuk payload:
  - array langsung
  - wrapper `{status,message,data}`
  - payload map dengan `data` list (pagination)
- Menambahkan ekstraksi error message dari backend (`message` atau `errors`).

**Penjelasan:**
- Ini adalah refactor utama parser latest/alerts/history.
- Semua endpoint sensor sekarang lewat satu pola parsing yang null-safe dan lebih mudah dirawat.

---

### 5) `lib/core/network/auth_storage.dart`
**Perubahan:**
- Menambahkan penyimpanan session aman dengan `flutter_secure_storage`.
- Menyimpan token bearer serta metadata user (`username`, `email`).

**Penjelasan:**
- Mengganti pola penyimpanan sensitif agar lebih aman dibanding storage biasa.
- Menjadi fondasi untuk auth interceptor dan login flow token-based.

---

### 6) `lib/core/network/auth_interceptor.dart`
**Perubahan:**
- Menambahkan interceptor untuk inject header `Authorization: Bearer <token>` otomatis.
- Menambahkan opsi `skipAuth` untuk endpoint publik (contoh login).
- Menambahkan pembersihan session lokal saat menerima `401`.

**Penjelasan:**
- Mengurangi duplikasi header auth di setiap request.
- Menjaga konsistensi perilaku auth ketika token sudah tidak valid.

---

### 7) `lib/core/network/api_client.dart`
**Perubahan:**
- Menambahkan konfigurasi `Dio` terpusat.
- Menambahkan `baseUrl` via `--dart-define=API_BASE_URL`.
- Menautkan `AuthInterceptor`.

**Penjelasan:**
- Semua call API sekarang lewat satu client terstandar.
- Memudahkan perpindahan environment tanpa edit kode berkali-kali.

---

### 8) `lib/core/services/auth_service.dart`
**Perubahan:**
- Menambahkan login API berbasis bearer token (`/mobile/login`).
- Menggunakan `ApiResponse` wrapper untuk parsing response login.
- Menambahkan fallback dan validasi token/user agar tidak crash saat payload berubah.
- Menambahkan `ApiException` untuk pesan error yang rapi ke UI.

**Penjelasan:**
- Login tidak lagi dummy delay, tapi benar-benar konsumsi backend.
- Error dari backend diproses ke pesan yang konsisten untuk user.

---

### 9) `lib/screens/login_screen.dart`
**Perubahan:**
- Mengganti proses login dari simulasi menjadi call ke `AuthService.login`.
- Menampilkan error API via `SnackBar` dengan pesan dari `ApiException`.

**Penjelasan:**
- UI login sekarang terhubung ke backend standar response.
- User mendapat feedback error yang lebih jelas (misal kredensial salah/server gagal).

---

### 10) `lib/screens/home_screen.dart`
**Perubahan:**
- Menambahkan pemanggilan ringkasan sensor saat awal screen:
  - latest
  - alerts
  - history
- Menambahkan handler `_showApiError()` untuk menampilkan pesan konsisten via `SnackBar`.
- Menambahkan clear secure session saat logout.

**Penjelasan:**
- Membuktikan parser latest/alerts/history benar-benar terpakai di UI.
- Menyatukan pola error tampil ke user pada screen utama.

---

### 11) `pubspec.yaml` dan `pubspec.lock`
**Perubahan:**
- Menambahkan dependency:
  - `dio`
  - `flutter_secure_storage`

**Penjelasan:**
- `dio` dipakai untuk HTTP client + interceptor.
- `flutter_secure_storage` dipakai untuk menyimpan token secara aman.

## Dampak Teknis
1. Arsitektur network menjadi terpusat (client + interceptor + wrapper).
2. Parsing data sensor dan login lebih tahan perubahan payload backend.
3. Pengalaman user lebih stabil karena error ditampilkan konsisten, bukan crash.

## Catatan Pengujian
- Dependency berhasil di-resolve melalui `flutter pub get`.
- Tidak ditemukan error compile pada file utama yang terkait perubahan parser dan auth saat pengecekan terakhir.

## Catatan Dependensi Backend
- Integrasi ini mengasumsikan backend menggunakan response standar (`status`, `message`, `data`).
- Jika backend mengirim format non-standar, beberapa flow sudah memiliki fallback parser, namun tetap disarankan backend konsisten.
