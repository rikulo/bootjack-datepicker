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
      String time, DateTime date, int step, bool enable24HourTime})
    => new _TimePickerImpl(element, time: time, date: date,
        step: step, enable24HourTime: enable24HourTime);

  /** Get time with format: '00:00'.
   */
  String get time;

  /** Set time with format: '00:00'.
   */
  set time(String t);

  /** Get date.
   */
  DateTime get date;

  /** Set date.
   */
  set date(DateTime d);

  /** Get step for minute field
   */
  int get step;

  /** Set step for minute field
   */
  void set step(int s);

  void set enable24HourTime(bool enable);

  /**
   * The date format locale of the calendar value.
   */
  String get locale;
  void set locale(String locale);

  void highlightHour();
  void highlightMinute();
  void highlightAmPm();
  void incrementHour(bool add);
  void incrementMinute(bool add);
  void toggleAmPm();

  /** Retrieve the wired TimePicker object from an element. If there is no wired
   * TimePicker object, a new one will be created.
   *
   * + [create] - If provided, it will be used for TimePicker creation. Otherwise
   * the default constructor with no optional parameter value is used.
   */
  static TimePicker wire(Element element, [TimePicker create()]) =>
      p.wire(element, _name, create ?? (() => new TimePicker(element)));

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

enum _HighlightUnit {hour, minute, ampm}

/** A time picker component.
 */
class _TimePickerImpl extends Base implements TimePicker {

  static const _defaultStep = 5;
  static const _maxHour = 24;
  static const _maxMinute = 60;

  _TimePickerImpl(Element element, {String time, DateTime date, int step, bool enable24HourTime}):
  super(element, TimePicker._name) {
    $element
    ..on('keydown', _onKeydown)
    ..on('input', _onInput)
    ..on('focus click', _highlightUnit)
    ..on('blur', _fireChange);

    this.enable24HourTime = enable24HourTime ?? element.dataset['date-24'] == 'true';
    this.locale = _data(locale, element, 'date-locale', Intl.systemLocale);


    //input.value count on
    //1. date, 2. time, 3. data attribute
    this.time = _data(time, element, 'time', '––:––');
    if (date != null) this.date = date;

    this.step = step;
  }

  InputElement get input => element as InputElement;
  int _hour, _minute, _step, _ampmIndex = 0;
  _HighlightUnit _highlightedUnit;
  bool _in24Hour = false;
  String _locale;
  List<String> _ampms;

  @override
  int get step => _step ?? _defaultStep;

  @override
  void set step(int s) => _step = s ?? _defaultStep;

  @override
  void set enable24HourTime(bool enable) => _in24Hour = enable == true;

  @override
  String get locale => _locale;

