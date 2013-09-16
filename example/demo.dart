import 'dart:html';
import 'package:dquery/dquery.dart';
import 'package:bootjack_datepicker/bootjack_datepicker.dart';


void main() {
 
  Calendar.wire(query('#calendar'));
  $('[data-toggle="datepicker"]').forEach((Element elem) => Datepicker.wire(elem));
}
