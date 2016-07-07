// preamble
clear all
set more off

// directories
local root 		/Users/slhudson/Documents/sbst/scorecard
local scratch		`root'/data/scratch
sysdir set PERSONAL	`root'/programs/ado

// data files
local data_raw	`root'/data/raw/Most-Recent-Cohorts-All-Data-Elements.csv
local data_dict	`root'/data/raw/CollegeScorecardDataDictionary-09-08-2015.csv

// variables in data dictionary that don't exist in most recent data
local varsNotFound 	inlist(variablename, "locale2") 

***********************************************

*** FORMAT DATA DICTIONARY ***

// load dictionary
insheet using `data_dict', comma names clear

// fill down blank variable names
gen first = !missing(variablename)
replace variablename = variablename[_n-1] if !first
tempfile dict
save `dict'

// save variable names and labels
keep if first
keep variablename nameofdataelement
replace name = trim(itrim(name))
drop if `varsNotFound'
tempfile names
save `names'
keep if !missing(value)***********************************************

*** FORMAT SCORECARD DATA ***

// load raw data
insheet using `data_raw', comma names clear

// name and label variables
rename_plus using `names', name_new(variablename) name_old(variablename) label(nameofdataelement) keepx caseignore

***********************************************