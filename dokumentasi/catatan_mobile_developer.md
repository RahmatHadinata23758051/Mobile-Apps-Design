# 📱 Catatan Penyesuaian untuk Tim Mobile Developer
## HERA 2.0 — Backend Compatibility Notes
> Dibuat: 16 April 2026  
> Backend: Laravel 11 + Sanctum (VPS: `http://103.217.145.187:8000`)

---

## ℹ️ Garis Besar

Backend HERA 2.0 (Laravel) **sudah berjalan di VPS**. Berikut adalah hal-hal yang perlu **tim mobile sesuaikan** di sisi Flutter agar kompatibel dengan kontrak API yang sudah ada di backend.

---

## 1. Konfigurasi Base URL ke VPS

Ganti default value di `backend_endpoints.dart`:

```dart
// Sebelumnya (lokal):
defaultValue: 'http://127.0.0.1:3000'

// Setelah (production VPS):
defaultValue: 'http://103.217.145.187:8000'
```

---

## 2. Path Endpoint Sensor — Wajib Disesuaikan di Mobile

Saat ini mobile memanggil path sensor **tanpa prefix `/api/mobile/`** dan **tanpa Sanctum Bearer Token**.  
Backend sudah menyediakan endpoint sensor yang benar dengan Sanctum auth, namun di path yang berbeda.

| Fitur | Path Mobile Saat Ini | Path Backend yang Benar | Keterangan |
|-------|---------------------|------------------------|------------|
| Sensor Latest | `GET /sensor/latest` | `GET /api/mobile/sensor/latest` | Perlu Bearer Token Sanctum |
| Sensor Alerts | `GET /sensor/alerts` | `GET /api/mobile/sensor/alerts` | Perlu Bearer Token Sanctum |
| Sensor History | `GET /sensor/history` | `GET /api/mobile/sensor/history` | Path & query param berbeda (lihat poin 3) |

**Tindakan:** Update konstanta di `BackendEndpoints`:
```dart
static const String sensorLatest  = '/api/mobile/sensor/latest';
static const String sensorAlerts   = '/api/mobile/sensor/alerts';
static const String sensorHistory  = '/api/mobile/sensor/history';
```

Pastikan request sensor sudah menggunakan `AuthInterceptor` (Bearer Token), bukan request publik.

---

## 3. Query Parameter Sensor History — Perlu Disesuaikan

Backend menggunakan nama query parameter yang **berbeda** dari yang dipakai mobile saat ini.

| Parameter | Mobile Saat Ini | Backend (Gunakan ini) |
|-----------|----------------|----------------------|
| Start date | `from` | `from_date` |
| End date | `to` | `to_date` |
| Filter status | `source` | `status` (`normal`, `warning`, `danger`) |
| Pagination | `cursor` | `page` (offset-based, bukan cursor) |
| Limit per page | `limit` | `limit` ✅ |

**Contoh request yang benar:**
```
GET /api/mobile/sensor/history?from_date=2026-04-01&to_date=2026-04-16&status=danger&limit=50&page=1
```

---

## 4. Format Response Profil User — Perlu Disesuaikan di Mobile

Backend mengembalikan profil user dengan struktur yang **berbeda** dari yang diharapkan `AuthService.getCurrentUser()` di mobile.

**Yang backend kembalikan (`GET /api/mobile/profile`):**
```json
{
  "status": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@hera.ac.id",
    "role": "operator"
  }
}
```

**Yang mobile harapkan (parser di `auth_service.dart` baris 178):**
```json
{
  "data": {
    "user": { "id": 1, "name": "...", "email": "..." }
  }
}
```

**Tindakan:** Update parser di `AuthService.getCurrentUser()` agar membaca `body['data']` langsung (tanpa `.user`), ATAU update path dari `/api/mobile/me` menjadi `/api/mobile/profile`.

---

## 5. Endpoint `me`, Update Profil & Ganti Password — Tidak Tersedia

Endpoint berikut **tidak ada** di backend dan **tidak akan dibuat** (Mobile harus menyesuaikan):

| Endpoint Mobile | Alternatif di Backend |
|----------------|----------------------|
| `GET /api/mobile/me` | Gunakan `GET /api/mobile/profile` |
| `PUT /api/mobile/me` | ❌ Belum tersedia — fitur update profil via mobile belum ada di backend |
| `PUT /api/mobile/password` | ❌ Belum tersedia |

**Rekomendasi sementara:** Nonaktifkan fitur Edit Profil & Ganti Password di mobile sampai endpoint ini dibuat di periode development berikutnya.

---

## 6. Testing History — Format Response Sudah Diupdate ✅

Backend sudah diupdate agar mendukung **cursor-based pagination** yang diharapkan mobile.

**Format response baru `GET /api/mobile/testing/history`:**
```json
{
  "status": true,
  "message": "Success retrieve history",
  "data": {
    "data": [ ... list field test ... ],
    "next_cursor": "2026-04-15T10:00:00+07:00"
  }
}
```

Query parameter yang didukung:
- `limit` — jumlah item per halaman (default: 20)
- `cursor` — ISO datetime string dari `next_cursor` sebelumnya (opsional, untuk halaman berikutnya)

**Tidak ada perubahan yang perlu dilakukan di mobile untuk fitur ini.**

---

## 7. Field `altitude` pada Testing Location — Sudah Didukung Backend ✅

Backend sudah diupdate untuk menyimpan field `altitude` yang dikirimkan mobile.  
Kolom `altitude` sudah ditambahkan ke tabel `field_tests` (nullable, decimal).

**Format request `POST /api/mobile/testing/location`:**
```json
{
  "latitude": -6.967585,
  "longitude": 107.659063,
  "altitude": 768.5,
  "suhu_air": 28.5,
  "suhu_lingkungan": 30.0,
  "kelembapan": 75.0,
  "ec": 450.0,
  "tds": 300.0,
  "ph": 7.5,
  "tegangan": 3.8
}
```

**Tidak ada perubahan yang perlu dilakukan di mobile untuk fitur ini.**
