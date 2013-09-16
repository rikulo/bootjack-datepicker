#Bootjack Datepicker

Bootjack datepicker component is a datepicker component of [Bootjack](http://github.com/rikulo/bootjack).

* [Home](http://rikulo.org)
* [Git Repository](https://github.com/rikulo/bootjack-datepicker)
* [Discussion](http://stackoverflow.com/questions/tagged/rikulo)
* [Issues](https://github.com/rikulo/bootjack-datepicker/issues)

##Install from Dart Pub Repository

Include the following in your `pubspec.yaml`:

    dependencies:
      bootjack_datepicker: any

Then run the [Pub Package Manager](http://pub.dartlang.org/doc) in Dart Editor (Tool > Pub Install). If you are using a different editor, run the command
(comes with the Dart SDK):

    pub install

##Usage

First of all in your HTML file, you need to include the CSS resource:
  
	<head>
		...
		<link rel="stylesheet" href="packages/bootjack_datepicker/css/bootjack_datepicker.min.css">
	</head>

###Embedded calendar

	<div data-picker="calendar" data-date="2013/09/16" data-date-format="yyyy/MM/dd"></div>
	
With the following global registration in Dart:

	void main() {
		Calendar.use();
	}
	
###Datepicker

	<div class="input-group" data-picker="datepicker" 
	  data-date="2013/09/16" data-date-format="yyyy/MM/dd">
		
	  <input type="text" class="form-control">
	  
	  <span class="input-group-btn">
		
		<button class="btn btn-default dropdown-toggle" type="button" 
		  data-toggle="dropdown" data-target="#">
		  <span class="glyphicon glyphicon-calendar"></span>
		</button>
		
		<div class="dropdown-menu" >
		</div>
		
	  </span>
	</div>
	
With the following global registration in Dart:

	void main() {
		Datepicker.use();
	}
	
Check more [examples](https://github.com/rikulo/bootjack-datepicker/tree/master/example).
	
##Notes to Contributors

###Test and Debug

You are welcome to submit [bugs and feature requests](https://github.com/rikulo/bootjack-datepicker/issues). Or even better if you can fix or implement them!

###Fork Bootjack Datepicker

If you'd like to contribute back to the core, you can [fork this repository](https://help.github.com/articles/fork-a-repo) and send us a pull request, when it is ready.

Please be aware that one of Rikulo's design goals is to keep the sphere of API as neat and consistency as possible. Strong enhancement always demands greater consensus.

If you are new to Git or GitHub, please read [this guide](https://help.github.com/) first.
