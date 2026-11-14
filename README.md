<p align="center">
  <img src="assets/icon/icon.png" width="112" alt="Al-Qur'an app icon">
</p>

<h1 align="center">Al-Qur'an</h1>

<p align="center">
  A calm, offline-first Qur'an reader for Indonesian readers — with Arabic text,
  Indonesian translation, Madinah and Kemenag mushaf layouts, per-ayah audio,
  colour-coded bookmarks, and a light/dark theme.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white">
  <img alt="Riverpod" src="https://img.shields.io/badge/State-Riverpod-0F5B4E">
  <img alt="Hive" src="https://img.shields.io/badge/Storage-Hive-C9A227">
</p>

---

## Screenshots

<table>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/home-light.png" alt="Surah list, light mode" width="300"><br>
      <strong>Light mode</strong>
    </td>
    <td width="50%" align="center">
      <img src="docs/screenshots/home-dark.png" alt="Surah list, dark mode" width="300"><br>
      <strong>Dark mode</strong>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/reader-light.png" alt="Ayah-by-ayah reader" width="300"><br>
      <strong>Ayah-by-ayah reading</strong>
    </td>
    <td width="50%" align="center">
      <img src="docs/screenshots/mushaf-light.png" alt="Mushaf page reader" width="300"><br>
      <strong>Mushaf page reading</strong>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/settings-light.png" alt="Settings, light mode" width="300"><br>
      <strong>Settings &amp; theme picker</strong>
    </td>
    <td width="50%" align="center">
      <img src="docs/screenshots/settings-dark.png" alt="Settings, dark mode" width="300"><br>
      <strong>Theme picker in dark mode</strong>
    </td>
  </tr>
</table>

## Key Features

### Reading experience
- **Ayah-by-ayah mode** — Arabic text, Indonesian translation underneath each
  verse, adjustable Arabic font size, per-ayah audio, and a bookmark action on
  every verse.
- **Page-by-page mushaf** — a horizontal `PageView` across 604 pages, complete
  with juz markers, surah headings, basmalah, ayah-end ornaments, and Arabic
  page numbers.
- **Two authentic mushaf layouts** — Madinah (Uthmani text) and Mushaf Standar
  Indonesia/Kemenag, each with its own page breaks and Arabic script style.
- **Arabic typography** — bundled Amiri Quran and Scheherazade New fonts. The
  font size slider applies to the ayah reader and is persisted.

### Bookmarks
- Save any ayah with one of four colour categories: **red, green, yellow, or
  blue**.
- Bookmarks are grouped by colour, filterable, sortable by recency, and can be
  removed by swipe with an undo action.
- Tapping a bookmark opens its surah and scrolls directly to the saved ayah,
  highlighting it on arrival.
- Bookmarks are stored locally in Hive, so they survive app restarts and work
  without a connection.

### Light & Dark Mode
- Three theme preferences: **Terang**, **Gelap**, and **Sistem** (follow the
  device).
- A quick sun/moon toggle in the surah list app bar and a segmented control in
  **Pengaturan → Tema**.
- Selection is persisted in Hive and restored on startup; theme changes animate
  smoothly.
- Every screen uses the app's custom `ThemeData`/`ColorScheme` for backgrounds,
  cards, text, icons, dividers, sheets, and navigation. The mushaf page has a
  dedicated parchment palette for each brightness.

### Data & offline support
- Quran text, Indonesian translation, and audio URLs from **equran.id**.
- Madinah/Uthmani text enrichment from **Quran.com**.
- Surah lists and details are cached in Hive with TTL and stale-cache fallback.
- Mushaf page boundaries are bundled as an asset, so page navigation and juz
  metadata are available offline.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.47+ / Dart 3.13+ |
| State management | Riverpod 3 (`Notifier`, `AsyncNotifier`, `FutureProvider.family`) |
| Local storage | Hive 2 + hand-written `BookmarkModel` `TypeAdapter` |
| Networking | `http` with a small `ApiClient` error-mapping layer |
| Audio | `just_audio` (murottal per ayah) |
| Long lists | `scrollable_positioned_list` for jump-to-ayah scrolling |
| App icon | `flutter_launcher_icons` 0.14.4 |
| Splash screen | `flutter_native_splash` 2.4.8 |
| Lints | `flutter_lints` |

## Architecture

The code follows a three-layer clean architecture, with Riverpod as the
dependency/state bridge:

