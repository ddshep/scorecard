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

// variables that we're ranking on
#delimit ;
local vars_rank 
	npt4? 							// net price by income quintile	
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
log on 
tab st_fips
log off

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


save $root/data/scratch/clean, replace

***********************************************
