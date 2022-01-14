part of bootjack_datepicker;

/** A calendar component.
 */
class Calendar extends Base {
  static const _name = 'calendar';
  
  static const day = 'day';
  static const month = 'month';
  static const year = 'year';
  
  static const _calendarTemplate = '''
<table class="cnt" width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr class="header">
    <th colspan="7">
      <a class="left-icon"><i class="icon-caret-left"></i></a>
      <a class="title"></a>
      <a class="right-icon"><i class="icon-caret-right"></i></a>
    </th>
  </tr>
</table>
''';
  static const _dowTemplate = '''
<tr class="dow">
  <th class="wkend"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkend"></th>
</tr>
''';
  static const _dowWithWeekNumbersTemplate = '''
<tr class="dow">
  <th class="wn"></th>
  <th class="wkend"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkday"></th>
  <th class="wkend"></th>
</tr>
''';
  static const _dayrowTemplate = '''
<tr class="dayrow">
  <td class="day wkend"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkend"></td>
</tr>
''';
  static const _dayrowWithWeekNumbersTemplate = '''
<tr class="dayrow">
  <td class="wn"></td>
  <td class="day wkend"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkday"></td>
  <td class="day wkend"></td>
</tr>
''';
  static const _cell12rowTemplate = '''
<tr class="cell12row">
  <td colspan="7">
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
    <span></span>
  </td>
</tr>
''';

  String _format;
  
  DateTime? _value, _currentValue;
  
  String? _date;
  
  String _locale;

  late int _firstDayOfWeek;
  int? _defaultFirstDayOfWeek;
  
  String _view;

  late DateFormat _dfmt;
  
  Function? _newDate;

  String get view => _view;

  /**
   * The date format of the calendar value.
   */
  String get format => _format;
  void set format(String format) {
    if (_format != format) {
      _format = format;
      _dfmt = DateFormat(_format, _locale);
    }
  }
  
