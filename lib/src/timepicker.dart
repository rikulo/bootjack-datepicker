part of bootjack_timepicker;

abstract class TimePicker {
  static const _name = 'timepicker';

  /** Construct a TimePicker object, wired to [element].
   *
   * * [element] - the container to put the [TimePicker].
   * * [time] - the time displayed on input, legal format: '12:25'
   * * [step] - specify a step for the minute field.
   *
   */
  factory TimePicker(Element element, {
      String? time, DateTime? date, int? step, int? maxHour = 24,
      bool? enable24HourTime, bool? enableSecond, 
      bool? enableDay, bool? enableDayHourOnly, 
      bool? enableDefaultEmpty})
    => _TimePickerImpl(element, time: time, date: date,
        step: step, maxHour: maxHour,
        enableDay: enableDay,
        enableDayHourOnly: enableDayHourOnly,
        enableSecond: enableSecond,
        enable24HourTime: enable24HourTime,
        enableDefaultEmpty: enableDefaultEmpty,
    );

  /** Get time with format: '00:00'.
   */
  String get time;

  /** Set time with format: '00:00'.
   */
  set time(String t);

  /** Get date.
   */
  DateTime? get date;

  /** Set date.
   */
  set date(DateTime? d);

  /** Get days.
   */
  int get days;

  /** Set date.
   */
  set days(int d);

  /** Get step for minute field
   */
  int get step;

  /** Set step for minute field
   */
  void set step(int s);

  void set enable24HourTime(bool enable);

  void set enableSecond(bool enable);

  void set enableDay(bool enable);

  void set enableDayHourOnly(bool enable);

  /// Whether to enable default empty `--:--` (default: true).
  void set enableDefaultEmpty(bool enable);

  /**
   * The date format locale of the calendar value.
   */
  String get locale;
  void set locale(String locale);

  /// Get value of day field.
  String get day;

  /// Get value of hour field.
  String get hour;

  /// Get value of minute field.
  String get minute;

  /// Get value of second field.
  String get second;

  List<int?> get timeValues;

  /// highlight first field
  void highlight();

  void highlightDay();
  void highlightHour();
  void highlightMinute();
  void highlightSecond();
  void highlightAmPm();

  void incrementDay(bool add);
  void incrementHour(bool add);
  void incrementMinute(bool add);
  void incrementSecond(bool add);
  void toggleAmPm();

  /** Retrieve the wired TimePicker object from an element. If there is no wired
   * TimePicker object, a new one will be created.
   *
   * + [create] - If provided, it will be used for TimePicker creation. Otherwise
   * the default constructor with no optional parameter value is used.
   */
  static TimePicker wire(Element element, [TimePicker create()?]) =>
      p.wire(element, _name, create ?? (() => TimePicker(element)));

  // Data API //
  static bool _registered = false;

  /** Register to use TimePicker component.
   */
  static void use() {
    if (_registered) return;
    _registered = true;

    $window().on('load', (QueryEvent e) {
      for (final elem in $('[class~="timepicker"]')) {
        TimePicker.wire(elem);
      }
    });
  }
}

enum _HighlightUnit {day, hour, minute, second, ampm}

/** A time picker component.
 */
class _TimePickerImpl extends Base implements TimePicker {

  static const _defaultStep = 5;
  static const _maxMinute = 60;

  _TimePickerImpl(Element element, {String? time,
    DateTime? date, int? step, bool? enable24HourTime, 
    bool? enableSecond, bool? enableDay, bool? enableDayHourOnly, 
    int? maxHour = 24, bool? enableDefaultEmpty}):
  super(element, TimePicker._name) {
    
    $element
    ..on('keydown', _onKeydown)
    ..on('keypress', _onKeypress)
    ..on('input', _onInput)
    ..on('focus click', _highlightUnit)
    ..on('blur', _fireChange);

    element.onMouseWheel.listen(_doMousewheel);

    final maxStr = element.dataset['max-hour'];
    _maxHour0 = maxStr != null ? int.tryParse(maxStr): maxHour;

    this.enable24HourTime = _maxHour == null 
      || (enable24HourTime ?? element.dataset['date-24'] == 'true');
    this.enableSecond = enableSecond ?? element.dataset['second'] == 'true';
    this.enableDay = enableDay ?? element.dataset['day'] == 'true';
    this.enableDayHourOnly = enableDayHourOnly ?? element.dataset['day-hour'] == 'true';
    this.enableDefaultEmpty = enableDefaultEmpty ?? element.dataset['default-empty'] != 'false';
    this._locale0 = _data(null, element, 'date-locale', Intl.systemLocale);

    //input.value count on
    //1. date, 2. time, 3. data attribute
    this.time = _data(time, element, 'time', '$_emptyVal:$_emptyVal');
    if (date != null) this.date = date;

    this.step = step;
  }

