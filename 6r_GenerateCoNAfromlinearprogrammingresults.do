/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: Take linear programming output to generate CoNA and nutrient and semi-elasticities
		with revised shared nutrient requirements (defined by members 4 and above only)
NOTE: This analysis requires substantial computing power. It will need days to
	  run on a standard desktop. Use of a supercomputer (e.g. high powered cluster)
	  is necessary.
*/

// PART 0 // FILE AND BIG DATA WORKFLOW MANAGEMENT
cd "yourfilepath"
cap log close
log using "06r_GenerateCoNA_SemiElasticities_`c(current_date)'", replace
***Log of Do File #6r "Transform Linear Programming Output into Variables"
di "`c(current_date)' `c(current_time)'"

global nutrients energy carbohydrate protein lipids vitA retinol vitC vitE thiamin riboflavin niacin vitB6 folate ///
	vitB12 calcium copper iron magnesium phosphorus selenium zinc sodium
set more off

* SHARING SCENARIO (HOUSEHOLDS)

// PART 1 // GENERATE CONA - SHARING
* Create food composition data to merge back in
use "CPIDataForCoNA_oldstata.dta", clear 

keep food_no food_item $nutrients refusal_pct food_group food_group_name ///
MWI_food_group_name MWI_food_group
	* Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
			local l`v' "`v'"
			}
		}
	* Collapse
	collapse (first) food_item $nutrients refusal_pct food_group ///
	food_group_name MWI_food_group_name MWI_food_group, by(food_no)
	*Relabel
	foreach v of var * {
		label var `v' "`l`v''"
			}
		
save "CPIDataForCoNA_foodcomp.dta", replace

* Read R result back to Stata
clear
insheet using "HH_LPResults_sharing_r.csv"
describe
sum
save "HH_LPResults_sharing_r.dta", replace

* Generate market number, year and month
use "HH+CPI_LPInput_sharing_r.dta", clear
describe
sum
collapse (mean) nutr_no (first) market_no, by(hhxround case_id HHID y2_hhid y3_hhid year month data_round date_consump)
egen v1=seq() 
order v1, first
drop nutr_no

* Add linear programming food intakes 
merge 1:1 v1 using "HH_LPResults_sharing_r.dta"
drop v1 _merge
forvalues i=2/52 {
rename v`i' F`=`i'-1'
}
describe
sum
gen nutr_no=0
order nutr_no, before(F1)
order market_no, before(nutr_no)

* Add food price data
append using "HH+CPI_LPInput_sharing_r.dta"
cap drop rel rhs
sum
describe
sort case_id HHID y2_hhid y3_hhid year month nutr_no
order hhxround case_id HHID y2_hhid y3_hhid market_no data_round date_consump year month nutr_no, before(F1)
sum if hhxround==. // check, this variable was creating a problem

tab nutr_no, m
	* Nutr_no=0 : Intake - confirmed 
	* Nutr_no=1 : Price - confirmed
sum if nutr_no==0 // intake (grams)
sum if nutr_no==1 // price (Nominal MWK per gram)	
	
drop if nutr_no>1 // Keep only price & intake
sum if nutr_no==.
drop if nutr_no==. // if any exist, need to figure out where they came from
quietly rename F* F*_
tab nutr_no, m
misstable sum F* nutr_no
reshape wide F*_, i(hhxround case_id HHID y2_hhid y3_hhid data_round market_no year month date_consump) j(nutr_no)
forvalues i=1/51 {  
quietly rename F`i'_* N*_`i'
}
reshape long N0_ N1_, i(hhxround case_id HHID y2_hhid y3_hhid market_no data_round year month date_consump) j(food_no)
rename N*_ N*
rename N0 intake
rename N1 price
tab food_no, sum(price)
tab food_no if intake!=0, sum(intake) // average quantity when the food is included at all
misstable sum price intake
lab var intake "Intake of edible portion in grams"
lab var price "Net price (Nominal MWK) per gram"
tab food_no if price==. 
tab food_no if price==0
tab food_no, sum(price)
describe
sum

* Generate food_cost=intake*price
bys food_no: sum intake, d
gen food_cost=price*intake
tab food_no if food_cost==0 & intake!=0 // rerun to figure out errors if any observations here
sum food_cost if food_cost!=0, d
sum if food_cost==0, d

