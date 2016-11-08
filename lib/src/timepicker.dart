part of bootjack_timepicker;

abstract class TimePicker {
  static const String _NAME = 'timepicker';

  /** Construct a TimePicker object, wired to [element].
   *
   * * [element] - the container to put the [TimePicker].
   * * [time] - the time displayed on input, legal format: '12:25'
   * * [step] - specify a step for the minute field.
   *
   */
  factory TimePicker(Element element, {String time, DateTime date, int step}) => new _TimePickerImpl(element, time: time, date: date, step: step);

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
  set step(int s);

  void highlightHour();
  void highlightMinute();
  void incrementHour(bool add);
  void incrementMinute(bool add);

  /** Retrieve the wired TimePicker object from an element. If there is no wired
   * TimePicker object, a new one will be created.
   *
   * + [create] - If provided, it will be used for TimePicker creation. Otherwise
   * the default constructor with no optional parameter value is used.
   */
  static TimePicker wire(Element element, [TimePicker create()]) =>
      p.wire(element, _NAME, p.fallback(create, () => () => new TimePicker(element)));

  // Data API //
  static bool _registered = false;

  /** Register to use TimePicker component.
   */
  static void use() {
    if (_registered) return;
    _registered = true;

    $window().on('load', (QueryEvent e) {
      for (Element elem in $('[class~="timepicker"]')) {
        TimePicker.wire(elem);
      }
    });
  }
}

/** A time picker component.
 */
class _TimePickerImpl extends Base implements TimePicker {

  static const String HOUR = 'hour';
  static const String MINUTE = 'minute';
  static const int DEFAULT_STEP = 5;
  static const int MAXHOUR = 24;
  static const int MAXMINUTE = 60;

  _TimePickerImpl(Element element, {String time, DateTime date, int step}) : super(element, TimePicker._NAME) {
    $element
    ..on('keydown', _onKeydown)
    ..on('input', _onInput)
    ..on('focus click', _highlightUnit)
    ..on('blur', _fireChange);

    input.maxLength = 5;

    //input.value count on
    //1. date, 2. time, 3. data attribute
    this.time = _data(time, element, 'time', '00:00');
    if (date != null) this.date = date;

    this.step = step;
  }

  InputElement get input => element as InputElement;
  int _hour, _minute, _step;
  String _highlightedUnit;

  @override
  int get step => _step ?? DEFAULT_STEP;

  @override
  set step(int s) => _step = s ?? DEFAULT_STEP;

  /**
   * Get value of hour field.
   */
  String get hour {
    return '${_hour < 10 ? '0' : ''}$_hour';
  }

  /**
   * Get value of minute field.
   */
  String get minute {
    return '${_minute < 10 ? '0' : ''}$_minute';
  }

  void _highlightUnit(QueryEvent event) {
    int position = getCursorPosition();
    if (position >= 0 && position <= 2) {
      highlightHour();
    } else if (position >=3 && position <= 5) {
      highlightMinute();
    }
  }

  void highlightNextUnit() => _highlightedUnit == MINUTE ? highlightHour() : highlightMinute();

  //delay highlight to prevent unexpected browser behavior
  void highlightHour() {
    _highlightedUnit = HOUR;
    Timer.run(() => input.setSelectionRange(0, 2));
  }

  void highlightMinute() {
    _highlightedUnit = MINUTE;
    Timer.run(() => input.setSelectionRange(3, 5));
  }

  void incrementHour(bool add) {
    _hour += add ? 1 : -1;
    if (_hour == MAXHOUR) _hour = 0;
    else if (_hour < 0) _hour = MAXHOUR - 1;
  }

  void incrementMinute(bool add) {
    int newMin = _minute + (add ? 1 : -1) * step;

    if (newMin > 59 || newMin < 0) {
      incrementHour(add);
      _minute = newMin + (add ? -1 : 1) * 60;
    } else
      _minute = newMin;
  }

  @override
  String get time => '$hour:$minute';

