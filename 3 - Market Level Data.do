/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: 
	1. Merge market prices and food composition data
	2. Standardize food, nutrient and price units
	3. Merge in geographic variables that match to IHPS data
	4. Further reshape and prepare data to merge with IHPS data and run linear programming
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
log using "02_Market data_`c(current_date)'", replace
***Log of Do File #3 "Market Level Data"
di "`c(current_date)' `c(current_time)'"

// PART 1 // MERGE PRICES AND COMPOSITION
* Import Food Composition Databases
clear
import excel "$otherrawdata$foodcomp", sheet("MalawiFoodsComp") firstrow clear
tempfile MalawiFoodsComp
	save `MalawiFoodsComp', replace

clear
import excel "$otherrawdata$foodcomp", sheet("USDAFoodsComp") firstrow clear
destring USDA_code, replace
tempfile USDAFoodsComp
	save `USDAFoodsComp', replace

clear
import excel "$otherrawdata$foodcomp", sheet("Food_Identification") firstrow clear
sum
destring USDA_code, replace

* Merge food composition databases
merge m:1 USDA_code using `USDAFoodsComp'
drop if _merge==2
drop _merge
merge m:1 MW_code using `MalawiFoodsComp'
drop if _merge==2
drop _merge
sort food_no
encode FCT_Source_Primary, gen(FCT_source_filter)
	tab FCT_source_filter
	tab FCT_source_filter, nolabel
	recode FCT_source_filter (1=3) (2=1) (3=2)
	lab def fct 1 "MW" 2 "USDA" 3 "Excluded, no comp data"
	lab val FCT_source_filter fct
	tab fooditem, sum(FCT_source_filter) // check
destring, replace
drop AU-FO

// PART 2 // GENERATE NUTRIENT VARIABLES
* 23 Nutrients included as constraints in our analyses
	// Food composition attribution: 
	// Malawi value selected as default and USDA as secondary data source
		* Malawi data has been confirmed with the compilers of the FCT
		
gen energy=EnergyCalculatedkCal if FCT_source_filter==1
replace energy=Energ_Kcal if FCT_source_filter==2
	list fooditem if energy==. & EnergyCalculatedkCal==. & FCT_source_filter!=3

gen protein=Totalproteing if FCT_source_filter==1
replace protein=Protein if FCT_source_filter==2
	list fooditem if protein==. & Totalproteing==. & FCT_source_filter!=3

gen lipids=TotalFatsg if FCT_source_filter==1
replace lipids=Lipid_Tot if FCT_source_filter==2
	list fooditem if lipids==. & TotalFatsg==. & FCT_source_filter!=3

	replace TotalCHOforUDB="0" if TotalCHOforUDB=="[0]"
	destring TotalCHOforUDB, replace
gen carbohydrate=TotalCHOforUDB if FCT_source_filter==1
replace carbohydrate=Carbohydrt if FCT_source_filter==2
	list fooditem if carbohydrate==. & TotalCHOforUDB==. & FCT_source_filter!=3

gen calcium=Camg if FCT_source_filter==1
replace calcium=Calcium if FCT_source_filter==2
	list fooditem if calcium==. & Camg==. & FCT_source_filter!=3

gen iron=Femg if FCT_source_filter==1
replace iron=Iron if FCT_source_filter==2
	list fooditem if iron==. & Femg==. & FCT_source_filter!=3
	
gen magnesium=Mgmg if FCT_source_filter==1
replace magnesium=Magnesium if FCT_source_filter==2
	list fooditem if magnesium==. & Mgmg==. & Magnesium!=. & FCT_source_filter!=3
	
	replace Pmg="42" if Pmg=="[42]"
	destring Pmg, replace
gen phosphorus=Pmg if FCT_source_filter==1
replace phosphorus=Phosphorus if FCT_source_filter==2
	list fooditem if phosphorus==. & Pmg==. & Phosphorus!=. & FCT_source_filter==1

gen zinc=Znmg if FCT_source_filter==1
replace zinc=Zinc if FCT_source_filter==2
	list fooditem if zinc==. & Znmg==. & Zinc!=. & FCT_source_filter==1	

gen copper=Cumg if FCT_source_filter==1
replace copper=Copper if FCT_source_filter==2
	list fooditem if copper==. & Cumg==. & Copper!=. & FCT_source_filter==1

gen selenium=Semcg if FCT_source_filter==1
replace selenium=Selenium if FCT_source_filter==2
	list fooditem if selenium==. & Semcg==. & Selenium!=. & FCT_source_filter!=3
	* NOTE: many selenium containing foods missing selenium values

