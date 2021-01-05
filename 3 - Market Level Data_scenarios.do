/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: 
	1. Change price and food composition to reflect modeled scenarios
	2. Reshape each new dataset for merge with household data and linear programming
*/

// PART 0 // FILE MANAGEMENT
global ihpsraw "MWI_IHPS_2010-2013-2016"
global otherrawdata "datafolder"
global analysis "workingfolder"
global nutrients energy carbohydrate protein lipids vitA retinol vitC vitE thiamin riboflavin niacin vitB6 folate ///
	vitB12 calcium copper iron magnesium phosphorus selenium zinc sodium
global foodcomp "\MalawiFoods_FoodComp_Prices.xlsx"

* Working directory
cd "$analysis"
cap log close
log using "03_Market data scenarios_`c(current_date)'", replace
***Log of Do File #3_scenarios "Market Level Data - Scenarios"
di "`c(current_date)' `c(current_time)'"

* Create dataset of Malawi CPI to deflate prices
import excel using "$otherrawdata/Malawi CPI 1990-2019 RBM", firstrow clear
describe Dates
gen year=year(Dates)
gen month=month(Dates)
drop if month==.
	gen dateMY=ym(year, month)
	format dateMY %tmCCYY-NN
	tab dateMY, m
	lab var dateMY "Date (Month-Year)"
drop Dates
ren OverallCPI CPI
ren FoodCPI foodCPI
ren XfoodCPI nonfoodCPI
browse if CPI==100
	* CPI was rebased in December 2012 and again in December 2017
save MalawiCPI, replace

// PART 1 // CREATE DATASET FOR EACH SCENARIO

use CPIDataForCoNA, clear

	// Create dummy variable for available
	gen available=1 if uni_price_net!=.
		replace available=0 if uni_price_net==.
	tab food_item, sum(available)
	
* Prices before 
gen uni_price_net_orig=uni_price_net
	lab var uni_price_net_orig "Original price"
	
save CPIDataForCoNA_forscenarios, replace

// PART 2 // SCENARIOS
* Median price over all markets by month in nominal terms 
	/* Use of nominal prices rationale:
		- Does not distort seasonal fluctuation if present
		- Deflating food prices by CPI may be biased depending on how much 
			weight each specific food gets in the CPI, and because food overall
			carries the majority weight in the index
		- Deflating to identify the median in real prices and then reflating doesn't make sense
		- But because of using nominal prices, taking the median at the month level, not year
			*/

****************
* Scenario 1: % Price reduction in eggs
use CPIDataForCoNA_forscenarios, clear
* Eggs: food_no==46
	* Availability by market
	tab market if food_no==46, sum(available)
	sum available if food_no==46, d
	tempvar meanavail
		egen `meanavail'=mean(available) if food_no==46, by(market_no)
		kdensity `meanavail'	

egen medianprice=median(uni_price_net) if food_no==46, by(dateMY)
tab uni_price_net if food_no==46, m
tab medianprice if food_no==46, m

replace uni_price_net=medianprice if uni_price_net==. & food_no==46
drop medianprice
		
replace uni_price_net=uni_price_net*0.90 if food_no==46
save CPIDataForCoNA_s1a, replace

use CPIDataForCoNA_forscenarios, clear
replace uni_price_net=uni_price_net*0.85 if food_no==46
save CPIDataForCoNA_s1b, replace

use CPIDataForCoNA_forscenarios, clear
replace uni_price_net=uni_price_net*0.80 if food_no==46
save CPIDataForCoNA_s1c, replace

****************
* Scenario 2: Dried and tinned fishes available in all markets and months at median price
use CPIDataForCoNA_forscenarios, clear
* Dried fish: inlist(food_no,33,34,35)
	* Availability by market
	tab market if food_no==33, sum(available)
	sum available if food_no==33, d
	tempvar meanavail
		egen `meanavail'=mean(available) if food_no==33, by(market_no)
		kdensity `meanavail'

egen medianprice=median(uni_price_net) if food_no==33, by(dateMY)
tab uni_price_net if food_no==33, m
tab medianprice if food_no==33, m

replace uni_price_net=medianprice if uni_price_net==. & food_no==33
drop medianprice
tab uni_price_net if food_no==33, m

save CPIDataForCoNA_s2, replace

****************
* Scenario 3: Groundnuts available in all markets and months at 10% reduction in price
use CPIDataForCoNA_forscenarios, clear
* Groundnuts: food_no==13
	* Availability by market
	tab market if food_no==13, sum(available)
	sum available if food_no==13, d
	tempvar meanavail
		egen `meanavail'=mean(available) if food_no==13, by(market_no)
		kdensity `meanavail'

egen medianprice=median(uni_price_net) if food_no==13, by(dateMY)
tab uni_price_net if food_no==13, m
tab medianprice if food_no==13, m

replace uni_price_net=medianprice if uni_price_net==. & food_no==13
drop medianprice
tab uni_price_net if food_no==13, m

