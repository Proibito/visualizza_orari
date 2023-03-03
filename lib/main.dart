import 'dart:convert';
import 'package:built_value/built_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import "./Eveto.dart";
import "package:intl/intl.dart";

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
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: const MyHomePage(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English, no country code
          Locale('it', ''), // Italiano
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
  final DateTime oraInizio;
  final DateTime oraFine;

  const Lezioni(this.title, this.oraInizio, this.oraFine);
}

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // CalendarController _calendarController = CalendarController();
  var lezioni = <Lezioni>[];

  String inizio = "";
  String fine = "";
  late final PageController _pageController;

  Future<void> _makePostRequest() async {
    lezioni = <Lezioni>[];

    final url = Uri.parse(
        'https://apache.prod.up.cineca.it/api/Impegni/getImpegniCalendarioPubblico');
    final headers = {'Content-Type': 'application/json'};
    print(inizio);
    print(fine);
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
    setState(() {
      var res = json.decode(response.body);
      int giro = 0;
      for (var test in res) {
        giro++;
        lezioni.add(Lezioni(test["nome"], DateTime.parse(test["dataInizio"]),
            DateTime.parse(test["dataFine"])));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Visualizza Orari'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            TableCalendar(
              calendarFormat: _calendarFormat,
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: DateTime.now(),
              locale: Localizations.localeOf(context).languageCode,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onCalendarCreated: (controller) => _pageController = controller,
              eventLoader: (date) {
                if (date.weekday == DateTime.monday) {
                  return ["sium", "un altro"];
                }
                return [];
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
                inizio = DateTime.utc(focusedDay.year, focusedDay.month, 1)
                    .toString();
                fine = DateTime.utc(focusedDay.year, focusedDay.month, 31)
                    .toString();
                print(DateFormat.yMMMd("it").format(DateTime.now()));
                _makePostRequest();

                if (!isSameDay(_selectedDay, selectedDay)) {
                  // Call `setState()` when updating the selected day
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
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
            // MyList(myList: myList),
            ElevatedButton(
              onPressed: _makePostRequest,
              child: const Text('Invia richiesta POST'),
            ),
            // for(var lezione in lezioni) Text(.parse(lezione.oraFine))
            ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 50,
                  color: Colors.white,
                  child: Center(
                      child: Text(
                    '${lezioni[index].title}',
                    style: TextStyle(fontSize: 14),
                  )),
                );
              },
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemCount: lezioni.length,
              shrinkWrap: true,
            ),
          ],
        )));
  }
}
