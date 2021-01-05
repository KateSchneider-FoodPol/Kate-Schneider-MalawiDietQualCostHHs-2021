/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: Merge IHPS and Market data and prepare for linear programming for policy scenarios

* THIS DO FILE IS FOR ARCHIVE PURPOSES ONLY *
* THIS DO FILE WAS NOT USED TO CALCULATE LEAST COST DIETS IN MY PHD THESIS *
* ONLY THE REVISED NUTRIENT REQUIREMENTS WERE USED IN MY THESIS FOR THE 
	PAPERS INCORPORATING LEAST-COST DIETS *

	NOTE: This analysis requires substantial computing power. It will need days to
	  run on a standard desktop. Use of a supercomputer (e.g. high powered cluster)
	  is necessary.
*/

// PART 0 // FILE MANAGEMENT
set more off

* Set working directory
cd "yourfilepath"
log using "04_scenarios_MergeIHPSandMarketDataLPInput_`c(current_date)'", replace

***Log of Do File #4 "4_scenarios Merge IHPS and Market Data LP Input"
di "`c(current_date)' `c(current_time)'"


foreach s in a b c {
// PART 1 // PREPARE SHARING SCENARIO DATA FOR LINEAR PROGRAMMING
* Join household and market level data to expand out every household
* 		by it's nearest market price time series
use "HHdata_tomerge_sharing_oldstata.dta", clear
joinby market_no nutr_no using "CPIDataForCoNA_tomerge_oldstata_s1`s'.dta"

sort hhxround year month nutr_no 
unique hhxround
tab year
tab month
tab nutr_no
tab market_no

* Checks for post-merge and after linear programming
tabstat ear ul amdr_lower amdr_upper, by(nutr_no) stats(mean sd min max count) c(s)
bys nutr_no: tabstat F*, stats(mean sd min max count) c(s)


order hhxround case_id HHID data_round nutr_no ear ul amdr_lower amdr_upper date_consump market_no year month, before(F1_)
sum case_id HHID data_round date_consump nutr_no ear ul amdr_lower amdr_upper
	// total observations should be 4508*23*127=13,167,868

rename ear NR1
	lab var NR1 "EAR" 
rename ul NR2
	lab var NR2 "UL"
rename amdr_lower NR3
	lab var NR3 "AMDR-lower"
rename amdr_upper NR4
	lab var NR4 "AMDR-upper"
order market_no year month nutr_no nutr case_id HHID y2_hhid y3_hhid data_round date_consump
sort hhxround year month nutr_no

unique market_no year month case_id HHID y2_hhid y3_hhid data_round 
	// Should be 4508*127=572,516
	cap drop _*

* Reshape long
    // Check
    unique market_no year month nutr_no case_id HHID y2_hhid y3_hhid ///
	data_round date_consump
	// should be 4508*23*127=13,167,868
	quietly cap drop _*

reshape long NR, i(market_no year month nutr_no hhxround date_consump) j(NR_no)
order NR_no, after(NR)
describe NR_no
lab drop domain
tab2 nutr_no NR_no

// Sample size check
unique market_no year month nutr_no hhxround
	* Should be 13,167,868*4=52,671,472
		quietly cap drop _*

unique market_no year month hhxround 
	* Should be 572,516
		quietly cap drop _*

* Insert constraint signs
gen rel=">="
replace rel="=" if nutr_no==1 // Price=
replace rel="=" if nutr_no==2 // Energy=
replace rel="<=" if NR_no==2 // UL<=
replace rel="<=" if NR_no==4 // AMDR upper bound<=
tab nutr_no if NR==.
tab nutr_no if NR==0
drop if NR==. // Drops if there's no UL or AMDR
drop if NR==0 & nutr_no!=1
sum // check
sort hhxround year month nutr_no NR_no
drop NR_no
order NR rel, last
rename NR rhs
order rel, before(rhs)

* Change the nutrients composition data to be unit per kg (now is per 100g)
forvalues i=2/23 {
forvalues j=1/51{ 
quietly replace F`j'_=F`j'_*10 if nutr_no==`i' 
}
}

* Change everything in the unit per g (prices were already per kg, now all per gram)
forvalues i=1/23 {
forvalues j=1/51{ 
quietly replace F`j'_=F`j'_/1000 if nutr_no==`i' 
}
}

* Rename variables 
forvalues j=1/51 {  
quietly rename F`j'_ F`j' 
}

* Replace missing as 0
forvalues j=1/51 {    
quietly replace F`j'=0 if F`j'==. 
}

replace rhs=0 if rhs==.

order rel, before(rhs)

saveold "HH+CPI_LPInput_sharing_s1`s'.dta", replace

}

