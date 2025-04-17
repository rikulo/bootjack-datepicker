import 'package:web/web.dart';

import 'package:bootjack_datepicker/bootjack_datepicker.dart';
import 'package:bootjack_datepicker/bootjack_timepicker.dart';


void main() {

  for (final elem in JSImmutableListWrapper(document.querySelectorAll('[class~="calendar"]')).cast<Element>()) {
    Calendar.wire(elem);
  }
  for (final elem in JSImmutableListWrapper(
      document.querySelectorAll('[class~="timepicker"]')).cast<Element>()) {
    TimePicker.wire(elem);
  }
}
