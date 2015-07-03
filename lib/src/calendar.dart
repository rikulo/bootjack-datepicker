part of bootjack_datepicker;

/** A calendar component.
 */
class Calendar extends Base {
  static const String _NAME = 'calendar';
  
  static const String DAY = 'day';
  static const String MONTH = 'month';
  static const String YEAR = 'year';
  
  static const String _CALENDAR_TEMPLATE = '''
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
  static const String _DOW_TEMPLATE = '''
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
  static const String _DAYROW_TEMPLATE = '''
<tr class="dayrow">
  <td class="wkend"></td>
  <td class="wkday"></td>
  <td class="wkday"></td>
  <td class="wkday"></td>
  <td class="wkday"></td>
  <td class="wkday"></td>
  <td class="wkend"></td>
</tr>
''';
  static const String _CELL12ROW_TEMPLATE = '''
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
  
  DateTime _value, _currentValue;
  
  String _date;
  
  String _locale;
  
  int _firstDayOfWeek;
  
  String _view;
  
  DateFormat _dfmt;
  
  Function _newDate;
  
  /**
   * The date format of the calendar value.
   */
  String get format => _format;
  void set format(String format) {
    if (_format != format) {
      _format = format;
      _dfmt = new DateFormat(_format, _locale);
    }
  }
  
  /**
   * The date format locale of the calendar value.
   */
  String get locale => _locale;
  void set locale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      _dfmt = new DateFormat(_format, _locale);
    }
  }
  
  /**
   * The text value of selected date.
   */
  String get date => _date;
  void set date(String date) {
    if (_date != date) {
      _date = date;
      if (_dfmt != null) {
        try {
          _value = _currentValue = _setDateValue(_dfmt.parse(date));
          _markCal();
        } on FormatException catch (_) {
          //_value = null; keep previous value
        }
      }
    }
  }
  
  /**
   * The date value of selected date.
   */
  DateTime get value => _value;
  void set value(DateTime value) {
    if (_value != value) {
      _value = _currentValue = _setDateValue(value);
      if (_dfmt != null) {
        _date = value != null ? _dfmt.format(value): null;
        _markCal();
      }
    }
  }
  
  String _dataTargetSelector;
  
  
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
   * 
   */
  Calendar(Element element, {String format, String date, String locale, int firstDayOfWeek,
    DateTime value, String dataTargetSelector, DateTime newDate(y,m,d)}) : 
  this._format = _data(format, element, 'format', 'yyyy/MM/dd'),
  this._date = _data(date, element, 'date'),
  this._locale = _data(locale, element, 'date-locale', Intl.systemLocale),
  this._dataTargetSelector = _data(dataTargetSelector, element, 'target'),
  this._firstDayOfWeek = firstDayOfWeek,
  this._value = value,
  this._currentValue = value,
  this._newDate = newDate,
  super(element, _NAME) {
    _initCalendar();
    _initDatepicker();
  }
  
  /** Retrieve the wired Calendar object from an element. If there is no wired
   * Calendar object, a new one will be created.
   * 
   * + [create] - If provided, it will be used for Calendar creation. Otherwise 
   * the default constructor with no optional parameter value is used.
   */
  static Calendar wire(Element element, [Calendar create()]) => 
      p.wire(element, _NAME, p.fallback(create, () => () => new Calendar(element)));
  
  void _initCalendar() {
    _dfmt = new DateFormat(this._format, this._locale);
    if (_firstDayOfWeek == null)
      _firstDayOfWeek = _dfmt.dateSymbols.FIRSTDAYOFWEEK;
    
    if (_date == null) {
      if (_value != null)
        _date = _dfmt.format(_value);
    } else if (_value == null) {
      try {
        _value = _currentValue = _setDateValue(_dfmt.parse(date));
      } on FormatException catch (_) {
        //_value = null; keep previous value
      }
    }
    
    element
    ..innerHtml = _CALENDAR_TEMPLATE
    ..onMouseWheel.listen(_doMousewheel);
    
    $(element)
    ..on('click', _changeView, selector: '.title')
    ..on('click', _clickArrow, selector: '.left-icon')
    ..on('click', _clickArrow, selector: '.right-icon')
    
    ..on('click', _clickDate, selector: '.dayrow td, .cell12row span');
    
    _setView(DAY);
  }
  
  void _initDatepicker() {
    Dropdown.use();
    $element.on('change.bs.calendar', _onCalChange);
    
    if (_dataTargetSelector != null) {
      querySelectorAll(_dataTargetSelector).forEach(_bindCalendarValue);
    }
  }
  
  void _onCalChange(QueryEvent e) {//cal value to elements 
    if (_view != Calendar.DAY) return;
    
    if (_dataTargetSelector != null) {
      
      querySelectorAll(_dataTargetSelector).forEach((Element elem) {
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
      Element p = element.parent;
      if (p != null && (p = p.parent) != null && p.classes.contains('open')) {
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
    String text = inp.value;
    try {
      DateTime val = new DateFormat(format, locale).parse(text);
      _clearError(inp);
      value = val;
    } on FormatException catch (_) {
      _markError(inp);
    }
   
    $(inp).trigger('change.bs.datepicker', data: {'value': value});
  }
  
  void _clearError(Element inp) {
    Element p = inp.parent;
    if (p != null)
      p.classes.remove('has-error');
    $(inp).trigger('error.bs.datepicker');
  }
  
  void _markError(Element inp) {
    Element p = inp.parent;
    if (p != null)
      p.classes.add('has-error');
  }
  
  void _setView(String view) {
    
    //clear tbody
    Element dow = element.querySelector('.dow');
    Element cell12row = element.querySelector('.cell12row');
    List<Element> dayrow = element.querySelectorAll('.dayrow'); 
    if (cell12row != null)
      cell12row.remove();
    if (dow != null)
      dow.remove();
    for (Element e in dayrow) {
      e.remove();
    }
    
    
    this._view = view;
    switch (view) {
    case DAY:
      _dayView();
      break;
    case MONTH:
      _cell12View(_dfmt.dateSymbols.SHORTMONTHS);
      break;
    case YEAR:
      List<String> labels = [];
      int y = _currentValue.year;
      int yofs = y - (y % 10 + 1);

      for (int i = 12; --i >= 0; yofs++) {
        labels.add('$yofs');
      }

      _cell12View(labels);
      break;
    }
    _markCal();
  }
  
  void _dayView() {
    TableElement calBody = element.querySelector('.cnt');
    Element dow = calBody.tBodies[0].createFragment(_DOW_TEMPLATE).children[0];
    List<Element> children = dow.children;
    
    List<String> swkDays = _dfmt.dateSymbols.SHORTWEEKDAYS;
    int ofs = (_firstDayOfWeek + 1) % 7;
    //render week days
    for (int i = swkDays.length; --i >= 0;) {
      children[i].text = swkDays[(i + ofs) % 7];
    }
    
    var buffer = new StringBuffer();
    for (int i = 6; --i >= 0;) {
      buffer.write(_DAYROW_TEMPLATE);
    }
    
    calBody.tBodies[0].append(dow);
    _appendTableHtml(calBody, buffer.toString());
  }
  
  void _cell12View(List<String> labels) {
    Element body = (element.querySelector('.cnt') as TableElement).tBodies.first;
    Element cell12row = body.createFragment(_CELL12ROW_TEMPLATE).children[0];
    List<Element> children = cell12row.children.first.children;
    
    //render month
    for (int i = labels.length; --i >= 0;) {
      children[i].text = labels[i];
    }
    
    body.append(cell12row);
  }
  
  void _markCal([bool silent]) {
    Element seld = element.querySelector('.cnt .seld');
    if (seld != null)
      seld.classes.remove('seld');
    
    Element todayElem = element.querySelector('.cnt .today');
    if (todayElem != null)
      todayElem.classes.remove('today');
    
    bool isNullValue = _value == null;
    
    DateTime today = _setDateValue(todayUtc());
    if (_currentValue == null)
      _currentValue = today;
    
    int y = _currentValue.year;
    int m = _currentValue.month;
    
    Element title = element.querySelector('.title');
    
    if (_view == DAY) {
      
      DateTime beginDate = _newDateTime(y, m, 1, true);
      int ofs = beginDate.weekday - ((_firstDayOfWeek + 1) % 7);
      if (ofs < 0)
        ofs += 7;
      
      beginDate = beginDate.subtract(new Duration(days: ofs));
      
      bool inTodayRange = _inDayViewRange(beginDate, today);
      bool inSelectedDayRange = _value == null ? false: _inDayViewRange(beginDate, _value);
      
      title.text = '${_dfmt.dateSymbols.SHORTMONTHS[m - 1]} $y';
      List<Element> dayrow = element.querySelectorAll('.dayrow');
      List<Element> outside = element.querySelectorAll('.dayrow td.outside');
      for (Element e in outside) {
        e.classes.remove('outside');
      }
      
      for (Element row in dayrow) {
        for (Element td in row.children) {
          td.text = '${beginDate.day}';
          
          int monofs = 0;
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
          
          if (inSelectedDayRange && beginDate.month == _value.month && beginDate.day == _value.day){
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
      
      bool isMon = _view == MONTH;
      int index = isMon? m - 1: y % 10 + 1;
      
      int yofs = 0;
      
      if (isMon)
        title.text = '$y';
      else {
        yofs = y - index;
        title.text = '$yofs-${yofs + 11}';
        yofs += 11;
      }
      
      bool inSelectedDayRange = isNullValue ? false: _currentValue.year == _value.year;
      
      if (!isNullValue) {
        if (isMon) {
          index = _value.month - 1;
        } else {
          inSelectedDayRange = (yofs - 11) <= _value.year && _value.year <= yofs;
          index = _value.year  - yofs + 11;
        }
        
      }
      
         
      List<Element> cell12row = element.querySelectorAll('.cell12row span');
      for (int i = cell12row.length; --i >= 0; yofs--) {
        if (!isMon)
          cell12row[i].text = '$yofs';
        if (inSelectedDayRange && index == i) {
          cell12row[i].classes.add('seld');
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
  
  void renderSelectedDay(Element elem) {
    
  }
  
  void renderToDay(Element elem) {
    
  }
  
  void _doMousewheel(WheelEvent e) {
    _shiftView(e.deltaY > 0 ? 1: -1);
    e.stopPropagation();
  }
  
  void _clickArrow(QueryEvent evt) {
    _shiftView((evt.currentTarget as Element)
        .classes.contains('left-icon') ? -1: 1);
    evt.stopPropagation();
  }
  
  void _shiftView(int ofs) {
    switch (this._view) {
    case DAY:
      _shiftDate(MONTH, ofs);
      break;
    case MONTH:
      _shiftDate(YEAR, ofs);
      break;
    case YEAR:
      _shiftDate(YEAR, ofs * 10);
      break;
    }
    _markCal();
    
    $element.trigger('shiftView.bs.calendar', data: {'value': _currentValue, 'view': _view});
  }
  
  void _shiftDate (String opt, int ofs) {
    DateTime val = _currentValue != null ? _currentValue: _setDateValue(todayUtc());
    
    int y = val.year;
    int m = val.month;
    int d = val.day;
    bool nofix = false;
    switch(opt) {
    case DAY :
      d += ofs;
      nofix = true;
      break;
    case MONTH :
      m += ofs;
      break;
    case YEAR :
      y += ofs;
      break;
    }
    
    _currentValue = _newDate0(y, m ,d, !nofix);
//    $element.trigger('change.bs.calendar', 
//        data: {'value': value, 'view': this._view, 'shallClose': false, 'shiftDate': true});
  }
  
  void _changeView(QueryEvent evt) {
    switch (this._view) {
      case DAY:
        _setView(MONTH);
        break;
      case MONTH:
        _setView(YEAR);
        break;
      case YEAR:
        break;
    }
    evt.stopPropagation();
  }

  void _clickDate(QueryEvent evt) {
    DateTime val = _currentValue != null ? _currentValue: _setDateValue(todayUtc());
    
    ElementQuery target = $(evt.target);
    switch (this._view) {
    case DAY:
      _setTime(null, (val.month + target.data.get("monofs")),  int.parse(target.html), true);
      _markCal();
      break;
    case MONTH:
      _setTime(null, $('.cell12row span').indexOf(evt.target) + 1);
      _setView(DAY);
      break;
    case YEAR:
      _setTime(int.parse(target.html));
      _setView(MONTH);
      break;
    }
    evt.stopPropagation();
  }
  
  void _setTime(int y, [int m, int d, bool readValue]) {
    DateTime val = _currentValue != null ? _currentValue: _setDateValue(todayUtc());
    int year = y != null ? y  : val.year;
    int month = m != null ? m : val.month;
    int day = d != null ? d : val.day;
    
    _currentValue = _newDate0(year, month, day, d == null);
    
    if (readValue) {
      value = _newDate != null ? _newDate(year, month, day): _currentValue;
      $element.trigger('change.bs.calendar', data: {'value': value, 'view': this._view});
    }
  }
  
  DateTime _newDate0(int year, int month, int day, bool bFix) {
      DateTime v = new DateTime(year, month, day);
      return bFix && v.month != month && v.day != day ?
          _setDateValue(_newDateTime(year, month + 1, 0, true))/*last day of month*/: 
          _setDateValue(v);
    }
    
    static DateTime _newDateTime(int year, int month, int day, bool isUtc)
      => isUtc ? new DateTime.utc(year, month, day): new DateTime(year, month, day);
      
    static DateTime todayUtc() {
      DateTime today = new DateTime.now();
      return new DateTime.utc(today.year, today.month, today.day);
    }
  
  static DateTime _setDateValue(DateTime date) {
    if (date == null) return null;
    
    return new DateTime.utc(date.year, date.month, date.day, 12);
  }
  
  /**
   * Make calendar back to day view and selected date.
   */
  void reset() {
    _currentValue = _value;
    _setView(DAY);
  }
  
  static void _appendTableHtml(TableElement t, String html) {
    t.tBodies[0].append(t.tBodies[0].createFragment('<table>$html</table>'));
  }
  
  // Data API //
  static bool _registered = false;
  
  /** Register to use Calendar component.
   */
  static void use() {
    if (_registered) return;
    _registered = true;
    
    $window().on('load', (QueryEvent e) {
      for (Element elem in $('[class~="calendar"]')) {
        Calendar.wire(elem);
      }
    });
  }
}

_data(value, Element elem, String name, [defaultValue]) =>
    p.fallback(value, () => elem.attributes["data-$name"], () => defaultValue);
