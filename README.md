# Știri UNITBV

Aplicație Flutter realizată pentru taskul TSG 2026, versiunea `1.1.0+2`. Interfața folosește sigla UNITBV și fontul local UT Sans. Tema urmează setarea sistemului, cu accent albastru în modul deschis și portocaliu în modul întunecat. Butonul RO/EN schimbă limba interfeței pentru sesiunea curentă.

## Funcționalități

- **Știri** din Hacker News Algolia. Cardurile afișează titlul, autorul, data publicării, punctele și comentariile. Articolul original se poate deschide direct din Știri sau Favorite.
- **Detalii și rezumat** într-un panou de lectură. Rezumatul este extractiv, realizat local din textul disponibil prin Jina Reader sau din textul postării Hacker News. Păstrează limba sursei.
- **Favorite persistente** prin `shared_preferences`, cu o pagină separată pentru consultare și ștergere. Ultima listă încărcată este disponibilă offline.
- **Export în calendar** prin `device_calendar` pe Android și iOS, cu permisiuni, selector de calendar și confirmarea rezultatului. În browser, exportul descarcă un fișier `.ics`. Evenimentul include titlul, autorul, linkul și data publicării.

Ziua aleasă în dialog stabilește intervalul evenimentelor.

| Zi | Interval |
| --- | --- |
| Luni, miercuri, vineri | 14:00–20:00 |
| Marți, joi | 12:00–18:00 |
| Sâmbătă, duminică | 08:00–12:00 |

## Arhitectură

| Director | Rol |
| --- | --- |
| `lib/models/` | Modelele pentru știri și rezumate |
| `lib/controllers/` | Starea aplicației și coordonarea încărcării și a favoritelor |
| `lib/services/` | API, stocare locală, rezumare și export pe platforme |
| `lib/screens/`, `lib/widgets/`, `lib/theme/` | Interfață, componente reutilizabile și temă |
| `test/` | Teste de unitate și de widget |

Aplicația folosește endpointurile HTTPS `/api/v1/search?tags=front_page` și `/api/v1/items/:id` de pe `hn.algolia.com`. Apelurile se fac către serviciile publice, fără backend propriu sau configurarea unei chei API.

## Instalare și rulare

Folosește Flutter 3.50.1 cu Dart 3.14. Comenzile se rulează din rădăcina proiectului.

```sh
flutter pub get
flutter run -d chrome
```

- **Android** · Pornește un emulator din Android Studio sau conectează un telefon, rulează `flutter devices`, apoi `flutter run -d ID_DISPOZITIV`. Scripturile `Configureaza-Android.cmd` și `Genereaza-Android.cmd` pregătesc SDK-ul local și APK-ul semnat.
- **iOS** · Pentru aplicația nativă ai nevoie de macOS, Xcode și semnare Apple. Pe Windows poți folosi `Porneste-iPhone.cmd` după buildul web, cu Python instalat și iPhone-ul pe aceeași rețea locală. Varianta din Safari oferă export `.ics`.

Pașii pentru SDK, semnare, instalare și testare pe telefon sunt în [ghidul de instalare](docs/INSTALARE-TELEFON.md).

## Testare

```sh
flutter analyze
flutter test
flutter build web
```

| Comandă | Rezultat la predare |
| --- | --- |
| `flutter analyze` | Fără probleme |
| `flutter test` | 67 din 67 de teste trecute |
| `flutter build web` | Compilare reușită în `build/web/` |

În această rundă am rulat analiza, testele automate și buildul web pe Windows. Testele de calendar nativ simulează canalul pluginului. Aplicațiile native Android și iOS, permisiunile și salvarea directă în calendar, VoiceOver/TalkBack și fluiditatea la 90/120 Hz rămân neverificate pe telefoane fizice. Un build Android de debug a fost pornit anterior în emulator.

## Documentație

- [Cum funcționează aplicația](docs/CUM-FUNCTIONEAZA.md)
- [Design, animații și accesibilitate](docs/DESIGN-SI-ANIMATII.md)
- [Sistemul vizual](DESIGN.md)
