# Mobile - Integrasi WebSocket Realtime Sensor

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Integrasi WebSocket Realtime Sensor**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi WebSocket Realtime Sensor

## Objective Card
Mengimplementasikan alur penerimaan data sensor realtime pada mobile secara stabil dengan pendekatan WebSocket yang kompatibel terhadap stack backend aktif, termasuk mekanisme subscribe channel, listener event, reconnect strategy, dan pengendalian duplikasi data pasca reconnect.

## Ringkasan Implementasi

### 1) Setup pusher client (diadaptasi ke Socket.IO client)
Status: Selesai

Perubahan utama:
- Implementasi disesuaikan ke **Socket.IO client** karena backend sudah berjalan di Socket.IO, sehingga integrasi lebih kompatibel dan sederhana dibanding menambahkan Pusher terpisah.
- Konfigurasi koneksi realtime pada mobile diseragamkan di tiga layar utama realtime:
  - Dashboard (`home_screen.dart`)
  - Monitoring (`monitoring_screen.dart`)
  - Pengujian Lokasi (`test_location_screen.dart`)

File terkait:
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/monitoring_screen.dart`
- `mobile/lib/screens/test_location_screen.dart`
- `mobile/pubspec.yaml`

### 2) Subscribe channel `sensor-monitoring`
Status: Selesai

Perubahan utama:
- Setelah `onConnect`, client mengirim event subscribe ke channel `sensor-monitoring`.
- Re-subscribe juga dijalankan kembali pada event reconnect agar room tetap aktif setelah koneksi sempat putus.

File terkait:
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/monitoring_screen.dart`
- `mobile/lib/screens/test_location_screen.dart`
- `backend/src/services/socketService.js`

### 3) Listen event `SensorDataUpdated`
Status: Selesai

Perubahan utama:
- Listener `SensorDataUpdated` aktif di layar yang membutuhkan realtime.
- Payload diubah ke model `SensorReading` sebelum update state, sehingga konsumsi data UI tetap typed dan aman.
- Error parsing event ditangani agar aplikasi tidak crash jika payload tidak sesuai format.

File terkait:
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/monitoring_screen.dart`
- `mobile/lib/screens/test_location_screen.dart`
- `backend/src/services/mqttIngestService.js`

### 4) Reconnect strategy saat koneksi putus
Status: Selesai

Perubahan utama:
- Konfigurasi reconnect diterapkan eksplisit:
  - `setTransports(['websocket'])`
  - `enableReconnection()`
  - `setReconnectionAttempts(20)`
  - `setReconnectionDelay(1000)`
  - `setReconnectionDelayMax(5000)`
  - `setTimeout(20000)`
- Listener lifecycle koneksi ditambahkan:
  - `onReconnect`
  - `onReconnectAttempt`
  - `onDisconnect`
  - `onConnectError`
  - `onError`

File terkait:
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/monitoring_screen.dart`
- `mobile/lib/screens/test_location_screen.dart`

### 5) Data realtime masuk konsisten
Status: Selesai

Perubahan utama:
- Data realtime dari backend diterima konsisten pada layar monitoring dan dashboard.
- Alur realtime dipertahankan berdampingan dengan data inisialisasi API (initial latest) sehingga tampilan awal tetap terisi sebelum stream realtime datang.

File terkait:
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/monitoring_screen.dart`
- `mobile/lib/screens/test_location_screen.dart`

### 6) Reconnect berhasil tanpa duplikasi berlebih
Status: Selesai

Perubahan utama:
- Ditambahkan guard anti-duplikasi untuk data realtime pada list histori di dashboard.
- Deduplikasi menggunakan kombinasi prioritas:
  - `id` data bila tersedia
  - fallback ke timestamp + nilai kunci sensor
- Untuk stream data pengujian, deduplikasi juga ditambahkan agar event ulang pasca reconnect tidak membanjiri list.

File terkait:
- `mobile/lib/screens/home_screen.dart`

## Mapping Definition of Done (DoD)

### DoD 1: Data realtime masuk konsisten
Status: Tercapai

Bukti:
- Event `SensorDataUpdated` diterima dan dipetakan ke model lalu ditampilkan ke UI pada layar realtime.

### DoD 2: Reconnect berhasil tanpa duplikasi berlebih
Status: Tercapai

Bukti:
- Reconnect strategy aktif dan channel di-subscribe ulang saat reconnect.
- Guard deduplikasi mencegah data ganda berlebih pada histori dashboard.

### DoD 3: Kualitas kode realtime stabil
Status: Tercapai

Bukti:
- Analisis statis untuk file realtime target menghasilkan: `No issues found`.

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh checklist card "Mobile - Integrasi WebSocket Realtime Sensor" sudah terpenuhi dengan pendekatan Socket.IO yang paling kompatibel terhadap arsitektur backend saat ini.