  Element get input => element;
  int? _day, _hour, _minute, _second, _step, _maxHour0;
  int _ampmIndex = 0;
  _HighlightUnit? _highlightedUnit;

  bool _in24Hour = false, _enableDay0 = false, _enableDayHourOnly = false,
    _enableSecond0 = false, _enableDefaultEmpty = true;
  late String _locale;
  late List<String> _ampms;

  int? get _maxHour => _enableDay ? 24: _maxHour0;

  bool get _enableDay => _enableDayHourOnly || _enableDay0;

  bool get _enableSecond => !_enableDayHourOnly && _enableSecond0;

  @override
  int get step => _step ?? _defaultStep;

  @override
  void set step(int? s) => _step = s ?? _defaultStep;

  @override
  void set enableDayHourOnly(bool enable) => _enableDayHourOnly = enable;

  @override
  void set enable24HourTime(bool enable) => _in24Hour = enable;

  @override
  void set enableDay(bool enable) => _enableDay0 = enable;

  @override
  void set enableSecond(bool enable) => _enableSecond0 = enable;
  
  @override
  void set enableDefaultEmpty(bool enable) => _enableDefaultEmpty = enable;

  @override
  String get locale => _locale;

  @override
  void set locale(String locale) {
    if (_locale != locale) {
      _locale0 = locale;
    }
  }

  void set _locale0(String locale) {
    _locale = locale;
    _ampms = DateFormat.Hm(_locale).dateSymbols.AMPMS;
    if (_maxHour == null || _enableDay)
      input.removeAttribute('maxlength');
    else
      setInputMaxLength(input, 5 + (_in24Hour ? 0:
        1 + max(_ampms[0].length, _ampms[1].length)));//e.g. 00:00 AM
  }

  @override
  String get day  => _day == null ? _emptyVal : '$_day';

  @override
  String get hour => _hour == null ? _emptyVal : '${_hour! < 10 ? '0' : ''}$_hour';

  @override
  String get minute => _minute == null ? _emptyVal : '${_minute! < 10 ? '0' : ''}$_minute';
  
  @override
  String get second => _second == null ? _emptyVal : '${_second! < 10 ? '0' : ''}$_second';

  int _getFirstPartIndex(String value, [int min = 2]) {
    return max(min, value.replaceAll(_reNumFormat, '')
        .split(':')[0].length);
  }

   int get _dayEndIndex {
    final val = getInputValue(input) ?? '',
      day = _day;
    return _enableDay ? _getFirstPartIndex(val, 
      day != null && day < 10 ? 1: 2): 0;
   }

  int get _hourEndIndex {
    final val = getInputValue(input) ?? '';
    var start = 0;
    if (_enableDay) {
      start = _dayEndIndex + 1;
    }

    if (_maxHour == null)
      return _getFirstPartIndex(val.substring(start));

    return start + 2;
  }

  void _highlightUnit(QueryEvent event) {
    if (event.type == 'focus')//make click event high priority
      Timer.run(_highlightUnit0);
    else if (getInputSelectionStart(input) == getInputSelectionEnd(input))
      _highlightUnit0();
  }
  void _highlightUnit0() {
    final position = getCursorPosition(),
      hourIndex = _hourEndIndex;
    if (position >= 0 && position <= hourIndex) {
      var inDay = false;
      if (_enableDay) {
        final val = getInputValue(input) ?? '';
        if (position <= _getFirstPartIndex(val)) {
          inDay = true;
          highlightDay();
        }
      }

      if (!inDay)
        highlightHour();
    } else if (position >=(hourIndex + 1) && position <= (hourIndex + 3)) {
      highlightMinute();
    } else if (_enableSecond && position >=(hourIndex + 4) && position <= (hourIndex + 7)) {
      highlightSecond();
    } else if (position >= (hourIndex + 4 + (_enableSecond ? 3: 0))) {
      highlightAmPm();
    }
  }