  /**
   * The date format locale of the calendar value.
   */
  String get locale => _locale;
  void set locale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      _dfmt = DateFormat(_format, _locale);
    }
  }

  void set firstDayOfWeek(int firstDayOfWeek) {
    _firstDayOfWeek = firstDayOfWeek;
  }
  
  /**
   * The text value of selected date.
   */
  String? get date => _date;
  void set date(String? date) {
    if (_date != date) {
      _date = date;
      try {
        if (date != null)
          _value = _currentValue = _setDateValue(_dfmt.parse(date));
        _markCal();
      } on FormatException catch (_) {
        //_value = null; keep previous value
      }
    }
  }
  
  /**
   * The date value of selected date.
   */
  DateTime? get value => _value;
  void set value(DateTime? value) {
    if (_value != value) {

      _value = _currentValue = _setDateValue(value);
      _date = value != null ? _dfmt.format(value): null;
      _markCal();
    }
  }

  bool displayWeekNumbers = false;
  
  String? _dataTargetSelector;
  
  
  /** Construct a calendar object, wired to [element].
   * 
   * * [element] - the container to put the [Calendar].
   * * [format] - the date format for output string, default: yyyy/MM/dd
   * * [locale] - the date locale, default: [Intl.systemLocale]
   * * [firstDayOfWeek] - the first day of week, 
   * *   default: [DateFormat.dateSymbols.FIRSTDAYOFWEEK] from [locale]
   * * [value] - the selected [DateTime] value
   * * [dataTargetSelector] - the selector for [InputElement] to display date value
   * * [newDate] - the function to create [DateTime] value when select
   * * [displayWeekNumbers] - whether to show week numbers, default: false
   * 
   */
  Calendar(Element element, {String? format, String? date, String? locale, int? firstDayOfWeek,
    DateTime? value, String? dataTargetSelector, DateTime? newDate(y,m,d)?,
    bool? displayWeekNumbers}) :
  this._format = _data(format, element, 'format', 'yyyy/MM/dd')!,
  this._locale = _data(locale, element, 'date-locale', Intl.systemLocale)!,
  this._view = day,
  this._dataTargetSelector = _data(dataTargetSelector, element, 'target'),
  this._defaultFirstDayOfWeek = firstDayOfWeek,
  this._date = _data(date, element, 'date'),
  this._value = value,
  this._currentValue = value,
  this._newDate = newDate,
  this.displayWeekNumbers = displayWeekNumbers ?? element.dataset['weeknumbers'] == 'true',
  super(element, _name) {
    _initCalendar();
    _initDatepicker();
  }
  
  /** Retrieve the wired Calendar object from an element. If there is no wired
   * Calendar object, a new one will be created.
   * 
   * + [create] - If provided, it will be used for Calendar creation. Otherwise 
   * the default constructor with no optional parameter value is used.
   */
  static Calendar wire(Element element, [Calendar create()?]) =>
      p.wire(element, _name, create ?? (() => Calendar(element)));
  
  void _initCalendar() {
    _dfmt = DateFormat(this._format, this._locale);
    _firstDayOfWeek = _defaultFirstDayOfWeek ?? _dfmt.dateSymbols.FIRSTDAYOFWEEK;
    
    if (_date == null) {
      if (_value != null)
        _date = _dfmt.format(_value!);
    } else if (_value == null) {
      try {
        if (_date != null)
          _value = _currentValue = _setDateValue(_dfmt.parse(_date!));
      } on FormatException catch (_) {
        //_value = null; keep previous value
      }
    }
    
    element
    ..innerHtml = _calendarTemplate
    ..onMouseWheel.listen(_doMousewheel);
    
    $(element)
    ..on('click', _changeView, selector: '.title')
    ..on('click', _clickArrow, selector: '.left-icon')
    ..on('click', _clickArrow, selector: '.right-icon')
    
    ..on('click', _clickDate, selector: '.dayrow .day, .cell12row span');
    
    _setView(day);
  }
  
  void _initDatepicker() {
    Dropdown.use();
    $element.on('change.bs.calendar', _onCalChange);
    
    if (_dataTargetSelector != null) {
      querySelectorAll(_dataTargetSelector!).forEach(_bindCalendarValue);
    }
  }
  
  void _onCalChange(QueryEvent e) {//cal value to elements 
    if (_view != Calendar.day) return;
    
    if (_dataTargetSelector != null) {
      querySelectorAll(_dataTargetSelector!).forEach((Element elem) {
        if (elem is InputElement) {
          elem.value = _date;
          _updateChange(elem);//for clear error and fire change
        } else {
          //todo bind text to label? e.innerHtml = _date;
        }
      });
    }
    
    //Close dropdown
    if (e.data == null || e.data['shallClose'] != false) {
      var p = element.parent;
      if (p != null && (p = p.parent) != null && p!.classes.contains('open')) {
        $document().trigger('click.bs.dropdown.data-api');
      }
    }
  }
  
  void _bindCalendarValue(Element elem) {//element value to cal
    if (elem is InputElement) {
      elem.addEventListener("change", (_) => _updateChange(elem));
    }
  }
  
  void _updateChange(InputElement inp) {
    final text = inp.value!;
    try {
      final val = DateFormat(format, locale).parse(text);
      _clearError(inp);
      value = val;
    } on FormatException catch (_) {
      _markError(inp);
    }
   
    $(inp).trigger('change.bs.datepicker', data: {'value': value});
  }
  
  void _clearError(Element inp) {
    final p = inp.parent;
    if (p != null)
      p.classes.remove('has-error');
    $(inp).trigger('error.bs.datepicker');
  }
  
  void _markError(Element inp) {
    final p = inp.parent;
    if (p != null)
      p.classes.add('has-error');
  }
  
  void _setView(String view) {
    
    //clear tbody
    var dow = element.querySelector('.dow'),
      cell12row = element.querySelector('.cell12row'),
      dayrow = element.querySelectorAll('.dayrow');
    if (cell12row != null)
      cell12row.remove();
    if (dow != null)
      dow.remove();
    for (final e in dayrow) {
      e.remove();
    }

    //reset colspan
    final header = element.querySelector('.header > th') as TableCellElement?;
    header?.colSpan = 7;

    this._view = view;
    switch (view) {
    case day:
      _dayView();
      break;
    case month:
      _cell12View(_dfmt.dateSymbols.SHORTMONTHS);
      break;
    case year:
      final labels = <String>[];
      var y = _currentValue!.year,
        yofs = y - (y % 10 + 1);

      for (int i = 12; --i >= 0; yofs++) {
        labels.add('$yofs');
      }

      _cell12View(labels);
      break;
    }
    _markCal();
  }
  
  void _dayView() {
    final calBody = element.querySelector('.cnt') as TableElement,
      dowTemplate = displayWeekNumbers ? _dowWithWeekNumbersTemplate : _dowTemplate,
      dayrowTemplate = displayWeekNumbers ? _dayrowWithWeekNumbersTemplate : _dayrowTemplate,
      startPos = displayWeekNumbers ? 1 : 0,
      dow = calBody.tBodies[0].createFragment(dowTemplate).children[0],
      children = dow.children,
      swkDays = _dfmt.dateSymbols.SHORTWEEKDAYS,
      ofs = (_firstDayOfWeek + 1) % 7;

    final header = element.querySelector('.header > th') as TableCellElement;
    header.colSpan = displayWeekNumbers ? 8 : 7;

    //render week days
    for (var i = swkDays.length; --i >= 0;) {
      children[startPos + i].text = swkDays[(i + ofs) % 7];
    }

    final buffer = StringBuffer();
    for (var i = 6; --i >= 0;) {
      buffer.write(dayrowTemplate);
    }
    
    calBody.tBodies[0]
    ..append(dow)
    ..appendHtml(buffer.toString(), treeSanitizer: NodeTreeSanitizer.trusted);
  }
  
  void _cell12View(List<String> labels) {
    final body = (element.querySelector('.cnt') as TableElement).tBodies.first,
      cell12row = body.createFragment(_cell12rowTemplate).children[0],
      children = cell12row.children.first.children;
    
    //render month
    for (int i = labels.length; --i >= 0;) {
      children[i].text = labels[i];
    }
    
    body.append(cell12row);
  }
  
  void _markCal() {
    final seld = element.querySelector('.cnt .seld');
    if (seld != null)
      seld.classes.remove('seld');

    final todayElem = element.querySelector('.cnt .today');
    if (todayElem != null)
      todayElem.classes.remove('today');

    final isNullValue = _value == null;

    final today = _setDateValue(todayUtc())!;
    if (_currentValue == null)
      _currentValue = today;

    final y = _currentValue!.year,
      m = _currentValue!.month,
      title = element.querySelector('.title')!;
    
    if (_view == day) {

      var beginDate = _newDateTime(y, m, 1, true),
       ofs = beginDate.weekday - ((_firstDayOfWeek + 1) % 7);
      if (ofs < 0)
        ofs += 7;
      
      beginDate = beginDate.subtract(new Duration(days: ofs));

      final inTodayRange = _inDayViewRange(beginDate, today),
        inSelectedDayRange = _value == null ? false: _inDayViewRange(beginDate, _value!);
      
      title.text = '${_dfmt.dateSymbols.SHORTMONTHS[m - 1]} $y';
      final dayrow = element.querySelectorAll('.dayrow'),
        outside = element.querySelectorAll('.dayrow td.outside');
      for (final e in outside) {
        e.classes.remove('outside');
      }
      
      for (final row in dayrow) {
        final len = row.children.length;
        for (var i = 0; i < len; i++) {
          final td = row.children[i];
          if (i == 0 && displayWeekNumbers) { // Week numbers
            td.text = getWeekOfYear(beginDate, _firstDayOfWeek).toString();
            renderWeekNumber(td);
            continue;
          }

          td.text = '${beginDate.day}';
          renderDay(td, beginDate);
          
          var monofs = 0;
          if (beginDate.month != m) {
            td.classes.add('outside');
            
            int curY = beginDate.year;
            if (curY == y) {
              monofs = beginDate.month > m ? 1: -1;
            } else {
              monofs = curY > y ? 1: -1;
            }
          }
          $(td).data.set('monofs', monofs);
          
          if (inSelectedDayRange && beginDate.month == _value!.month
              && beginDate.day == _value!.day){
            td.classes.add('seld');
            renderSelectedDay(td);
          }
          
          if (inTodayRange && beginDate.month == today.month && beginDate.day == today.day) {
            td.classes.add('today');
            renderToDay(td);
          }
          
          beginDate = _newDateTime(beginDate.year, beginDate.month, beginDate.day + 1, true);
        }
      }

      
    } else {
      
      final isMon = _view == month,
        valY = (_value ?? _currentValue)!.year;

      var index = isMon? m - 1: y % 10 + 1,
        yofs = 0;
      
      if (isMon)
        title.text = '$y';
      else {
        yofs = y - index;
        title.text = '$yofs-${yofs + 11}';
        yofs += 11;
      }

      var inSelectedDayRange = isNullValue ? false: _currentValue!.year == valY;
      
      if (!isNullValue) {
        if (isMon) {
          index = _value!.month - 1;
        } else {
          inSelectedDayRange = (yofs - 11) <= valY && valY <= yofs;
          index = valY  - yofs + 11;
        }
      }

      List<Element> cell12row = element.querySelectorAll('.cell12row span');
      for (var i = cell12row.length; --i >= 0; yofs--) {
        final cell = cell12row[i];
        if (!isMon)
          cell.text = '$yofs';

        final date = isMon ? _newDateTime(valY, i + 1, 1, true): _newDateTime(yofs, 1, 1, true);
        renderDay(cell, date);
        if (inSelectedDayRange && index == i) {
          cell.classes.add('seld');
          renderSelectedDay(cell12row[i]);
        }
      }
    }
    
    $element.trigger('changView.bs.calendar', data: {'value': _currentValue, 'view': _view});
  }
  
  bool _inDayViewRange(DateTime beginDate, DateTime date) {
    int days = beginDate.difference(date).inDays;
    if (-42 < days && days < 1)
      return true;
    return false;
  }

  void renderDay(Element elem, DateTime date) {

  }
  
  void renderSelectedDay(Element elem) {
    
  }
  
  void renderToDay(Element elem) {
    
  }

  void renderWeekNumber(Element elem) {

  }

  DateTime? _wheelWhen;
  void _doMousewheel(WheelEvent event) {
    final now = DateTime.now();
    //shift too fast for trackpad
    if (_wheelWhen == null
        || now.difference(_wheelWhen!).inMilliseconds > 200) {
      _wheelWhen = now;
      _shiftView(event.deltaY > 0 ? 1: -1);
    }
    event.stopPropagation();
    event.preventDefault();
  }
  
  void _clickArrow(QueryEvent evt) {
    _shiftView((evt.currentTarget as Element)
        .classes.contains('left-icon') ? -1: 1);
    evt.stopPropagation();
  }
  
  void _shiftView(int ofs) {
    switch (this._view) {
    case day:
      _shiftDate(month, ofs);
      break;
    case month:
      _shiftDate(year, ofs);
      break;
    case year:
      _shiftDate(year, ofs * 10);
      break;
    }
    _markCal();
    
    $element.trigger('shiftView.bs.calendar', data: {'value': _currentValue, 'view': _view});
  }
  
  void _shiftDate (String opt, int ofs) {
    final val = _currentValue != null ? _currentValue!: _setDateValue(todayUtc())!;
    
    int y = val.year;
    int m = val.month;
    int d = val.day;
    bool nofix = false;
    switch(opt) {
    case day :
      d += ofs;
      nofix = true;
      break;
    case month :
      m += ofs;
      break;
    case year :
      y += ofs;
      break;
    }
    
    _currentValue = _newDate0(y, m ,d, !nofix);
//    $element.trigger('change.bs.calendar', 
//        data: {'value': value, 'view': this._view, 'shallClose': false, 'shiftDate': true});
  }
  
  void _changeView(QueryEvent evt) {
    switch (this._view) {
      case day:
        _setView(month);
        break;
      case month:
        _setView(year);
        break;
      case year:
        break;
    }
    evt.stopPropagation();
  }

  void _clickDate(QueryEvent evt) {
    final val = _currentValue ?? _setDateValue(todayUtc())!,
      target = $(evt.target);

    switch (this._view) {
    case day:
      _setTime(null, (val.month + target.data.get("monofs") as int), int.tryParse(target.text), true);
      _markCal();
      break;
    case month:
      _setTime(null, $('.cell12row span').indexOf(evt.target as Element) + 1);
      _setView(day);
      break;
    case year:
      _setTime(int.tryParse(target.text));
      _setView(month);
      break;
    }
    evt.stopPropagation();
  }
  
  void _setTime(int? y, [int? m, int? d, bool readValue = false]) {
    final val = _currentValue ?? _setDateValue(todayUtc())!,
      year = y ?? val.year,
      month = m ?? val.month,
      day = d ?? val.day;
    
    _currentValue = _newDate0(year, month, day, d == null);
    
    if (readValue) {
      value = _newDate != null ? _newDate!(year, month, day): _currentValue;
      $element.trigger('change.bs.calendar', data: {'value': value, 'view': this._view});
    }
  }
  
  DateTime _newDate0(int year, int month, int day, bool bFix) {
    final v = DateTime(year, month, day);
    return _setDateValue(bFix && v.month != month && v.day != day ?
      _newDateTime(year, month + 1, 0, true): v)!/*last day of month*/;
  }
    
  static DateTime _newDateTime(int year, int month, int day, bool isUtc)
    => isUtc ? DateTime.utc(year, month, day): DateTime(year, month, day);
      
  static DateTime todayUtc() {
    final today = DateTime.now();
    return DateTime.utc(today.year, today.month, today.day);
  }
  
  static DateTime? _setDateValue(DateTime? date) {
    if (date == null) return null;
    
    return DateTime.utc(date.year, date.month, date.day, 12);
  }
  
  /**
   * Make calendar back to day view and selected date.
   */
  void reset() {
    _currentValue = _value;
    _setView(day);
  }
  
  // Data API //
  static bool _registered = false;
  
  /** Register to use Calendar component.
   */
  static void use() {
    if (_registered) return;
    _registered = true;
    
    $window().on('load', (QueryEvent e) {
      for (final elem in $('[class~="calendar"]')) {
        Calendar.wire(elem);
      }
    });
  }
}

