# Panduan & Dokumentasi Integrasi Backend untuk Tim Mobile (HERA 2.0)

Dokumen ini disusun khusus untuk Tim Pengembang Mobile (Android/iOS/Flutter/React Native) agar dapat memahami arsitektur komunikasi data HERA 2.0 saat ini, serta **penyesuaian apa saja yang harus kita lakukan di sisi Backend** agar Mobile App dapat terintegrasi secara mulus.

---

## 1. Skema Database (Model Data)

Untuk memudahkan tim Mobile memetakan format data SQLite lokal (*Local DB Cache*) atau membuat kelas struktur obyek (*Data Transfer Object/Models*), berikut ini adalah skema data utama sistem HERA:

### Tabel: `sensor_readings`
Setiap data telemetri yang datang dari IoT akan tercatat di entitas ini.

| Kolom | Tipe Data Asisten (Backend) | Tipe Data Mobile (Dart/Swift/Kt) | Keterangan |
| :--- | :--- | :--- | :--- |
| `id` | BigInt / Primary | unsigned integer | ID Unit Identifikasi |
| `ec` | Float | double | Kandungan Elektrik (µS/cm) |
| `tds` | Float | double | Total Partikel Padat (mg/L) |
| `ph` | Float | double | Kadar Asam/Basa |
| `suhu_air` | Float | double | Temperatur Air (°C) |
| `suhu_lingkungan` | Float | double | Temperatur Udara (°C) |
| `kelembapan` | Float | double | Kelembapan Relatif (%) |
| `tegangan` | Float | double | Baterai/AC Listrik (Voltage) |
| `cr_estimated` | Float (Nullable) | double? | Prediksi Hexavalent Chromium |
| `status` | String | String | Enum: `normal`, `warning`, `danger` |
| `created_at` | Timestamp | DateTime / String | Menggunakan standar ISO 8601 |
| `updated_at` | Timestamp | DateTime / String | Abaikan di _client_ |

### Tabel: `users`
Tabel profil otentikasi akun.

| Kolom | Tipe Data Asisten (Backend) | Tipe Data Mobile (Dart/Swift/Kt) | Keterangan |
| :--- | :--- | :--- | :--- |
| `id` | BigInt / Primary | unsigned integer | ID Pengguna |
| `name` | String | String | Nama Lengkap |
| `email` | String | String | Log-in identitas unik |
| `password` | String | String | Hash (Jangan disimpan di HP) |
| `role` | String | String | Enum: `direksi`, `pekerja`, `guest` |
| `created_at` | Timestamp | DateTime / String | ISO 8601 |

> [!NOTE]
> *App Settings* (pengaturan kustomasi) lazimnya diproses via API khusus secara terpisah dan di-fetch satu kali saja per sesi/awal *app open*, berformat pasangan `{ kunci: nilai }` dasar.

---

## 2. Topik Kritis: Penyesuaian yang Perlu Dilakukan di Backend untuk Mobile

Sistem backend HERA saat ini dibangun terutama untuk **Single Page Application (SPA) Web** yang berjalan menggunakan otentikasi _Session/Cookies_. Untuk mengakomodasi aplikasi Mobile secara kokoh dan aman, Backend harus disesuaikan di area berikut (ini adalah *backlog* masa depan untuk spesialis Backend):

> [!IMPORTANT]
> **A. Otentikasi Berbasis Token API (Laravel Sanctum / Passport)**
> Saat ini *endpoints* di `routes/api.php` masih dilindungi oleh *middleware* `[web, auth]` yang memaksa aplikasi Mobile untuk menyimpan dan mengirim _Session Cookies_ (Kurang ideal & sulit dipelihara di platform native).
> **Tugas Backend:** Backend wajib meng-install Laravel Sanctum, mengubah pelindung rute menjadi `middleware('auth:sanctum')`, serta merilis 2 *endpoint* baru: `POST /api/mobile/login` (menghasilkan *Bearer Token*) dan `POST /api/mobile/logout` (menghanguskan token).

> [!TIP]
> **B. Struktur Respon JSON yang Terstandarisasi**
> Mobile lebih rentan terhadap _Crash_ jika terjadi _Null Pointer Exception_ atau struktur JSON berubah-ubah secara mentah.
> **Tugas Backend:** Seluruh balasan API perlu dibungkus menggunakan antarmuka standar (*API Resources/Transformers*), misalnya selalu menggunakan kerangka:
> `{ "status": true, "message": "Berhasil", "data": { ... } }`