  void highlightNextUnit(bool right) {
    switch(_highlightedUnit) {
      case _HighlightUnit.day:
        if (right)
          highlightHour();
        else if (!_in24Hour)
          highlightAmPm();
        break;
      case _HighlightUnit.hour:
        if (right) {
          if (_enableDayHourOnly)
            highlightAmPm();
          else
            highlightMinute();
        } else if (_enableDay)
          highlightDay();
        else if (!_in24Hour)
          highlightAmPm();
        break;
      case _HighlightUnit.minute:
        if (!right)
          highlightHour();
        else if (_enableSecond)
          highlightSecond();
        else if (!_in24Hour)
          highlightAmPm();
        else
          highlightMinute();
        break;
      case _HighlightUnit.second:
        if (!right)
          highlightMinute();
        else if (!_in24Hour)
          highlightAmPm();
        else
          highlightSecond();
        break;
      case _HighlightUnit.ampm:
        if (!_in24Hour) //just in case
          right ? _enableDay ? highlightDay(): highlightHour(): 
            _enableDayHourOnly ? highlightHour():
            _enableSecond ? highlightSecond(): highlightMinute();
        break;
      case null:
        break;
    }
  }

  @override
  void highlight() {
    if (_enableDay)
      highlightDay();
    else
      highlightHour();
  }

  @override
  void highlightDay() {
    _highlightedUnit = _HighlightUnit.day;
    Timer.run(_highlightDay);
  }

  void _highlightDay() {
    setSelectionRange(input, 0, _dayEndIndex);
  }

  //delay highlight to prevent unexpected browser behavior
  @override
  void highlightHour() {
    _highlightedUnit = _HighlightUnit.hour;
    Timer.run(_highlightHour);
  }

  void _highlightHour() {
    setSelectionRange(input, _enableDay ? (_dayEndIndex + 1): 0, _hourEndIndex);
  }

  @override
  void highlightMinute() {
    _highlightedUnit = _HighlightUnit.minute;
    Timer.run(_highlightMinute);
  }

  void _highlightMinute() {
    final index = _hourEndIndex;
    setSelectionRange(input, index + 1, index + 3);
  }

  @override
  void highlightSecond() {
    _highlightedUnit = _HighlightUnit.second;
    Timer.run(_highlightSecond);
  }

  void _highlightSecond() {
    final index = _hourEndIndex + 3;
    setSelectionRange(input, index + 1, index + 3);
  }

  @override
  void highlightAmPm() {
    if (_in24Hour) return;

    _highlightedUnit = _HighlightUnit.ampm;
    Timer.run(_highlightAmPm);
  }

  void _highlightAmPm() {
    setSelectionRange(input, _hourEndIndex 
      + (_enableSecond ? 6: _enableDayHourOnly ? 0: 3), 
      getInputMaxLength(input)!);
  }

  @override
  void toggleAmPm() {
    if (_in24Hour) return;

    _initTimeVars(_HighlightUnit.hour);
    var hour = _hour ?? DateTime.now().hour;
    _hour = hour += hour < 12 ? 12: -12;
    _syncAmPm();
  }

  void _syncAmPm() {
    final hour = _hour;
    if (hour != null)
      _ampmIndex = hour < 12 ? 0: 1;
  }

  void _initTimeVars(_HighlightUnit unit) {
    if (_second == null && unit != _HighlightUnit.second) _second = 0;
    if (_minute == null && unit != _HighlightUnit.minute) _minute = 0;
    if (_hour == null && unit != _HighlightUnit.hour) _hour = 0;
    if (_day == null && unit != _HighlightUnit.day) _day = 0;
  }

  @override
  void incrementDay(bool add) {
    if (!_enableDay) return;

    _initTimeVars(_HighlightUnit.day);
    _day = _day ?? 0;
     final newDay = _day! + (add ? 1 : -1);
     _day = max(newDay, 0);
  }

  @override
  void incrementHour(bool add) {
    _initTimeVars(_HighlightUnit.hour);
    _hour = _hour ?? (_maxHour == null ? 0: DateTime.now().hour);
    final newHour = _hour! + (add ? 1 : -1),
      maxHour = _maxHour;

    if (maxHour != null && (newHour > maxHour - 1 || newHour < 0)) {
      incrementDay(add);
      _hour = newHour < 0 ? maxHour - 1: 0;
    } else
      _hour = max(newHour, 0);

    _syncAmPm();
  }