  @override
  void set locale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      _ampms = new DateFormat.Hm(_locale).dateSymbols.AMPMS;
      input.maxLength = 5 + (_in24Hour ? 0:
        1 + max(_ampms[0].length, _ampms[1].length));//e.g. 00:00 AM
    }
  }

  /**
   * Get value of hour field.
   */
  String get hour => _hour == null ? _emptyVal : '${_hour < 10 ? '0' : ''}$_hour';

  /**
   * Get value of minute field.
   */
  String get minute => _minute == null ? _emptyVal : '${_minute < 10 ? '0' : ''}$_minute';

  void _highlightUnit(QueryEvent event) {
    if (event.type == 'focus')//make click event high priority
      Timer.run(_highlightUnit0);
    else
      _highlightUnit0();
  }
  void _highlightUnit0() {
    final position = getCursorPosition();
    if (position >= 0 && position <= 2) {
      highlightHour();
    } else if (position >=3 && position <= 5) {
      highlightMinute();
    } else if (position >= 6) {
      highlightAmPm();
    }
  }

  void highlightNextUnit(bool right) {
    switch(_highlightedUnit) {
      case _HighlightUnit.hour:
        if (right)
          highlightMinute();
        else if (!_in24Hour)
          highlightAmPm();
        break;
      case _HighlightUnit.minute:
        if (!right)
          highlightHour();
        else if (!_in24Hour)
          highlightAmPm();
        else
          highlightMinute();
        break;
      case _HighlightUnit.ampm:
        if (!_in24Hour) //just in case
          right ? highlightHour(): highlightMinute();
        break;
    }
  }

  //delay highlight to prevent unexpected browser behavior
  @override
  void highlightHour() {
    _highlightedUnit = _HighlightUnit.hour;
    Timer.run(() => input.setSelectionRange(0, 2));
  }

  @override
  void highlightMinute() {
    _highlightedUnit = _HighlightUnit.minute;
    Timer.run(() => input.setSelectionRange(3, 5));
  }

  @override
  void highlightAmPm() {
    if (_in24Hour)
      return;

    _highlightedUnit = _HighlightUnit.ampm;
    Timer.run(() => input.setSelectionRange(6, input.maxLength));
  }

  @override
  void toggleAmPm() {
    if (_in24Hour)
      return;

    if (_minute == null) _minute = 0;
    _hour = _hour ?? new DateTime.now().hour;
    _hour +=  _hour < 12 ? 12: -12;
    _syncAmPm();
  }

  void _syncAmPm() {
    if (_hour != null)
      _ampmIndex = _hour < 12 ? 0: 1;
  }

  @override
  void incrementHour(bool add) {
    if (_minute == null) _minute = 0;
    _hour = _hour ?? new DateTime.now().hour;
    final newHour = _hour + (add ? 1 : -1);

    if (newHour > _maxHour - 1 || newHour < 0) {
      _hour = newHour < 0 ? _maxHour - 1: 0;
    } else
      _hour = newHour;

    _syncAmPm();
  }

  @override
  void incrementMinute(bool add) {
    if (_hour == null) incrementHour(true);
    _minute = _minute ?? 0;
    final newMin = _minute + (add ? 1 : -1) * step;

    if (newMin > 59 || newMin < 0) {
      incrementHour(add);
      _minute = newMin + (add ? -1 : 1) * 60;
    } else
      _minute = newMin;
  }

  @override
  String get time {
    _syncAmPm();
    return _in24Hour ? '$hour:$minute':
      '${_hour == null ? _emptyVal: _hour == 0 ? '12':
      _hour > 12 ? '${_hour < 22 ? '0': ''}${_hour - 12}': hour}:$minute ${_ampms[_ampmIndex]}';
  }

  @override
  void set time(String t) {
    if (t == null || t.isEmpty) {
      reset();
      return;
    }

    final parsedTime = parseTime(t, null);
    _hour = parsedTime[0] == null ? null : parsedTime[0] >= _maxHour ? 0 : parsedTime[0];
    _minute = parsedTime[1] == null ? null : parsedTime[1] >= _maxMinute ? 0 : parsedTime[1];
    _syncAmPm();

    _updateInput();
  }

  DateTime _date;

  @override
  DateTime get date {
    if (_hour == null || _minute == null) return null;

    //isUTC is true by default
    bool isUTC = !(_date?.isUtc == false);
    DateTime d = _date ?? new DateTime.now();

    return isUTC ? new DateTime.utc(d.year, d.month, d.day, _hour, _minute) :
                   new DateTime(d.year, d.month, d.day, _hour, _minute);
  }

  @override
  void set date(DateTime d) {
    _date = d;

    if (d == null) {
      reset();
      return;
    }

    _hour = d.hour;
    _minute = d.minute;
    _syncAmPm();

    _updateInput();
  }

  List<int> parseTime(String time, [int defaultValue = 0]) {
    if (time == null || time.isEmpty)
      return [null, null];

    final timeArray = time.replaceAll(_reNumFormat, '').split(':');
    int h, m;

    try {
      h = _string2int(timeArray[0], defaultValue);
      if (!_in24Hour && h > 12) {
        final m = h%10;
        return [1, m > 5? m: m*10];
      }
    } catch (e) {
      //array index out of bound
      h = defaultValue;
    }

    try {
      m = _string2int(timeArray[1], defaultValue);
    } catch (e) {
      //array index out of bound
      m = defaultValue;
    }
    return [h, m];
  }

  static final RegExp _reNumFormat = new RegExp('[^0-9\:]');

  void _updateInput() {
    input.value = time;
  }

  void _fireChange(_) {
    _updateInput();
    //trigger event
    $element.trigger('changeTime.bs.timepicker', data: {
      'time': time,
      'date': date,
      'hour': _hour,
      'minute': _minute,
    });
  }

  /**
   * Reset time picker to '00:00'
   */
  void reset() {
    _hour = null;
    _minute = null;
    _ampmIndex = 0;
    _updateInput();
  }

  void _onKeydown(QueryEvent e) {
    final key = e.keyCode,
          inAmPm = _highlightedUnit == _HighlightUnit.ampm,
          isNum = (key >= KeyCode.ZERO && key <= KeyCode.NINE) ||
                  key >= KeyCode.NUM_ZERO && key <= KeyCode.NUM_NINE;
    //prevent typing any character except numbers
    if (!isNum) {
      switch (key) {
        case KeyCode.BACKSPACE:
        case KeyCode.DELETE:
          int cursorPos = getCursorPosition();
          //set time to null when hour or minute is cleared
          if (!rangeSelected()) {
            if (cursorPos == 3 || cursorPos == 0) {
              _hour = null;
              _minute = null;
              e.preventDefault();
              highlightHour();
              _updateInput();
            } else if (cursorPos == 6) {
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
          switch(_highlightedUnit) {
            case _HighlightUnit.hour:
              incrementHour(key == KeyCode.UP);
              highlightHour();
              break;
            case _HighlightUnit.minute:
              incrementMinute(key == KeyCode.UP);
              highlightMinute();
              break;
            case _HighlightUnit.ampm:
              highlightAmPm();
              toggleAmPm();
              break;
          }
          _updateInput();
          break;
        case KeyCode.LEFT:
        case KeyCode.RIGHT:
          _updateInput();
          highlightNextUnit(key == KeyCode.RIGHT);
          break;
        default:
          //prevent typing characters
          if (!inAmPm)
            e.preventDefault();
          break;
      }
    }
  }

  void _onInput(QueryEvent event) {
    //in order to get new _hour & _minute, we call setTime without update input.value
    final val = input.value,
          parsedTime = parseTime(val, 0),
          parsedText = val.replaceAll(_reNumFormat, '').split(':'),
          newHour = parsedTime[0], newMinute = parsedTime[1];

    switch(_highlightedUnit) {
      case _HighlightUnit.hour:
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
            shallHighlight: newHour > shallAppend0
              || parsedText[0].length > 1);
        }
        break;
      case _HighlightUnit.minute:
        if (_hour == null) incrementHour(true);

        _updateTime(newMinute, _maxMinute,
            save: (final val) => _minute = val,
            shallHighlight: newMinute > 5
              || parsedText[1].length > 1);
        break;
      case _HighlightUnit.ampm:
        if (!_in24Hour) {
          if (val.length > 6) {
            if (_hour == null) incrementHour(true);
            final newAmPm = val.substring(6).toLowerCase();

            if (newAmPm == 'a' || newAmPm == _ampms[0].toLowerCase()[0]) {
              if (_hour >= 12)
                toggleAmPm();
              _updateInput();
              highlightAmPm();
            } else if (newAmPm == 'p' || newAmPm == _ampms[1].toLowerCase()[0]) {
              if (_hour < 12 || _hour == 0)
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

        if (!_in24Hour && val.length > 7) {//just in case

        }
        break;
    }
  }


  void _updateTime(int value, int max, {bool shallHighlight, void save(int value)}) {
    value = value >= max ? max - 1: value;
    save(value);
    if (shallHighlight) {
      _updateInput();
      highlightNextUnit(true);
    }
  }

  int getCursorPosition() {
    return input.selectionStart;
  }

  bool rangeSelected() {
    return input.selectionEnd - input.selectionStart > 0;
  }
}

int _string2int(String s, [int defaultValue = 0]) {
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
    value ?? elem.attributes["data-$name"] ?? defaultValue;

const _emptyVal = '––';