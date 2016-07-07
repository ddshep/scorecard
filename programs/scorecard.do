// preamble
clear all
label  drop _all
matrix drop _all
macro  drop _all
set more off

// directories
global root 		/Users/slhudson/Documents/sbst/scorecard
sysdir set PERSONAL	$root/programs/ado

// data files
global data_clean	$root/data/clean/scorecard

***********************************************

// format raw data
do $root/programs/clean 

***********************************************