  @override
  void incrementMinute(bool add) {
    _initTimeVars(_HighlightUnit.minute);
    _minute = _minute ?? 0;
    final newMin = _minute! + (add ? 1 : -1) * step;

    if (newMin > 59 || newMin < 0) {
      incrementHour(add);
      _minute = newMin + (add ? -1 : 1) * 60;
    } else
      _minute = newMin;
  }

  @override
  void incrementSecond(bool add) {
     _initTimeVars(_HighlightUnit.second);
    _second = _second ?? 0;
    final bakStep = step,
      newSec = _second! + (add ? 1 : -1) * step;

    if (newSec > 59 || newSec < 0) {
      step = 1;
      incrementMinute(add);
      step = bakStep;
      _second = newSec + (add ? -1 : 1) * 60;
    } else
      _second = newSec;
  }

  @override
  String get time {
    _syncAmPm();
    if (!_enableDefaultEmpty
        && _day == null && _hour == null && _minute == null
        && (!_enableSecond || _second == null)) {
      return '';
    }
    final hour0 = _hour,
      second0 = _enableSecond ? ':$second': '',
      day0 = _enableDay ? '$day:': '',
      time = _in24Hour ? _enableDayHourOnly ? hour: '$hour:$minute$second0':
        '${hour0 == null ? _emptyVal: hour0 == 0 ? '12':
        hour0 > 12 ? '${hour0 < 22 ? '0': ''}${hour0 - 12}': hour}'
        '${_enableDayHourOnly ? '': ':$minute$second0'} ${_ampms[_ampmIndex]}';

