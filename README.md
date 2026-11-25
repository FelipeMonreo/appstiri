# Știri și favorite

Aplicație Flutter pentru cerințele din Task-2026.pdf. Interfața este în română, cu butoane mari și două pagini: toate știrile și favorite. Nu necesită backend propriu sau cheie API.

## Interfața din versiunea 1.1.0+2

Tema urmează telefonul: albastru/alb în light mode, gri închis/alb în dark mode. Fonturile Bitter și Manrope sunt incluse local. Titlul știrii are o tranziție Hero către ecranul de lectură; cererile de detalii și rezumat așteaptă terminarea tranziției. Butonul articolului complet rămâne vizibil jos. Sunt respectate atât Remove animations pe Android, cât și Reduce Motion pe iOS.

Explicațiile modificărilor, ale frecvenței de randare și ale testelor sunt în [Design și animații](docs/DESIGN-SI-ANIMATII.md). [DESIGN.md](DESIGN.md) documentează sistemul vizual și folosirea resurselor solicitate. Validare: **62 de teste**, analiză fără probleme și build web release reușit; compilările native și măsurarea pe ecrane de 90/120 Hz rămân de executat pe dispozitive.

## Instalarea ca aplicație pe telefon

Pașii compleți și starea verificărilor sunt în [ghidul Android/iPhone](docs/INSTALARE-TELEFON.md). Pentru explicația codului și a modificărilor, vezi [cum funcționează proiectul](docs/CUM-FUNCTIONEAZA.md).

Pe Windows: `Configureaza-Android.cmd` instalează SDK-ul local, apoi `Genereaza-Android.cmd` rulează analiza/testele și generează APK-ul semnat în `distributie/android/`. Prima compilare necesită acces la internet și acceptarea licențelor SDK. `Pregateste-pentru-Mac.cmd` creează arhiva surselor pentru iOS; pe Mac, după instalarea Flutter/Xcode/CocoaPods, rulezi `bash scripts/prepare-ios.sh` și configurezi contul Apple în Xcode.

Pregătirea pentru instalare nu înseamnă că buildurile native au fost deja verificate: APK-ul și versiunea iOS rămân de compilat și testat pe dispozitive. Modificările făcute în cod nu actualizează automat aplicațiile instalate; trebuie construită și distribuită o versiune nouă.

## Pornire pe localhost

