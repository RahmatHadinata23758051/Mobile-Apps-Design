# Mobile - Integrasi Altitude pada Lokasi Pengujian

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Integrasi Altitude pada Lokasi Pengujian**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi Altitude pada Lokasi Pengujian

## Objective Card
Menambahkan dukungan altitude secara end-to-end pada alur pengujian lokasi mobile, mulai dari capture GPS, pengiriman API, penyimpanan database, hingga visualisasi pada histori dashboard dan halaman histori pengujian.

## Ringkasan Implementasi

### 1) Ambil nilai altitude dari GPS saat capture lokasi (`Geolocator Position.altitude`)
Status: Selesai

Perubahan utama:
- Capture lokasi kini mengambil tiga nilai koordinat: latitude, longitude, dan altitude dari objek `Position`.
- Pengambilan dilakukan saat inisialisasi halaman dan saat tombol simpan ditekan.

File terkait:
- `mobile/lib/screens/test_location_screen.dart`

### 2) Tambahkan tampilan Altitude di layar pengujian lokasi
Status: Selesai

Perubahan utama:
- Bagian "Tangkapan GPS" di layar pengujian sekarang menampilkan kolom `Altitude` berdampingan dengan `Latitude` dan `Longitude`.
- Format tampilan altitude menggunakan meter agar mudah dibaca pengguna.

File terkait:
- `mobile/lib/screens/test_location_screen.dart`

### 3) Kirim altitude di payload API pengujian (`sendTestingData`)
Status: Selesai

Perubahan utama:
- Method `sendTestingData` sudah menerima parameter `altitude`.
- Payload request ke endpoint pengujian kini menyertakan field `altitude`.

File terkait:
- `mobile/lib/core/services/test_service.dart`
- `mobile/lib/screens/test_location_screen.dart`

### 4) Update service/model mobile agar mendukung field altitude
Status: Selesai

Perubahan utama:
- Service pengujian sudah disesuaikan agar field `altitude` dapat dikirim konsisten.
- Komponen histori di dashboard dan halaman histori pengujian sudah membaca field `altitude`.

File terkait:
- `mobile/lib/core/services/test_service.dart`
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/testing_history_screen.dart`

### 5) Backend menerima field altitude (nullable-safe)
Status: Selesai

Perubahan utama:
- Controller backend menerima `alt`/`altitude`, melakukan parsing aman, dan menyimpan sebagai `null` jika nilai tidak tersedia.
- Validasi koordinat tetap berjalan tanpa mematahkan alur lama.

File terkait:
- `backend/src/controllers/testController.js`

### 6) Simpan altitude ke database histori pengujian
Status: Selesai

Perubahan utama:
- Skema `testing_data` sudah memiliki kolom `altitude`.
- Insert data pengujian kini menulis nilai altitude ke PostgreSQL.

File terkait:
- `backend/src/models/postgres/testModel.js`

### 7) Sertakan altitude pada response histori pengujian
Status: Selesai

Perubahan utama:
- Query histori mengambil seluruh kolom termasuk `altitude`, sehingga otomatis ikut pada response API histori.

File terkait:
- `backend/src/models/postgres/testModel.js`
- `backend/src/controllers/testController.js`

### 8) Tampilkan altitude di tabel histori pengujian (dashboard/testing history)
Status: Selesai

Perubahan utama:
- Dashboard menampilkan lokasi dengan format `(Lat, Lng, Alt)`.
- Halaman histori pengujian juga menampilkan altitude pada kolom lokasi.

File terkait:
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/testing_history_screen.dart`

### 9) Tambahkan fallback jika altitude tidak tersedia (mis. tampil `-`)
Status: Selesai

Perubahan utama:
- UI pengujian lokasi menampilkan "Belum didapat" bila altitude belum tersedia.
- UI histori menampilkan `-` bila nilai altitude null/tidak tersedia.

File terkait:
- `mobile/lib/screens/test_location_screen.dart`
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/testing_history_screen.dart`

### 10) Verifikasi dengan test manual end-to-end + `flutter analyze`
Status: Selesai

Perubahan utama:
- Flow end-to-end sudah tervalidasi: capture lokasi -> kirim API -> simpan database -> tampil di histori.
- Analisis statis Flutter pada file terkait dinyatakan bersih.

File terkait:
- `mobile/lib/screens/test_location_screen.dart`
- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/testing_history_screen.dart`

### 11) Add an item: stabilisasi auto-update histori setelah lama berjalan
Status: Selesai

Perubahan utama:
- Dashboard ditambah fallback auto-refresh periodik.
- Dashboard melakukan refresh saat app kembali aktif (`resumed`) dan saat kembali dari halaman pengujian.
- Reconnect Socket.IO kini memicu sinkronisasi ulang dari API agar tabel tidak stale.

File terkait:
- `mobile/lib/screens/home_screen.dart`

## Mapping Definition of Done (DoD)

### DoD 1: Data pengujian baru menyimpan latitude, longitude, dan altitude
Status: Tercapai

Bukti:
- Backend menerima, memproses, dan menyimpan nilai altitude ke tabel `testing_data`.

### DoD 2: Altitude tampil di UI pengujian dan histori
Status: Tercapai

Bukti:
- Altitude tampil di panel GPS pada layar pengujian.
- Altitude tampil pada tabel histori di dashboard dan halaman histori pengujian.

### DoD 3: Tidak ada error parsing/API setelah penambahan field
Status: Tercapai

Bukti:
- Payload dan parser API sudah kompatibel untuk field `altitude`, termasuk kondisi nullable.

### DoD 4: Realtime/flow existing tetap berjalan normal
Status: Tercapai

Bukti:
- Event realtime tetap berjalan.
- Fallback refresh tambahan menjaga data histori tetap update walau terjadi miss event/reconnect.

## Status Akhir CARD
Status: **Done**

Catatan:
- Seluruh target card sudah selesai diimplementasikan end-to-end. Integrasi altitude berjalan dari mobile ke backend hingga database dan kembali ke UI histori secara konsisten.
