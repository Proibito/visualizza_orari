import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import "package:intl/intl.dart";
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Guarda meglio',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: const MyHomePage(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('it'), // Spanish
        ],
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // var current = WordPair.random();

  void getNext() {
    // current = WordPair.random();
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Lezioni {
  final String title;
  final String oraInizio;
  final String oraFine;

  const Lezioni(this.title, this.oraInizio, this.oraFine);
}

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // CalendarController _calendarController = CalendarController();
  SplayTreeMap<String, List<Lezioni>> lezioni = SplayTreeMap();
  var lezioniList = <Lezioni>[];
  String inizio = "";
  String fine = "";

  List<Lezioni> _ottieniEventiPerGiorno(DateTime day) {
    // Implementation example
    var stringaGiorno = DateUtils.dateOnly(day).toString();
    return lezioni[stringaGiorno] ?? [];
  }

  Future<void> _makePostRequest() async {
    SplayTreeMap<String, List<Lezioni>> rawData =
        SplayTreeMap((a, b) => a.compareTo(b));

    final url = Uri.parse(
        'https://apache.prod.up.cineca.it/api/Impegni/getImpegniCalendarioPubblico');
    final headers = {'Content-Type': 'application/json'};
    // print(inizio);
    // print(fine);
    final body = jsonEncode({
      'mostraImpegniAnnullati': true,
      'mostraIndisponibilitaTotali': false,
      'linkCalendarioId': '613b940fda7aec0018faeede',
      'clienteId': '5852fd1ab7305612a8354d51',
      'pianificazioneTemplate': false,
      'dataInizio': inizio,
      'dataFine': fine,
    });
    final response = await http.post(url, headers: headers, body: body);

    var res = json.decode(response.body);
    lezioniList.clear();
    for (var test in res) {
      lezioniList
          .add(Lezioni(test["nome"], test["dataInizio"], test["dataFine"]));
    }

    // Ordino la lista
    lezioniList.sort((a, b) {
      var adate = a.oraInizio;
      var bdate = b.oraInizio;
      return adate.compareTo(bdate);
    });

    for (var lezione in lezioniList) {
      var data =
          DateUtils.dateOnly(DateTime.parse(lezione.oraInizio)).toString();
      if (rawData[data] == null) {
        rawData[data] = [lezione];
      } else {
        rawData[data]!.add(lezione);
      }
    }
    setState(() {
      lezioni = rawData;
    });
  }

  void caricaDate(DateTime giornoSelezionato) {
    if (_calendarFormat == CalendarFormat.week) {
      // Calcola il numero di giorni trascorsi dall'inizio della settimana corrente (lunedì)
      int daysSinceMonday = giornoSelezionato.weekday - DateTime.monday;

      // Calcola la data di inizio settimana (lunedì)
      DateTime startOfWeek =
          giornoSelezionato.subtract(Duration(days: daysSinceMonday)).toUtc();

      // Calcola la data di fine settimana (domenica)
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6)).toUtc();
      setState(() {
        inizio = startOfWeek.toString();
        fine = endOfWeek.toString();
      });
    } else {
      inizio = DateTime.utc(giornoSelezionato.year, giornoSelezionato.month, 1)
          .toString();
      fine = DateTime.utc(giornoSelezionato.year, giornoSelezionato.month, 31)
          .toString();
    }
    _makePostRequest();
  }

  void _handleChildCallback() {
    // Fa qualcosa
    print('Funzione di callback chiamata dal widget figlio');
  }

  final GlobalKey<_MyTest> _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    caricaDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Visualizza Orari'),
        ),
        body: Column(
          children: [
            TableCalendar(
              calendarFormat: _calendarFormat,
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              locale: Localizations.localeOf(context).languageCode,
              startingDayOfWeek: StartingDayOfWeek.monday,
              // onCalendarCreated: (controller) => _pageController = controller,
              eventLoader: (date) {
                return _ottieniEventiPerGiorno(date);
              },
              availableCalendarFormats: const {
                CalendarFormat.week: '1 settimana',
                CalendarFormat.twoWeeks: '2 settimane',
                CalendarFormat.month: 'Mesile',
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = selectedDay;
                  _selectedDay = selectedDay;
                });
                caricaDate(selectedDay);
                _childKey.currentState?.doSomething(selectedDay);
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                caricaDate(focusedDay);
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: Colors.red,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            MyTest(key: _childKey, lezioni: lezioni),
          ],
        ));
  }
}

class MyTest extends StatefulWidget {
  final SplayTreeMap<String, List<Lezioni>> lezioni;

  MyTest({Key? key, required this.lezioni}) : super(key: key);

  @override
  _MyTest createState() => _MyTest();
}

class _MyTest extends State<MyTest> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  void doSomething(DateTime data) {
    int i = 0;
    for (i = 0; i < widget.lezioni.length; i++) {
      String chiave = widget.lezioni.keys.elementAt(i);
      if (chiave == DateUtils.dateOnly(data).toString()) {
        break;
      }
    }
    itemScrollController.scrollTo(
        index: i, duration: const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      //       child: Scrollbar(
      // controller: _controller,
      child: ScrollablePositionedList.builder(
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          itemCount: widget.lezioni.length,
          itemBuilder: (BuildContext context, int index) {
            String chiave = widget.lezioni.keys.elementAt(index);
            return LezioniWidget(lezioni: widget.lezioni[chiave]!);
          }),
    )
        // )
        );
  }
}

class LezioniWidget extends StatelessWidget {
  final List<Lezioni> lezioni;
  const LezioniWidget({Key? key, required this.lezioni}) : super(key: key);

  String formattaData(String data) {
    var dataFormata = DateTime.parse(data);
    var formatter = DateFormat('Hm', "it");
    String formattedDate = formatter.format(dataFormata);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 30, bottom: 10),
              child: Text(
                DateFormat.yMMMd("it")
                    .format(DateTime.parse(lezioni[0].oraInizio)),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            )
          ],
        ),
        for (var lezione in lezioni)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: ListTile(
                title: Text(lezione.title),
                subtitle: Text(
                    '${formattaData(lezione.oraInizio)} - ${formattaData(lezione.oraFine)}'),
              ),
            ),
          ),
      ],
    ));
  }
}
