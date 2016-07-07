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
	mkdir $root/data/scratch
}

// switches
local switch_build 	= 0
local switch_clean	= 1

***********************************************

// build raw scorecard data
if `switch_build' {
	do $root/programs/build 
}

// clean data
if `switch_clean' {

	// load data
	use $root/data/build/scorecard, clear

	// drop variables we're not using in our analysis
	do $root/programs/dropVars 

	// select our sample of eligible schools
	do $root/programs/sample
}

***********************************************