forval s=2/6 {
// PART 1 // PREPARE SHARING SCENARIO DATA FOR LINEAR PROGRAMMING
* Join household and market level data to expand out every household
* 		by it's nearest market price time series
use "HHdata_tomerge_sharing_oldstata.dta", clear
joinby market_no nutr_no using "CPIDataForCoNA_tomerge_oldstata_s`s'.dta"

sort hhxround year month nutr_no 

* Checks for post-merge and after linear programming
tabstat ear ul amdr_lower amdr_upper, by(nutr_no) stats(mean sd min max count) c(s)
bys nutr_no: tabstat F*, stats(mean sd min max count) c(s)


order hhxround case_id HHID data_round nutr_no ear ul amdr_lower amdr_upper date_consump market_no year month, before(F1_)
sum case_id HHID data_round date_consump nutr_no ear ul amdr_lower amdr_upper
	// total observations should be 4508*23*127=13,167,868

rename ear NR1
	lab var NR1 "EAR" 
rename ul NR2
	lab var NR2 "UL"
rename amdr_lower NR3
	lab var NR3 "AMDR-lower"
rename amdr_upper NR4
	lab var NR4 "AMDR-upper"
order market_no year month nutr_no nutr case_id HHID y2_hhid y3_hhid data_round date_consump
sort hhxround year month nutr_no

unique market_no year month case_id HHID y2_hhid y3_hhid data_round 
	// Should be 4508*127=572,516
	cap drop _*

* Reshape long
    // Check
    unique market_no year month nutr_no case_id HHID y2_hhid y3_hhid ///
	data_round date_consump
	// should be 4508*23*127=13,167,868
	quietly cap drop _*

reshape long NR, i(market_no year month nutr_no hhxround date_consump) j(NR_no)
order NR_no, after(NR)
describe NR_no
lab drop domain
tab2 nutr_no NR_no

// Sample size check
unique market_no year month nutr_no hhxround
	* Should be 13,167,868*4=52,671,472
		quietly cap drop _*

unique market_no year month hhxround 
	* Should be 572,516
		quietly cap drop _*

* Insert constraint signs
gen rel=">="
replace rel="=" if nutr_no==1 // Price=
replace rel="=" if nutr_no==2 // Energy=
replace rel="<=" if NR_no==2 // UL<=
replace rel="<=" if NR_no==4 // AMDR upper bound<=
tab nutr_no if NR==.
tab nutr_no if NR==0
drop if NR==. // Drops if there's no UL or AMDR
drop if NR==0 & nutr_no!=1
sum // check
sort hhxround year month nutr_no NR_no
drop NR_no
order NR rel, last
rename NR rhs
order rel, before(rhs)

* Change the nutrients composition data to be unit per kg (now is per 100g)
forvalues i=2/23 {
forvalues j=1/51{ 
quietly replace F`j'_=F`j'_*10 if nutr_no==`i' 
}
}

* Change everything in the unit per g (prices were already per kg, now all per gram)
forvalues i=1/23 {
forvalues j=1/51{ 
quietly replace F`j'_=F`j'_/1000 if nutr_no==`i' 
}
}

* Rename variables 
forvalues j=1/51 {  
quietly rename F`j'_ F`j' 
}

* Replace missing as 0
forvalues j=1/51 {    
quietly replace F`j'=0 if F`j'==. 
}

replace rhs=0 if rhs==.

order rel, before(rhs)

saveold "HH+CPI_LPInput_sharing_s`s'.dta", replace

}