* Generate CoNA in long dataset as check for collapse
egen CoNA_sharing_tocheck=total(food_cost), by(hhxround case_id HHID y2_hhid y3_hhid data_round year month)
sum CoNA_sharing_tocheck, d
sum CoNA_sharing_tocheck if CoNA_sharing_tocheck!=0, d

preserve
    * Generate total nutrient intakes per household diet
        merge m:1 food_no using "CPIDataForCoNA_foodcomp.dta", ///
        	keepusing($nutrients food_item food_group food_group_name MWI_food_group_name MWI_food_group)
        drop if _merge==2 // foods not observed
        drop _merge
		    // Check for correct match from intake to food item 
        	sum food_item if intake!=0 & (price==0 | price==.)
        	tab market_no if intake!=0 & (price==0 | price==.)
        describe
        sum
		// Nutrient quantity per food
        foreach v in $nutrients {
        	quietly replace `v'=`v'/100 // FCTs are nutrients per 100g
			lab var `v' "`v' per gram"
        	tempvar `v'perfood
			gen ``v'perfood'=`v'*intake
        	}
        // Total nutrient quantity in least-cost diet
		foreach v in $nutrients {
			egen total_`v'=total(``v'perfood'), by(hhxround case_id HHID y2_hhid y3_hhid data_round year month)
			lab var total_`v' "`v' intake (nutrient units - vary by nutrient)"
			}
	
	* Convert intake from grams to kg
	quietly gen intake_kg=intake/1000
	quietly lab var intake_kg "Intake (Kg)"
	
	* Generate CoNA
		egen CoNA_sharing=total(food_cost), by(hhxround case_id HHID y2_hhid y3_hhid data_round year month)
		sum CoNA_sharing, d
		sum CoNA_sharing_tocheck, d
		drop CoNA_sharing_tocheck
	* Additional data management
		// Generate Year-month variable
		cap drop dateMY
		gen dateMY=ym(year, month)
		format dateMY %tmCCYY-NN
		tab dateMY, m
		lab var dateMY "Date (Month-Year)"
		
	    // Label food groups
			describe food_group food_group_name
			tab food_group_name, sum(food_group)
			lab def foodgroup ///
				1	"Alcohol, stimulants, spices & condiment" ///
				2	"Caloric beverages" ///
				3	"Cereals & cereal products" ///
				4	"Dark green leafy vegetables" ///
				5	"Eggs" ///
				6	"Fish & seafood" ///
				7	"Flesh meat" ///
				8	"Legumes" ///
				9	"Milk & milk products" ///
				10	"Oils & fats" ///
				11	"Other fruit" ///
				12	"Other vegetable" ///
				13	"Roots & tubers" ///
				14	"Salty snacks & fried foods" ///
				15	"Sweets & confectionary" ///
				16	"Vitamin-A rich fruits" ///
				17	"Vitamin-A rich vegetables & tubers" ///
				18	"Water"
			lab val food_group foodgroup
			lab var food_group "Food Group - Disaggregated to 18 categories"

			describe MWI_food_group_name MWI_food_group
			destring MWI_food_group, replace
			tab MWI_food_group_name, sum(MWI_food_group)
			tab MWI_food_group, m
			tab food_group if MWI_food_group==.
			lab def MWIfoodgroup ///
				1	"Animal foods" ///
				2	"Fats and oils" ///
				3	"Fruits" ///
				4	"Legumes and nuts" ///
				5	"Staples" ///
				6	"Vegetables" 
			lab val MWI_food_group MWIfoodgroup
			lab var MWI_food_group "Malawi Food Group (6 Food Groups)"
	drop if intake==0 // only keep dataset of foods included in CoNA, much smaller that way
	
	* Save food level dataset
	save "HHCoNA_sharing_foodlevel_r.dta", replace

	* Save total nutrient intakes dataset to confirm CoNA diet meets needs
	sum total*
	collapse (first) total* CoNA_sharing market_no date_consump, by(hhxround case_id HHID y2_hhid y3_hhid data_round year month) 
	sum total*
	save "HHCoNA_sharing_totalnutrients_r.dta", replace

restore

* Convert intake from grams to kg
quietly replace intake=intake/1000
quietly lab var intake "Intake (Kg)"
describe

sum

* Generate CoNA (sharing)
collapse (sum) food_cost (first) market_no date_consump, by(case_id HHID y2_hhid y3_hhid data_round year month)
rename food_cost CoNA_sharing
label var CoNA_sharing "Cost of Nutrient Adaquacy"

