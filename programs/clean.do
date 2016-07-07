// preamble
clear
set more off

// directories
local root 		/Users/slhudson/Documents/sbst/scorecard
local data_raw	`root'/data/raw/Most-Recent-Cohorts-All-Data-Elements.csv
local data_dict	`root'/data/raw/CollegeScorecardDataDictionary-09-08-2015.csv

********************************************

*** FORMAT DATA DICTIONARY ***

// load data
insheet using `data_dict', comma names clear

// fill down blank variable names
replace variablename = variablename[_n-1] if missing(variablename)

// keep variables that have encoded values
keep if !missing(value)