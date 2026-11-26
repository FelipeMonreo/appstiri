# Design și animații

Referință tehnică pentru Știri UNITBV, versiunea `1.1.0+2`.

Aplicația păstrează știrile, favoritele, rezumatele și exportul în calendar. Interfața a fost refăcută pentru a urmări tema telefonului, pentru lectură și pentru butoane ușor de înțeles. Nu trebuie rescrisă separat pentru Android și iPhone: cele două folosesc aceleași ecrane Dart.

## 1. De unde schimbi aspectul

| Fișier | Ce controlează |
| --- | --- |
| `lib/theme/app_theme.dart` | Culorile celor două teme, fonturile, dimensiunile de bază, butoanele și stilul dialogurilor. |
| `lib/app.dart` | Configurează `ThemeMode.system`, limba interfeței și succesiunea animației de pornire. |
| `lib/screens/news_screen.dart` | Știri, Favorite, sigla și selectorul de limbă din antet, plus navigarea adaptată la lățime. |
| `lib/widgets/article_card.dart` | Cardul comun pentru ambele liste, cu toate metadatele și acțiunile articolului. |
| `lib/screens/details_screen.dart` | Panoul de lectură cu fundal estompat, rezumat și acces la articolul complet. |
| `lib/screens/export_dialog.dart` | Alegerea datei/calendarului și comenzile mari de export/anulare. |
| `lib/widgets/reader_components.dart` | Barele de sticlă mată, navigarea mobilă, animația de refresh și componentele comune. |
| `assets/fonts/`, `pubspec.yaml` | Fonturile UT Sans Regular, Medium și Bold declarate în Flutter. |

Tema deschisă folosește albastru pe suprafețe deschise. Tema închisă folosește portocaliu pe suprafețe aproape negre. Telefonul alege automat varianta prin setările sale; aplicația se adaptează și când schimbi tema în timpul utilizării.

Un widget folosește de exemplu `Theme.of(context).colorScheme.primary`, nu o culoare copiată în fiecare buton. Astfel, când se schimbă tema, toate componentele primesc culori compatibile. Paleta completă și motivele alegerilor sunt în [DESIGN.md](../DESIGN.md).

## 2. Ce se întâmplă când deschizi o știre

1. Apăsarea titlului apelează `_details()` din `news_screen.dart`.
2. Navigatorul deschide un panou `ArticleRoute` la aproximativ 70% din înălțimea ecranului. Intrarea durează 460 ms, iar închiderea durează 280 ms.
3. `ArticleHeadline` are același identificator Hero în listă și în ecranul de lectură. Flutter poate lega vizual cele două poziții ale titlului.
4. Panoul păstrează focusul în interior și poate fi închis cu butonul Înapoi sau prin atingerea fundalului.
5. Ecranul afișează imediat datele deja disponibile. Cererile pentru detalii și rezumat încep după terminarea tranziției reale.
6. Rezumatul înlocuiește starea de încărcare printr-o tranziție scurtă. Butonul **Citește articolul complet** rămâne vizibil jos în timpul lecturii.

Există un detaliu tehnic testat: Hero măsoară temporar pagina ca și cum animația ar fi terminată. De aceea folosim animația controllerului real al rutei pentru a decide când pornim cererile. Altfel, cererile puteau începe încă din timpul tranziției, deși codul părea să aștepte.

## 3. Ce înseamnă 60, 90 sau 120 Hz

Hz este frecvența cu care ecranul se poate actualiza. FPS este numărul de cadre pe care aplicația reușește să le livreze. Un telefon cu ecran de 120 Hz nu garantează că fiecare aplicație produce 120 de cadre în fiecare secundă.

