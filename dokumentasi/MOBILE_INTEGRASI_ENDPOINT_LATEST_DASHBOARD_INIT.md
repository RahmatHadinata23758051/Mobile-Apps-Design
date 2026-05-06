# Mobile - Integrasi Endpoint Latest untuk Dashboard Init

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Integrasi Endpoint Latest untuk Dashboard Init**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi Endpoint Latest untuk Dashboard Init

## Objective Card
Mengintegrasikan endpoint nilai terbaru (latest) dari database PostgreSQL (`/sensor/latest`) khusus untuk layar Dashboard agar langsung memiliki nilai acuan (*initial data*) sebelum modul perangkat keras (Bluetooth/ESP32) berhasil disinkronkan, dengan penanganan state (Loading/Empty/Error) mutlak.

## Ringkasan Implementasi

### 1) Integrasi endpoint latest
Status: Selesai

Perubahan utama:
- Mobile sekarang memanggil endpoint `GET /sensor/latest` melalui perantara `SensorService.fetchLatest()` secara otomatis saat awal layar Dashboard dimuat.
- Pemanggilan API dikelola secara asinkron (melalui fungsi `_fetchLatestDataInit()` di blok `initState`) agar aktivitas layar UI tidak mematung/terblokir.
- Permintaan API tersebut sudah mendapat injeksi token otentikasi (Bearer) hasil bentukan rutin `AuthInterceptor`.

File terkait:
- `HERA_V2/lib/screens/dashboard_screen.dart`
- `HERA_V2/lib/core/services/sensor_service.dart`

### 2) Mapping ke chart/list
Status: Selesai

Perubahan utama:
- Data tangkapan terbaru yang mengembalikan tipe objek `SensorReading` telah dipetakan (di-mapping ulang) ke dictionary model parameter `_sensorData`.
- Variabel terukur dari response seperti Suhu Air, Suhu Lingkungan, Kelembapan, TDS, Tegangan, EC, dan pH seketika diekstrak menempati posisi matriks pada komponen `GridView` ("Data Sensor").
- Proses pemetaan dirakit sedemikian rupa sehingga 100% kompatibel (tidak mematahkan) skema sinkronisasi data rekam *real-time* Bluetooth (jika ESP32 sudah online menimpa variabel state).

File terkait:
- `HERA_V2/lib/screens/dashboard_screen.dart`

### 3) Loading/empty/error state
Status: Selesai

Perubahan utama:
- Terdapat render pengamanan antarmuka UI *fail-safe* spesifik bereaksi secara adaptif menurut siklus pembacaan HTTP:
  - **Loading**: Merender animasi lingkar `CircularProgressIndicator` saat muatan HTTP Request berlangsung (`_isLoadingLatest = true`).
  - **Error State**: Menyediakan teks pesan peringatan berwarna merah beserta tombol operasional *"Coba Lagi (Server)"* apabila panggailan jaringan terputus (`_latestError`).
  - **Empty State**: Mengeluarkan pemicu fallback visual ("Belum ada data awal dari Server atau ESP32.") jika respons array API tak mengandung data sensor apa-apa.

File terkait:
- `HERA_V2/lib/screens/dashboard_screen.dart`

### 4) Monitorngmenampilkan initial data dengan benar
Status: Selesai

Perubahan utama:
- Tidak ada lagi kesan "Kekosongan / Tak Ada Perangkat Tersambung" untuk menyambut pengguna layar. Dashboard merilis fitur penampakan snapshot nilai pamungkas fungsional dari PostgreSQL backend.
- Pengguna sanggup seketika memonitor dan bernavigasi ria melalui pemahaman kondisi data kolam terakhir, sembari memantau sinkronisasi *hardware*.

File terkait:
- `HERA_V2/lib/screens/dashboard_screen.dart`

## Mapping Definition of Done (DoD)

### DoD 1: Dashboard memanggil API /sensor/latest saat load awal (Init)
Status: Tercapai

Bukti:
- Panggilan fungsi `_sensorService.fetchLatest()` ditembak langsung secara sekuensial di dalam blok `initState` menuju backend, sehingga parameter nilai tak lagi gersang saat menanti Bluetooth.

### DoD 2: Mapping integrasi tanpa kompromi performa Bluetooth
Status: Tercapai

Bukti:
- Nilai penampungan `_sensorData` ditimpa tepat menurut standar Map dictionary format pembacaan Bluetooth, alhasil Grid Layout "Data Sensor" berfungsi dengan normal dari server, dan terbarui tanpa batas memakan data ganti dari alat *local real-time stream*.

### DoD 3: Melengkapi Loading, Error, & Empty State
Status: Tercapai

Bukti:
- Adanya `CircularProgressIndicator`, kondisi render kondisional penangkap string asinkronus `_latestError`, beserta mekanisme fallback interaktif teks apabila tangkapan data ternyata kosong.

## Status Akhir CARD
Status: **Done**

Catatan:
- Ringkasan akhir: Keseluruhan tuntutan poin evaluasi dan kelayakan untuk tiket "Mobile - Integrasi Endpoint Latest untuk Dashboard Init" telah terselesaikan. Muatan data observasi pembuka aplikasi (Dashboard Init API) stabil dieksekusi secara mandiri dengan perlindungan *state UI rendering* utuh.
