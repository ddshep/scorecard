// This is the master program for the Scorecard data
// cleaning an analysis.  All other programs are called 
// from within it.

// preamble
clear all
label  drop _all
matrix drop _all
macro  drop _all
set more off

// switches: use these to skip over the time intensive data building 
// after you've done it once
local switch_build 	= 1
local switch_rank	= 1

// directories
global root 		/Users/slhudson/Documents/sbst/scorecard
sysdir set PERSONAL	$root/programs/ado
cap mkdir			$root/documentation
cap mkdir			$root/output
cap mkdir			$root/data
if !_rc {
	mkdir $root/data/raw
	mkdir $root/data/build
	mkdir $root/data/scratch
}

// initalize log file
cap log close
log using $root/output/log.txt, text replace 
qui log off

***********************************************

// build raw scorecard data
if `switch_build' {
	do $root/programs/build 
}

// clean data
if `switch_rank' {

	// load data
	use $root/data/build/scorecard, clear

	// drop variables we're not using in our analysis
	do $root/programs/dropVars 

	// select our sample of eligible schools
	do $root/programs/rank
}

// close log
log close

***********************************************