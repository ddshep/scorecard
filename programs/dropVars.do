// This program drops excess variables from the Scorecard
// data that we're not using in our analysis.

***********************************************

*** GRADUATION RATES ***

// restrict attention to 150% of on-time rates
drop c200* d200*

// drop race-specific completion rates
foreach v of varlist c150* d150* {
	if !regexm("`v'", "pooled") {
		drop `v'
	}
}

// drop NSLDS completion variables
drop comp_* *_comp_* *_yr?_*

// drop subject-specific degrees variables
drop cip* pcip*

***********************************************

*** NET PRICE ***

// combine variables across institution types
foreach bracket in "" "1" "2" "3" "4" "5" {
	foreach prefix in npt4 num4 {
		gen `prefix'`bracket' = .
		foreach type in pub priv prog other {
			replace `prefix'`bracket' = `prefix'`bracket'_`type' if missing(`prefix'`bracket') 
			drop `prefix'`bracket'_`type'
		}
	}
}

// label variables
label var npt4 "avg. net price for Title IV undergrads"
label var num4 "# of Title IV students (undergrads?)"
forvalues x = 1/5 {
	label var npt4`x' "avg. net price for Title IV undergrads from income quintile `x'"
	label var num4`x' "# of Title IV students (undergrads?) from income quintile `x'"
}

// drop merged income bracket versions
drop npt4_048* npt4_75up* npt4_3075*

***********************************************

*** REPAYMENT RATES ***

// keep only aggregate and income bracket repayment rates
foreach v of varlist *_rpy_* {
	if !regexm("`v'", "_inc") {
		drop `v'
	}
}

***********************************************

*** EARNINGS ***

// focus on earnings 10 years out
foreach v of varlist *earn* {
	if !regexm("`v'", "10") {
		drop `v'
	}
}

***********************************************

*** TEST SCORES ***

// drop subject specific scores
drop satvr* satmt* satwr*
drop acten* actmt* actwr*

***********************************************