import 'dart:html';
import 'package:dquery/dquery.dart';
import 'package:bootjack/bootjack.dart';
import 'package:bootjack_datepicker/bootjack_datepicker.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';



void main() {
 
  Calendar.wire(query('#calendar'));
  $('[data-toggle="datepicker"]').forEach((Element elem) => Datepicker.wire(elem));
  Dropdown.wire(query('#test'));
}
