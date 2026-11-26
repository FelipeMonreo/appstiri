import 'package:material_ui/material_ui.dart';

import '../services/calendar/calendar_service.dart';

extension ReaderLanguage on BuildContext {
  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';

  String tr(String romanian, String english) => isEnglish ? english : romanian;

  String localizedMessage(String message) =>
      isEnglish ? (_englishMessages[message] ?? message) : message;

  String calendarResult(CalendarExportResult result) {
    if (!isEnglish) return result.message;
    return result.downloaded
        ? 'The .ics file is ready. Import it into your calendar to save the events.'
        : '${result.created} events saved, ${result.skipped} already present, ${result.failed} failed.';
  }
}

// Services expose Romanian messages independently of the display locale.
const _englishMessages = {
  'Unele favorite salvate sunt deteriorate și nu pot fi afișate.':
      'Some saved favorites are damaged and cannot be displayed.',
  'Favoritele nu pot fi citite. Reîncearcă accesul la salvarea locală.':
      'Favorites could not be read. Retry access to local storage.',
  'Știrile sunt încărcate, dar copia pentru acces offline nu a putut fi salvată.':
      'News loaded, but the offline copy could not be saved.',
  'Știrile nu au putut fi încărcate. Încearcă din nou.':
      'News could not be loaded. Try again.',
  'Salvarea locală nu este disponibilă. Reîncearcă mai întâi.':
      'Local storage is unavailable. Try again first.',
  'Salvarea locală a eșuat. Verifică spațiul disponibil și setările browserului.':
      'Local storage failed. Check available space and your browser settings.',
  'Știrea nu mai este disponibilă.': 'This article is no longer available.',
  'Serverul de știri nu răspunde. Încearcă din nou.':
      'The news server is not responding. Try again.',
  'Conexiunea durează prea mult. Încearcă din nou.':
      'The connection timed out. Try again.',
  'Serverul a trimis date invalide. Încearcă din nou.':
      'The server sent invalid data. Try again.',
  'Nu se poate contacta serverul. Verifică internetul.':
      'Could not reach the server. Check your internet connection.',
  'Lista de știri primită este invalidă.': 'The news list is invalid.',
  'Știrile primite nu pot fi citite. Încearcă din nou.':
      'The news could not be read. Try again.',
  'Identificator invalid.': 'Invalid identifier.',
  'Detaliile știrii sunt invalide.': 'The article details are invalid.',
  'Detaliile nu au putut fi încărcate.':
      'The article details could not be loaded.',
  'Rezumatul nu a putut fi încărcat. Poți deschide articolul original mai jos.': 'The summary could not be loaded. You can open the original article below.',
  'Această știre nu are un text disponibil pentru rezumat. Poți deschide pagina originală mai jos.': 'This article has no text available to summarize. You can open the original page below.',
  'Pagina nu conține suficient text accesibil pentru un rezumat. Citește articolul complet folosind butonul de mai jos.': 'This page does not have enough accessible text for a summary. Use the button below to read the full article.',
  'Serviciul de citire a primit prea multe cereri. Așteaptă puțin și reîncearcă.': 'The reading service received too many requests. Wait a moment and try again.',
  'Articolul nu poate fi citit automat acum. Site-ul poate necesita autentificare sau poate bloca accesul.': 'The article cannot be read automatically right now. The site may require sign-in or block access.',
  'Pagina este prea mare pentru rezumat. Deschide articolul complet.':
      'The page is too large to summarize. Open the full article.',
  'Citirea articolului durează prea mult. Reîncearcă sau deschide sursa originală.': 'Reading the article took too long. Try again or open the original source.',
  'Serviciul de citire a trimis un răspuns neașteptat. Reîncearcă încărcarea articolului.': 'The reading service sent an unexpected response. Try loading the article again.',
  'Rezumatul nu poate fi încărcat. Verifică internetul și reîncearcă.': 'The summary could not be loaded. Check your internet connection and try again.',
  'Site-ul articolului nu a putut fi accesat de serviciul de citire.':
      'The reading service could not reach the article website.',
  'Site-ul articolului blochează citirea automată sau necesită autentificare.':
      'The article website blocks automatic reading or requires sign-in.',
  'Operația nu a reușit. Reîncearcă.': 'The operation failed. Try again.',
  'Calendarul dispozitivului este disponibil pe Android și iOS.':
      'Device calendars are available on Android and iOS.',
  'Calendarul este disponibil pe Android și iOS.':
      'Calendars are available on Android and iOS.',
  'Accesul la calendar nu a fost permis. Activează permisiunea din setările aplicației și reîncearcă.': 'Calendar access was denied. Enable it in the app settings and try again.',
  'Calendarele nu au putut fi citite. Încearcă din nou.':
      'Calendars could not be read. Try again.',
  'Calendarul local nu a putut fi creat. Adaugă un calendar în aplicația Calendar și reîncearcă.': 'A local calendar could not be created. Add a calendar in the Calendar app and try again.',
  'Alege mai întâi calendarul.': 'Select a calendar first.',
  'Evenimentele existente nu pot fi verificate. Reîncearcă exportul pentru a evita duplicatele.': 'Existing events could not be checked. Retry the export to avoid duplicates.',
};
