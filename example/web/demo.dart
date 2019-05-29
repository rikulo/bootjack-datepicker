import 'dart:html';

import 'package:bootjack_datepicker/bootjack_datepicker.dart';
import 'package:bootjack_datepicker/bootjack_timepicker.dart';


void main() {

  for (final elem in querySelectorAll('[class~="calendar"]')) {
    Calendar.wire(elem);
  }
  for (final elem in querySelectorAll('[class~="timepicker"]')) {
    TimePicker.wire(elem);
  }
}
