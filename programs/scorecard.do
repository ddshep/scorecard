// preamble
clear all
label  drop _all
matrix drop _all
macro  drop _all
set more off

// directories
global root 		/Users/slhudson/Documents/sbst/scorecard
sysdir set PERSONAL	$root/programs/ado
cap mkdir			$root/documentation
cap mkdir			$root/data
if !_rc {
	mkdir $root/data/raw
	mkdir $root/data/build
}

***********************************************

// format raw data
do $root/programs/clean 

***********************************************