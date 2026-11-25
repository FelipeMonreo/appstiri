# Designul nou: ce s-a schimbat, unde și de ce

Actualizare din 23 noiembrie 2026, versiunea `1.1.0+2`.

Aplicația păstrează știrile, favoritele, rezumatele și exportul în calendar. Interfața a fost refăcută pentru a urmări tema telefonului, pentru lectură și pentru butoane ușor de înțeles. Nu trebuie rescrisă separat pentru Android și iPhone: cele două folosesc aceleași ecrane Dart.

## 1. De unde schimbi aspectul

| Fișier | Ce controlează |
| --- | --- |
| `lib/theme/app_theme.dart` | Culorile celor două teme, fonturile, dimensiunile de bază, butoanele și stilul dialogurilor. |
| `lib/app.dart` | Activează `ThemeMode.system`, tema deschisă și tema închisă. |
| `lib/screens/news_screen.dart` | Pagina de știri, biblioteca de favorite, antetul și navigarea de jos. |
| `lib/widgets/article_card.dart` | Prima știre evidențiată, celelalte știri, metadatele și acțiunile fiecărui articol. |
| `lib/screens/details_screen.dart` | Ecranul de lectură, rezumatul, tranziția și butonul fix pentru articolul complet. |
| `lib/screens/export_dialog.dart` | Alegerea datei/calendarului și comenzile mari de export/anulare. |
| `lib/widgets/reader_components.dart` | Mesajele de eroare, starea fără știri și funcțiile care respectă reducerea animațiilor. |
| `assets/fonts/`, `pubspec.yaml` | Fișierele locale Bitter și Manrope, licențele lor și declararea lor în Flutter. |

Tema deschisă folosește albastru cu alb. Tema închisă folosește gri închis cu alb. Telefonul alege automat varianta prin setările sale; aplicația se adaptează și când schimbi tema în timpul utilizării.

Un widget folosește de exemplu `Theme.of(context).colorScheme.primary`, nu o culoare copiată în fiecare buton. Astfel, când se schimbă tema, toate componentele primesc culori compatibile. Paleta completă și motivele alegerilor sunt în [DESIGN.md](../DESIGN.md).

## 2. Ce se întâmplă când deschizi o știre

1. Butonul **Detalii** apelează `_details()` din `news_screen.dart`.
2. Navigatorul deschide un `ArticleRoute`. Durata normală de intrare este 360 ms; revenirea folosește 280 ms.
3. `ArticleHeadline` are același identificator Hero în listă și în ecranul de lectură. Flutter poate lega vizual cele două poziții ale titlului.
4. Ruta păstrează tranzițiile platformei, inclusiv revenirea specifică iPhone și predictive back pe Android.
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

Butoanele principale au o înălțime minimă de 56 de pixeli logici. Pe ecrane înguste se așază vertical. Textul important poate trece pe mai multe rânduri, iar dimensiunea fontului urmează setările telefonului.

Au fost verificate ecrane de 320 de pixeli logici la 200% text, inclusiv titluri lungi și exportul în calendar. Metadatele se pot împărți pe rânduri, iar titlul și conținutul dialogului pot derula împreună. Data decorativă din bara de sus poate fi ascunsă când nu mai are spațiu.

Android **Remove animations** și iOS **Reduce Motion** sunt preferințe distincte în această versiune Flutter. Codul le verifică pe ambele. Dacă una este activă, tranzițiile proprii folosesc durată zero și animația Hero este dezactivată. Nu limităm global mărimea textului pentru a ascunde probleme de aspect.

Testele de contrast verifică perechile semantice de text și fundal la minimum 4,5:1. Verificarea arborelui de accesibilitate din browser confirmă prezența titlurilor și a comenzilor. Aceste verificări nu înseamnă că am testat deja VoiceOver sau TalkBack pe telefon și nici că am făcut un audit WCAG complet.

## 5. Ce s-a verificat și ce urmează

Verificate: analiza statică fără probleme, **62 de teste trecute** și compilarea **web release**. Testele noi sunt în `test/reader_design_test.dart`; testele fluxurilor existente au fost adaptate să deruleze până la controale înainte de apăsare.

Capturile din `distributie/previews/` sunt făcute din aplicația compilată, cu răspunsuri API simulate pentru un rezultat repetabil. Articolele de demonstrație nu au fost adăugate în aplicația distribuită. Codul de producție continuă să ceară știrile reale din API.

Compilarea Android necesită în continuare SDK-ul Android, iar compilarea iOS necesită Mac/Xcode și semnarea cu contul Apple. Uneltele Android nu au putut fi descărcate de agent în acest mediu. Pe calculator a fost folosită o copie Flutter locală, ignorată în `.tooling/`, pentru analiză, teste și web, fără modificarea instalării tale principale. Arhiva pentru Mac nu include acea copie, cache-urile sau cheile private Android.

Pentru APK rulezi `Configureaza-Android.cmd`, apoi `Genereaza-Android.cmd` din contul Windows obișnuit. Pentru Mac folosești `Pregateste-pentru-Mac.cmd`. Procedurile complete sunt în [INSTALARE-TELEFON.md](INSTALARE-TELEFON.md).

## 6. Cum faci singur o schimbare mică

Pentru a schimba albastrul, modifici `AppTheme.blue` din `lib/theme/app_theme.dart`. Pentru titlul paginii principale, cauți textul în `_ReaderHeader` din `news_screen.dart`. Pentru durata deschiderii, modifici `ArticleRoute.transitionDuration` din `details_screen.dart` și verifici din nou comportamentul cu reducerea mișcării activată.

După o modificare rulezi `flutter analyze` și `flutter test`, apoi compilezi din nou platforma dorită. O schimbare în cod nu ajunge singură în aplicația instalată. Pentru o distribuire nouă crești versiunea și numărul buildului în `pubspec.yaml` și păstrezi aceeași cheie Android și același identificator de aplicație.