Animațiile folosesc [tickerul Flutter, apelat la fiecare cadru](https://api.flutter.dev/flutter/scheduler/Ticker-class.html), fără un temporizator fix la 60 FPS. Pe Android, `MainActivity.kt` cere cel mai rapid mod disponibil la rezoluția curentă. Sistemul poate limita cererea din cauza economisirii bateriei, temperaturii sau setărilor utilizatorului; este o preferință a ferestrei, nu ocolirea politicilor telefonului. Vezi [preferința Android pentru modul ecranului](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#preferredDisplayModeId).

Pe iPhone este păstrat `CADisableMinimumFrameDurationOnPhone=true` în `Info.plist`, pentru a permite frecvențele mari pe dispozitive compatibile. Telefoanele de 60 Hz rămân la capacitățile lor. Modul de consum redus și limitarea frecvenței din sistem rămân în controlul telefonului.

Verificarea reală se face pe telefon, în modul **profile**, după [ghidul Flutter pentru performanță](https://docs.flutter.dev/perf/ui-performance). Pentru Android poți folosi:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-android.ps1 -Mode profile -DeviceId ID_TELEFON
```

Înlocuiești `ID_TELEFON` cu valoarea din `flutter devices`. În DevTools → Performance înregistrezi deschiderea unui articol și derularea. Bugetul aproximativ al unui cadru este 16,7 ms la 60 Hz, 11,1 ms la 90 Hz și 8,3 ms la 120 Hz. Verifici atât lucrul interfeței, cât și randarea. Măsurătorile din browserul calculatorului nu înlocuiesc acest test.

Când există cheia proprie a proiectului, și buildul Android **profile** folosește aceeași semnătură ca release. Astfel poate actualiza instalarea aceleiași aplicații fără să ceară dezinstalarea și pierderea datelor locale. Pentru distribuirea finală generezi din nou APK-ul **release**; configurația nativă trebuie verificată la prima compilare Android.

## 4. Accesibilitate și text mare

Butoanele principale au o înălțime minimă de 56 de pixeli logici. Cardurile mută activitatea și acțiunile sub titlu pe ecrane înguste. Textul important poate trece pe mai multe rânduri, iar dimensiunea fontului urmează setările telefonului.

Au fost verificate ecrane de 320 de pixeli logici la 200% text, inclusiv titluri lungi și exportul în calendar. Metadatele se pot împărți pe rânduri, iar titlul și conținutul dialogului pot derula împreună. Câmpurile cardului se pot împărți pe mai multe rânduri.

Android **Remove animations** și iOS **Reduce Motion** sunt preferințe distincte în această versiune Flutter. Codul le verifică pe ambele. Dacă una este activă, tranzițiile proprii folosesc durată zero și animația Hero este dezactivată. Nu limităm global mărimea textului pentru a ascunde probleme de aspect.

Testele de contrast verifică perechile semantice de text și fundal la minimum 4,5:1. VoiceOver, TalkBack și conformitatea completă WCAG necesită verificări separate.

## 5. Pornire, feedback și verificare vizuală

Intro-ul din `lib/app.dart` durează aproximativ 5,54 secunde. Pătratul alb apare primul, liniile intră și formează sigla, iar aceasta se luminează pe segmente. Sigla se micșorează în poziția din antet. După 80 ms cardurile intră din stânga, decalat, și titlul se scrie în același timp. Pe Android, animația Dart așteaptă primul cadru rasterizat.

Bara mobilă este lipită de marginea de jos. Indicatorul glisează în 280 ms între Știri și Favorite. Pictograma refresh face o rotație în 850 ms cât timp cererea este activă. La salvarea unei favorite, semnul de carte pulsează discret timp de 240 ms. Setarea de reducere a mișcării dezactivează aceste animații.

Testele din `test/reader_design_test.dart` acoperă contrastul, textul mărit, intro-ul, rotația refresh și tranziția articolului. [Rezultatele predării](../README.md#testare) sunt centralizate în README. Pentru instalare și verificări pe dispozitive, urmează [ghidul tehnic](INSTALARE-TELEFON.md).

## 6. Cum faci singur o schimbare mică

Pentru a schimba albastrul, modifici `AppTheme.brand` din `lib/theme/app_theme.dart`. Pentru titlul paginii principale, vezi apelul `ReaderHeaderTitle` din `news_screen.dart`. Pentru durata deschiderii, modifici `ArticleRoute.transitionDuration` din `details_screen.dart` și verifici din nou comportamentul cu reducerea mișcării activată.

După o modificare rulezi `flutter analyze` și `flutter test`, apoi compilezi din nou platforma dorită. O schimbare în cod nu ajunge singură în aplicația instalată. Pentru o distribuire nouă crești versiunea și numărul buildului în `pubspec.yaml` și păstrezi aceeași cheie Android și același identificator de aplicație.
