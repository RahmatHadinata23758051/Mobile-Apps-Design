# Arsitektur & Struktur Folder Mobile Apps HERA v2.0

Dokumen ini berisi penjelasan singkat mengenai struktur folder dan arsitektur dasar dari aplikasi seluler mobile HERA_V2 yang dibangun menggunakan framework **Flutter** dan **Dart**.

---

## 📄 `lib/main.dart`
File paling utama yang otomatis dipanggil pertama kali saat aplikasi dijalankan. Di sini kita menentukan konfigurasi utama aplikasi, *Routing* awal (jalur navigasi tiap halaman), penggunaan kerangka bawaan UI (*MaterialApp*), dan pemeriksaan sesi token *login* awal.

---

## 📂 `lib/screens/` (Folder Antarmuka / UI)
Folder ini murni berisi kode tampilan/desain halaman (UI) yang langsung dilihat atau berinteraksi langsung dengan pengguna. File-file di sini bertugas merender *Widgets* di layar.

*   **`login_screen.dart`** & **`signup_screen.dart`**: Halaman untuk masuk (Login) dan mendaftar akun baru (Register).
*   **`home_screen.dart`**: Halaman beranda utama tempat pengguna pertama kali mendarat setelah *login*. Berisi laci menu (*drawer*), ringkasan metrik sensor/API, kecepatan, dan tabel rentang riwayat data sensor dari PostgreSQL.
*   **`dashboard_screen.dart`**: Halaman rincian lebih lanjut yang memiliki alat untuk memindai jaringan, berinteraksi dengan perangkat lunak **BLE (*Bluetooth Low Energy*)**, serta tabel riwayat data sensor ekstra.
*   **`monitoring_screen.dart`**: Halaman antarmuka khusus yang dirancang untuk visualisasi metrik sensor secara mendetail, yang dapat dihubungkan ke data pembaruan *real-time*.
*   **`ble_scan_screen.dart`**: Halaman antarmuka yang sepenuhnya didedikasikan secara modular untuk fitur pencarian (scanning) dan penghubungan perangkat sensor via modul Bluetooth.
*   **`profile_view.dart`**: Halaman profil yang menyoroti data biodata pengguna (seperti `username` dan `email`) berdasarkan profil sesi *login* saat ini.

---

## 📂 `lib/core/` (Folder Logika Inti & Sistem Base)
Folder esensial ini menampung **urat nadi** aplikasi secara internal. Seluruh fondasi tersembunyi seperti penanganan *backend API*, konversi bahasa komputer JSON, pengamanan token, manajemen status (State), hingga logika keamanan, berada di folder ini.

*   **`core/database_helper.dart`**: 
    File manajemen/utilitas pendukung (seperti pengaturan penyambung SQLite atau konfigurator cache). Menangani hal-hal terkait utilitas database lokal aplikasi (apabila digabungkan dengan preferensi pengguna berbayar).

### 1. `core/models/` (Cetakan Data)
Folder pendefinisian cetak biru (blueprint) data.
*   **`sensor_reading.dart`** & **`sensor_history_result.dart`**: 
    Berkas *parser* (pengolah) yang bertugas secara otomatis mengurai Data teks JSON kotor hasil tangkapan dari *Backend* PostgreSQL dan Node.js ke format Objek *Dart* terstruktur (Model), agar aman dan mudah dioperasikan ke UI.

### 2. `core/network/` (Mesin Internet)
Otak komunikasi jaringan Aplikasi dan Backend NodeJS.
*   **`api_client.dart`**: Rumah konfigurasi *Dio HTTP client* sebagai instansi terpusat setiap tembakan akses jaringan (timeout logic, dsb).
*   **`auth_interceptor.dart`**: "Penjaga gawang" otomatis yang bertugas menyisipkan **Header Bearer Token Login** ke dalam setiap permintaan (Request).
*   **`auth_storage.dart`**: Manajer penyimpanan rahasia lokal (*Secure Storage* bawaan sistem operasi) untuk mengelola token API, `username`, dan `email` tanpa menyebarkannya.
*   **`backend_endpoints.dart`**: Daftar buku catatan untuk semua alamat jalur *URL API* (*Endpoints URL*). Mencegah penulisan hardcode berulang-ulang, misalnya `/api/mobile/login` atau `/sensor/history`.
*   **`api_response.dart`**: Format standardisasi pembungkus kelas JSON untuk segala penyesuaian jawaban (response) jaringan yang kembali dari server (baik Sukses/Error).

### 3. `core/services/` (Layanan Utama / Business Logic)
Menjembatani pemanggilan murni *UI Screens* menuju pusat kerja *Network*. Layar cukup memanggil layanan di sini, tanpa tahu beban jaringannya.
*   **`auth_service.dart`**: Mengontrol logika alur kerja secara utuh untuk menekan tombol *Login*, mencocokkan kredensial, mengambil detail profil (`getCurrentUser`), serta proses pembersihan saat *Logout*.
*   **`sensor_service.dart`**: Modul fungsional untuk berinteraksi dengan API yang menarik data angka/histori *PostgreSQL* bagi penyegaran metrik otomatis ke UI (*fetchLatest*, *fetchHistory*, dll).

### 4. `core/widgets/` (Rumah Komponen Bebas)
Tempat menaruh modul-modul UI buatan tangan (*Custom widgets*) yang dapat dipanggil dan diulang di berbagai tempat tanpa menyalin-rekat seluruh kodenya.
*   **`protected_route.dart`**: Logika Widget "Gerbang Pengaman". Apabila pengguna yang belum diautentikasi (atau token hilang di latar belakang) mencoba memaksa muat sebuah layar, program *wrapper* ini akan langsung membatalkan muatan dan menelurnya kembali ke halaman `/login`.

---
*Dibuat untuk memudahkan penjelajahan dan perawatan/pengembangan aplikasi mobile HERA v2.0 di tim pengembang mendatang.*