```text
lib/
├── main.dart                  # Hive bootstrap + ProviderScope
├── app.dart                   # MaterialApp + persisted themeMode
├── core/
│   ├── constants/             # endpoints, Hive names, assets, TTL
│   ├── error/                 # user-facing Failure type
│   ├── network/               # JSON ApiClient with timeout handling
│   ├── theme/                 # custom light/dark ThemeData + bookmark palette
│   └── utils/                 # Arabic digits, HTML stripping, dates
├── domain/
│   ├── entities/              # Ayah, Surah, Mushaf*, Bookmark, AppSettings
│   ├── repositories/          # repository contracts
│   └── usecases/              # GetSurahs, GetMushafPage, bookmark use cases
├── data/
│   ├── datasources/           # remote + Hive cache + bookmark box
│   ├── models/                # API/JSON models and Hive adapter
│   └── repositories/          # cache-first implementations with fallback
└── presentation/
    ├── pages/                 # shell, surah list, reader, mushaf, bookmarks, settings
    ├── providers/             # Riverpod providers, settings, audio
    └── widgets/               # ayah tile, colour sheet, mushaf page, pickers
```

**Theme flow:** `SettingsNotifier` exposes `AppSettings`, including
`AppThemeMode`. `QuranApp` watches only the theme preference with
`select`, maps it to Flutter's `ThemeMode`, and rebuilds `MaterialApp` when it
changes. `SettingsRepositoryImpl` writes the choice to the `settings` Hive box
under `theme_mode`.

## App Icon & Splash Screen

Both generators are configured in `pubspec.yaml`; the artwork lives in
`assets/icon/`.

| Asset | Purpose |
| --- | --- |
| `assets/icon/icon.png` | 1024 × 1024 master icon: open book and star in gold on emerald |
| `assets/icon/icon_foreground.png` | Transparent foreground for Android adaptive icons |
| `assets/icon/splash_icon.png` | Centred native splash mark for Android ≤ 11 and iOS |
| `assets/icon/splash_icon_android12.png` | Android 12+ splash glyph on the system icon background |

### Icon configuration

- Android adaptive background: `#0F5B4E`
- Source image: `assets/icon/icon.png`
- iOS alpha channel removed automatically
- Web, macOS, and Windows icons generated from the same master

### Splash configuration

- Light background: `#FFFBF1` (app light surface)
- Dark background: `#16201C` (app dark surface)
- Centred icon only, no branding text
- `image_dark` enables the dark-mode splash
- Android 12 uses the dedicated glyph and `#0F5B4E` icon background

### Generate the native assets

Run these from the project root after changing the icon or splash artwork:

```bash
# Launcher icons for Android, iOS, web, macOS, and Windows
dart run flutter_launcher_icons

# Native splash screens for Android, iOS, and web (light + dark)
dart run flutter_native_splash:create
```

Optional: remove generated splash files again with:

```bash
dart run flutter_native_splash:remove
```

> The web splash uses the `flutter-first-frame` event in `web/index.html` to
> remove itself after Flutter renders. Keep that listener if you regenerate the
> web splash.

## Setup & Installation

### Prerequisites

- Flutter 3.47 or newer, with a configured Android/iOS toolchain
- Dart 3.13 or newer (bundled with Flutter)
- Internet access on first launch for surah text and audio

### Run locally

```bash
git clone <your-repository-url>
cd my_quran

flutter pub get

# Generate launcher icons and splash screens
dart run flutter_launcher_icons
dart run flutter_native_splash:create

flutter run
```

For a release web build:

```bash
flutter build web --release
```

### Quality checks

```bash
flutter analyze
flutter test
```

The test suite covers page-index resolution, both bundled 604-page mushaf
indexes, Hive bookmark persistence, settings/theme persistence, and mushaf page
rendering.

## Data Sources & Credits

- **Text, translation, and per-ayah audio** — [equran.id API v2](https://equran.id/apidev/v2)
- **Madinah Uthmani text** — [Quran.com API v4](https://api-docs.quran.com/)
- **Madinah page metadata** — [Al Quran Cloud](https://alquran.cloud/api)
- **Kemenag page index** — [quran-json-kemenag](https://github.com/dyazincahya/quran-json-kemenag)
- **Arabic fonts** — [Amiri Quran](https://github.com/aliftype/amiri) and
  [Scheherazade New](https://software.sil.org/scheherazade/), both licensed under
  the SIL Open Font License. Licence files are in `assets/fonts/`.

## Notes & Limitations

- Page numbers differ between the two mushaf styles for the same verse because
  their page boundaries differ; this is intentional.
- A network connection is required for the first load of a surah or page.
  Subsequent reads use the Hive cache.
- If Quran.com is unavailable, the Madinah option falls back to Kemenag Arabic
  text while keeping the selected typography.
- Audio playback depends on the platform's network/audio support; web playback
  may be subject to the CDN's CORS policy.
- Screenshots in this README were captured from the running app (Chrome, mobile
  viewport) in light and dark system themes.