Din folderul proiectului:

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173
```

Deschide **http://localhost:5173** în browser și păstrează terminalul deschis. Comanda `r` face hot reload, `R` hot restart, `q` oprește aplicația. Dacă folosești serverul static descris mai jos, trebuie recompilat după modificări.

Poți folosi și:

```powershell
.\scripts\run-local.ps1
```

Dacă politica PowerShell blochează scripturile, folosește comenzile Flutter de mai sus. Configurația VS Code „Localhost :5173” este inclusă în `.vscode/launch.json` și necesită extensia Dart/Flutter.

Favoritele sunt salvate local, în profilul browserului. Folosește aceeași adresă și același port: `localhost` și `127.0.0.1` sunt origini diferite și au favorite separate. Navigarea privată sau ștergerea datelor browserului poate elimina favoritele. Favoritele de pe telefon sunt independente de cele din browser.

## Ce poți verifica

1. Actualizează lista și verifică titlul, autorul, publicarea, punctele și comentariile.
2. Adaugă știri la favorite. Deschide pagina Favorite, apoi reîncarcă aplicația: favoritele trebuie să rămână.
3. Deschide Detalii: sunt solicitate datele actuale din API și este pregătit un rezumat al articolului. La final apare butonul „Citește articolul complet”. Dacă o sursă nu poate fi citită, apare un mesaj cu reîncercare, iar articolul original rămâne accesibil.
4. Deschide articolul: se deschide în browser extern pe telefon și într-o filă nouă în browser. Articolele fără URL valid folosesc pagina lor Hacker News.
5. Exportă favoritele în calendar și alege data evenimentelor.
6. Șterge o favorită: dispare din lista de favorite și modificarea se păstrează la repornire.

La erori de rețea există reîncercare. Ultima listă încărcată este păstrată local pentru afișare fără internet, dacă aplicația a fost deja încărcată. Prima deschidere și articolele externe au nevoie de internet. O eroare de salvare a favoritelor este afișată, iar interfața nu pretinde că salvarea a reușit.

## Rezumatul articolelor

Pagina Detalii încarcă textul paginii originale prin [Jina Reader](https://docs.jina.ai/api.md), apoi aplicația selectează local până la patru propoziții relevante, în ordinea din articol, cu un buget de 140 de cuvinte. Rezumatul păstrează limba sursei. Este un rezumat extractiv, fără model generativ sau traducere automată.

Pentru articolele externe, URL-ul public este trimis serviciului Reader. Nu se trimit cookie-urile browserului, favoritele sau datele calendarului. Funcția nu necesită o cheie API în aplicație; accesul fără cheie are limite impuse de serviciu. Citirea este inițiată când deschizi detaliile. Pentru postările Hacker News fără articol extern, se folosește textul postării primit din API.

Rezultatele sunt păstrate în memoria aplicației timp de 30 de minute, pentru a evita cererile repetate la revenirea pe aceeași știre. O cerere eșuată poate fi reîncercată. Paginile care cer autentificare, blochează citirea automată sau nu conțin suficient text pot să nu aibă rezumat; aplicația afișează motivul și păstrează butonul către sursa originală.

Integrarea Reader folosește endpointul documentat cu URL prefixat și `Accept: text/plain`, fără preset care schimbă formatul. Testele de regresie acoperă Markdown, frontmatter și JSON cu sau fără anvelopă, conform [serializatoarelor publice ale serviciului](https://github.com/jina-ai/reader/blob/main/src/services/snapshot-formatter.ts). Aceste exemple nu sunt capturi ale răspunsului primit de utilizator la cererea eșuată.

## Calendar: browser și Android

În **browser**, butonul de export generează un fișier `.ics` cu toate favoritele. Descarcă-l și importă-l în calendar. Pentru Google Calendar pe desktop: Setări → Importă și exportă → Importă. Browserul nu poate accesa direct calendarul dispozitivului prin `device_calendar`.

În **aplicația Android/iOS**, exportul folosește `device_calendar`: cere permisiunea, afișează calendarele în care se poate scrie și salvează evenimentele în cel ales. Confirmarea arată câte au fost salvate, câte existau și câte au eșuat. Pentru aceeași știre, dată și oră, exportul verifică evenimentele existente și evită duplicatele. Dacă unele salvări eșuează, poți reîncerca: cele salvate nu sunt create încă o dată.

Dacă emulatorul nu are niciun calendar, poți crea unul local din dialogul de export. Pentru sincronizare cu Google Calendar, adaugă un cont Google în dispozitiv și alege calendarul acelui cont. Un calendar local nu se sincronizează automat cu Google.

**Data evenimentelor este aleasă de utilizator**, inițial ziua curentă. Data publicării știrii este inclusă separat în descriere, alături de autor și link. PDF-ul nu precizează explicit pe ce dată trebuie planificate evenimentele; alegerea datei permite verificarea tuturor regulilor:

| Zi | Început | Sfârșit |
| --- | --- | --- |
| Luni, miercuri, vineri | 14:00 | 20:00 |
| Marți, joi | 12:00 | 18:00 |
| Sâmbătă, duminică | 08:00 | 12:00 |

Toate favoritele exportate în aceeași zi au intervalul cerut, deci evenimentele se pot suprapune. Pe Android/iOS se folosește fusul orar al dispozitivului. Fișierul `.ics` folosește ore locale, interpretate de calendarul în care îl imporți. Identificatorii `.ics` sunt stabili; comportamentul la importuri repetate depinde de aplicația de calendar.

Ștergerea unei favorite nu șterge evenimentul deja exportat. Gestionarea evenimentelor se face în aplicația Calendar.

## Testare pe iPhone din Windows, fără comenzi

Pornește `Porneste-iPhone.cmd` prin dublu clic. Acesta servește buildul web existent pe portul 5175 și afișează adresa din rețeaua locală. Calculatorul și iPhone-ul trebuie conectate la aceeași rețea Wi-Fi. Deschide adresa afișată în Safari și păstrează fereastra serverului deschisă. Dacă Windows cere acces pentru Python, permite-l pe rețeaua privată. Adresa IP poate să se schimbe când te reconectezi la rețea.

Pornește fișierul din File Explorer, sub contul Windows obișnuit. În mediul Codex verificat aici, contul `codexsandboxoffline` are o regulă firewall care blochează conexiunile primite din rețea. Un server pornit de agent poate răspunde pe calculator și totuși să nu fie accesibil de pe iPhone. Pentru acces de pe telefon, serverul trebuie pornit de utilizator în afara acelui cont restricționat.

Această variantă permite verificarea interfeței, a știrilor, a rezumatelor, a favoritelor și a descărcării `.ics`. Favoritele din Safari sunt separate de cele din browserul calculatorului. Pentru importul `.ics` pe iPhone, [Apple documentează importul unui atașament din Mail](https://support.apple.com/en-ie/guide/iphone/ipha0d932e96/ios).

Pentru a testa permisiunile și salvarea directă în calendar, este necesară aplicația iOS instalată. [Compilarea iOS necesită Xcode pe macOS](https://docs.flutter.dev/platform-integration/ios/setup), local sau pe un serviciu de build cu macOS. Versiunea iOS nu a fost compilată ori testată pe acest calculator Windows. Deschiderea site-ului în Safari sau adăugarea lui pe ecranul principal nu activează pluginul nativ `device_calendar`.

## Telefon și emulator Android

Flutter și Dart sunt instalate pe acest calculator. La verificarea inițială, **Android SDK nu era instalat**, deci compilarea APK și testul pe emulator nu puteau fi executate încă.

1. Instalează [Android Studio](https://developer.android.com/studio).
2. În **SDK Manager**, instalează o platformă Android compatibilă cu versiunea Flutter instalată, Android SDK Build-Tools, Android SDK Platform-Tools, Android SDK Command-line Tools (latest), Android Emulator și NDK (Side by side), dacă buildul îl solicită. Ghidul oficial este [configurarea Android pentru Flutter](https://docs.flutter.dev/platform-integration/android/setup).
3. Rulează `flutter doctor --android-licenses` și citește/acceptă licențele necesare. Verifică apoi `flutter doctor -v`.
4. În **Device Manager**, creează un telefon virtual cu imagine **Google Play** sau **Google APIs**. Pornește-l. Virtualizarea hardware trebuie să fie activată pentru emulator.
5. Rulează:

```powershell
flutter emulators
flutter devices
flutter run -d emulator-5554
```

Înlocuiește `emulator-5554` cu ID-ul real din `flutter devices`. Poți porni și un emulator existent cu `flutter emulators --launch <id-emulator>`.

Pentru telefon fizic: activează Developer options și USB debugging, conectează cablul USB și acceptă autorizarea calculatorului pe telefon. Rulează `flutter devices`, apoi:

```powershell
flutter run -d <id-telefon>
```

Alternativ:

```powershell
.\scripts\run-android.ps1 -DeviceId <id-dispozitiv>
```

Pentru un APK de test:

```powershell
flutter build apk --debug
```

Rezultat: `build/app/outputs/flutter-apk/app-debug.apk`. Pentru instalarea obișnuită folosește `Genereaza-Android.cmd`, care construiește release cu cheia proprie a proiectului. Păstrează privat un backup al `android/upload-keystore.jks` și `android/key.properties`. Pregătirea APK-ului nu publică aplicația în Play Store; publicarea presupune configurarea și verificările magazinului.

Permisiunile INTERNET, READ_CALENDAR și WRITE_CALENDAR sunt declarate pentru Android. Sunt incluse regulile R8 pentru `device_calendar`. Dacă ai refuzat definitiv accesul la calendar, activează-l din Setări → Aplicații → Știri și favorite → Permisiuni, apoi reîncearcă.

Configurarea iOS pentru permisiunile calendarului și fusul orar este inclusă. Compilarea și testarea iOS necesită macOS/Xcode și nu au fost executate pe acest calculator Windows.

## Verificări și build web

```powershell
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Pentru a servi buildul rezultat, dacă ai Python:

