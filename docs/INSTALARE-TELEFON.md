# Instalarea pe Android și iPhone

Acest ghid explică ce faci, unde lucrezi și de ce. Codul aplicației este în `lib/`. Din același cod Flutter obținem două aplicații native, câte una pentru fiecare sistem de operare.

## Starea proiectului

- Versiunea din `pubspec.yaml` este `1.1.0+2`. Numele afișat pe Android și iOS este **Știri UNITBV**.
- Android folosește sigla UNITBV albă pe fundal albastru. Iconița din catalogul iOS folosește desenul cu ziar și stea.
- Identificatorul configurat pentru Android și Runner iOS este `ro.stirifavorite.app`. Echipa de semnare iOS se alege în Xcode.
- Un build Android de debug a fost instalat și pornit în emulator în timpul dezvoltării. Verificările de predare și limitele lor sunt în [README](../README.md#testare).

## 1. Android: obținerea fișierului instalabil

### Pasul A: instalezi uneltele o singură dată

În File Explorer deschizi folderul proiectului și dai dublu clic pe **`Configureaza-Android.cmd`**.

Comanda folosește `scripts/setup-android.ps1`. Ea descarcă de la Google uneltele de linie de comandă, verifică suma SHA256 și instalează Android SDK în `.tooling/android-sdk`. Nu instalează emulator și nu modifică permanent PATH-ul Windows. Va afișa licențele Google pentru a le citi și accepta. Prima instalare are nevoie de internet și de câțiva GB liberi; fereastra rămâne deschisă ca să poți vedea eventualele erori.

Configurarea folosește Flutter 3.50.1, platforma Android 36, Build Tools 36.0.0, NDK 28.2.13676358 și CMake 3.22.1. Poți folosi JDK 21 sau JDK-ul compatibil inclus în Android Studio. Scriptul caută Java în `JAVA_HOME`, apoi în variabila existentă `JavaHome`, apoi în JDK-ul inclus în Android Studio. Dacă nu găsește Java, instalezi Android Studio sau configurezi `JAVA_HOME` către JDK 21.

Alternativa cu interfață grafică este [Android Studio și SDK Manager](https://docs.flutter.dev/platform-integration/android/setup). Dacă SDK-ul este deja în locația standard, scriptul de compilare îl poate folosi. Un SDK aflat în altă locație se poate indica explicit:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-android.ps1 -SdkPath "C:\cale\Android\Sdk"
```

`ExecutionPolicy Bypass` se aplică doar procesului care rulează comanda. Nu schimbă politica Windows permanent.

### Pasul B: generezi APK-ul

Dai dublu clic pe **`Genereaza-Android.cmd`**.

Comanda apelează `scripts/build-android.ps1`, care execută pe rând:

```text
flutter pub get          → pregătește pachetele din pubspec.yaml/pubspec.lock
flutter analyze          → verifică problemele din cod
flutter test             → verifică comportamentele acoperite de teste
init-android-signing.ps1 → creează semnătura numai dacă nu există deja
flutter build apk --release --no-pub → construiește aplicația Android
```

La o eroare, scriptul se oprește. Nu afișează că APK-ul este gata dacă buildul a eșuat. Prima compilare descarcă și componente Flutter/Gradle, deci poate dura mai mult.

Pentru versiunea actuală `1.1.0+2`, rezultatul va fi:

```text
distributie/android/Stiri-si-favorite-1.1.0+2-release.apk
```

Fișierul `.apk.sha256` din același folder este o amprentă pentru verificarea integrității. Nu se instalează pe telefon. APK-ul original creat de Flutter se află în `build/app/outputs/flutter-apk/app-release.apk`.

### Pasul C: instalezi pe telefon

1. Transferi fișierul `.apk` pe Android, de exemplu prin cablu USB sau prin spațiul tău de stocare în cloud.
2. Pe telefon, îl deschizi din aplicația Fișiere/Files.
3. Dacă Android cere permisiunea de a instala din această sursă, o permiți pentru aplicația cu care ai deschis APK-ul.
4. Alegi **Instalează**. Aplicația apare cu numele și iconița pregătite.
5. O deschizi, încarci știrile și verifici exportul în calendar.

Pentru instalarea manuală din APK nu trebuie publicată în Google Play. Aplicația instalată poate rula cu calculatorul oprit; știrile noi și rezumatele au nevoie de internet pe telefon. Ultima listă încărcată și favoritele sunt păstrate local.

Poți instala și prin USB cu `adb install -r`, după activarea USB debugging. Pentru început, deschiderea fișierului APK pe telefon este suficientă.

### Ce păstrezi pentru actualizări

Aceste două fișiere sunt private și trebuie salvate împreună într-un backup sigur:

```text
android/upload-keystore.jks → cheia cu care semnăm aplicația
android/key.properties     → parola și datele folosite de Gradle
```

Nu le trimite împreună cu APK-ul și nu le publica în GitHub. Sunt excluse din arhiva pentru Mac. Scriptul nu înlocuiește o cheie existentă. Dacă există doar unul dintre cele două fișiere, se oprește și cere restaurarea perechii din backup.

Identificatorul aplicației + semnătura + numărul versiunii permit Android să recunoască o actualizare. Dacă schimbi identificatorul, Android o tratează ca altă aplicație. Dacă schimbi semnătura, poate refuza actualizarea. Nu dezinstala aplicația pentru o actualizare obișnuită: dezinstalarea poate șterge favoritele locale.

### Rulare în emulator sau pe un dispozitiv conectat

Pentru emulator instalezi **Android Emulator**, o imagine de sistem și **Android SDK Command-line Tools (latest)** din Android Studio. Verifici licențele cu `flutter doctor --android-licenses`, apoi pornești telefonul virtual din **Device Manager**. Pentru un telefon fizic activezi depanarea USB și autorizezi calculatorul.

```powershell
flutter devices
flutter run -d ID_DISPOZITIV
```

Folosești ID-ul afișat, de exemplu `emulator-5554`. Pentru un APK de debug rulezi `flutter build apk --debug`. Dacă un build Windows folosește sursele și cache-ul Pub de pe unități diferite, proiectul are compilarea incrementală Kotlin dezactivată în `android/gradle.properties`.

## 2. iPhone: transferul și instalarea folosind Mac-ul

### Testare în Safari pe iPhone, de pe Windows

Din rădăcina proiectului rulezi `flutter build web`, apoi deschizi `Porneste-iPhone.cmd`. Scriptul caută Python și servește `build/web` pe portul 5175. Lași fereastra deschisă, conectezi iPhone-ul și calculatorul la aceeași rețea și deschizi în Safari adresa afișată. Dacă Windows cere acces pentru Python, permiți conexiunile pe rețeaua privată.

Pentru testare pe calculator poți porni direct `flutter run -d chrome` sau `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173`. Favoritele din browser sunt asociate adresei, portului și profilului folosit. O adresă diferită poate afișa altă listă de favorite.

Safari permite testarea interfeței web și descărcarea fișierului `.ics`. Pentru a testa accesul direct la calendarul iOS, instalezi aplicația nativă de pe Mac.

### Ce pregătești pe Windows

Dai dublu clic pe **`Pregateste-pentru-Mac.cmd`**. Obții:

```text
distributie/Stiri-si-favorite-surse-Mac.zip
```

Este o arhivă cu **sursele proiectului**, nu o aplicație iPhone instalabilă. Include codul, testele, configurarea iOS, iconițele și acest ghid. Exclude buildurile, cache-urile Windows, căile generate către Flutter și cheile Android.

Copiază arhiva pe Mac și dezarhiveaz-o într-un folder în care poți scrie. Nu copia doar folderul `ios`: are nevoie de codul Dart și de `pubspec.yaml`.

### Ce instalezi pe Mac o singură dată

Urmezi [configurarea oficială Flutter pentru iOS](https://docs.flutter.dev/platform-integration/ios/setup):

1. Instalezi Flutter, preferabil aceeași versiune **3.50.1** ca pe Windows, și îl adaugi în PATH. `pubspec.yaml` cere Dart 3.14 sau compatibil; un Flutter mai vechi poate să nu rezolve pachetele.
2. Instalezi Xcode, îl deschizi și instalezi suportul pentru iOS cerut de Xcode. Citești și accepți licențele afișate de Apple.
3. Instalezi CocoaPods, necesar pentru pluginul de calendar folosit în proiect.
4. Verifici în Terminal cu `flutter doctor -v`. Problemele pentru Android nu împiedică lucrul la iOS; rezolvi secțiunile Xcode/CocoaPods.

Pentru selectarea uneltelor Xcode, ghidul oficial oferă:

```bash
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
```

Nu există o comandă Windows care să înlocuiască această compilare nativă cu Xcode.

### Pregătești proiectul și contul Apple

În Terminal intri în folderul `appstiri` dezarhivat. Poți scrie `cd ` și trage folderul din Finder în Terminal, apoi apeși Enter.

```bash
bash scripts/prepare-ios.sh
```

Scriptul verifică uneltele, obține dependențele, rulează analiza și testele, generează configurarea iOS, instalează pachetele CocoaPods și deschide **`ios/Runner.xcworkspace`** în Xcode. Deschizi workspace-ul, deoarece include și dependențele native.

În Xcode:

1. Adaugi contul tău Apple în **Xcode → Settings → Accounts**.
2. Selectezi proiectul **Runner**, apoi ținta **Runner → Signing & Capabilities**.
3. Activezi **Automatically manage signing** și alegi **Team**.
4. Verifici Bundle Identifier. Proiectul propune `ro.stirifavorite.app`; dacă Xcode spune că este indisponibil, îl înlocuiești cu unul unic din contul tău, pentru toate configurațiile Runner. Păstrezi valoarea aleasă pentru actualizările viitoare.
5. Conectezi iPhone-ul prin cablu, îl deblochezi și accepți **Trust this computer**.
6. Activezi **Developer Mode** din setările iPhone-ului, dacă sistemul îl solicită. Opțiunea poate apărea după prima conectare/configurare cu Xcode.

Pentru o primă testare pe telefonul propriu poți folosi un **Personal Team gratuit**. Apple precizează că profilul acestei instalări expiră după **7 zile**, după care aplicația trebuie recompilată și reinstalată. Pentru distribuire prin TestFlight/App Store este necesară înscrierea în Apple Developer Program. Vezi [explicația Apple despre Personal Team și distribuire](https://developer.apple.com/help/account/basics/about-your-developer-account).

### Instalezi versiunea care se poate redeschide de pe iconiță

După configurarea semnării, în Terminal, din rădăcina proiectului:

```bash
flutter devices
flutter run --release -d ID_IPHONE
```

Înlocuiești `ID_IPHONE` cu ID-ul real din prima comandă. Folosim **release** pentru utilizarea normală și redeschiderea de pe iconiță fără o sesiune de depanare. Dacă iPhone-ul cere încredere pentru certificatul dezvoltatorului, urmezi instrucțiunile lui din Settings → General → VPN & Device Management, apoi încerci din nou.

După instalare, verifici că poți redeschide aplicația de pe iconiță după oprirea sesiunii din Terminal și deconectarea cablului. Pentru Personal Team rămâne limita de valabilitate a profilului Apple.

Pentru distribuirea către alte persoane și ulterior App Store folosim [fluxul Flutter pentru iOS/TestFlight](https://docs.flutter.dev/deployment/ios). Acest proiect nu a fost încă trimis la Apple sau Google.

## 3. Cum publici o modificare ulterioară

**Salvarea unui fișier pe calculator nu modifică aplicațiile instalate.** Exemplu: schimbi culoarea unui buton în `lib/theme/app_theme.dart`. Telefoanele păstrează versiunea veche până instalezi un build nou.

1. Modifici codul din proiectul principal de pe Windows.
2. În `pubspec.yaml` crești versiunea, de exemplu din `1.1.0+2` în `1.1.1+3`. Cifra după `+` este numărul buildului și trebuie să crească la distribuiri noi.
3. Pentru Android rulezi din nou `Genereaza-Android.cmd`, folosind aceeași cheie. Instalezi APK-ul nou peste aplicația existentă.
4. Pentru iOS generezi o nouă arhivă cu `Pregateste-pentru-Mac.cmd`, o transferi pe Mac, refaci pregătirea și instalarea cu același cont și Bundle Identifier. Dacă ai schimbat Bundle Identifier pe Mac, păstrează modificarea și în proiectul principal de pe Windows pentru arhivele viitoare. Nu distribui accidental o copie veche de pe Mac.

Știrile noi vin de la API fără să recompilăm aplicația. Favoritele sunt salvate separat pe fiecare dispozitiv; nu există momentan cont de utilizator sau sincronizare Android–iPhone–browser.

Actualizările prin Google Play/App Store pot fi automatizate mai târziu. Aceste scripturi construiesc și pregătesc local aplicația; nu încarcă automat nimic în magazine.

## 4. Ce verifici pe fiecare telefon

1. Apare iconița și numele. Închizi complet aplicația și o redeschizi de pe iconiță, cu calculatorul oprit.
2. Pe Wi-Fi și pe date mobile se încarcă știrile și detaliile. Verifici și rezumatul unui articol accesibil public.
3. Adaugi o știre la favorite, închizi aplicația și confirmi că favorita există după redeschidere.
4. După o încărcare reușită, activezi modul avion și verifici lista păstrată local. Prima încărcare și articolele externe cer internet.
5. La export permiți accesul la calendar, alegi un calendar în care poți scrie și verifici titlul, autorul, linkul și data publicării în eveniment. Poți folosi un calendar local din dialog dacă dispozitivul nu are un calendar disponibil.
6. Repeți exportul cu aceeași știre și dată: evenimentul deja existent trebuie să fie raportat ca atare.
7. Verifici intervalele pentru o zi de luni/miercuri/vineri (14–20), marți/joi (12–18), sâmbătă/duminică (08–12).
8. Verifici și refuzul permisiunii: aplicația trebuie să explice problema, apoi să funcționeze după activarea accesului din setări. Pe iOS este nevoie de acces complet pentru citirea calendarelor și evitarea duplicatelor.
9. Instalezi o actualizare și verifici păstrarea favoritelor.

Un calendar local nu se sincronizează automat cu Google sau iCloud. Pentru sincronizare alegi calendarul contului respectiv de pe dispozitiv. Ștergerea unei favorite nu șterge evenimentul exportat anterior.

## 5. Dacă ceva se oprește

| Mesaj/situație | Ce verifici |
| --- | --- |
| `Flutter nu este in PATH` | `flutter --version` într-un terminal Windows nou; instalarea Flutter și PATH. |
| `JAVA_HOME` / Java lipsește | JDK 21 sau JDK-ul inclus în Android Studio. Variabila trebuie să indice folderul JDK, nu `bin/java.exe`. |
| Descărcarea Google eșuează | Accesul la internet, firewall/proxy; rulezi comanda în contul Windows obișnuit. |
| O descărcare întreruptă | Fișierul incomplet rămâne cu extensia `.partial`; următoarea rulare reîncearcă descărcarea. |
| Licențe Android neacceptate | Rulezi din nou configurarea și citești întrebările din fereastră. |
| SDK/NDK/Build Tools lipsă | Completezi instalarea cerută de mesajul Gradle; nu distribui un build eșuat. |
| Android refuză o actualizare | Verifici Application ID, semnătura, versiunea și dacă aplicația veche era un build debug. |
| Favoritele de pe calculator nu apar pe telefon | Sunt stocări separate; nu există sincronizare între dispozitive. |
| Calendarul este gol / nu apare în listă | Adaugi un cont/calendar în telefon și verifici că permite scrierea. |
| iOS: semnare / provisioning | Contul Apple, Team, identificatorul unic, conexiunea și încrederea telefonului. |
| iOS: după 7 zile nu mai pornește | Pentru Personal Team, refaci semnarea și instalarea; vezi explicația Apple de mai sus. |

Pentru a înțelege codul și rolul fiecărui fișier, continuă cu [CUM-FUNCTIONEAZA.md](CUM-FUNCTIONEAZA.md).
