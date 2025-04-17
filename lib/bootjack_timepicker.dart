//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Tue, Nov 8, 2016  12:38:12 AM
// Author: chunfuchang
library bootjack_timepicker;

import 'package:web/web.dart';
import 'dart:async';
import 'dart:math' show max;
import 'dart:js_interop';

import 'package:intl/intl.dart';
import "package:charcode/ascii.dart";

import 'package:dquery/dquery.dart';
import 'package:bootjack/bootjack.dart';
import 'package:bootjack/bootjack_plugin.dart' as p;

part 'src/timepicker.dart';

T? at<T>(List<T?>? list, int index) {
  if (list != null && list.length > index && index >= 0)
    return list[index];
  return null;
}