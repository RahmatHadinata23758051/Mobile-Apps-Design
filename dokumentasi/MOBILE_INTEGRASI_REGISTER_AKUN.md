# Mobile - Integrasi Register Akun

Dokumen ini merangkum perubahan yang sudah dilakukan berdasarkan Trello CARD: **Mobile - Integrasi Register Akun**.

## Referensi Trello
- Sumber backlog: [TRELLO_MOBILE_BACKLOG_HERA_V2.md](TRELLO_MOBILE_BACKLOG_HERA_V2.md)
- Card: Mobile - Integrasi Register Akun
- Priority: P2 (Lanjutan dari Login)
- Dependency: Endpoint register backend tersedia dan terdokumentasi

## Objective Card
Mengintegrasikan UI pendaftaran (Sign Up) mobile ke endpoint `/api/mobile/register` pada *backend*, merender *error field-level* secara presisi langsung pada kolom UI yang bermasalah, dan memastikan penanganan *error* jaringan tidak menyebabkan *crash* pada aplikasi.

## Ringkasan Implementasi
Perubahan telah diselaraskan penuh dengan infrastruktur Node.js/Express yang mensimulasikan *response* validasi dengan standar format JSON Laravel (422 Unprocessable Entity).

### 1) Integrasi Endpoint Register 
Status: Selesai

Perubahan utama:
- Penambahan variabel `_registerPath` (`/api/mobile/register`) yang dieksekusi via `Dio`.
- Pembuatan endpoint Node.js lokal merespons POST dari mobile, mencatat *user* baru menggunakan *bcrypt hash*, dan mengembalikan representasi objek User.
- Penggunaan `skipAuth: true` di interceptor agar *request* Sign Up tak ditolak ketiadaan *token* Bearer.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)
- [backend/server.js](../backend/server.js)

### 2) Menangani Error Validasi Field-Level
Status: Selesai

Perubahan utama:
- `auth_service.dart` dirancang untuk membedah *property* `errors: {...}` dari HTTP 422 JSON jika validasi gagal, dan melempar turunan kelas spesifik `ValidationApiException`.
- Layar *SignUp* menggunakan blok tangkapan variabel State UI (`_backendErrors`) untuk menahan peta error (key: name, email, password).
- Teks kemerahan (*errorText*) dicantumkan mandiri ke tiap `TextFormField` melalui perantara *Form Validation*. `onChanged` me-*reset* peringatan seketika saat diketik.

File terkait:
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)
- [lib/screens/signup_screen.dart](lib/screens/signup_screen.dart)

### 3) Menuju Login Mengiringi Keberhasilan 
Status: Selesai

Perubahan utama:
- Jika *response* bernilai `status: true`, sebuah SnackBar sukses berwarna hijau (atau standar layar) akan dipanggil.
- Transisi halaman tanpa tumpukan berlapis menggunakan `Navigator.pushReplacementNamed`, lengkap membawa argumen *username* dan *email* untuk pra-isi (pre-fill) form login selanjutnya.

File terkait:
- [lib/screens/signup_screen.dart](lib/screens/signup_screen.dart)

## Mapping Definition of Done (DoD)

### DoD 1: User baru bisa daftar dengan data valid
Status: Tercapai

Bukti:
- Endpoint *Express backend* merespon status HTTP 200/201 dan menginjeksikan data *user* baru ke tabel PostgreSQL `users`, sekaligus memberikan umpan balik log _query_ aman (`Pool.query`).  

### DoD 2: Error validasi tampil jelas di UI
Status: Tercapai

Bukti:
- Percobaan registrasi dengan input email *"admin@hera.com"* (yang telah ter-seeding di db) akan mewarnai _border_ maupun _sub-text_ tepat pada `TextFormField(Email)` dengan teks peringatan spesifik dari tangkapan backend.  

### DoD 3: Tidak ada crash saat register gagal
Status: Tercapai

Bukti:
- Kegagalan server (*500*) maupun Preflight/CORS dikendalikan di blok `try...catch` dan menghasilkan `SnackBar` info alih-alih melempar _red screen of death_ untuk _unhandled asynchronous exception_.

## Konfigurasi Run yang Direkomendasikan

Jalankan sisi backend lokal sebelum merefresh UI Flutter.
```bash
# Terminal Backend
npm start

# Terminal Flutter
flutter run -d chrome 
```

## Catatan Teknis Penting
- Di dalam arsitektur baru, karena respon yang ditangkap oleh Flutter bersandar pada tipe kelas `DioException`, keutuhan form API (khususnya status angka 422 *Unprocessable Entity*) mutlak wajib terpenuhi. Apabila Anda kelak beralih backend (*Laravel seutuhnya*), pastikan framework tersebut memang dikonfigurasi untuk mengeluarkan *array associative* di dalam key JSON bernama `errors`.

## Status Akhir CARD
Status: **Done**

Catatan:
- Layar registrasi (Registrasi -> Validasi Realtime -> Push Login) sudah disterilkan dari metode *delay/mock* buatan lama dan dihubungkan seutuhnya ke integrasi API interaktif.
