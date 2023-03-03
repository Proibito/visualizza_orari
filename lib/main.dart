import 'dart:convert';
import 'package:built_value/built_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _responseText = '';

  Future<void> _makePostRequest() async {
    print(_selectedDay);
    final url = Uri.parse(
        'https://apache.prod.up.cineca.it/api/Impegni/getImpegniCalendarioPubblico');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'mostraImpegniAnnullati': true,
      'mostraIndisponibilitaTotali': false,
      'linkCalendarioId': '613b940fda7aec0018faeede',
      'clienteId': '5852fd1ab7305612a8354d51',
      'pianificazioneTemplate': false,
      'dataInizio': '2023-02-26T23:00:00.000Z',
      'dataFine': '2023-03-03T23:00:00.000Z',
    });
    final response = await http.post(url, headers: headers, body: body);
    setState(() {
      _responseText = response.body;

      var res = json.decode(response.body);
      int giro = 0;
      for(var test in res){
        giro++;
        print("giro: "+ giro.toString());
      }
      print("sium  " + res[0]["dataInizio"]);

    });
  }

  final List<Map<String, String>> myList = [
    {
      'title': 'Elemento 1',
      'description': 'Descrizione dell\'elemento 1',
    },
    {
      'title': 'Elemento 2',
      'description': 'Descrizione dell\'elemento 2',
    },
    {
      'title': 'Elemento 3',
      'description': 'Descrizione dell\'elemento 3',
    },
  ];

  String ottieniDato() {
    return "ciao";
  }

  final List<String> entries = <String>['A', 'B', 'C'];
  final List<int> colorCodes = <int>[600, 500, 100];

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
              focusedDay: _focusedDay,
              firstDay: DateTime(2021),
              lastDay: DateTime(2030),
              locale: Localizations.localeOf(context).languageCode,
              startingDayOfWeek: StartingDayOfWeek.monday,
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
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
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
            ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: entries.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    color: Colors.amber[colorCodes[index]],
                    child: Center(child: Text('Entry ${entries[index]}')),
                  );
                })
          ],
        )));
  }
}