> [!WARNING]
> **C. Paginate Data vs Dump Data**
> Rute `/api/sensor/history` saat ini dapat mengambil hingga `limit=1000` data mentah sekaligus, yang mana tidak masalah untuk RAM Browser Desktop, namun berisiko sangat berat (_Out of Memory_) untuk perangkat _Mobile_ lama.
> **Tugas Backend:** Mengubah metode `->take($limit)` menjadi metode paginasi `->cursorPaginate(50)` atau memberikan antarmuka pemuatan per-*chunk*.

---

## 2. Struktur API Saat Ini (Perlu Penyesuaian Otentikasi)

Saat ini, *endpoints* berikut tersedia di bawah domain `[BASE_URL]/api/` (contoh: `https://[IP_ANDA]/api/...`).

### A. Dapatkan 30 Data Sensor Terakhir (Untuk *Live Init*)
`GET /api/sensor/latest`
- **Kegunaan:** Menarik jejak (30 baris terakhir) seketika untuk menggambar titik awal grafik pada _Dashboard_ sebelum koneksi *WebSocket* mengambil alih pembaruan detik-per-detik.
- **Respon Data (Array Objek):**
  ```json
  [
    {
      "id": 9942,
      "tegangan": "0.45",
      "suhu_air": "24.5",
      "suhu_lingkungan": "28.1",
      "kelembapan": "60.2",
      "tds": "301",
      "ph": "6.8",
      "cr_estimated": "45.2",
      "status": "normal",
      "created_at": "2024-04-10T01:05:00.000000Z"
    }
  ]
  ```

### B. Dapatkan Peringatan Terbaru
`GET /api/sensor/alerts`
- **Kegunaan:** Menarik maksimal 10 data paling urgen yang memegang status `warning` atau `danger`. Sangat berguna jika Mobile ingin memasang bagian khusus untuk papan pengingat (Alert Board).
- **Respon Data:** Sama persis dengan blok A, tapi hanya disaring khusus status bahaya.

### C. Analisis Historik Lanjutan (Custom Range)
`GET /api/sensor/history?from={ISO_DATE}&to={ISO_DATE}&limit={NUMBER}`
- **Kegunaan:** Didesain untuk grafik pemantauan berkala (jam, hari, tujuh hari).
- **Parameter Kueri Opsional:**
    - `from`: "2024-04-09T00:00:00Z"
    - `to`: "2024-04-10T00:00:00Z"
    - `limit`: Defaul membatasi "1000" baris data.

---

## 3. Dokumentasi WebSocket (Real-Time Streams)

Aplikasi *Mobile* TIDAK perlu memaksa hit API terus menerus setiap detik (*polling*). Semua rute data langsung ditembak melalui WebSockets menggunakan jembatan infrastruktur **Pusher** (atau yang kompatibel).

### Penyetelan Koneksi (Kredensial Mobile):
Tim Mobile harus langsung menginisialisasi pustaka _Pusher SDK_ di platform masing-masing (seperti `pusher_channels_flutter`).
*   **Host/Cluster:** Sesuai konfigurasi `.env` `PUSHER_APP_CLUSTER` (biasanya 'ap1' atau server mandiri jika menggunakan Soketi).
*   **App Key:** Sesuai kunci `.env` milik `PUSHER_APP_KEY`.

### Kanal Pendengaran (Channel Subscription):
*   **Channel Name:** `sensor-monitoring` (Ini adalah channel publik sementara).
*   **Event Name:** `.SensorDataUpdated` *(Perhatikan: Titik (".") di awal nama *event* di SDK klien seringkali merupakan penanda untuk melompati *namespace* standar Laravel. Jika diabaikan, maka Laravel biasa membroadcast sebagai `App\Events\SensorDataUpdated`)*.

### Format Muatan Data WebSocket (*Event Payload*):
Saat mesin sensor membroadcast detik per detiknya, tim Mobile akan otomatis dicegat JSON _event_ ini:
```json
{
  "sensorData": {
    "id": 9943,
    "tegangan": "0.46",
    "suhu_air": "24.6",
    ...
    "status": "normal",
    "created_at": "2024-04-10T01:05:01.000000Z"
  }
}
```

---

## Kesimpulan Rekomendasi
Jika Tim Mobile ingin mulai mencoba *(mock/dummy test)*, kalian dapat mengaksesnya sekarang. Namun, harap menahan diri terhadap penyelesaikan logik otentikasi _Login_ dan pemuatan data besar *(Historical)*, sebab Tim *Backend* harus mengerjakan rilis tiket infrastruktur "Modul API Mobile" terlebih dahulu untuk mengaktifkan Tokenisasi (Sanctum) yang aman dari perampokan sesi.
