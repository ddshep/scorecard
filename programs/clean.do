// preamble
clear all
label  drop _all
matrix drop _all
macro  drop _all
set more off

// directories
local root 			/Users/slhudson/Documents/sbst/scorecard
local scratch		`root'/data/scratch
sysdir set PERSONAL	`root'/programs/ado

// data files
local data_raw		`root'/data/raw/Most-Recent-Cohorts-All-Data-Elements.csv
local data_dict		`root'/data/raw/CollegeScorecardDataDictionary-09-08-2015.csv
local data_clean	`root'/data/clean/scorecard

// variables in data dictionary that don't exist in most recent data
local varsNotFound 	inlist(variablename, "locale2") 

// missing values
local null_str			NULL
local null_miss			.a
local null_int			999
local supp_str			PrivacySuppressed
local supp_miss			.b
local supp_int			9999	
local lbl_missing		`" `null_miss' "`null_str'" `supp_miss' "`supp_str'" "'

// degree offering categories
local cipVals		"0, 1, 2, `null_miss'"
local cip0			"Program not offered"
local cip1			"Program offered"
local cip2			"Program offered through an exclusively distance-education program"
local lbl_cip		`"`null_miss' "`null_str'" "'
foreach val in 0 1 2 {
	local lbl_cip	`" `lbl_cip' `val' "`cip`val''" "'
}

***********************************************
***********************************************
***********************************************

*** FORMAT DATA DICTIONARY ***

// load dictionary
insheet using `data_dict', comma names clear

// fill down blank variable names
gen first = !missing(variablename)
replace variablename = variablename[_n-1] if !first

// save full dictionary
drop if `varsNotFound'
tempfile dict
save `dict'

// get variable names and labels
keep if first
keep variablename nameofdataelement
replace name = trim(itrim(name))
tempfile names
save `names'

// get variable values 
use `dict', clear
keep if !missing(value)
keep variablename value label
gen clean = value
destring clean, replace

// save value labels for each variable separately
levelsof variablename, local(labeled)
foreach v of local labeled {
	preserve
	keep if variablename == "`v'"
	
		// add labels for missing values
		expand 3 in 1
		sort value 
		local i = 1
		foreach val in null supp {
			assert clean != ``val'_int'
			replace clean = ``val'_int'   if (_n == `i')
			replace value = "``val'_str'" if (_n == `i')
			replace label = "``val'_str'" if (_n == `i')
			local ++i
		}

	tempfile `v'
	save ``v''
	restore
}

***********************************************
***********************************************
***********************************************

*** FORMAT SCORECARD DATA ***

// load raw data
insheet using `data_raw', comma names clear

// name and label variables
rename_plus using `names', name_new(variablename) name_old(variablename) label(nameofdataelement) keepx caseignore

// encode categorial variables

	// one-off fixes for single observations
	tostring st_fips, replace
	replace st_fips	 = "NULL" if st_fips == "68"
	replace ccugprof = "NULL" if ccugprof == "0"

	// encode all but the CIP variables, which get handled below
	foreach v of local labeled {
		if !regexm("`v'", "^CIP") {
			local new = lower("`v'")
			encode_plus `new' using ``v'', raw(value) clean(clean) label(label) caseignore
		}
	}

// distinguish between missing and suppressed values
label define missing `lbl_missing', add
foreach v of varlist _all {
	cap confirm string variable `v'
	if !_rc {
		gen byte null = missing(`v') | (`v' == "`null_str'")
		replace `v' = "" if `v' == "`null_str'"
		replace `v' = "" if `v' == "`supp_str'"
		destring `v', replace
		cap confirm string variable `v'
		if _rc {
			replace `v' = `null_miss' if missing(`v') & null
			replace `v' = `supp_miss' if missing(`v') & !null
			label values `v' missing
		}
		drop null
	}
}

// encode CIP variables, which were not included in the data dictionary
label define cip `lbl_cip', add
foreach v of varlist cip* {
	assert inlist(`v', `cipVals')
	label values `v' cip
}

***********************************************
***********************************************
***********************************************

*** SAVE CLEAN DATA ***

aorder 
compress
save `data_clean', replace

***********************************************
***********************************************
***********************************************
