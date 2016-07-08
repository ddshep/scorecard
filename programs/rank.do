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

// local net price factor
local netPriceScale = 1.1

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

// keep four-year schools
keep if preddeg == "Predominantly bachelor's-degree granting":preddeg

// show distribution of first-time, full-time share
#delimit ; 
hist pftftug1_ef, 
	title("# of institutions by first-time, full-time share")
	ylabel(0(20)120)
	freq
;
graph export $root/output/firstTimeFullTime.pdf, replace ;
window manage close graph; 
#delimit cr

// restrict to those with sufficient first-time, full-time share
keep if pftftug1_ef > `ftft_min' & !missing(pftftug1_ef)

// count schools by state
qui log on 
tab st_fips
qui log off

***********************************************

*** JOIN DATA TO GENERATE COMPARISONS ***

// save sample
tempfile sample sample_using states
save `sample'

// add alt prefixes for candidate schools
keep `vars_rank' st_fips instnm 
rename * alt_*
rename alt_st_fips st_fips
save `sample_using'

// calculate state averages
use `sample', clear
keep `vars_rank' st_fips instnm ugds
collapse `vars_rank' [aw = ugds], by(st_fips)
rename * state_*
rename state_st_fips st_fips
save `states'

// join with all schools in the state
use `sample', clear
joinby st_fips using `sample_using'

// merge with state averages
merge m:1 st_fips using `states', assert(match) nogen
compress

***********************************************

*** RESHAPE BY INCOME BRACKET ***

// combine income quintiles into lo, md, hi brackets
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
gen i = _n
unab vars: *netPrice* *repayRate* *earnings*
local stubs: subinstr local vars "_lo" "", all
local stubs: subinstr local stubs "_md" "", all
local stubs: subinstr local stubs "_hi" "", all
local stubs: list uniq stubs
reshape long `stubs', i(i) j(bracket) string

***********************************************

*** DETERMINE SUGGESTED SCHOOLS ***

gen suggest = 1
replace suggest = 0 if alt_netPrice > (`netPriceScale' * netPrice)
foreach v of varlist c150_4_pooled_supp repayRate earnings {
	replace suggest = 0 if (alt_`v' > `v') | (alt_`v' < state_`v')
}

***********************************************