replace uni_price_net=uni_price_net*0.90 if food_no==13

save CPIDataForCoNA_s3, replace

****************
* Scenario 4: Fresh milk available in all markets and months at 10% reduction in price
use CPIDataForCoNA_forscenarios, clear
* Fresh milk: food_no==44
	* Availability by market
	tab market if food_no==44, sum(available)
	sum available if food_no==44, d
	tempvar meanavail
		egen `meanavail'=mean(available) if food_no==44, by(market_no)
		kdensity `meanavail'

egen medianprice=median(uni_price_net) if food_no==44, by(dateMY)
tab uni_price_net if food_no==44, m
tab medianprice if food_no==44, m

replace uni_price_net=medianprice if uni_price_net==. & food_no==44
drop medianprice
tab uni_price_net if food_no==44, m

replace uni_price_net=uni_price_net*0.90 if food_no==44

save CPIDataForCoNA_s4, replace

****************
* Scenario 5: Powdered milk available in all markets and months at median price
use CPIDataForCoNA_forscenarios, clear
* Powdered milk: food_no==45
	* Availability by market
	tab market if food_no==45, sum(available)
	sum available if food_no==45, d
	tempvar meanavail
		egen `meanavail'=mean(available) if food_no==45, by(market_no)
		kdensity `meanavail'
		
egen medianprice=median(uni_price_net) if food_no==45, by(dateMY)
tab medianprice if food_no==45, m

replace uni_price_net=medianprice if uni_price_net==. & food_no==45
drop medianprice
 
save CPIDataForCoNA_s5, replace

****************
* Scenario 6: Selenium soil biofortification
use CPIDataForCoNA_forscenarios, clear
* Maize grain: inlist(food_no,1,2)
* Maize flour (dehulled): food_no==3
* Maize flour (whole grain): food_no==4

replace selenium=11.3 if inlist(food_no,1,2,4)
replace selenium=5.1 if food_no==3

save CPIDataForCoNA_s6, replace

* Save old stata format
foreach s in a b c {
use CPIDataForCoNA_s1`s', clear
saveold CPIDataForCoNA_oldstata_s1`s', replace
}

forval s=2/6 {
use CPIDataForCoNA_s`s', clear
saveold CPIDataForCoNA_oldstata_s`s', replace
}

****************

// PART 2 // TRANSFORM AND RESHAPE FOR LINEAR PROGRAMMING

foreach s in a b c {

* Further clean and transform the dataset for linear programming in R
use CPIDataForCoNA_s1`s', clear

* Only keep variables of market_no, year, month, price (MWK), and nutritional contents  
keep market_no year month food_no uni_price_net $nutrients 
sort market_no year month food_no
sum

* Nothing for free assumption
tab food_no if uni_price_net==.
replace uni_price_net=0 if uni_price_net==.

foreach x in $nutrients { 
	replace `x'=0 if uni_price_net==0
	}

* Reshape
reshape wide uni_price_net energy carbohydrate protein lipids vitA retinol ///
	vitC vitE thiamin riboflavin niacin vitB6 folate vitB12 calcium ///
	copper iron magnesium phosphorus selenium zinc sodium, ///
	i(market_no year month) j(food_no)

* Rename variables
rename uni_price_net* F*_1
rename energy* F*_2
rename carbohydrate* F*_3
rename protein* F*_4
rename lipids* F*_5
rename vitA* F*_6
rename retinol* F*_7
rename vitC* F*_8
rename vitE* F*_9
rename thiamin* F*_10
rename riboflavin* F*_11
rename niacin* F*_12
rename vitB6* F*_13
rename folate* F*_14
rename vitB12* F*_15
rename calcium* F*_16
rename copper* F*_17
rename iron* F*_18
rename magnesium* F*_19
rename phosphorus* F*_20
rename selenium* F*_21
rename zinc* F*_22
rename sodium* F*_23

reshape long F1_ F2_ F3_ F4_ F5_ F6_ F7_ F8_ F9_ F10_ F11_ F12_ F13_ F14_ F15_ ///
F16_ F17_ F18_ F19_ F20_ F21_ F22_ F23_ F24_ F25_ F26_ F27_ F28_ F29_ F30_ F31_ ///
F32_ F33_ F34_ F35_ F36_ F37_ F38_ F39_ F40_ F41_ F42_ F43_ F44_ F45_ F46_ ///
F47_ F48_ F49_ F50_ F51_, i(market_no year month) j(nutr_no)

tab nutr_no
cap lab drop nutr
lab def nutr ///
	1 "Price" ///
	2 "Energy" ///
	3 "Carbohydrates" ///
	4 "Protein" ///
	5 "Lipids" ///
	6 "Vit A" ///
	7 "Retinol"  ///
	8 "Vit C" ///
	9 "Vit E" ///
	10 "Thiamin" /// 
	11 "Riboflavin" ///
	12 "Niacin" ///
	13 "Vit B6" ///
	14 "Folate" ///
	15 "Vit B12" ///
	16 "Calcium" ///
	17 "Copper" ///
	18 "Iron" ///
	19 "Magnesium" ///
	20 "Phosphorus" ///
	21 "Selenium" ///
	22 "Zinc" ///
	23 "Sodium"