gen vitC=VitaminCmg if FCT_source_filter==1
replace vitC=Vit_C if FCT_source_filter==2
	list fooditem food_no if vitC==. & VitaminCmg==. & Vit_C!=. & FCT_source_filter!=3 
	
gen thiamin=Thiaminmg if FCT_source_filter==1
replace thiamin=Thiamin if FCT_source_filter==2
	list fooditem food_no if thiamin==. & Thiaminmg==. & Thiamin!=. & FCT_source_filter!=3
	
gen riboflavin=Riboflavinmg if FCT_source_filter==1
replace riboflavin=Riboflavin if FCT_source_filter==2
	list fooditem food_no if riboflavin==. & Riboflavinmg==. & Riboflavin!=. & FCT_source_filter!=3 
	
gen niacin=Niacinmg if FCT_source_filter==1
replace niacin=Niacin if FCT_source_filter==2
	list fooditem food_no if niacin==. & Niacinmg==. & Niacin!=. & FCT_source_filter!=3 
	
gen vitB6=VitaminB6mg if FCT_source_filter==1
replace vitB6=Vit_B6 if FCT_source_filter==2
	list fooditem food_no if vitB6==. & VitaminB6mg==. & Vit_B6!=. & FCT_source_filter!=3 
	
gen folate=Folicacidmcg if FCT_source_filter==1
replace folate=Folate_Tot if FCT_source_filter==2
	list fooditem food_no if folate==. & Folicacidmcg==. & Folate_Tot!=. & FCT_source_filter!=3 

	tab VitaminB12mcg
	replace VitaminB12mcg="0" if VitaminB12mcg=="(0.0)"
	destring VitaminB12mcg, replace
gen vitB12=VitaminB12mcg if FCT_source_filter==1
replace vitB12=Vit_B12 if FCT_source_filter==2
	list fooditem food_no if vitB12==. & VitaminB12mcg==. & Vit_B12!=. & FCT_source_filter!=3 
	
gen vitA=VitaminARAEmcg if FCT_source_filter==1
replace vitA=Vit_A_RAE if FCT_source_filter==2
	list fooditem food_no if vitA==. & VitaminARAEmcg==. & Vit_A_RAE!=. & FCT_source_filter!=3
	* METHOD NOTE:
	* Malawi has several missing vitamin A values or carotenoid foods with values in RE units only
	* Use USDA values for vegetables, fruit, meat and dairy (justified by the fact that these are not influenced by soil conditions)
	replace vitA=Vit_A_RAE if inlist(food_no,6,18,20,21,26,41,45,205,208,402,405,504,604,609,703) & FCT_source_filter==1
	tab fooditem if inlist(food_no,6,18,20,21,26,41,45,205,208,402,405,504,604,609,703) & FCT_source_filter==1, sum(food_no)
	gen vitA_source=1 if FCT_source_filter==1 & !inlist(food_no,6,18,20,21,26,41,45,205,208,402,405,504,604,609,703)
	replace vitA_source=2 if FCT_source_filter==2 | (inlist(food_no,6,18,20,21,26,41,45,205,208,402,405,504,604,609,703) & FCT_source_filter==1)

list fooditem food_no if Retinol!=. & FCT_source_filter==1 & Retinol!=0
gen retinol=Retinol if FCT_source_filter==2 
	// Malawi FCT does not record retinol, use USDA values for all except fishes and enriched cereal (buns)
replace retinol=Retinol if FCT_source_filter==1 & inlist(food_no,31,43,44,45,46,501,506,508,509,522,701,702,823)
	tab fooditem if inlist(food_no,31,43,44,45,46,501,506,508,509,522,701,702,823) & FCT_source_filter==1, sum(food_no)
	gen retinol_source=2 if  FCT_source_filter==2 | (inlist(food_no,31,43,44,45,46,501,506,508,509,522,701,702,823) & FCT_source_filter==1)

gen vitE=VitaminEmg if FCT_source_filter==1
replace vitE=Vit_E if FCT_source_filter==2
	list fooditem food_no if vitE==. & VitaminEmg==. & Vit_E!=. & Vit_E!=0 & FCT_source_filter!=3

gen sodium=Namg if FCT_source_filter==1
replace sodium=Sodium if FCT_source_filter==2
	list fooditem food_no if sodium==. & Namg==. & Sodium!=. & Sodium!=0 & FCT_source_filter!=3
	
