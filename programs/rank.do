***********************************************

*** LOCAL MACROS ***

// first-time, full-time share threshold
local ftft_min = .5

// earnings time horizon
local year_earn = 10

// repayment rate time horizon
local year_repay = 3
if `year_repay' == 3 {
	local year_repay 3yr_rt_supp
}
else {
	local year_repay `year_repay'yr_rt
}

// maximum net price relative to initial FAFSA school
local netPriceMax = 1.1

// variables that we're ranking on
#delimit ;
local vars_rank 
	npt4? 							// net price by income quintile	
	num4?							// sample counts by income quintile
	c150_4_pooled_supp 				// bachelor's completion in 150% time
	mn_earn_wne_inc?_p`year_earn'	// median earnings by income bracket
	??_inc_rpy_`year_repay'			// repayment rate by income bracket
	// add test scores
;
#delimit cr

***********************************************

*** SAMPLE RESTRICTIONS ***

// keep currently operating schools 
assert inlist(curroper, 0, 1)
keep if curroper 

// drop distance-only schools, since we want to restrict on geography
keep if distanceonly == "Not distance-education only":distanceonly

// keep four-year schools
keep if preddeg == "Predominantly bachelor's-degree granting":preddeg

// restrict to those with sufficient first-time, full-time share
keep if pftftug1_ef > `ftft_min' & !missing(pftftug1_ef)

***********************************************

*** JOIN DATA TO GENERATE COMPARISONS ***

// save sample
tempfile sample alt states
save `sample'

// add alt prefixes for candidate schools
keep `vars_rank' st_fips instnm *opeid*
rename * alt_*
rename alt_st_fips st_fips
save `alt'

// calculate state averages
use `sample', clear
keep `vars_rank' st_fips instnm ugds
collapse `vars_rank' [aw = ugds], by(st_fips)
rename * state_*
rename state_st_fips st_fips
save `states'

// join with all schools in the state
use `sample', clear
gen i = _n
joinby st_fips using `alt'

// merge with state averages
merge m:1 st_fips using `states', assert(match) nogen
compress

***********************************************

*** RESHAPE BY INCOME BRACKET ***

// average income quintiles into lo, md, hi brackets used in repayment rate
foreach prefix in "" "alt_" "state_" {
	gen `prefix'netPrice_lo = `prefix'npt41
	gen `prefix'netPrice_md = ((`prefix'num42 * `prefix'npt42) + (`prefix'num43 * `prefix'npt43)) / (`prefix'num42 * `prefix'num43)
	gen `prefix'netPrice_hi = ((`prefix'num44 * `prefix'npt44) + (`prefix'num45 * `prefix'npt45)) / (`prefix'num44 * `prefix'num45)
} 

// rename repayment groups so that income bracket is last
rename *lo_inc_rpy_`year_repay' *repayRate_lo
rename *md_inc_rpy_`year_repay' *repayRate_md
rename *hi_inc_rpy_`year_repay' *repayRate_hi

// for now, act as if these brackets map onto terciles
rename *mn_earn_wne_inc1_p`year_earn' *earnings_lo
rename *mn_earn_wne_inc2_p`year_earn' *earnings_md
rename *mn_earn_wne_inc3_p`year_earn' *earnings_hi

// reshape by bracket
unab vars: *netPrice* *repayRate* *earnings*
local stubs: subinstr local vars "_lo" "", all
local stubs: subinstr local stubs "_md" "", all
local stubs: subinstr local stubs "_hi" "", all
local stubs: list uniq stubs
gen id_reshape = _n
reshape long `stubs', i(id_reshape) j(bracket) string

// format bracket
replace bracket = subinstr(bracket, "_", "", .)
replace bracket = "high" if bracket == "hi"
replace bracket = "mid"  if bracket == "md"
replace bracket = "low"  if bracket == "lo"
egen j = group(i bracket)

***********************************************

*** DETERMINE SUGGESTED SCHOOLS ***

// apply suggestion criteria
gen suggest = 1
replace suggest = 0 if alt_netPrice > (`netPriceMax' * netPrice)
foreach v of varlist c150_4_pooled_supp repayRate earnings {
	replace suggest = 0 if (alt_`v' > `v') | (alt_`v' < state_`v')
}

// drop own matches
drop if opeid6 == alt_opeid6

***********************************************

*** OUTPUT SUGGESTED SCHOOLS ***

// rename variables
keep j stabbr opeid6 instnm bracket suggest alt_instnm 
rename (instnm stabbr bracket) (college state income)

// save obs with no suggested alternatives
bysort j: egen anySuggest = max(suggest)
preserve
keep if !anySuggest
keep  state college opeid income 
order state college opeid income 
sort state college income
duplicates drop
export excel using $root/output/suggestedSchools.xlsx, firstrow(variables) sheet(none) sheetreplace
restore

// save schools with at least one suggested alternative
keep if suggest
rename alt_instnm suggested
keep  state college opeid income suggested
order state college opeid income suggested
sort state college income suggested
duplicates drop
export excel using $root/output/suggestedSchools.xlsx, firstrow(variables) sheet(suggested) sheetreplace

***********************************************