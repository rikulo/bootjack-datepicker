#CHANGES

**1.0.3**
* Slow down scrolling speed for Trackpad
* Fixed render customize cell error

**1.0.2**
* Fixed wrong cursor position when type 00 in hour field
* Keep focus in hour field if only type 1 digit
* Don't parse `18` to 6 pm, it shall be 01:08 am
* Timepicker support mouse scrolling to set time

**1.0.1**
* Support set firstDayOfWeek
* Timepicker support AM/PM

**1.0.0**
* Dart 2 required

**0.5.9*
* Fixed pass a wrong date when render year view

**0.5.8*
* Timepicker support null value
* Set time to null when keep pressing backspace
* Fixed pick year error when value is null

**0.5.7*
* Fixed render first day of week with Sat
* Support timepicker

**0.5.6**
* Fixed table content do not render correctly
* Fixed mouse wheel event
* Support first day of week 

**0.5.5**
* Support chang date view and shift date view event
* Fixed DST timezone date render issue

**0.5.4**
* Support Dquery 0.7.0

**0.5.3**

* Upgrade for Dart SDK 1.0
* Apply new style.
* Fixed dropdown doesn't trigger close event
* Fine tune calendar event data
* Apply today class
* Support renderSelectedDay, renderToDay
* Fixed pick previous year bug
* Fixed navigate date by click right/left arrow bug

**0.5.2**

* Apply new implement for datepicker component, remove Datepicker class.

**0.5.1**

* Create datepicker component
