import 'package:material_ui/material_ui.dart';

import '../widgets/reader_components.dart';
import '../widgets/reader_language.dart';

import 'package:intl/intl.dart';

import '../models/article.dart';
import '../services/app_exception.dart';
import '../services/calendar/calendar_document.dart';
import '../services/calendar/calendar_service.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    required this.articles,
    required this.calendar,
  });
  final List<Article> articles;
  final CalendarService calendar;
  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  List<CalendarTarget> _targets = [];
  String? _selected;
  String? _error;
  bool _busy = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.calendar.isNative) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final targets = await widget.calendar.calendars();
      if (!mounted) return;
      setState(() {
        _targets = targets;
        _selected = targets.firstOrNull?.id;
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(
      () => _error = error is AppException
          ? error.message
          : 'Operația nu a reușit. Reîncearcă.',
    );
  }

  Future<void> _createCalendar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final target = await widget.calendar.createLocalCalendar();
      if (!mounted) return;
      setState(() {
        _targets = [..._targets, target];
        _selected = target.id;
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: context.tr('Data evenimentelor', 'Event date'),
      builder: (context, child) => ReaderPanelBackdrop(child: child!),
    );
    if (date != null && mounted) setState(() => _day = date);
  }

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.calendar.export(
        widget.articles,
        _day,
        calendarId: _selected,
      );
      if (!mounted) return;
      if (result.failed > 0) {
        setState(
          () => _error =
              '${context.calendarResult(result)} ${context.tr('Reîncearcă pentru cele nereușite; cele salvate nu se dublează.', 'Retry the failed events. Previously saved events will not be duplicated.')}',
        );
      } else {
        Navigator.pop(context, result);
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final native = widget.calendar.isNative;
    final ready = !_busy && !_loading && (!native || _selected != null);
    final screen = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        scrollable: true,
        constraints: BoxConstraints(
          maxWidth: screen.width >= 720
              ? screen.width * .70
              : screen.width - 32,
          maxHeight: screen.height * .70,
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Text(
          context.tr(
            'Exportă favoritele în calendar',
            'Export favorites to calendar',
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.articles.length} ${widget.articles.length == 1 ? context.tr('știre favorită', 'favorite article') : context.tr('știri favorite', 'favorite articles')} · ${context.tr('un eveniment pentru fiecare știre.', 'one event per article.')}',
                ),
                const SizedBox(height: 16),
                Text(
                  native
                      ? context.tr(
                          'Alege data și calendarul în care salvezi evenimentele.',
                          'Choose the date and calendar for the events.',
                        )
                      : context.tr(
                          'În browser se descarcă un fișier .ics. Îl poți importa în Google Calendar, Outlook sau alt calendar. Salvarea directă este disponibilă în aplicația Android/iOS.',
                          'Your browser downloads an .ics file. Import it into Google Calendar, Outlook, or another calendar. The Android/iOS app can save events directly.',
                        ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _chooseDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${context.tr('Data', 'Date')}: ${DateFormat('EEEE, dd.MM.yyyy', Localizations.localeOf(context).languageCode).format(_day)}',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${context.tr('Interval automat', 'Automatic time slot')}: ${CalendarSlot.forDay(_day).label}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Luni, miercuri, vineri: 14:00–20:00\nMarți, joi: 12:00–18:00\nWeekend: 08:00–12:00',
                    'Monday, Wednesday, Friday: 14:00–20:00\nTuesday, Thursday: 12:00–18:00\nWeekend: 08:00–12:00',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Data publicării, autorul și linkul știrii vor fi incluse în descrierea evenimentului.',
                    'The event description includes the publication date, author, and article link.',
                  ),
                ),
                if (native) ...[
                  const SizedBox(height: 20),
                  if (_loading) const LinearProgressIndicator(),
                  if (_targets.isNotEmpty)
                    Theme(
                      // The iOS dropdown scrollbar bypasses ScrollbarTheme.
                      data: Theme.of(context).platform == TargetPlatform.iOS
                          ? Theme.of(context)
                                .copyWith(platform: TargetPlatform.android)
                          : Theme.of(context),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selected),
                        initialValue: _selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Calendar',
                        ),
                        items: _targets
                            .map(
                              (target) => DropdownMenuItem(
                                value: target.id,
                                child: Text(
                                  target.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _busy || _loading
                            ? null
                            : (value) => setState(() => _selected = value),
                      ),
                    ),
                  if (_targets.isEmpty && !_loading && _error == null) ...[
                    Text(
                      context.tr(
                        'Nu există calendare în care poți scrie. Adaugă un cont Google în dispozitiv sau creează un calendar local.',
                        'No writable calendars are available. Add a Google account to your device or create a local calendar.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _createCalendar,
                      icon: const Icon(Icons.add),
                      label: Text(
                        context.tr(
                          'Creează calendar local',
                          'Create local calendar',
                        ),
                      ),
                    ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.localizedMessage(_error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (native && _selected == null)
                    TextButton(
                      onPressed: _loading ? null : _load,
                      child: Text(
                        context.tr(
                          'Reîncearcă accesul la calendar',
                          'Retry calendar access',
                        ),
                      ),
                    ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  Text(
                    context.tr('Se salvează evenimentele…', 'Saving events…'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: ready ? _export : null,
                  icon: Icon(native ? Icons.event_available : Icons.download),
                  label: Text(
                    native
                        ? context.tr('Salvează în calendar', 'Save to calendar')
                        : context.tr(
                            'Descarcă fișierul .ics',
                            'Download .ics file',
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(context.tr('Anulează', 'Cancel')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
