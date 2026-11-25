# Știri și favorite

A Romanian Flutter news reader for Android, iPhone and the browser. The shared Dart code lives in `lib/`; native integration lives in `android/` and `ios/`.

## People and tasks

People read technology news on their phones in short sessions, save stories locally, read an extractive summary, open the original source, and export saved stories into a calendar. The interface must work with large text, modest connectivity, the phone's theme and reduced motion. The owner also needs to understand and reproduce the implementation, builds and updates; explain changes in the Romanian guides under `docs/`.

## Product truth

- News and details come from the Hacker News Algolia API over HTTPS. No app backend or API key is required.
- Jina Reader retrieves public article text; local code selects summary sentences. This is not generative AI or automatic translation.
- Favorites and the last news list persist locally. They do not synchronize between devices or with the browser.
- Native calendar export uses `device_calendar`, asks for permissions, selects a writable calendar and checks for duplicate events. Browser export downloads `.ics`.
- The selected calendar date determines the required weekday time slot. Article publication time is separate metadata.
- Existing loading, retry, error and partial-export behaviors must remain functional during visual changes.

## Binding design requirements

Follow system brightness automatically. Light mode is blue and white; dark mode is charcoal and white. Keep large labeled controls, Romanian copy, readable article typography and a smooth article-opening transition. Preserve native back behavior and accessibility motion preferences. Use native Flutter motion rather than a browser scrolling library.

## Shipping constraints

The working machine is Windows. Android release builds need Android SDK and the existing private signing key. iOS builds need macOS/Xcode and the owner's Apple team. A web build is not evidence of native calendar or 120 Hz performance. Do not call unsigned iOS output installable or claim a native build succeeded without actually compiling it.

Current version: `1.1.0+2`. See `docs/INSTALARE-TELEFON.md` for the exact status and commands; see `DESIGN.md` for tokens and motion.
