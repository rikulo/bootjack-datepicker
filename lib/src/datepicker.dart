part of bootjack_datepicker;

/** A datepicker component.
 */
class Datepicker extends Base {
  
  static const String _NAME = 'datepicker';
  
  /** Construct a datepicker object, wired to [element].
   * 
   */
  Datepicker(Element element) : 
  super(element, _NAME) {
    Element dropdownBtn = element.query('[data-toggle="dropdown"]');
    
    if (dropdownBtn != null) {
      this._dropdown = Dropdown.wire(dropdownBtn);
      dropdownBtn.$dom_addEventListener('click', onBtnClick);
    }
    
    
    Element dropdown = element.query('[class~="dropdown-menu"]');
    if (dropdown != null) {
      _cal = new Calendar(dropdown, 
          format: element.attributes['data-date-format'], 
          date: element.attributes['data-date']);
      _cal.$element.on('change.bs.calendar', onCalChange);
    }
    
    _inp = element.query('[class~="form-control"]');
    if (_inp != null) {
      _inp.$dom_addEventListener("change", onInpChange);
      if (_cal != null)
        _inp.value = _cal.date;
    }
  }
  
  void onCalChange(DQueryEvent e) {
    if (_cal.view != Calendar.DAY) return;
    
    if (_inp != null) {
      _inp.value = _cal.date;
      $element.trigger('change.bs.datepicker');
      
      if (_dropdown != null) {
        if (e.data == null || e.data['shallClose'] != false)
          _dropdown.toggle();
      }
    }
  }
  
  void onBtnClick(MouseEvent e) {
    //there no isOpen API for checking dropdown open
    //check dropdown open
   if (_dropdown.element.parent.classes.contains('open')) {
     _cal.date = _inp.value;
   }
  }
  
  void onInpChange(Event e) {
    String text = _inp.value;
    
    try {
     DateTime val = new DateFormat(_cal.format, _cal.locale).parse(text);
     _clearError();
     _cal.value = val;
    } on FormatException catch (e) {
      _markError();
    }
   
    $element.trigger('change.bs.datepicker');
  }
  
  void _clearError() {
    element.classes.remove('has-error');
  }
  
  void _markError() {
    element.classes.add('has-error');
    $element.trigger('error.bs.datepicker');
  }
  
  
  /** Retrieve the wired Datepicker object from an element. If there is no wired
   * Datepicker object, a new one will be created.
   * 
   * + [create] - If provided, it will be used for Datepicker creation. Otherwise 
   * the default constructor with no optional parameter value is used.
   */
  static Datepicker wire(Element element, [Datepicker create()]) => 
      p.wire(element, _NAME, p.fallback(create, () => () => new Datepicker(element)));
  
  Calendar _cal;
  Dropdown _dropdown;
  InputElement _inp;
  
  // Data API //
  static bool _registered = false;
  
  /** Register to use Scrollspy component.
   */
  static void use() {
    if (_registered) return;
    _registered = true;
    
    $window().on('load', (DQueryEvent e) {
      for (Element elem in $('[data-picker="datepicker"]')) {
        Datepicker.wire(elem);
      }
    });
  }
  
}
