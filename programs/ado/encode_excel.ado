// We'll work on the preamble at the very end.
// Purpose: This program maps raw values to clean, labeled integers using a crosswalk 
// provided in an external spreadsheet.

**************************************************************************************
**************************************************************************************
**************************************************************************************

capture program drop encode_excel

program define encode_excel, nclass
	syntax varname using/, 	raw(string) clean(string) label(string) ///
							[sheet(string)] [noallow_missing]	///
							[CASEignore]

	
	di "encoding `varlist' from `using'..."
	
	// declare temporary variables
	tempvar merge code N
	
	// determine if varlist is string or number
	cap confirm numeric variable `varlist' 
	local type_string = _rc
	if `type_string' != 0 & "`caseignore'" == "caseignore" {
		qui replace `varlist' = lower(`varlist')
	}
	preserve
	**************************************************************************************
	
	*** DEFINE MAPPING FROM RAW TO CLEAN VALUES ***
	
	// get code values matched to raw values 
	import excel  `using', sheet(`sheet') firstrow clear
	keep `clean' `raw' `label'
	
		// allow for raw and (label or clean) to be same spreadsheet column
		foreach v in label clean { 
			if "``v''" == "`raw'" {
				tempvar `v'
				gen ``v'' = `raw'
			}
		}
		
	// make `raw' string or not depending on `varlist' format, and reduce to 
	// unique combinations of raw, clean, and label values 
	if `type_string'  {
		qui tostring `raw', replace usedisplayformat 
		qui drop if `raw' == "."
		if "`caseignore'" == "caseignore" {
			qui replace `raw' = lower(`raw')
		}
	}
	qui drop if missing(`raw')
	qui duplicates drop
		
	// save matched codes data set	
	rename  `raw' `varlist' 
	gen `code' = `clean'
	tempfile codes
	qui save `codes'
	
	**************************************************************************************
	
	*** DEFINE MAPPING FROM CLEAN VALUES TO LABELS ***

	// verify that only one label is supplied for each clean code value	
	bysort `clean' `label': keep if (_n == 1)
	bysort `clean': gen `N' = _N	
	cap assert (`N' == 1)
	if _rc { 
		display as error "The following code values are assigned to more than one label"
		list `clean' `label' if (`N' > 1)
		exit _rc
	}

	// define label: this is a PITA method to store a local for each value label
	qui levelsof `clean', local(codes_clean) 
	foreach x of local codes_clean {
		forvalues i = 1/`=_N'{
			if `clean'[`i'] == `x' {
				local label_`x' = `label'[`i']
				break
			}
		}
	}

	**************************************************************************************
		
	*** ENCODE AND LABEL VARIABLES ***
	
	// restore master data
	restore
	
	// merge with clean values
	qui merge m:1 `varlist' using `codes', keep(master match) keepusing(`code')  gen(`merge')

	// verify that all raw values could be found in the provided spreadsheet
	cap assert (`merge' != 1 | missing(`varlist'))
	if _rc {
		display as error "The following values for `varlist' were not found in the supporting spreadsheet:"
		display as error "Function call was encode_excel `0' "
		tab `varlist' if (`merge' == 1)
		exit _rc
	}	
		
	// verify that all raw values have found a non-missing clean value unless allow_missing is specified
	cap assert !missing(`code') if !missing(`varlist')
	if _rc & "`allow_missing'" == "noallow_missing" {
		display as error "The following raw values for `varlist' must be mapped to non-missing clean values:" 
		tab `varlist' if missing(`code')
		exit _rc
	}
	
	// replace raw values with clean values
	drop `varlist'
	generate `varlist' = `code'		
	
	// label values
	cap label drop `varlist'
	local i = 1
	foreach x of local codes_clean {
		label define `varlist' `x' "`label_`x''", modify	
	}	
	label values `varlist' `varlist'
	drop `merge' `code' 
	
	// tab new codes
	qui compress `varlist'
	tab `varlist', missing
	di ""

end	

**************************************************************************************
**************************************************************************************
**************************************************************************************