```powershell
python -m http.server 5173 --bind 127.0.0.1 --directory build/web
```

Deschide http://localhost:5173. Fișierele de randare sunt incluse local în build; nu este necesară încărcarea CanvasKit de pe CDN. Știrile continuă să necesite acces la API-ul Hacker News.

Testele acoperă modelele și datele invalide, API-ul prin răspunsuri simulate, favoritele persistente și erorile de scriere, încărcarea offline, regulile celor șapte zile, formatul `.ics`, serializarea exportului nativ, refuzul permisiunilor, evitarea duplicatelor și fluxurile interfeței pe desktop și ecran îngust. Testele native utilizează un canal de platformă simulat; nu înlocuiesc testarea pe un dispozitiv real.

Verificare curentă (23 noiembrie 2026): **62 de teste trecute**, `flutter analyze` fără probleme și build web release reușit. Fluxul din Chromium a fost verificat cu răspunsuri API simulate: deschiderea articolului, schimbarea temei, favoritele, persistența după reîncărcare, descărcarea `.ics` și ștergerea, fără excepții JavaScript. Accesul extern al agentului este restricționat; încărcarea cu date reale trebuie verificată din browserul obișnuit al utilizatorului. Compilarea și testarea native rămân de executat după instalarea Android SDK și, pentru iOS, pe Mac cu Xcode. Frecvențele de 90/120 Hz trebuie măsurate pe telefoane fizice.

## Organizare

- `lib/models/`: modelul știrii și conversia JSON.
- `lib/services/`: API HTTP, stocare prin `SharedPreferencesAsync`, export calendar separat pentru web și mobil.
- `lib/controllers/`: starea aplicației și logica favoritelor.
- `lib/screens/`: lista, detaliile și dialogul de export.
- `lib/widgets/`: componenta reutilizabilă pentru afișarea unei știri.
- `test/`: teste automate.

API-uri: `https://hn.algolia.com/api/v1/search?tags=front_page` și `https://hn.algolia.com/api/v1/items/:id`. Endpointul pentru detalii este folosit prin HTTPS.

Versiuni locale folosite la implementare: Flutter 3.50.1 și Dart 3.14.0. Pachetul Material UI este cel din proiectul inițial, compatibil cu acest SDK.