* Identify HH-market-months with no linear programming solution
sum if CoNA_sharing==0
replace CoNA_sharing=. if CoNA_sharing==0 

* Inspect
sum CoNA_sharing, d

* No solution?
tempvar CoNA_nosolution
	gen `CoNA_nosolution'=1 if CoNA_sharing==.
	replace `CoNA_nosolution'=0 if CoNA_sharing!=. & `CoNA_nosolution'==.
	tab `CoNA_nosolution', m

* Generate market price observation date
cap drop dateMY
	gen dateMY=ym(year, month)
	format dateMY %tmCCYY-NN
	tab dateMY, m
	lab var dateMY "Date (Month-Year)"

* Generate date variable for consumption date in same format as the market price observations
tempvar dcm
	gen `dcm'=month(date_consump)
tempvar dcy
	gen `dcy'=year(date_consump)
gen date_consump_MY=ym(`dcy', `dcm')
	format date_consump_MY %tmCCYY-NN
	
save "HHCoNA_sharing_r.dta", replace
	
* Time series treatment of CoNA
    // Create HH by round identifier for time series operations
	ssc install unique
    cap drop _*
    cap drop hh_round
    distinct case_id HHID y2_hhid y3_hhid
    unique case_id HHID y2_hhid y3_hhid date_consump CoNA_sharing
    egen hh_round=group(case_id HHID y2_hhid y3_hhid date_consump), missing
    sum hh_round
    bys hh_round: egen date_seq=seq()
    cap drop _*
    	
xtset hh_round dateMY, format(%tmCCYY-NN)
xtdescribe
xtsum date_seq
xtsum CoNA_sharing

unique hh_round
gen obs_date_tag=0
replace obs_date_tag=1 if date_consump_MY==dateMY
tab date_seq if obs_date_tag==1    

* Inspect
describe
sum
save "HHCoNA_sharing_r.dta", replace