    return '$day0$time';
  }

  @override
  void set time(String? t) {
    if (t == null || t.isEmpty) {
      reset();
      return;
    }

    final parsedTime = parseTime(t, null);
    _day = _getParsedTime(parsedTime[0], null);
    _hour = _getParsedTime(parsedTime[1], _maxHour);
    _minute = _getParsedTime(parsedTime[2], _maxMinute);
    _second = _getParsedTime(parsedTime[3], _maxMinute);

    _syncAmPm();
    _updateInput();
  }

  int? _getParsedTime(int? parsedTime, int? max) {
    return parsedTime == null ? null:
      (max != null && parsedTime >= max) ? 0: parsedTime;
  }

  DateTime? _date;

  @override
  DateTime? get date {
    if (_hour == null || _minute == null) return null;

    //isUTC is true by default
    final isUTC = !(_date?.isUtc == false),
      d = _date ?? DateTime.now();

    return isUTC ? DateTime.utc(d.year, d.month, d.day, _hour!, _minute!, _second ?? 0) :
       DateTime(d.year, d.month, d.day, _hour!, _minute!, _second ?? 0);
  }

  @override
  void set date(DateTime? d) {
    _date = d;

    if (d == null) {
      reset();
      return;
    }

    _hour = d.hour;
    _minute = d.minute;
    _second = d.second;
    _syncAmPm();

    _updateInput();
  }

  @override
  int get days => _day ?? 0;

  @override
  void set days(int d) {
    _day = d;
    _updateInput();
  }


  @override
  List<int?> get timeValues {
    return parseTime(getInputValue(input), null);
  }


  List<int?> parseTime(String? time, [int? defaultValue = 0]) {
    if (time == null || time.isEmpty)
      return [null, null, null, null];

    final timeArray = time.replaceAll(_reNumFormat, '').split(':');
    int? d, h, m, s;
    var i = _enableDay ? 1: 0;

    try {
      d = _enableDay ? _string2int(timeArray[0], defaultValue): 0;
    } catch (e) {
      //array index out of bound
      d = defaultValue;
    }

    try {
      h = _string2int(timeArray[i], defaultValue);
      if (!_in24Hour && h != null && h > 12) {
        final m = h%10;
        return _enableDayHourOnly ? [d, 1, 0, 0]: 
          [d, 1, m > 5? m: m*10, s];
      }
    } catch (e) {
      //array index out of bound
      h = defaultValue;
    }

    try {
      m = _string2int(timeArray[i + 1], defaultValue);
    } catch (e) {
      //array index out of bound
      m = defaultValue;
    }

    try {
      s = _string2int(timeArray[i + 2], defaultValue);
    } catch (e) {
      //array index out of bound
      s = defaultValue;
    }
    return _enableDayHourOnly ? [d, h, 0, 0]: 
      [d, h, m, s];
  }

  static final _reNumFormat = RegExp('[^0-9\:]');

  void _updateInput() {
    setInputValue(input, time);
  }

  void _fireChange(_) {
    _updateInput();
    //trigger event
    $element.trigger('changeTime.bs.timepicker', data: {
      'time': time,
      'date': date,
      'day': _day,
      'hour': _hour,
      'minute': _minute,
    });
  }

  /**
   * Reset time picker to '00:00'
   */
  void reset() {
    _day = _hour = _minute = _second = null;
    _ampmIndex = 0;
    _updateInput();
  }

  DateTime? _wheelWhen;
  void _doMousewheel(WheelEvent event) {
    final now = DateTime.now();
    //shift too fast for trackpad
    if (_wheelWhen == null
        || now.difference(_wheelWhen!).inMilliseconds > 200) {
      _wheelWhen = now;
      _nextTimeStep(event.deltaY > 0);
    }
    event.stopPropagation();
    event.preventDefault();
  }

  void _onKeypress(QueryEvent e) {
    //prevent typing characters
    final code = e.charCode,
      inAmPm = _highlightedUnit == _HighlightUnit.ampm;
    if (!inAmPm && !($0 <= code && code <= $9) ) {
      e.preventDefault();
    }
  }

  void _onKeydown(QueryEvent e) {
    final key = e.keyCode,
      isNum = (key >= KeyCode.ZERO && key <= KeyCode.NINE) ||
              key >= KeyCode.NUM_ZERO && key <= KeyCode.NUM_NINE;
    //prevent typing any character except numbers
    if (!isNum) {
      switch (key) {
        case KeyCode.BACKSPACE:
        case KeyCode.DELETE:
          final cursorPos = getCursorPosition();
          //set time to null when hour or minute is cleared
          if (!rangeSelected()) {
            if (cursorPos == (_hourEndIndex + 1) || cursorPos == 0) {
              _day = _hour = _minute = _second = null;
              e.preventDefault();

              if (_enableDay)
                highlightDay();
              else
                highlightHour();

              _updateInput();
            } else if (cursorPos == (_hourEndIndex + 4)) {
              e.preventDefault();
              _ampmIndex = 0;
              _updateInput();
              highlightMinute();
            }
          }
          break;
        case KeyCode.TAB:
          _updateInput();
          break;
        case KeyCode.UP:
        case KeyCode.DOWN:
          e.preventDefault();
          _nextTimeStep(key == KeyCode.UP);
          break;
        case KeyCode.LEFT:
        case KeyCode.RIGHT:
          _updateInput();
          highlightNextUnit(key == KeyCode.RIGHT);
          break;
      }
    }
  }

  void _nextTimeStep(bool add) {
    final curStart = getInputSelectionStart(input) ?? 0,
      curEnd = getInputSelectionEnd(input) ?? 0;

    switch(_highlightedUnit) {
      case _HighlightUnit.day:
        incrementDay(add);
        highlightDay();
        break;
      case _HighlightUnit.hour:
        incrementHour(add);
        highlightHour();
        break;
      case _HighlightUnit.minute:
        incrementMinute(add);
        highlightMinute();
        break;
      case _HighlightUnit.second:
        incrementSecond(add);
        highlightSecond();
        break;
      case _HighlightUnit.ampm:
        highlightAmPm();
        toggleAmPm();
        break;
      case null:
        break;
    }
    _updateInput();
    setSelectionRange(input, curStart, curEnd);
  }

  void _onInput(QueryEvent event) {
    //in order to get new _hour & _minute, we call setTime without update input.value
    final val = getInputValue(input)!,
      parsedTime = parseTime(val, 0),
      parsedText = val.replaceAll(_reNumFormat, '').split(':'),
      newDay = parsedTime[0], 
      newHour = parsedTime[1], 
      newMinute = parsedTime[2] ?? 0, 
      newSecond = at(parsedTime, 3) ?? 0,
      index = _enableDay ? 1: 0;

    switch(_highlightedUnit) {
      case _HighlightUnit.day:
        _initTimeVars(_HighlightUnit.day);
        if (newDay == null)//empty string case
          _day = 0;
        else {
          _updateTime(newDay, null,
            save: (final val) => _day = val,
            shallHighlight: false);
        }
        break;
      case _HighlightUnit.hour:
        if (_day == null) _day = 0;
        if (_second == null) _second = 0;
        if (_minute == null) _minute = 0;
        if (newHour == null)//empty string case
          _hour = 0;
        else {
          final shallAppend0 = _in24Hour ? 2 : 1;
          _updateTime(newHour, _maxHour,
            save: (final val) {
              _hour = val;
              _minute = newMinute;
            },
            shallHighlight: _maxHour != null && (newHour > shallAppend0
              || (at(parsedText, index) ?? '').length > 1));
        }
        break;
      case _HighlightUnit.minute:
        if (_hour == null) incrementHour(true);
        if (_second == null) _second = 0;

        _updateTime(newMinute, _maxMinute,
            save: (final val) => _minute = val,
            shallHighlight: newMinute > 5
              || (at(parsedText, index + 1) ?? '').length > 1);
        break;
      case _HighlightUnit.second:
        if (_hour == null) incrementHour(true);
        if (_minute == null) _minute = 0;

        _updateTime(newSecond, _maxMinute,
            save: (final val) => _second = val,
            shallHighlight: newSecond > 5
              || (at(parsedText, index + 2) ?? '').length > 1);
        break;
      case _HighlightUnit.ampm:
        if (!_in24Hour) {
          if (val.length > (_hourEndIndex + (_enableSecond ? 7: _enableDayHourOnly ? 1: 4))) {
            if (_hour == null) incrementHour(true);
            final newAmPm = val.substring(_enableSecond ? 9: 6).toLowerCase();

            if (newAmPm == 'a' || newAmPm == _ampms[0].toLowerCase()[0]) {
              if (_hour! >= 12)
                toggleAmPm();
              _updateInput();
              highlightAmPm();
            } else if (newAmPm == 'p' || newAmPm == _ampms[1].toLowerCase()[0]) {
              if (_hour! < 12 || _hour == 0)
                toggleAmPm();
              _updateInput();
              highlightAmPm();
            } else {
              _updateInput();
              highlightAmPm();
            }
          } else {
          }
        }
        break;
      case null:
        break;
    }
  }


  void _updateTime(int value, int? max, {
      required bool shallHighlight,
      required void save(int value)}) {
    value = (max != null && value >= max) ? max - 1: value;
    save(value);
    if (shallHighlight) {
      _updateInput();
      highlightNextUnit(true);
    }
  }

  int getCursorPosition() {
    return getInputSelectionStart(input)!;
  }

  bool rangeSelected() {
    return (getInputSelectionEnd(input)! 
      - getInputSelectionStart(input)!) > 0;
  }
}

