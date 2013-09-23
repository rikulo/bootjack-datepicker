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
  <tr>
    <th class="left-icon">&laquo;</th>
    <th class="title" colspan="5"></th>
    <th class="right-icon">&raquo;</th>
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

  
  /**
  * 
  */
  String _format;
  
  /**
   * 
   */
  DateTime _value;
  
  /**
   * 
   */
  String _date;
  
  /**
   * 
   */
  String _locale;
  
  /**
   * 
   */
  String _view;
  
  /**
   * 
   */
  DateFormat _dfmt;
  
  
  String get format => _format;
  void set format(String format) {
    if (_format != format) {
      _format = format;
      _dfmt = new DateFormat(_format, _locale);
    }
  }
  
  String get locale => _locale;
  void set locale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      _dfmt = new DateFormat(_format, _locale);
    }
  }
  
  String get date => _date;
  void set date(String date) {
    if (_date != date) {
      _date = date;
      if (_dfmt != null) {
        try {
          _value = _dfmt.parse(date);
          _markCal();
        } on FormatException catch (e) {
          //_value = null; keep previous value
        }
      }
    }
  }
  
  DateTime get value => _value;
  void set value(DateTime value) {
    if (_value != value) {
      _value = value;
      if (_dfmt != null) {
        _date = value != null ? _dfmt.format(value): null;
        _markCal();
      }
    }
  }
  
  /**
   * 
   */
  String _dataTargetSelector;
  
  
  /** Construct a calendar object, wired to [element].
   * 
   */
  Calendar(Element element, {String format, String date, String locale, DateTime value, String dataTargetSelector}) : 
  this._format = _data(format, element, 'format', 'yyyy/MM/dd'),
  this._date = _data(date, element, 'date'),
  this._locale = _data(locale, element, 'date-locale', Intl.systemLocale),
  this._dataTargetSelector = _data(dataTargetSelector, element, 'target'),
  this._value = value,
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
    
    if (_date == null) {
      if (_value != null)
        _date = _dfmt.format(_value);
    } else if (_value == null) {
      try {
        _value = _dfmt.parse(date);
      } on FormatException catch (e) {
        //_value = null; keep previous value
      }
    }
    
    element.innerHtml = _CALENDAR_TEMPLATE;
    
    element.query('.title').$dom_addEventListener('click', _changeView);
    element.query('.left-icon').$dom_addEventListener('click', _clickArrow);
    element.query('.right-icon').$dom_addEventListener('click', _clickArrow);
    element.$dom_addEventListener('mousewheel', _doMousewheel);
    
    $(element).on('click', _clickDate, selector: '.dayrow td, .cell12row span');
    
    _setView(DAY);
  }
  
  void _initDatepicker() {
    Dropdown.use();
    $element.on('change.bs.calendar', _onCalChange);
    
    if (_dataTargetSelector != null) {
      queryAll(_dataTargetSelector).forEach(_bindCalendarValue);
    }
  }
  
  void _onCalChange(DQueryEvent e) {//cal value to elements 
    if (_view != Calendar.DAY) return;
    
    if (_dataTargetSelector != null) {
      
      queryAll(_dataTargetSelector).forEach((Element elem) {
        if (elem is InputElement) {
          (elem as InputElement).value = _date;
          _updateChange(elem);//for clear error and fire change
        } else {
          //todo bind text to label? e.innerHtml = _date;
        }
      });
    }
    
    //Close dropdown
    if (e.data == null || e.data['shallClose'] != false) {
      Element p = element.parent;
      if (p != null && (p = p.parent) != null)
        p.classes.remove('open');
    }
  }
  
  void _bindCalendarValue(Element elem) {//element value to cal
    if (elem is InputElement) {
      (elem as InputElement).$dom_addEventListener("change", (_) => _updateChange(elem));
    }
  }
  
  void _updateChange(InputElement inp) {
    String text = inp.value;
    try {
      DateTime val = new DateFormat(format, locale).parse(text);
      _clearError(inp);
      value = val;
    } on FormatException catch (e) {
      _markError(inp);
    }
   
    $(inp).trigger('change.bs.datepicker');
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
    Element dow = element.query('.dow');
    Element cell12row = element.query('.cell12row');
    List<Element> dayrow = element.queryAll('.dayrow'); 
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
      int y = _value.year;
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
    Element body = (element.query('.cnt') as TableElement).tBodies.first;
    
    Element dow = body.createFragment(_DOW_TEMPLATE).children[0];
    List<Element> children = dow.children;
    
    List<String> swkDays = _dfmt.dateSymbols.SHORTWEEKDAYS;
    
    //render week days
    for (int i = swkDays.length; --i >= 0;) {
      children[i].innerHtml = swkDays[i];
    }
    
    var buffer = new StringBuffer();
    for (int i = 6; --i >= 0;) {
      buffer.write(_DAYROW_TEMPLATE);
    }
    
    body.append(dow);
    body.appendHtml(buffer.toString());
  }
  
  void _cell12View(List<String> labels) {
    Element body = (element.query('.cnt') as TableElement).tBodies.first;
    Element cell12row = body.createFragment(_CELL12ROW_TEMPLATE).children[0];
    List<Element> children = cell12row.children.first.children;
    
    //render month
    for (int i = labels.length; --i >= 0;) {
      children[i].innerHtml = labels[i];
    }
    
    body.append(cell12row);
  }
  
  void _markCal([bool silent]) {
    Element seld = element.query('.cnt .seld');
    if (seld != null)
      seld.classes.remove('seld');
    DateTime val = _value != null ? _value: new DateTime.now();
    int y = val.year;
    int m = val.month;
    Element title = element.query('.title');
    
    if (_view == DAY) {
      title.innerHtml = '${_dfmt.dateSymbols.SHORTMONTHS[m - 1]} $y';
      
      DateTime beginDate = new DateTime(y, m, 1);
      beginDate = beginDate.subtract(new Duration(days: beginDate.weekday));
      List<Element> dayrow = element.queryAll('.dayrow');
      int d = val.day;
      
      List<Element> outside = element.queryAll('.dayrow td.outside');
      for (Element e in outside) {
        e.classes.remove('outside');
      }
      
      for (Element row in dayrow) {
        for (Element td in row.children) {
          td.innerHtml = '${beginDate.day}';
          td.innerHtml = beginDate.day.toString();
          
          $(td).data.set('monofs', 0);
          if (beginDate.month != m) {
            td.classes.add('outside');
            $(td).data.set('monofs', beginDate.month > m ? 1: -1);
          } else if (beginDate.day == d){
            td.classes.add('seld');
          }
          
          beginDate = beginDate.add(new Duration(days: 1));
        }
      }

      
    } else {
      
      
      bool isMon = _view == MONTH;
      int index = isMon? m - 1: y % 10 + 1;
      int yofs = 0;
      
      if (isMon)
        title.innerHtml = '${_dfmt.dateSymbols.SHORTMONTHS[m - 1]} $y';
      else {
        yofs = y - index;
        title.innerHtml = '$yofs-${yofs + 11}';
        yofs += 11;
      }
      
         
      List<Element> cell12row = element.queryAll('.cell12row span');
      for (int i = cell12row.length; --i >= 0; yofs--) {
        if (!isMon)
          cell12row[i].innerHtml = '$yofs';
        if (index == i)
          cell12row[i].classes.add('seld');
      }
    }
  }
  
  void _doMousewheel(WheelEvent evt) {
    _shiftView(evt.deltaY > 0 ? 1: -1);
    evt.stopPropagation();
  }
  
  void _clickArrow(MouseEvent evt) {
    _shiftView((evt.target as Element)
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
  }
  
  void _shiftDate (String opt, int ofs) {
    DateTime val = _value != null ? _value: new DateTime.now();
    
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
    
    value = _newDate(y, m ,d, !nofix);
    $element.trigger('change.bs.calendar', data: {'value': _value, 'shallClose': false});
  }
  
  void _changeView(MouseEvent evt) {
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

  void _clickDate(DQueryEvent evt) {
    DateTime val = _value != null ? _value: new DateTime.now();
    
    ElementQuery target = $(evt.target);
    switch (this._view) {
    case DAY:
      _setTime(null, (val.month + target.data.get("monofs")),  int.parse(target.html));
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
  
  DateTime _newDate(int year, int month, int day, bool bFix) {
    DateTime v = new DateTime(year, month, day);
    return bFix && v.month != month && v.day != day ?
      new DateTime(year, month + 1, 0)/*last day of month*/: v;
  }
  
  void _setTime(int y, [int m, int d]) {
    DateTime val = _value != null ? _value: new DateTime.now();
    int year = y != null ? y  : val.year;
    int month = m != null ? m : val.month;
    int day = d != null ? d : val.day;
    
    value = _newDate(year, month, day, d == null);
    $element.trigger('change.bs.calendar', data: {'value': _value});
  }
  
  // Data API //
  static bool _registered = false;
  
  /** Register to use Scrollspy component.
   */
  static void use() {
    if (_registered) return;
    _registered = true;
    
    $window().on('load', (DQueryEvent e) {
      for (Element elem in $('[class~="calendar"]')) {
        Calendar.wire(elem);
      }
    });
  }
}

_data(value, Element elem, String name, [defaultValue]) =>
    p.fallback(value, () => elem.attributes["data-$name"], () => defaultValue);