order $nutrients, after(food_no)
sum $nutrients
foreach v in $nutrients {
	di as text "`v'"
	tab fooditem, sum(`v')
	}
foreach v in $nutrients {
	lab var `v' "`v' per 100g"
	}

* Transform refusal percentage in %
	// Note refusal percentage is based on USDA codes
gen refusal_pct=Refuse_Pct/100
drop Refuse_Pct

keep food_no-MWI_food_group_name FCT_source_filter-refusal_pct
drop if food_no==.

* Generate age group identifier for infant formula
gen formula_agegroup=.
replace formula_agegroup=2 if note=="Child age-gender group 2"
replace formula_agegroup=3 if note=="Child age-gender group 3"

save FoodComp, replace

* Import Food Price Databases
clear
import excel "$otherrawdata$foodcomp", sheet("MalawiFoodPrice") firstrow clear
sum

* Reshape into long format
reshape long food, i(market year month) j(food_no)
tab food_no
rename food price_lcu

* Merge with food composition dataset
merge m:m food_no using FoodComp
sort market food_no year month
tab food_no
drop _merge
describe market
tab market, m
distinct market // 29 Markets
unique market month year // 3701 unique market-month-year combinations (for R)
tab month, m
tab year, m
tab market, m
* browse if year==. // IHPS foods
drop if year==.
distinct market // 29 Markets
unique market month year // 3701 unique market-month-year combinations (for R)

* Encode market in alphabetical order
egen market_no=group(market)
order market_no, before(market)
tab market, sum(market_no) // Confirm 29 markets
tab market_no, m
	tab market, sum(market_no) // Market Labels 
	
* Summarize prices in original units	
tab food_no, sum(price_lcu)

// PART 2 // CONVERT UNITS & MANAGE FOOD ITEMS
* Understand different units of all food items and change all of them into "kg"
tab unit, m
	// Conversion factors obtained from:
		* NSO Provided to Stevier Kaiyatsa
		* https://www.aqua-calc.com/calculate/food-volume-to-weight based on USDA
tab2 volume unit
	
* Convert g to kg
replace volume=volume/1000 if unit=="g"
replace unit="kg" if unit=="g"
		
* Foods with prices as item have been replaced in spreadsheet using conversion factors
	// provided to Stevier Kaiyatsa by NSO: Biscuits, Mandazi and White buns
	ren fooditem food_item
	tab food_item if unit=="item" // Check - none

* Convert units for liquids in liters 
tab food_item volume if unit=="liter", sum(food_no)
	* Cooking Oil (Sunflower oil)
		// Aqua-calc item: Oil, sunflower, linoleic, (approx. 65%)
		// 1 liter = 0.92kg
		replace volume=volume*0.92 if unit=="liter" & inlist(food_no, 47, 48)
		replace unit="kg" if unit=="liter" & inlist(food_no, 47, 48)

* Convert units for liquids in mL
tab food_item volume if unit=="ml", sum(food_no)
	* Milk
		// Aqua-calc item:Milk, whole, 3.25% milkfat, without added vitamin A and vitamin D
		// 1 liter=1.01 kg
	replace volume=(volume/1000)*1.01 if food_item=="Fresh milk"
	replace unit="kg" if food_item=="Fresh milk"
	* Maheu
		// Aqua-calc item:Beverages, coffee substitute, cereal grain beverage, powder, prepared with whole milk
		// 1 liter=1.04 kg
	replace volume=(volume/1000)*1.04 if food_item=="Maheu"
	replace unit="kg" if food_item=="Maheu" 
	* Coca-Cola
		//Aqua-calc item: Beverages, carbonated, cola, regular
		// 1 liter=1.04 kg
	replace volume=(volume/1000)*1.04 if food_item=="Cocacola"
	replace unit="kg" if food_item=="Cocacola" 

* Fix unit for eggs in years after 2012
tab unit volume if food_item=="Chicken eggs"
tab note if food_item=="Chicken eggs"
tab note2 if food_item=="Chicken eggs" 
	* For egg, unit is 10 eggs between 2007-2012, but 30 eggs after 2013
		// Volume in spreadsheet is for a single egg (avg. weight in kg), provided by NSO
	replace volume=volume*10 if food_item=="Chicken eggs" & year<=2012
	replace volume=volume*30 if food_item=="Chicken eggs" & year>2012

* Check food unit again to confirm everything is in "kg" now
tab unit
sum // N=203,555

* Review food list
sort food_no
tab food_item, sum(food_no)
tab food_no // Confirm 3,701 observations per food item (corresponds to market-month-year)

* Drop tea (3 types) and Maheu due to lack of appropriate food composition data
tab food_item if inlist(food_no,51,52,53,55)
drop if inlist(food_no,51,52,53,55) // 51 food and beverage items remain

* Recode food number variable to be sequential (after foods are dropped)
tab food_no
recode food_no (54=51)
tab food_item, sum(food_no)
tab food_no
order food_no, after(month) 
tab food_item, sum(food_no)

* Calculate different variables of prices (per kg)
* 1) Price per kg in local currency
tab volume, m // confirm no missing
tab food_item if price_lcu==. // Missing price observations (N=63,083)
gen uni_price_mwk=price_lcu/volume
tab food_no, sum(uni_price_mwk)
tab food_item if uni_price_mwk==. // N=63,083

