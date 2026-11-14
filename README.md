# Al-Qur'an — Flutter

Aplikasi Al-Qur'an berbahasa Indonesia dengan dua mode baca (ayat per ayat dan
mushaf per halaman), dua gaya mushaf (Madinah dan Standar Indonesia/Kemenag),
audio murottal per ayat, serta penanda ayat berkategori warna yang tersimpan
offline.

## Fitur

- **Mode ayat per ayat** — teks Arab rasm sesuai gaya mushaf yang dipilih,
  terjemahan Indonesia di bawah setiap ayat, slider ukuran teks, pemutar audio,
  dan tombol penanda pada setiap ayat.
- **Mode mushaf per halaman** — `PageView` horizontal untuk 604 halaman, tata
  letak bergaya lembar mushaf, nomor halaman Arab, juz, dan nama surah. Tersedia
  pemenggalan halaman **Mushaf Madinah** dan **Mushaf Standar Indonesia
  (Kemenag)**.
- **Penanda warna** — kategori merah, hijau, kuning, dan biru. Penanda disimpan
  di Hive, ditampilkan berkelompok per warna, dapat difilter, dihapus dengan
  geser, dan dikembalikan lewat *Urungkan*. Mengetuk penanda membuka surah tepat
  pada ayat tersebut.
- **Offline-first** — daftar surah dan teks surah disimpan di Hive. Indeks
  halaman mushaf dibundel sebagai asset sehingga pemetaan halaman selalu
  tersedia tanpa jaringan.
- **Dukungan audio** — audio murottal per ayat dari equran.id.

## Arsitektur

Proyek ini memisahkan lapisan `domain`, `data`, dan `presentation`, dengan
Riverpod sebagai penghubung dan Hive sebagai penyimpanan lokal.

```text
lib/
├── app.dart
├── main.dart
├── core/
│   ├── constants/          # endpoint, nama box Hive, path asset, TTL cache
│   ├── error/              # Failure yang ramah pengguna
│   ├── network/            # ApiClient JSON + timeout + pemetaan error
│   ├── theme/              # tema Material 3 + palet warna penanda
│   └── utils/              # strip HTML, angka Arab, format tanggal
├── domain/
│   ├── entities/           # Ayah, Surah, MushafStyle, MushafPageIndex, Bookmark
│   ├── repositories/       # kontrak repository
│   └── usecases/           # GetSurahs, GetSurahDetail, GetMushafPage, CRUD bookmark
├── data/
│   ├── datasources/        # quran remote/local, bookmark local
│   ├── models/             # model JSON + TypeAdapter Hive buatan tangan
│   └── repositories/       # implementasi kontrak, cache, fallback stale
└── presentation/
    ├── pages/              # shell, daftar surah, reader ayat, mushaf, penanda, setelan
    ├── providers/          # koneksi Riverpod untuk repository, bookmark, audio
    └── widgets/            # tile ayat, sheet warna, sheet font/gaya, halaman mushaf
```

### Alur data

1. `QuranRemoteDataSource` mengambil daftar surah, detail surah, dan teks
   Uthmani dari equran.id serta quran.com melalui `ApiClient`.
2. `QuranRepositoryImpl` menggabungkan teks Kemenag dengan teks Uthmani,
   menyimpannya ke `QuranLocalDataSource` (Hive), dan menyediakan fallback ke
   cache lama bila jaringan gagal.
3. `MushafRepositoryImpl` membaca `assets/data/mushaf_page_index.json`,
   menentukan rentang ayat satu halaman, lalu meminta detail surah yang
   diperlukan dari repository yang sama.
4. Provider Riverpod mengekspos hasilnya sebagai `AsyncValue`; UI hanya
   berinteraksi dengan provider dan use case.

### Penanda ayat

`Bookmark` berisi `id`, `surahName`, `surahNumber`, `verseNumber`,
`arabicText`, `translation`, `color`, dan `timestamp`. Model Hive ditulis
sebagai `BookmarkModel` dengan adapter versi manual, sehingga tidak perlu
menjalankan `build_runner`. Satu ayat memiliki satu penanda; memilih warna baru
pada ayat yang sama akan memperbarui penanda lama.

## Sumber data & kredit

- Teks Arab (Kemenag), terjemahan Indonesia, dan audio per ayat:
  [equran.id API v2](https://equran.id/apidev/v2).
- Teks Uthmani Madinah:
  [Quran.com API v4](https://api-docs.quran.com/).
- Pemetaan halaman Madinah: [Al Quran Cloud](https://alquran.cloud/api)
  (`/v1/meta`, 604 halaman) dipadukan dengan nomor juz standar.
- Pemetaan halaman Mushaf Standar Indonesia: data per ayat Kemenag dari
  [quran-json-kemenag](https://github.com/dyazincahya/quran-json-kemenag).
- Font: [Amiri Quran](https://github.com/aliftype/amiri) dan
  [Scheherazade New](https://software.sil.org/scheherazade/), keduanya di bawah
  SIL Open Font License. Berkas lisensi ada di `assets/fonts/`.

Indeks halaman dibundel dalam bentuk yang ringkas: hanya ayat pertama dari
setiap halaman, dilengkapi nomor juz. Repositori ini tidak menyertakan berkas
audio atau terjemahan; semuanya diambil dari API di atas.

## Menjalankan

```bash
flutter pub get
flutter run
```

Pemeriksaan statis dan pengujian:

```bash
flutter analyze
flutter test
```

## Catatan

- Pemenggalan halaman mengikuti masing-masing mushaf, sehingga nomor halaman
  untuk ayat yang sama dapat berbeda antara gaya Madinah dan Kemenag.
- Teks Madinah bersifat opsional: bila quran.com tidak dapat dihubungi, aplikasi
  tetap menampilkan teks Kemenag dengan font gaya yang dipilih.
- Koneksi internet diperlukan saat pertama kali membuka surah atau halaman.
  Setelah itu teks tersedia dari cache Hive.