_data(value, Element elem, String name, [defaultValue]) =>
    value ?? elem.dataset[name] ?? defaultValue;

/// Returns a 0-based [weekday] index, according to [firstDayOfWeek].
/// * [weekday] should be [DateTime.weekday] (1-based)
/// * [firstDayOfWeek] is 0-based (0 is Monday, 6 is Sunday)
int weekDayReIndex(int weekday, int firstDayOfWeek)
=> (((weekday - DateTime.monday) - firstDayOfWeek) + 7) % 7;

/// Get the week number of year of [date].
/// ref: https://stackoverflow.com/a/6117889
/// * [firstDayOfWeek] is 0-based (0 is Monday, 6 is Sunday), default is Monday (ISO 8601)
int getWeekOfYear(DateTime date, [int firstDayOfWeek = 0]) {
  final midnight = DateTime.utc(date.year, date.month, date.day),
    daysDiff = weekDayReIndex(DateTime.thursday, firstDayOfWeek) - weekDayReIndex(date.weekday, firstDayOfWeek),
    thursday = midnight.add(Duration(days: daysDiff)),
    yearStart = DateTime.utc(thursday.year, DateTime.january , 1),
    millisDiff = thursday.millisecondsSinceEpoch - yearStart.millisecondsSinceEpoch;
  return (((millisDiff / 86400000) + 1) / 7).ceil();
}