// PART 2 // GENERATE NUTRIENT SHADOW PRICES - SHARING
* Read R result back to Stata
clear
insheet using "HH_Shadowprices_sharing_r.csv"
describe
sum
* Label variables (constraints in order)
ren v2 energy_eer
ren v3 carb_ear
ren v4 carb_amdrlo
ren v5 carb_amdrhi
ren v6 protein_ear
ren v7 protein_amdrlo
ren v8 protein_amdrhi
ren v9 lipids_amdrlo
ren v10 lipids_amdrhi
ren v11 vitA_ear
ren v12 retinol_ul
ren v13 vitc_ear
ren v14 vitc_ul
ren v15 vite_ear
ren v16 thiamin_ear
ren v17 riboflavin_ear
ren v18 niacin_ear
ren v19 vitb6_ear
ren v20 vitb6_ul
ren v21 folate_ear
ren v22 vitb12_ear
ren v23 calcium_ear
ren v24 calcium_ul
ren v25 copper_ear
ren v26 copper_ul
ren v27 iron_ear
ren v28 iron_ul
ren v29 magnesium_ear
ren v30 phosphorus_ear
ren v31 phosphorus_ul
ren v32 selenium_ear
ren v33 selenium_ul
ren v34 zinc_ear
ren v35 zinc_ul
ren v36 sodium_ul
gen price=0
order price, before(energy_eer)
ren (price-sodium_ul) ///
(shadowprice(##)), addnumber
forval i=1/9 {
	ren shadowprice0`i' shadowprice`i'
	}
reshape long shadowprice, i(v1) j(constraint_no)
ren shadowprice shadowprice_sharing
save "HH_shadowprices_sharing_r.dta", replace

* Merge shadow prices into household identifiers & CoNA
use "HHCoNA_sharing_r", clear
	sort case_id HHID y2_hhid y3_hhid data_round dateMY
		replace y2_hhid="." if y2_hhid==""
		replace y3_hhid="." if y3_hhid==""
		egen v1=group(case_id HHID y2_hhid y3_hhid dateMY)
		replace y2_hhid="" if y2_hhid=="."
		replace y3_hhid="" if y3_hhid=="."
	merge 1:m v1 using "HH_shadowprices_sharing_r"
	drop _merge
	lab def constraintno 1 "Price" ///
		2 "Energy_eer" ///
		3 "Carb_ear" ///
		4 "Carb_amdrlo" ///
		5 "Carb_amdrhi" ///
		6 "Protein_ear" ///
		7 "Protein_amdrlo" ///
		8 "Protein_amdrhi" ///
		9 "Lipids_amdrlo" ///
		10 "Lipids_amdrhi" ///
		11 "VitA_ear" ///
		12 "Retinol_ul" ///
		13 "Vitc_ear" ///
		14 "Vitc_ul" ///
		15 "Vite_ear" ///
		16 "Thiamin_ear" ///
		17 "Riboflavin_ear" ///
		18 "Niacin_ear" ///
		19 "Vitb6_ear" ///
		20 "Vitb6_ul" ///
		21 "Folate_ear" ///
		22 "Vitb12_ear" ///
		23 "Calcium_ear" ///
		24 "Calcium_ul" ///
		25 "Copper_ear" ///
		26 "Copper_ul" ///
		27 "Iron_ear" ///
		28 "Iron_ul" ///
		29 "Magnesium_ear" ///
		30 "Phosphorus_ear" ///
		31 "Phosphorus_ul" ///
		32 "Selenium_ear" ///
		33 "Selenium_ul" ///
		34 "Zinc_ear" ///
		35 "Zinc_ul" ///
		36 "Sodium_ul" 
		lab var constraint_no constraintno
	* Label nutrients
	gen nutr_no=.
	replace nutr_no=1 if constraint_no==1
	replace nutr_no=2 if constraint_no==2
	replace nutr_no=3 if inlist(constraint_no,3,4,5)
	replace nutr_no=4 if inlist(constraint_no,6,7,8)
	replace nutr_no=5 if inlist(constraint_no,9,10)
	replace nutr_no=6 if constraint_no==11
	replace nutr_no=7 if constraint_no==12
	replace nutr_no=8 if inlist(constraint_no,13,14)
	replace nutr_no=9 if constraint_no==15
	replace nutr_no=10 if constraint_no==16
	replace nutr_no=11 if constraint_no==17
	replace nutr_no=12 if constraint_no==18
	replace nutr_no=13 if inlist(constraint_no,19,20)
	replace nutr_no=14 if constraint_no==21
	replace nutr_no=15 if constraint_no==22
	replace nutr_no=16 if inlist(constraint_no,23,24)
	replace nutr_no=17 if inlist(constraint_no,25,26)
	replace nutr_no=18 if inlist(constraint_no,27,28)
	replace nutr_no=19 if constraint_no==29
	replace nutr_no=20 if inlist(constraint_no,30,31)
	replace nutr_no=21 if inlist(constraint_no,32,33)
	replace nutr_no=22 if inlist(constraint_no,34,35)
	replace nutr_no=23 if constraint_no==36

* Label
lab var shadowprice_sharing "Shadow price (nominal MWK) for 1 unit change in constraint"
preserve
	use "HH+CPI_LPInput_sharing_r", clear
		* Generate market price observation date
			cap drop dateMY
			gen dateMY=ym(year, month)
			format dateMY %tmCCYY-NN
			tab dateMY, m
			lab var dateMY "Date (Month-Year)"
		* Generate v1 to merge
		replace y2_hhid="." if y2_hhid==""
		replace y3_hhid="." if y3_hhid==""
		egen v1=group(case_id HHID y2_hhid y3_hhid dateMY)
		replace y2_hhid="" if y2_hhid=="."
		replace y3_hhid="" if y3_hhid=="."
		sum v1
		* Generate constraint type to merge
		encode rel, gen(constraint_type)
		tab constraint_type
		tab constraint_type, sum(constraint_type)

		* Generate constraint number to merge
		cap drop constraint_no
		egen constraint_no=seq(), by(dateMY case_id HHID y2_hhid y3_hhid)
		tab constraint_no
	
	keep v1 constraint_no constraint_type nutr_no rel rhs case_id HHID y2_hhid y3_hhid market_no dateMY
		save "HHNR_timeseries_r", replace

restore
* Label nutrient requirement types
cap drop constraint_type
gen constraint_type=.
		replace constraint_type=1 if inlist(constraint_no,5,8,10,12,14,20,24,26,28,31,33,35,36)
		replace constraint_type=2 if inlist(constraint_no,1,2)
		replace constraint_type=3 if inlist(constraint_no,3,4,6,7,9,11,13,15,16,17,18,19,21,22,23,25,27,29,30,32,34)
			tab2 nutr_no constraint_type

* Merge in nutrient requirements data
merge 1:1 v1 constraint_no constraint_type nutr_no dateMY case_id HHID y2_hhid y3_hhid market_no ///
	using "HHNR_timeseries_r", keepusing(rel rhs)
	drop _merge
	drop v1

* Generate semi-elasticities
cap drop semielasticity_sharing
gen semielasticity_sharing=shadowprice_sharing/(rhs/100)
tab nutr, sum(semielasticity_sharing)
bys constraint_type: tab nutr, sum(semielasticity_sharing)
lab var semielasticity_sharing "Semi-elasticity (nominal MWK) for 1% change in constraint"

* Generate elasticities
cap drop elasticity_sharing
gen elasticity_sharing=((CoNA_sharing+shadowprice_sharing)-(CoNA_sharing))/(rhs/100)
lab var elasticity_sharing "Nutrient Elasticity: % change in CoNA for a 1% change in Nutrient Requirement"

	//Label nutrients
	lab def nutr ///
		1 "Price" ///
		2 "Energy" ///
		3 "Carbohydrate" ///
		4 "Protein" ///
		5 "Lipids" ///
		6 "Vitamin_A" ///
		7 "Retinol" ///
		8 "Vitamin_C" ///
		9 "Vitamin_E" ///
		10 "Thiamin" ///
		11 "Riboflavin" ///
		12 "Niacin" ///
		13 "Vitamin_B6" ///
		14 "Folate" ///
		15 "Vitamin_B12" ///
		16 "Calcium" ///
		17 "Copper" ///
		18 "Iron" ///
		19 "Magnesium" ///
		20 "Phosphorus" ///
		21 "Selenium" ///
		22 "Zinc"  ///
		23 "Sodium"
	lab val nutr_no nutr
tab nutr_no

* Inspect
// EAR/AMDR Lower
tab nutr_no if constraint_type==3, sum(semielasticity_sharing)
tab nutr_no if constraint_type==3, sum(elasticity_sharing)

// UL/AMDR Upper
tab nutr_no if constraint_type==1, sum(semielasticity_sharing)
tab nutr_no if constraint_type==1, sum(elasticity_sharing)

sort case_id HHID y2_hhid y3_hhid dateMY nutr_no constraint_no
save "HH_shadowprices_sharing_r", replace

// Save time series datasets

	* Save applicable dates for time series of shadow prices
	use "HH_shadowprices_sharing_r"
		// Generate an annual mean shadow price per household
		gen shadowprice_sharing_pd=shadowprice_sharing/7
	tab2 year data_round
		drop if data_round==1 & year>=2013
		drop if data_round==2 & (year<2013 | year>2015)
		drop if data_round==3 & year<2016
	tab2 year data_round
	tab nutr_no
	bys constraint_type: tab nutr_no, sum(shadowprice_sharing)
	bys nutr_no: tab constraint_no, sum(semielasticity_sharing)
		save "HHCoNA_ShadowPrices_r", replace
		
	* * Keep applicable dates for time series dataset
	use "HHCoNA_sharing_r", clear
	sum CoNA_sharing, d
	tab2 year data_round

	sum CoNA_sharing, d 
		drop if data_round==1 & year>=2013
		drop if data_round==2 & (year<2013 | year>2015)
		drop if data_round==3 & year<2016
	tab2 year data_round
	sum CoNA_sharing, d
	// Generate time scale aggregations
	lab var CoNA_sharing "CoNA per week"
	gen CoNA_sharing_pd=CoNA_sharing/7
		lab var CoNA_sharing_pd "Household CoNA, food sharing, per day (month level)"
	gen CoNA_sharing_month=.
		replace CoNA_sharing_month=CoNA_sharing_pd*28 if month==2 & !inlist(year,2008,2012,2016)
		replace CoNA_sharing_month=CoNA_sharing_pd*29 if month==2 & inlist(year,2008,2012,2016)
		replace CoNA_sharing_month=CoNA_sharing_pd*30 if inlist(month,4,6,11)
		replace CoNA_sharing_month=CoNA_sharing_pd*31 if CoNA_sharing_month==.
		lab var CoNA_sharing_month "CoNA per month"
	save "HHCoNA_r", replace

	use "HHCoNA_sharing_foodlevel_r", clear
	cap drop _*
	cap drop hhxround
	* Keep only relevant time series
	drop if data_round==1 & year>=2013
	drop if data_round==2 & (year<2013 | year>2015)
	drop if data_round==3 & year<2016
	tab2 year data_round
	drop if intake==0
	save "HHCoNA_foodlevel_r", replace


log close