  @override
  set time(String t) {
    if (t == null || t.isEmpty) {
      reset();
      return;
    }

    final parsedTime = parseTime(t);
    _hour = parsedTime[0] >= MAXHOUR ? 0 : parsedTime[0];
    _minute = parsedTime[1] >= MAXMINUTE ? 0 : parsedTime[1];

    _updateInput();
  }

  DateTime _date;

  @override
  DateTime get date {
    //isUTC is true by default
    bool isUTC = !(_date?.isUtc == false);
    DateTime d = _date ?? new DateTime.now();

    return isUTC ? new DateTime.utc(d.year, d.month, d.day, _hour, _minute) :
                   new DateTime(d.year, d.month, d.day, _hour, _minute);
  }

  @override
  set date(DateTime d) {
    _date = d;

    if (d == null) {
      reset();
      return;
    }

    _hour = d.hour;
    _minute = d.minute;

    _updateInput();
  }

  List<int> parseTime(String time) {
    final timeArray = time.replaceAll(_reNumFormat, '').split(':');
    int h, m;

    try {
      h = _string2int(timeArray[0]);
    } catch (e) {
      //array index out of bound
      h = 0;
    }

    try {
      m = _string2int(timeArray[1]);
    } catch (e) {
      //array index out of bound
      m = 0;
    }
    return [h, m];
  }

  static final RegExp _reNumFormat = new RegExp('[^0-9\:]');

  void _updateInput() {
    input.value = time;
  }

  void _fireChange(_) {
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
    _hour = 0;
    _minute = 0;
    input.value = time;
  }

  void _onKeydown(QueryEvent e) {
    final key = e.keyCode;
    final isNum = (key >= KeyCode.ZERO && key <= KeyCode.NINE) ||
                  key >= KeyCode.NUM_ZERO && key <= KeyCode.NUM_NINE;
    //prevent typing any character except numbers
    if (!isNum) {
      switch (key) {
        case KeyCode.BACKSPACE:
          if (getCursorPosition() == 3 && !rangeSelected())
            e.preventDefault();
          break;
        case KeyCode.TAB:
          _updateInput();
          break;
        case KeyCode.UP:
        case KeyCode.DOWN:
          if (_highlightedUnit == HOUR) {
            incrementHour(key == KeyCode.UP);
            highlightHour();
          } else if (_highlightedUnit == MINUTE) {
            incrementMinute(key == KeyCode.UP);
            highlightMinute();
          }
          _updateInput();
          break;
        case KeyCode.LEFT:
        case KeyCode.RIGHT:
          _updateInput();
          highlightNextUnit();
          break;
        default:
          //prevent typing characters
          e.preventDefault();
          break;
      }
    }
  }

  void _onInput(QueryEvent event) {
    int oldHour = _hour;
    //in order to get new _hour & _minute, we call setTime without update input.value
    final parsedTime = parseTime(input.value);
    int newHour = parsedTime[0], newMinute = parsedTime[1];

    if (_highlightedUnit == HOUR) {
      if (newHour > MAXHOUR) {
        //not allow input hour > 24
        //change input.value to old value, and set cursor to previous position
        _hour = oldHour;
        input.value = '$_hour:$minute';
        input.setSelectionRange(1, 1);
      } else if (newHour >= 3) {
        _hour = newHour == MAXHOUR ? 0 : newHour;
        _updateInput(); //update input.value with legal format (ex. two digit for every unit)
        highlightNextUnit();
      } else
        _hour = newHour; //update _hour, so press RIGHT will update input.value with correct unit
    } else if (_highlightedUnit == MINUTE) {
      if (newMinute >= 6) {
        _minute = newMinute == MAXMINUTE ? 0 : newMinute;
        _updateInput();
        highlightMinute();
      } else
        _minute = newMinute;
    }
  }

  int getCursorPosition() {
    return input.selectionStart;
  }

  bool rangeSelected() {
    return input.selectionEnd - input.selectionStart > 0;
  }
}

int _string2int(String s, [int defaultValue]) {
  return int.parse(s, onError: (_) => defaultValue ?? 0);
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
    p.fallback(value, () => elem.attributes["data-$name"], () => defaultValue);
