***********************************************

*** LOCAL MACROS ***

// first-time, full-time share threshold
local ftft_min = .5

// earnings time horizon
local year_earn = 10

// repayment rate time horizon; if year 3, we can use the version that suppresses small cells
local year_repay 3yr_rt_supp

// maximum net price relative to initial FAFSA school
local netPriceMax = 1.1

// family income percentiles
local income0  	= 0 
local income20 	= 30000
local income40 	= 48000
local income60 	= 75000
local income80 	= 110000
local income33 	= 36000		// these last two are my ballparks of the tercile cut points
local income66 	= 81000 
local income100	= .
local income_pcts 0 20 33 40 60 66 80

// test score bandwidths
local bw_actcm = 5
local bw_satmt = 200
local bw_satvr = `bw_satmt'

// variables that we're ranking on
#delimit ;
local vars_rank 
	netPrice					
	grad			
	earnings					
	repay				
	sat* act*					
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

*** HARMONIZE INCOME BRACKETS ***

// generate one row for each income bracket
gen i = _n
local n_brackets: word count `income_pcts'
expand `n_brackets'
bysort i: gen n = _n

// set income ranges for each bracket
gen income_low 	= .
gen income_high = . 
forvalues j = 1/`n_brackets' {
	local low: 	word `j' 		of `income_pcts'
	local high:	word `=`j'+1'	of `income_pcts'
	replace income_low 	= `income`low'' 	if (n == `j')
	if `j' < `n_brackets' {
		replace income_high	= `income`high''	if (n == `j')
	}
}

// net price is reported in quintiles
gen netPrice = .
forvalues j = 5(-1)1 {
	replace netPrice = npt4`j' if (income_high <= `income`=20*`j''')
} 

// repayment rate is 1st quintile, 2+3 quintile, 4+5 quintile
gen repay 		= hi_inc_rpy_`year_repay'
replace repay 	= md_inc_rpy_`year_repay' if (income_high <= `income60')
replace repay 	= lo_inc_rpy_`year_repay' if (income_high <= `income20')

// earnings is in terciles
gen earnings 	 = mn_earn_wne_inc3_p`year_earn' 
replace earnings = mn_earn_wne_inc2_p`year_earn' if (income_high <= `income66') 
replace earnings = mn_earn_wne_inc1_p`year_earn' if (income_high <= `income33') 

// graduation rate is not dissagregated by income
rename c150_4_pooled_supp grad

***********************************************

*** JOIN DATA TO GENERATE COMPARISONS ACROSS SCHOOLS ***

// save sample
tempfile sample alt states
save `sample'

// add alt prefixes for candidate schools
keep `vars_rank' st_fips income* instnm *opeid*
rename * alt_*
rename (alt_st_fips alt_income*) (st_fips income*)
save `alt'

// calculate state averages
use `sample', clear
keep `vars_rank' st_fips income* instnm ugds
collapse `vars_rank' [aw = ugds], by(st_fips income_low income_high)
rename * state_*
rename (state_st_fips state_income*) (st_fips income*)
save `states'

// join with all schools in the state
use `sample', clear
joinby st_fips income_low income_high using `alt'

// merge with state averages
merge m:1 st_fips income_low income_high using `states', assert(match) nogen
compress

***********************************************

*** DETERMINE SUGGESTED SCHOOLS ***

// initialize suggested indicator
gen suggest = 1

// candidate net price cannot exceed sum fraction of chosen net price
replace suggest = 0 if alt_netPrice > (`netPriceMax' * netPrice)

// graduation, repayment and earnings must be higher than both chosen school and state average
foreach v of varlist grad repay earnings {
	replace suggest = 0 if (alt_`v' < `v') | (alt_`v' < state_`v') 
}

// if chosen school has non-missing test scores, 25th percentile of candidate schools cannot be 
// too much higher than the chosen school's 50th percentile.
//
// Need to think more carefully about what to do if either the chosen or alternate= school has missing values
foreach exam in actcm satmt satvr {
	replace suggest = 0 if !missing(`exam'mid) & !missing(alt_`exam'25) & (alt_`exam'25 > `exam'mid + `bw_`exam'')
}

// drop own matches
drop if opeid6 == alt_opeid6

***********************************************

*** OUTPUT SUGGESTED SCHOOLS ***

// rename identifiers
rename (instnm stabbr) (college state)

// save obs with no suggested alternatives
bysort i: egen anySuggest = max(suggest)
preserve
keep if !anySuggest
keep  state college opeid income* 
order state college opeid income* 
sort state college income_low
duplicates drop
export excel using $root/output/suggestedSchools.xlsx, firstrow(variables) sheet(none) sheetreplace
restore

// save schools with at least one suggested alternative
keep if suggest
rename alt_instnm suggested
keep  state college opeid income* suggested
order state college opeid income* suggested
sort state college income_low suggested
export excel using $root/output/suggestedSchools.xlsx, firstrow(variables) sheet(suggested) sheetreplace

***********************************************