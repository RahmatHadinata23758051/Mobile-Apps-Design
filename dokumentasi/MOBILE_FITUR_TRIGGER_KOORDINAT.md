# Mobile - Menambahkan Fitur Trigger untuk Mengirimkan Koordinat

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Menambahkan Fitur Trigger untuk Mengirimkan Koordinat**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Menambahkan Fitur Trigger untuk Mengirimkan Koordinat

## Objective Card
Mengimplementasikan pemicu manual (*trigger*) fungsional pengujian di *Mobile Application* yang sanggup mencegat titik koordinat GPS seketika dan mentransmisikannya langsung bersama parameter kualitas air (Auto-Fill real-time dari alat) secara terisolasi ke database pengujian khusus (*testing_data*) di Backend.

## Ringkasan Implementasi

### 1) Menentukan kondisi trigger pengiriman koordinat
Status: Selesai

Perubahan utama:
- Kondisi pengujian pemicu tembakan data berhasil dikembangkan di layar independen yang diakses dari bilah samping (Drawer) bernama "Pengujian Koordinat".
- Proses trigger terjadi saat pengguna memencet tombol raksasa "Simpan Data Pengujian" dan memuat proses *loading state* anti-klik-ganda.
- Data dari _SensorService_ otomatis terekam (auto-fill dari stream sensor dua-detikan) untuk dikemas bersama data GPS aktif.

File terkait:
- `HERA_V2/lib/screens/test_location_screen.dart`

### 2) Menyiapkan endpoint atau mekanisme pengiriman data
Status: Selesai

Perubahan utama:
- Endpoint penerima dan penyimpan pengujian koordinat sudah sepenuhnya dibuat di sistem Node.js backend. Sebuah rute baru POST `/api/mobile/testing/location` telah disambungkan. 
- Ia memiliki kendali penampung dan pengolah melalui *TestController* serta menggunakan relasi *TestModel*.
- Database mengamodasi tabel histori tersendiri (`testing_data`) sehingga tak mencemari grafik riwayat kolam utama aslinya.

File terkait:
- `backend/src/routes/testRoutes.js`
- `backend/src/controllers/testController.js`
- `backend/src/models/postgres/testModel.js`

### 3) Mengambil data latitude dan longitude
Status: Selesai

Perubahan utama:
- Konfigurasi data Lintang (*latitude*) dan Bujur (*longitude*) sekarang dicegat secara otonom di latar belakang melalui intervensi mulus pustaka internal standar industri `geolocator`. 
- Sistem mengurai otomatis prosedur permintaan izin GPS (*Location Permissions*), mengelola kemungkinan penolakan selamanya, hingga eksekusi penetapan penarikkan akurasi GPS tertinggi (*LocationAccuracy.high*). 

File terkait:
- `HERA_V2/lib/screens/test_location_screen.dart`

### 4) Mengirim koordinat saat trigger aktif
Status: Selesai

Perubahan utama:
- Setelah trigger aktif mendeteksi dan menyelesaikan parameter titik Latitude dan Longitude milik Smartphone, nilai tersebut direkatkan bersama 6 buah parameter fisik sampel air *(PPM, Suhu, dll.)*. 
- Mempekerjakan jembatan perantara Dio yang membengkus format form menuju Endpoint REST, ditangani oleh metode global terbaru `TestService.sendTestingData()`.

File terkait:
- `HERA_V2/lib/core/services/test_service.dart`

### 5) Melakukan validasi data koordinat yang dikirim
Status: Selesai

Perubahan utama:
- Skrip validasi lapis pertama telah digembar-gemborkan pada sistem pelayan di baris kode terdepan server aslinya. 
- Menjaga wujud data selalu bernilai eksak *floating-point math* (Float).
- Mencegat pelanggaran mutlak aturan matematika Bumi: *latitude* (mutlak wajib berada di antara rentang -90° hingga 90°) dan *longitude* (-180° hingga 180°). Bila meleset akibat rusaknya receiver HP, API memuntahkan peringatan tolakan dan layar HP menghitam menjadi *Error Alert*.

File terkait:
- `backend/src/controllers/testController.js`

### 6) Testing trigger dan pengiriman data
Status: Selesai

Perubahan utama:
- Rute trigger divalidasi tidak mematahkan siklus UI sama sekali. Terdapat fitur interaksi berupa indikator memuat *(CircularProgressIndicator)* selama pengunggahan letak geografis hingga peneluran warna *Success/Red Snackbar*.
- Seluruh riwayat rekaman tak hanya lenyap di Backend, melainkan dikomunikasikan kembali memancarkan representasi *Tabel View* masif berjudul **"Histori Pengujian (Dengan Lokasi GPS)"** ke layar **Dashboard** paling bawah (bersama icon letak GPS-nya!).

File terkait:
- `HERA_V2/lib/screens/test_location_screen.dart`
- `HERA_V2/lib/screens/dashboard_screen.dart`

## Mapping Definition of Done (DoD)

### DoD 1: Trigger Pengiriman & Auto-Fetch Koordinat
Status: Tercapai

Bukti:
- Modul _Geolocator_ bekerja serentak bersama _SensorService._ Saat memencet *Trigger*, lokasi langsung didapatkan, diverifikasi *Permissions*-nya, digabungkan dengan real-value perairan, lalu disiarkan ke backend server via layanan `TestService`.

### DoD 2: Database Storage Ekslusif Testing
Status: Tercapai

Bukti:
- Tabel baru postgres bernama `testing_data` otomotik dikonstruksi apabila baru pertama dinyalakan (`testModel.ensureSchema`), merepresentasikan rekam jejak koordinat lapangan mutlak tak tercampur aduk.

### DoD 3: Perlindungan Integritas Format Koordinat
Status: Tercapai

Bukti:
- Keberhasilan integrasi _Server-side Guard_: Skala rentang sudut dan letak titik geografik bumi akan sepenuhnya dibenturkan secara algoritmik apabila terkirim di luar perputaran globe validnya.

## Status Akhir CARD
Status: **Done**

Catatan:
- Ringkasan akhir: Keseluruhan target esensial dari tiket ini sudah sepenuhnya terimplementasikan, bahkan ditenagai kecerdasan *Auto-Fill live* memuat tabel demonstrasi pemantauan _history_ visual di antarmuka dasar Mobile HERA V2.
