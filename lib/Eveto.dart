class Event {
  final String title;
  final DateTime oraInizio;
  final DateTime oraFine;


  const Event(this.title, this.oraInizio, this.oraFine);

  @override
  String toString() => title;
}