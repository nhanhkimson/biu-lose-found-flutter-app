import 'package:intl/intl.dart';

final _displayDate = DateFormat('MMM d, yyyy');

String formatEventDate(DateTime date) => _displayDate.format(date.toLocal());