lab val nutr_no nutr

* Document Sample Size
distinct market_no year month
unique market_no year month

* Drop the August 2017 observation so there are 127 per market
	// These occur after last household observation anyways so will be dropped eventually
tab month year
drop if month==8 & year==2017
	// confirm 127 observations per market
	forval i=1/29 {
	di as text "Market Number is:" as result "`i'"
	unique year month if market_no==`i'
	}
	* Total number of loops with addition of sodium and reduction of August 2017 will be 3683
	unique year month market

* Sort
sort market_no year month nutr_no
	
* Checks for post-merge and after linear programming
bys nutr_no: tabstat F*, stats(mean sd min max count) c(s)
	
save CPIDataForCoNA_tomerge_s1`s', replace
* Save in format that is readable by older versions of Stata
	// Stata 13 is available on Tufts high power cluster computer with interactive interface option
saveold CPIDataForCoNA_tomerge_oldstata_s1`s', replace
}


forval s=2/6 {

* Further clean and transform the dataset for linear programming in R
use CPIDataForCoNA_s`s', clear

* Only keep variables of market_no, year, month, price (MWK), and nutritional contents  
keep market_no year month food_no uni_price_net $nutrients 
sort market_no year month food_no
sum

* Nothing for free assumption
tab food_no if uni_price_net==.
replace uni_price_net=0 if uni_price_net==.

foreach x in $nutrients { 
	replace `x'=0 if uni_price_net==0
	}

* Reshape
reshape wide uni_price_net energy carbohydrate protein lipids vitA retinol ///
	vitC vitE thiamin riboflavin niacin vitB6 folate vitB12 calcium ///
	copper iron magnesium phosphorus selenium zinc sodium, ///
	i(market_no year month) j(food_no)

* Rename variables
rename uni_price_net* F*_1
rename energy* F*_2
rename carbohydrate* F*_3
rename protein* F*_4
rename lipids* F*_5
rename vitA* F*_6
rename retinol* F*_7
rename vitC* F*_8
rename vitE* F*_9
rename thiamin* F*_10
rename riboflavin* F*_11
rename niacin* F*_12
rename vitB6* F*_13
rename folate* F*_14
rename vitB12* F*_15
rename calcium* F*_16
rename copper* F*_17
rename iron* F*_18
rename magnesium* F*_19
rename phosphorus* F*_20
rename selenium* F*_21
rename zinc* F*_22
rename sodium* F*_23

reshape long F1_ F2_ F3_ F4_ F5_ F6_ F7_ F8_ F9_ F10_ F11_ F12_ F13_ F14_ F15_ ///
F16_ F17_ F18_ F19_ F20_ F21_ F22_ F23_ F24_ F25_ F26_ F27_ F28_ F29_ F30_ F31_ ///
F32_ F33_ F34_ F35_ F36_ F37_ F38_ F39_ F40_ F41_ F42_ F43_ F44_ F45_ F46_ ///
F47_ F48_ F49_ F50_ F51_, i(market_no year month) j(nutr_no)

tab nutr_no
cap lab drop nutr
lab def nutr ///
	1 "Price" ///
	2 "Energy" ///
	3 "Carbohydrates" ///
	4 "Protein" ///
	5 "Lipids" ///
	6 "Vit A" ///
	7 "Retinol"  ///
	8 "Vit C" ///
	9 "Vit E" ///
	10 "Thiamin" /// 
	11 "Riboflavin" ///
	12 "Niacin" ///
	13 "Vit B6" ///
	14 "Folate" ///
	15 "Vit B12" ///
	16 "Calcium" ///
	17 "Copper" ///
	18 "Iron" ///
	19 "Magnesium" ///
	20 "Phosphorus" ///
	21 "Selenium" ///
	22 "Zinc" ///
	23 "Sodium"
lab val nutr_no nutr

* Document Sample Size
distinct market_no year month
unique market_no year month

* Drop the August 2017 observation so there are 127 per market
	// These occur after last household observation anyways so will be dropped eventually
tab month year
drop if month==8 & year==2017
	// confirm 127 observations per market
	forval i=1/29 {
	di as text "Market Number is:" as result "`i'"
	unique year month if market_no==`i'
	}
	* Total number of loops with addition of sodium and reduction of August 2017 will be 3683
	unique year month market

* Sort
sort market_no year month nutr_no
	
* Checks for post-merge and after linear programming
bys nutr_no: tabstat F*, stats(mean sd min max count) c(s)
	
save CPIDataForCoNA_tomerge_s`s', replace
* Save in format that is readable by older versions of Stata
	// Stata 13 is available on Tufts high power cluster computer with interactive interface option
saveold CPIDataForCoNA_tomerge_oldstata_s`s', replace
}

log close