int? _string2int(String s, [int? defaultValue = 0]) {
  return int.tryParse(s) ?? defaultValue;
}

/*
String _date2time(DateTime date, [String defaultValue]) {
  String time = defaultValue;

  if (date != null) {
    time = '${date.hour < 10 ? '0' : ''}${date.hour}:${date.minute < 10 ? '0' : ''}${date.minute}';
  }

  return time;
}
*/

_data(value, Element elem, String name, [defaultValue]) =>
    value ?? elem.dataset[name] ?? defaultValue;

const _emptyVal = '––';

bool isInputElement(input)
  => input is InputElement || input is TextAreaElement;

String? getInputValue(input) {
  assert(isInputElement(input));
  return input != null ? input.value as String: null;
}

void setInputValue(input, String value) {
  assert(isInputElement(input));
  if (input != null)
    input.value = value;
}

int? getInputMaxLength(input) {
  assert(isInputElement(input));
  return input != null ? input.maxLength as int: null;
}

void setInputMaxLength(input, int value) {
  assert(isInputElement(input));
  if (input != null)
    input.maxLength = value;
}

void setSelectionRange(input, int start, int end) {
  assert(isInputElement(input));
  if (input != null)
    input.setSelectionRange(start, end);
}

int? getInputSelectionStart(input) {
  assert(isInputElement(input));
  return input != null ? input.selectionStart as int: null;
}

int? getInputSelectionEnd(input) {
  assert(isInputElement(input));
  return input != null ? input.selectionEnd as int: null;
}