* 2) Price per kg of edible portion in nominal MWK
* Check which food items do not have refusal percentage data (fish, oil and powder milk)
sum refusal_pct
tab food_item if refusal_pct>0 & refusal_pct!=., sum(refusal_pct)
tab food_item if refusal_pct==., sum(food_no) // N=25,907 
* Assume the refusal percentage of these food items are zero
replace refusal_pct=0 if refusal_pct==.
* Generate price per kg of edible portion 
gen uni_price_net=uni_price_mwk/(1-refusal_pct) // missing N=63,083: no price
lab var uni_price_net "Net Unit Price (nominal MWK)"

order uni_price_mwk uni_price_net, after(price_lcu) 
order food_item, after (food_no)

save CPIDataForCoNA, replace

// PART 3 // DATA MANAGEMENT TO MERGE MARKET AND HOUSEHOLD DATA
* Import matching file (matches IHPS EAs to CPI markets) 
	clear
	import excel "$otherrawdata\IHPS-EAID_CPI-Market", sheet(Market_Match) firstrow
	drop ea_id region
	collapse (first) district_name market market_no, by(district)
	foreach v in district_name market market_no {
		lab var `v' ""
		}
	save market_match, replace
	
* Import region, district and urban/rural identifiers for markets
import excel "$otherrawdata\Additional Data\CPI\MalawiMktPrices_Recd25Jan2018_ks.xlsx", firstrow clear
	describe
	keep region district market_centre rural_urban
	tab market_centre, m
	rename market_centre market
	drop if market=="" // Empty lines result from import excel
	tempvar dup
	bys market:  gen `dup'=cond(_N==1,0,_n)
	tab `dup'
	drop if `dup'>1
	tab market
	
	// Merge in market number with CPI data
	merge 1:m market using CPIDataForCoNA, keepusing(market_no)
	drop _merge
	tab market, sum(market_no)
	distinct market market_no
	unique market market_no
	tempvar dup
	bys market_no:  gen `dup'=cond(_N==1,0,_n)
	tab `dup'
	drop if `dup'>1
	sum
	tab market, sum(market_no)

tempfile CPI_Geos
save `CPI_Geos', replace

* Merge geo variables with food item level dataset
use CPIDataForCoNA, clear
	cap drop _merge
	merge m:1 market market_no using `CPI_Geos'
	drop _merge
	order region district, after(market)
	cap drop __000000 __000001
	
	// Generate Year-month variable
	tab year
	tab month
	cap drop dateMY
	gen dateMY=ym(year, month)
	format dateMY %tmCCYY-NN
	tab dateMY, m
	lab var dateMY "Date (Month-Year)"

sort market_no year month food_no
	
save CPIDataForCoNA, replace
saveold CPIDataForCoNA_oldstata, replace

// PART 4 // TRANSFORM AND RESHAPE FOR LINEAR PROGRAMMING

* Further clean and transform the dataset for linear programming in R
clear
use CPIDataForCoNA, clear

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
	
save CPIDataForCoNA_tomerge, replace
* Save in format that is readable by older versions of Stata
	// Stata 13 is available on Tufts high power cluster computer with interactive interface option
saveold CPIDataForCoNA_tomerge_oldstata, replace

* Prepare PPP data to convert results to 2011 PPP USD
* Import the World Bank PPP convention factor Database and convert to monthly PPP
import excel "$otherrawdata\MalawiFoods_FoodComp_Prices.xlsx", sheet("MalawiPPP") firstrow clear
tsset year, yearly
save ppp_annual, replace

log close
