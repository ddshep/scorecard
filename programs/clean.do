***********************************************
***********************************************
***********************************************

*** LOCAL MACROS ***

// data files
local raw_url		https://collegescorecard.ed.gov/downloads
local raw_file		Most-Recent-Cohorts-All-Data-Elements.csv
local dict_url		https://collegescorecard.ed.gov/assets
local dict_file		CollegeScorecardDataDictionary-09-08-2015.csv
local doc_file		FullDataDocumentation.pdf

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
local cipVals			"0, 1, 2, `null_miss'"
local cip0				"Program not offered"
local cip1				"Program offered"
local cip2				"Program offered through an exclusively distance-education program"
local lbl_cip			`"`null_miss' "`null_str'" "'
foreach val in 0 1 2 {
	local lbl_cip		`" `lbl_cip' `val' "`cip`val''" "'
}

***********************************************
***********************************************
***********************************************

*** FORMAT DATA DICTIONARY ***

// download raw data
cap confirm file $root/data/raw/`dict_file'
if _rc {
	shell curl -o $root/data/raw/`dict_file' `dict_url'/`dict_file'
}

// download documentation 
cap confirm file $root/documentation/`doc_file'
if _rc {
	shell curl -o $root/documentation/`doc_file' `dict_url'/`doc_file'
}

// load dictionary
insheet using $root/data/raw/`dict_file', comma names clear

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

// download raw data
cap confirm file $root/data/raw/`raw_file'
if _rc {
	shell curl -o $root/data/raw/`raw_file' `raw_url'/`raw_file'
}

// load raw data
insheet using $root/data/raw/`raw_file', comma names clear

// name and label variables
rename_plus using `names', name_new(variablename) name_old(variablename) label(nameofdataelement) keepx caseignore

// encode categorical variables

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

// add labels to predominant degree
label values sch_deg highdeg

***********************************************
***********************************************
***********************************************

// save clean data
aorder 
compress
save $root/data/build/scorecard, replace

***********************************************
***********************************************
***********************************************
