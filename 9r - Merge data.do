/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: Merge datasets into final formats using the revised nutrient requirements
			(only household members 4 and above can define the shared nutrient
			requirement).
Datasets produced: Produces datasets at the person-nutrient, person, 
	household-nutrient, household, asset, and food item levels. Least-cost diet
	datasets are monthly for the fully period.
	
* LEAST-COST DIET RESULTS CREATED IN THIS DATASET ARE THOSE USED IN ANALYSIS *
* HOUSEHOLD DATASETS UNAFFECTED BY NUTRIENT REQUIREMENTS ARE ONLY CREATED IN 
	THE MAIN DO FILE #9. BOTH MUST BE RUN TO REPLICATE CHAPTERS 5 AND 6 
	(THE TWO OF THREE PAPERS WITH LEAST-COST DIETS). *

*/

// PART 0 // FILE MANAGEMENT
global ihpsraw "MWI_IHPS_2010-2013-2016"
global otherrawdata "datafolder"
global analysis "workingfolder"
global NRs "\NutrientRequirements_DRIs_2019_ks.xlsx"
global whogrowth "\WHO growth reference tables_2006_ks.xlsx"
global iCoNA "\ICoNA files"
global nutrients energy carbohydrate protein lipids vitA retinol vitC vitE thiamin riboflavin niacin vitB6 folate ///
	vitB12 calcium copper iron magnesium phosphorus selenium zinc sodium
global finaldata "outputfolder"


* Working directory
cd "$analysis"

* Input datasets that differ from those saved to final
* in do file #9
	// Household and Individual Identifiers and Sociodemographics
		* Sample size
	// Nutrient Requirements
	use HHNeeds_HHLevel_r, clear
		save "$finaldata\HHNeeds_HHLevel_r", replace
	use HHNeeds_IndivLevel_r, clear
		save "$finaldata\HHNeeds_IndivLevel_r", replace
		
	// CoNA results
	use HHCoNA_sharing_r, clear // Full time series
			* Generate time summary indicators 
			lab var CoNA_sharing "CoNA per week"
			gen CoNA_sharing_pd=CoNA_sharing/7
				lab var CoNA_sharing_pd "Household CoNA, food sharing, per day (month level)"
			gen CoNA_sharing_month=.
			replace CoNA_sharing_month=CoNA_sharing_pd*28 if month==2 & !inlist(year,2008,2012,2016)
			replace CoNA_sharing_month=CoNA_sharing_pd*29 if month==2 & inlist(year,2008,2012,2016)
			replace CoNA_sharing_month=CoNA_sharing_pd*30 if inlist(month,4,6,11)
			replace CoNA_sharing_month=CoNA_sharing_pd*31 if CoNA_sharing_month==.
			lab var CoNA_sharing_month "CoNA per month"
			cap drop *_
			save HHCoNA_sharing_r, replace
		save "$finaldata\HHCoNA_sharing_r", replace
	use HHCoNA_r, clear // Applicable dates
			* Fix time summary indicators 
			drop CoNA_sharing_*
			cap drop _*
			lab var CoNA_sharing "CoNA per week"
			gen CoNA_sharing_pd=CoNA_sharing/7
				lab var CoNA_sharing_pd "Household CoNA, food sharing, per day (month level)"
			gen CoNA_sharing_month=.
			replace CoNA_sharing_month=CoNA_sharing_pd*28 if month==2 & !inlist(year,2008,2012,2016)
			replace CoNA_sharing_month=CoNA_sharing_pd*29 if month==2 & inlist(year,2008,2012,2016)
			replace CoNA_sharing_month=CoNA_sharing_pd*30 if inlist(month,4,6,11)
			replace CoNA_sharing_month=CoNA_sharing_pd*31 if CoNA_sharing_month==.
			lab var CoNA_sharing_month "CoNA per month"
			cap drop *_
		save HHCoNA_r, replace
			save "$finaldata\HHCoNA_r", replace
	use HHCoNA_sharing_foodlevel_r, clear
		save "$finaldata\HHCoNA_sharing_foodlevel_r", replace
	use HHCoNA_sharing_totalnutrients_r, clear
		save "$finaldata\HHCoNA_sharing_totalnutrients_r", replace
	
	// Semi-elasticities results
	use HHCoNA_ShadowPrices_r, clear
	save "$finaldata\HHCoNA_ShadowPrices_r", replace
	
	// Policy scenarios
		* Revised nutrient requirements - Main CoNA
			use HHCoNA_sharing_r_s1a, clear // Eggs -10%
				save "$finaldata\HHCoNA_sharing_r_s1a", replace
			use HHCoNA_sharing_r_s1b, clear // Eggs -15%
				save "$finaldata\HHCoNA_sharing_r_s1b", replace
			use HHCoNA_sharing_r_s1c, clear // Eggs -20%
				save "$finaldata\HHCoNA_sharing_r_s1c", replace
			use HHCoNA_sharing_r_s2, clear // Fishes
				save "$finaldata\HHCoNA_sharing_r_s2", replace
			use HHCoNA_sharing_r_s3, clear // Groundnuts
				save "$finaldata\HHCoNA_sharing_r_s3", replace
			use HHCoNA_sharing_r_s4, clear // Fresh milk
				save "$finaldata\HHCoNA_sharing_r_s4", replace
			use HHCoNA_sharing_r_s5, clear // Powdered milk
				save "$finaldata\HHCoNA_sharing_r_s5", replace
			use HHCoNA_sharing_r_s6, clear // Selenium soil biofortification of maize
				save "$finaldata\HHCoNA_sharing_r_s6", replace
		* Revised nutrient requirements - Shadow prices
			use HHCoNA_ShadowPrices_r_s1a, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s1a", replace
			use HHCoNA_ShadowPrices_r_s1b, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s1b", replace
			use HHCoNA_ShadowPrices_r_s1c, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s1c", replace
			use HHCoNA_ShadowPrices_r_s2, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s2", replace
			use HHCoNA_ShadowPrices_r_s3, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s3", replace
			use HHCoNA_ShadowPrices_r_s4, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s4", replace
			use HHCoNA_ShadowPrices_r_s5, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s5", replace
			use HHCoNA_ShadowPrices_r_s6, clear
				save "$finaldata\HHCoNA_ShadowPrices_r_s6", replace
		
********************************************************************************
cap log close
log using "9r_Merge+Descriptives_`c(current_date)'", replace
***Log of Do File #9r "09r_Data Combination & Creation of Final Datasets"
di "`c(current_date)' `c(current_time)'"
di "revised needs of 3 year olds"

// NUTRIENT LEVEL DATASET //

* Merge household/individual with outcomes and key sociodemographic variables
use HH+Indiv, clear

recode reside (1=0) (2=1)
lab def reside 1 "Rural" 0 "Urban"
lab val reside reside
lab var reside "Rural (%)"
unique case_id HHID y2_hhid y3_hhid data_round
unique case_id HHID y2_hhid y3_hhid data_round PID

cap drop _*
joinby case_id data_round HHID y2_hhid y3_hhid date_consump ///
	using HHNeeds_HHLevel_r // To produce nutrient level dataset	
unique case_id HHID y2_hhid y3_hhid data_round
unique case_id HHID y2_hhid y3_hhid data_round PID
unique case_id HHID y2_hhid y3_hhid data_round PID nutr_no

merge m:1 case_id data_round HHID y2_hhid y3_hhid ///
	date_consump using HHConsumptionAggregate
	// Drop unmatched households: no one ate at home (N=15)
	drop if _merge==2
	drop _merge
sort case_id HHID y2_hhid y3_hhid PID data_round nutr_no
order case_id HHID y2_hhid y3_hhid hhxround PID data_round PID nutr_no
cap drop _*
	tempvar dcm
		gen `dcm'=month(date_consump)
	tempvar dcy
		gen `dcy'=year(date_consump)
	gen date_consump_MY=ym(`dcy', `dcm')
		format date_consump_MY %tmCCYY-NN
unique case_id HHID y2_hhid y3_hhid data_round
bys data_round: distinct case_id HHID y2_hhid y3_hhid
cap drop __*

* Label Nutrients
cap drop __*

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

save IHPS_NeedsExpenditure_r, replace
	save "$finaldata\IHPS_NeedsExpenditure_r", replace

* Merge in CoNA
preserve
	collapse (first) date_consump_MY, by(case_id HHID y2_hhid y3_hhid data_round)
	tempfile IHPSdates
		save `IHPSdates', replace
	use HHCoNA_r, clear
		merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
			using `IHPSdates'
			drop if _merge==2 // Urban markets
			drop _merge
			sum CoNA*, d
			* Save only date matching HH survey for analysis
			keep if dateMY==date_consump_MY
			unique case_id HHID y2_hhid y3_hhid data_round
			save HHCoNA_IHPSdates_r, replace
				save "$finaldata\HHCoNA_IHPSdates_r", replace
restore
merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
	using HHCoNA_IHPSdates_r
	tab reside if _merge==1
	tab district if _merge==1
	// unmerged are households in urban markets
	drop _merge
	unique case_id HHID y2_hhid y3_hhid data_round
	unique case_id HHID y2_hhid y3_hhid data_round PID
	unique case_id HHID y2_hhid y3_hhid data_round PID nutr_no

* Order variables
order district district_name market market_no ta_code hh_a02b year month ///
	date_consump wealth wealth_quintile TA_name age_rptd ageinmonths age_sex_grp ///
	pal lactating bfchild_ageinmonths daysate_conv hhsize haz waz whz stunted ///
	underweight wasted_overweight, after(y3_hhid)
order AMDRlow_sharing AMDRup_sharing EAR_sharing KCAL_hh_perday KCAL_hh_perweek ///
	UL_sharing age_sex_grp age_rptd ageinmonths date_consump date_consump_MY ///
	daysate_hh_conv sex haz head_ed lactating market market_no ///
	month nutr_no spouse_ed stunted ///
	underweight wasted_overweight ///
	waz wealth wealth_quintile whz, after(y3_hhid)
order pweight CoNA*, after(hhsize)
	
destring, replace	

// PERSON - NUTRIENT LEVEL DATASET //
save MalawiIHPS_DietQualCost_Nut_PID_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_Nut_PID_r", replace

// PERSON LEVEL DATASET //
* Reshape nutrient-level variables wide to person-level for regression analyses
sort case_id HHID y2_hhid y3_hhid PID data_round nutr_no
cap drop __*
drop amdrlow_toddler_perweek amdrup_toddler_perweek ///
	energytoddler max_amdrlow_perkcal min_amdrup_perkcal

foreach v in EAR* UL* AMDR* {
		ren `v' `v'_
		}

	tab nutr_no
	drop if nutr_no==1
	misstable sum case_id HHID y2_hhid y3_hhid PID hhxround data_round nutr_no
		unique case_id HHID y2_hhid y3_hhid PID hhxround data_round 
		unique case_id HHID y2_hhid y3_hhid PID hhxround data_round nutr_no

reshape wide *EAR* *UL* *AMDR* , ///
	i(case_id HHID y2_hhid y3_hhid PID hhxround data_round) j(nutr_no)

* Reorder nutrient level variables to end, key variables to beginning
order AMDRlow_sharing_2-AMDRup_targeting_23, last
order data_round pweight sex hh_b04 district-hh_a02b year-region TA_name ///
	age_rptd-daysate_hh_conv ///
	date_consump_MY head_ed-dateMY CoNA*, ///
	after(y3_hhid)
cap drop __*

save MalawiIHPS_DietQualCost_PID_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_PID_r", replace

// MERGE SHADOW PRICES INTO NUTRIENT LEVEL DATASET //
use IHPS_NeedsExpenditure_r, clear
	collapse (first) date_consump_MY, by(case_id HHID y2_hhid y3_hhid data_round nutr_no)
	tempfile IHPSdates
		save `IHPSdates', replace	
	use HHCoNA_ShadowPrices_r, clear
	merge m:1 case_id HHID y2_hhid y3_hhid data_round nutr_no ///
		using `IHPSdates'
		drop if _merge==2
		drop _merge
			* Save only date matching HH survey for analysis
			sum if dateMY==date_consump_MY
			keep if dateMY==date_consump_MY
			save HHCoNAShadowPrices_IHPSdates_r, replace
			save "$finaldata\HHCoNAShadowPrices_IHPSdates_r", replace

	* Reshape to merge with nutrient level dataset
	tab rel
	describe rel
	tab2 nutr_no constraint_type
	gen NR_type=.
	replace NR_type=2 if rel=="=" // Energy
	replace NR_type=1 if rel==">=" & !inlist(constraint_no,4,7) // EARs
	replace NR_type=3 if rel=="<=" & !inlist(constraint_no,5,8) // ULs
	replace NR_type=4 if rel==">=" ///
		& inlist(constraint_no,4,7,9) // AMDR lower
	replace NR_type=5 if rel=="<=" ///
		& inlist(constraint_no,5,8, 10) // AMDR upper
	tab2 nutr_no NR_type
	drop constraint_no constraint_type rel rhs
	reshape wide sp_sharing se_sharing e_sharing, ///
		i(case_id HHID y2_hhid y3_hhid data_round dateMY nutr_no) ///
		j(NR_type)
	ren (*1 *2 *3 *4 *5) (*_EAR *_Kcal *_UL *_AMDRlow *_AMDRup)	
	cap drop _merge
	merge 1:m case_id HHID y2_hhid y3_hhid data_round nutr_no ///
		using MalawiIHPS_DietQualCost_Nut_PID_r
	// Unmerged are urban with no food price data
drop _merge

save MalawiIHPS_DietQualCost_Nut_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_Nut_r", replace
	
// HOUSEHOLD-NUTRIENT LEVEL DATASET //
	* Save labels
	foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
		}
	}
cap drop _*
collapse (first) reside sp_* se_* e_* ///
	year month CoNA* market_no date_consump date_consump_MY ///
	AMDR* EAR* KCAL* TA_name UL* daysate_hh_conv head_ed   ///
	 market spouse_ed wealth* district*  ///
	 ta_code hh_a02b hhsize pweight ///
	 hhxround ea_id fed_others region baseline_rural dropurban education dependency_ratio  ///
	 fem_male_ratio totalexp_* totalexpenditure pctfoodexp, ///
		by(case_id HHID y2_hhid y3_hhid data_round dateMY nutr_no)

	* Relabel
	foreach v of var * {
 	label var `v' "`l`v''"
		}	
save MalawiIHPS_DietQualCost_Nut_HH_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_Nut_HH_r", replace

// HOUSEHOLD LEVEL DATASET //
use MalawiIHPS_DietQualCost_PID_r, clear
	* Save labels
	foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
		}
	}
cap drop _*
	collapse (first) pweight ea_id district district_name ta_code ///
		hh_a02b year hhsize qx_type date_consump_MY daysate_hh_conv ///
		reside stratum fed_others region TA_name date_consump ///
		head_ed market market_no month spouse_ed wealth* ///
		dropurban education dependency_ratio fem_male_ratio ///
		totalexp_* totalexpenditure pctfoodexp CoNA* dateMY, ///
		by(case_id HHID y2_hhid y3_hhid data_round)
	* Relabel
	foreach v of var * {
 	label var `v' "`l`v''"
		}
	
save MalawiIHPS_DietQualCost_HH_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_HH_r", replace

// FOOD ITEM LEVEL DATASETS //	
** FOOD ITEMS IN CONA
use HHCoNA_sharing_foodlevel_r, clear
cap drop _*
unique case_id HHID y2_hhid y3_hhid
distinct case_id HHID y2_hhid y3_hhid

	// Generate % cost by food group
	foreach v of varlist food_group food_group_name ///
		MWI_food_group_name MWI_food_group {
			tab `v'
		}
	lab var food_cost "Price * Intake"
preserve
		* save labels
		foreach v of var * {
		local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
			}
		}
		
		collapse (sum) food_cost (first) CoNA_sharing, by(hhxround case_id ///
			HHID y2_hhid y3_hhid market_no data_round dateMY food_group)
			* Relabel
			foreach v of var * {
			label var `v' "`l`v''"
				}
		ren food_cost foodgroup_totalcost
		lab var foodgroup_totalcost "Cost per food group (18 item list)"
		gen CoNAbyFoodGroup=foodgroup_totalcost/CoNA_sharing
		lab var CoNAbyFoodGroup "Food Group Cost as percent of CoNA"
		tempfile foodgroupcost
		save `foodgroupcost'
restore
merge m:1 hhxround case_id HHID y2_hhid y3_hhid market_no ///
	data_round dateMY food_group using `foodgroupcost'

preserve 
		* save labels
		foreach v of var * {
		local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
			}
		}
		
		collapse (sum) food_cost (first) CoNA_sharing, by(hhxround case_id ///
			HHID y2_hhid y3_hhid market_no data_round dateMY MWI_food_group)
			* Relabel
			foreach v of var * {
			label var `v' "`l`v''"
				}
		ren food_cost foodgroup_totalcost_MWI
		lab var foodgroup_totalcost_MWI "Cost per food group (18 item list)"
		gen CoNAbyFoodGroup_MWI=foodgroup_totalcost/CoNA_sharing
		lab var CoNAbyFoodGroup_MWI "Food Group Cost as percent of CoNA"
		tempfile foodgroupcost
		save `foodgroupcost'
restore
cap drop _merge
merge m:1 hhxround case_id HHID y2_hhid y3_hhid market_no ///
	data_round dateMY MWI_food_group using `foodgroupcost'
drop _merge
 
	// Merge in svy vars and weights
	merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
		using MalawiIHPS_DietQualCost_HH_r, ///
		keepusing(ea_id reside pweight)
	drop if _merge==2 // urban households, no food prices
	
	// Fix food groups to match IHPS data 
	describe food_group
	lab drop foodgroup
		replace food_group=11 if food_group_name=="Oils & fats"
		replace food_group=12 if food_group_name=="Other fruit"
		replace food_group=13 if food_group_name=="Other vegetable"
		replace food_group=14 if food_group_name=="Roots & tubers"
		replace food_group=15 if food_group_name=="Salty snacks & fried foods"
		replace food_group=16 if food_group_name=="Sweets & confectionary"
		replace food_group=17 if food_group_name=="Vitamin-A rich fruits"
		replace food_group=18 if food_group_name=="Vitamin-A rich vegetables & tubers"
	tab food_group
	tab food_group_name
	
	cap lab drop foodgroup
	lab def foodgroup ///
		1 "Alcohol_stimulants_spices_condiments" ///
		2 "Caloric_beverages" ///
		3 "Cereals_cereal_products" ///
		4 "Dark_green_leafy_vegetables" ///
		5 "Eggs" ///
		6 "Fish_seafood" ///
		7 "Flesh_meat" ///
		8 "Legumes" ///
		9 "Milk_milk products" ///
		10 "Nuts_seeds" ///
		11 "Oils_fats" ///
		12 "Other_ruit" ///
		13 "Other_vegetable" ///
		14 "Roots_tubers" ///
		15 "Salty_snacks_friedfoods" ///
		16 "Sweets_confectionary" ///
		17 "VitA_rich_fruits" ///
		18 "VitA_rich_vegetables_tubers"
	lab val food_group foodgroup
	tab food_group
	tab food_group, nolabel
	tab food_group_name
		
save MalawiIHPS_DietQualCost_FoodCoNA_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_FoodCoNA_r", replace

// TOTAL NUTRIENTS IN CONA DIETS MERGED WITH REQUIREMENTS //
	use HHCoNA_sharing_totalnutrients_r, clear
	* Keep only relevant time series
		tab2 year data_round
	drop if data_round==1 & year>=2013
	drop if data_round==2 & (year<2013 | year>2015)
	drop if data_round==3 & year<2016
	tab2 year data_round

	foreach v of varlist total_* {
		lab var `v' "`v'"
		}
	gen total_price=.
	order total_price, before(total_energy)
	ren (total_*) nutr_no#, addnumber
	order case_id HHID y2_hhid y3_hhid data_round year month CoNA_sharing market_no date_consump, first
	reshape long nutr_no, ///
		i(case_id HHID y2_hhid y3_hhid data_round year month hhxround) ///
		j(totnut_inCoNA)
	ren (nutr_no totnut_inCoNA) (totnut_inCoNA nutr_no)
	order nutr_no, before(totnut_inCoNA)
	drop if nutr_no==1 // price not relevant for this comparison of CoNA intakes to HH needs
	save HHCoNA_sharing_totalnutrients_MWKnominal_applicabledates_r, replace
	
	use HHNeeds_HHLevel_r, clear
	drop year month hhxround 
	drop if nutr_no==1 // price
	drop if dropurban==1
	merge 1:m case_id HHID y2_hhid y3_hhid data_round nutr_no market_no date_consump ///
		using HHCoNA_sharing_totalnutrients_MWKnominal_applicabledates_r
		tab market_no if _merge==2, m // urban
		drop if _merge==2
		drop _merge
	foreach v in EAR_targeting UL_targeting AMDRlow_targeting ///
		AMDRup_targeting EAR_sharing UL_sharing AMDRlow_sharing AMDRup_sharing ///
		KCAL_hh_perday KCAL_hh_perweek totnut_inCoNA {
			replace `v'=round(`v',.01) if `v'!=0 & `v'!=.
		}	
		
	* Merge in household member types
	merge m:1 case_id HHID y2_hhid y3_hhid data_round using HH_NRgroups, ///
		keepusing(age_sex_grp*)
	tab market_no if _merge==2, m // urban
	drop if _merge==2 //
	drop _merge 
	
		foreach v of varlist age_sex_grp* {
		replace `v'=0 if `v'==.
		}
	sum age_sex_grp*
	
	save HHCoNA_sharing+HHNeeds_HHLevel_r, replace
	save "$finaldata\HHCoNA_sharing+HHNeeds_HHLevel_r", replace
	
// CONA TIME SERIES WITH HOUSEHOLD DATA //
use HHCoNA_r, clear 
	* Merge in age-sex groups
	merge m:1 case_id HHID y2_hhid y3_hhid data_round using HH_NRGroups
	tab market if _merge==2, m
	drop if _merge==2 // Urban markets
	drop _merge
	foreach v of varlist age_sex_grp* {
		replace `v'=0 if `v'==.
		}
	
* Label markets
	lab def mkt ///
		1 "Balaka_boma" ///
		2 "Chilumba" ///
		3 "Chitakale" ///
		4 "Chitipa_boma" ///
		5 "Dedza_boma" ///
		6 "Ekwendeni" ///
		7 "Jali" ///
		8 "Karonga_boma" ///
		9 "Kasungu_boma" ///
		10 "Liwonde" ///
		11 "Lunzu" ///
		12 "Mangochi_boma" ///
		13 "Mbulumbuzi" ///
		14 "Mchinji_boma" ///
		15 "Mitundu" ///
		16 "Mponera" ///
		17 "Mwanza_boma" ///
		18 "Mzimba_boma" ///
		19 "Nchalo" ///
		20 "Nkhatabay_boma" ///
		21 "Nkhotakota_boma" ///
		22 "Nsalu" ///
		23 "Nsanje_boma" ///
		24 "Nsundwe" ///
		25 "Ntcheu_boma" ///
		26 "Phalombe_boma" ///
		27 "Rumphi_boma" ///
		28 "Salima_boma" ///
		29 "Thyolo"
	lab val market_no mkt

gen CoNA_solution=.
	replace CoNA_solution=1 if CoNA_sharing!=.
	replace CoNA_solution=0 if CoNA_sharing==.

* Merge in survey weights
	merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
		using MalawiIHPS_DietQualCost_HH_r, ///
		keepusing(ea_id reside pweight)
	drop if _merge==2 // urban households, no food prices
	drop _merge
		
save MalawiIHPS_DietQualCost_CoNAseries_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_CoNAseries_r", replace
	
// Merge sharing and individual time series //
use MalawiIHPS_DietQualCost_iCoNA, clear
	cap drop _*
	drop if year<2013
	gen data_round=2 if year>=2013 & year<=2015
	replace data_round=3 if year>=2016
	drop iCoNA_pd iCoNA_month iCoNA_ppp iCoNA_month_ppp iCoNA_pd_ppp
	tempfile icona
		save `icona', replace
use MalawiIHPS_DietQualCost_PID_r, clear
	keep PID age_sex_grp case_id HHID y2_hhid y3_hhid data_round pweight hhsize pal daysate_conv ea_id reside market market_no
	drop if reside!=1
	drop if market_no==.
joinby age_sex_grp market_no pal data_round using `icona'
cap drop _*
unique PID if data_round==2
unique PID if data_round==3
unique case_id HHID y2_hhid if data_round==2
unique case_id HHID y2_hhid y3_hhid if data_round==3

replace iCoNA=iCoNA*daysate_conv
gen iCoNA_pd=iCoNA/7
		lab var iCoNA_pd "iCoNA per day, month level, adjusted for partial mealtaking"
	gen iCoNA_month=.
		replace iCoNA_month=iCoNA_pd*28 if month==2 & !inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*29 if month==2 & inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*30 if inlist(month,4,6,11)
		replace iCoNA_month=iCoNA_pd*31 if iCoNA_month==.
		lab var iCoNA_month "iCoNA per month, adjusted for partial mealtaking"
tab2 dateMY data_round
egen solutionscount=count(iCoNA_month), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
tab solutionscount
	tempvar count
	gen `count'=1
	replace `count'=. if age_sex_grp==1
	egen hhsizeminusinfant=count(`count'), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
		tab hhsizeminusinfant
sum hhsizeminusinfant solutionscount ///
	if hhsizeminusinfant!=solutionscount
egen iCoNA_HH_pd=total(iCoNA_pd), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
	replace iCoNA_HH_pd=. if hhsizeminusinfant!=solutionscount
	gen iCoNA_solutionallHH=1 if iCoNA_HH_pd!=.
		replace iCoNA_solutionallHH=0 if iCoNA_HH_pd==.
	tab iCoNA_solutionallHH
	* save labels
		foreach v of var * {
		local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
			}
		}
collapse (first) iCoNA_HH_pd iCoNA_solutionallHH, ///
	by(case_id HHID y2_hhid y3_hhid data_round dateMY)
	* Relabel
	foreach v of var * {
	label var `v' "`l`v''"
		}

tempfile iCoNA
	save `iCoNA', replace

use MalawiIHPS_DietQualCost_CoNAseries_r, clear
merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
	using MalawiIHPS_DietQualCost_HH_r, keepusing(reside ea_id pweight)
drop if _merge==2 // No price data
drop _merge
merge 1:1 case_id HHID y2_hhid y3_hhid data_round dateMY using `iCoNA'
	tab reside if _merge==1 
	tab district if _merge==1 // all urban
	drop _merge
cap drop _*

merge m:1 dateMY using PPP_Denton
drop if _merge==2 // Aug-Dec 2017 not observed
drop _merge

foreach v in CoNA_sharing_pd iCoNA_HH_pd {
	gen `v'_ppp=`v'/PPP_month_interpolated
	}
	
lab var CoNA_sharing_pd_ppp "Daily Household CoNA (2011 US$), food sharing, month level"
lab var iCoNA_HH_pd_ppp "Daily Household total Individual CoNAs (2011 US$), month level"

save MalawiIHPS_DietQualCost_CoNAiCoNAseries_r, replace
save "$finaldata\MalawiIHPS_DietQualCost_CoNAiCoNAseries_r", replace

// PART // POLICY SCENARIOS			
foreach s in a b c {
	use HHCoNA_sharing_r_s1`s', clear
* * Keep applicable dates for time series dataset
	sum CoNA_sharing_s1`s', d
	tab2 year data_round

	sum CoNA_sharing_s1`s', d 
		drop if data_round==1 & year>=2013
		drop if data_round==2 & (year<2013 | year>2015)
		drop if data_round==3 & year<2016
	tab2 year data_round
	sum CoNA_sharing_s1`s', d
	
	// Generate time scale aggregations
	lab var CoNA_sharing_s1`s' "CoNA per week s1`s'"
	gen CoNA_sharing_pd_s1`s'=CoNA_sharing/7
		lab var CoNA_sharing_pd_s1`s' "Household CoNA, food sharing, per day (month level) s1`s'"
	gen CoNA_sharing_month_s1`s'=.
		replace CoNA_sharing_month_s1`s'=CoNA_sharing_pd_s1`s'*28 if month==2 & !inlist(year,2008,2012,2016)
		replace CoNA_sharing_month_s1`s'=CoNA_sharing_pd_s1`s'*29 if month==2 & inlist(year,2008,2012,2016)
		replace CoNA_sharing_month_s1`s'=CoNA_sharing_pd_s1`s'*30 if inlist(month,4,6,11)
		replace CoNA_sharing_month_s1`s'=CoNA_sharing_pd_s1`s'*31 if CoNA_sharing_month_s1`s'==.
		lab var CoNA_sharing_month_s1`s' "CoNA per month"
	save HHCoNA_r_s1`s', replace
}	

forval s=2/6 {
	use HHCoNA_sharing_r_s`s', clear
* * Keep applicable dates for time series dataset
	sum CoNA_sharing_s`s', d
	tab2 year data_round

	sum CoNA_sharing_s`s', d 
		drop if data_round==1 & year>=2013
		drop if data_round==2 & (year<2013 | year>2015)
		drop if data_round==3 & year<2016
	tab2 year data_round
	sum CoNA_sharing_s`s', d
	
	// Generate time scale aggregations
	lab var CoNA_sharing_s`s' "CoNA per week s`s'"
	gen CoNA_sharing_pd_s`s'=CoNA_sharing/7
		lab var CoNA_sharing_pd_s`s' "Household CoNA, food sharing, per day (month level) s`s'"
	gen CoNA_sharing_month_s`s'=.
		replace CoNA_sharing_month_s`s'=CoNA_sharing_pd_s`s'*28 if month==2 & !inlist(year,2008,2012,2016)
		replace CoNA_sharing_month_s`s'=CoNA_sharing_pd_s`s'*29 if month==2 & inlist(year,2008,2012,2016)
		replace CoNA_sharing_month_s`s'=CoNA_sharing_pd_s`s'*30 if inlist(month,4,6,11)
		replace CoNA_sharing_month_s`s'=CoNA_sharing_pd_s`s'*31 if CoNA_sharing_month_s`s'==.
		lab var CoNA_sharing_month_s`s' "CoNA per month"
	save HHCoNA_r_s`s', replace
}	

use HHCoNA_r_s1a, clear
cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	using HHCoNA_r_s1b
	cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	using HHCoNA_r_s1c
	cap drop _*
forval s=2/6 {
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	using HHCoNA_r_s`s'
	cap drop _*
}

* Generate solution variable
foreach s in a b c {
	gen CoNA_solution_s1`s'=1 if CoNA_sharing_s1`s'!=.
		replace CoNA_solution_s1`s'=0 if CoNA_sharing_s1`s'==.
	}
forval s=2/6 {
	gen CoNA_solution_s`s'=1 if CoNA_sharing_s`s'!=.
		replace CoNA_solution_s`s'=0 if CoNA_sharing_s`s'==.
	}

save HHCoNA_r_scenarios, replace
save "$finaldata\HHCoNA_r_scenarios", replace

* Merge with main CoNA series
use MalawiIHPS_DietQualCost_CoNAseries_r, clear
cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY ///
	using HHCoNA_r_scenarios
	drop _merge
	
	// Generate comparison relative to main results
	foreach s in a b c {
	gen CoNA_diffpd_s1`s'=((CoNA_sharing_pd_s1`s'-CoNA_sharing_pd)/CoNA_sharing_pd)*100
	}
	forval s=2/6 {
	gen CoNA_diffpd_s`s'=((CoNA_sharing_pd_s`s'-CoNA_sharing_pd)/CoNA_sharing_pd)*100
	}
	
* Merge in svy vars and weights
	merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
		using MalawiIHPS_DietQualCost_HH_r, ///
		keepusing(ea_id reside pweight)
	drop if _merge==2 // urban households, no food prices
drop if year<2013

* Reshape long
cap drop _*
foreach v in CoNA_sharing CoNA_solution CoNA_sharing_pd CoNA_sharing_month {
	ren `v' `v'_s0
	}
ren *_s1a *_s11
ren *_s1b *_s12
ren *_s1c *_s13
reshape long CoNA_sharing_s CoNA_solution_s CoNA_sharing_pd_s ///
	CoNA_sharing_month_s  CoNA_diffpd_s, ///
	i(case_id HHID y2_hhid y3_hhid data_round dateMY) j(scenario)
ren *_s *
lab val scenario .
tab scenario
recode scenario (0=1) (2=5) (3=6) (4=7) (5=8) (6=9) (11=2) (12=3) (13=4) 

		cap lab drop scen
		lab def scen 1 "Base case" ///
			2 "Eggs -10%"  ///
			3 "Eggs -15%"  ///
			4 "Eggs -20%"  ///
			5 "Fish Available"  ///
			6 "Groundnuts Available -10%"  ///
			7 "Fresh milk -10%"  ///
			8 "Powdered milk Available"  ///
			9 "Selenium Soil Biofort (Maize)"
		lab val scenario scen


lab def year 1 "2010" 2 "2013" 3 "2016/17"
lab val data_round year
cap drop _*
	
save MalawiIHPS_DietQualCost_CoNAseries_r_scenarios	, replace
save "$finaldata\MalawiIHPS_DietQualCost_CoNAseries_r_scenarios", replace

// Shadow prices policy scenarios
foreach s in a b c {
	use HHCoNA_ShadowPrices_r_s1`s', clear
	cap drop _*
	cap ren shadowprice_sharing sp_sharing
	cap ren semielasticity_sharing se_sharing
	cap drop shadowprice_sharing_pd shadowprice_sharing_annual semielasticity_sharing_pd ///
		semielasticity_sharing_annual elasticity_sharing_pd elasticity_sharing_annual
	drop e_sharing
	gen e_sharing=((CoNA_sharing_s1`s'+sp_sharing)/(CoNA_sharing))/(rhs/100)
	
	foreach v in sp_* se_* e_* {
		ren `v' `v'_s1`s'
		}
		save HHCoNA_ShadowPrices_r_s1`s', replace
		}
forval s=2/6 {
	use HHCoNA_ShadowPrices_r_s`s', clear
	cap drop _*
	cap ren shadowprice_sharing sp_sharing
	cap ren semielasticity_sharing se_sharing
	drop e_sharing
	gen e_sharing=((CoNA_sharing_s`s'+sp_sharing)/(CoNA_sharing))/(rhs/100)
	cap drop shadowprice_sharing_pd shadowprice_sharing_annual semielasticity_sharing_pd ///
		semielasticity_sharing_annual elasticity_sharing_pd elasticity_sharing_annual
	foreach v in sp_* se_* e_* {
		ren `v' `v'_s`s'
		}
		save HHCoNA_ShadowPrices_r_s`s', replace
		}
use HHCoNA_ShadowPrices_r_s1a, clear
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_r_s1b
	cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_r_s1c
	cap drop _*
forval s=2/6 {
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_r_s`s'
	cap drop _*
}
	drop if year<2013
	
save HHCoNA_ShadowPrices_r_scenarios, replace
save "$finaldata\HHCoNA_ShadowPrices_r_scenarios", replace

use HHCoNA_ShadowPrices_r, clear
	drop e_sharing
	gen e_sharing=((CoNA_sharing+sp_sharing)/(CoNA_sharing))/(rhs/100)
		foreach v in *sharing {
			ren `v' `v'_s0
			}
	drop if year<2013

merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY nutr_no constraint_type rel rhs using ///
	HHCoNA_ShadowPrices_r_scenarios
	drop _*
// Generate comparison relative to main results
	foreach s in a b c {
	gen sp_diff_s1`s'=((sp_sharing_s1`s'-sp_sharing_s0)/sp_sharing_s0)*100
	}
	forval s=2/6 {
	gen sp_diff_s`s'=((sp_sharing_s`s'-sp_sharing_s0)/sp_sharing_s0)*100
	}
	* Rename
		cap drop _*
		ren *_s1a *_s11
		ren *_s1b *_s12
		ren *_s1c *_s13

	* Reshape wide by constraint
	tab rel
	describe rel
	tab2 nutr_no constraint_type
	gen NR_type=.
	replace NR_type=2 if rel=="=" // Energy
	replace NR_type=1 if rel==">=" & !inlist(constraint_no,4,7) // EARs
	replace NR_type=3 if rel=="<=" & !inlist(constraint_no,5,8) // ULs
	replace NR_type=4 if rel==">=" ///
		& inlist(constraint_no,4,7,9) // AMDR lower
	replace NR_type=5 if rel=="<=" ///
		& inlist(constraint_no,5,8, 10) // AMDR upper
	tab2 nutr_no NR_type
	drop constraint_no constraint_type rel rhs
	cap drop 
	reshape wide sp_sharing* se_sharing* e_sharing* sp_diff*, ///
		i(case_id HHID y2_hhid y3_hhid data_round dateMY nutr_no) ///
		j(NR_type)
	ren (sp*1 sp*2 sp*3 sp*4 sp*5) (sp*_EAR sp*_Kcal sp*_UL sp*_AMDRlow sp*_AMDRup)	
	ren (se*1 se*2 se*3 se*4 se*5) (se*_EAR se*_Kcal se*_UL se*_AMDRlow se*_AMDRup)	
	ren (e*1 e*2 e*3 e*4 e*5) (e*_EAR e*_Kcal e*_UL e*_AMDRlow e*_AMDRup)	
	cap drop _merge
	ren *_s*_Kcal *_Kcal_s*
	ren *_s*_EAR *_EAR_s*
	ren *_s*_UL *_UL_s*
	ren *_s*_AMDRlow *_AMDRlow_s*
	ren *_s*_AMDRup *_AMDRup_s*
	
		* Reshape long by scenario		
		ren *_s6 *9
		ren *_s5 *8
		ren *_s4 *7
		ren *_s3 *6
		ren *_s2 *5
		ren *_s13 *4
		ren *_s12 *3
		ren *_s11 *2
		ren *_s0 *1
		
		reshape long CoNA_sharing e_sharing_AMDRlow e_sharing_AMDRup e_sharing_EAR ///
			e_sharing_Kcal e_sharing_UL se_sharing_AMDRlow se_sharing_AMDRup ///
			se_sharing_EAR se_sharing_Kcal se_sharing_UL sp_diff_AMDRlow sp_diff_AMDRup  ///
			sp_diff_EAR sp_diff_Kcal sp_diff_UL sp_sharing_AMDRlow sp_sharing_AMDRup ///
			sp_sharing_EAR sp_sharing_Kcal sp_sharing_UL, ///
			i(case_id HHID y2_hhid y3_hhid data_round dateMY nutr_no) j(scenario)
		lab val scenario .
		tab scenario
		cap lab drop scen
		lab def scen 1 "Base case" ///
			2 "Eggs -10%"  ///
			3 "Eggs -15%"  ///
			4 "Eggs -20%"  ///
			5 "Fish Available"  ///
			6 "Groundnuts Available -10%"  ///
			7 "Fresh milk -10%"  ///
			8 "Powdered milk Available"  ///
			9 "Selenium Soil Biofort (Maize)"
		lab val scenario scen

		lab def year 1 "2010" 2 "2013" 3 "2016/17"
		lab val data_round year
		cap drop _*
	
* Merge in svy vars and weights
	merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
		using MalawiIHPS_DietQualCost_HH_r, ///
		keepusing(ea_id reside pweight)
	drop if _merge==2 // urban households no food prices

drop if nutr_no==1
svyset ea_id [pweight=pweight], strata(reside) singleunit(centered)
save MalawiIHPS_DietQualCost_SPseries_r_scenarios, replace
save "$finaldata\MalawiIHPS_DietQualCost_SPseries_r_scenarios", replace

// Food item policy scenarios
	foreach s in a b c {
		use HHCoNA_foodlevel_r_s1`s', clear
		drop if year<2013
		gen scenario="s1`s'"
		save HHCoNA_foodlevel_r_s1`s's, replace
		}
			
	forval s=2/6 {
		use HHCoNA_foodlevel_r_s`s', clear
		drop if year<2013
		gen scenario="s`s'"
		save HHCoNA_foodlevel_r_s`s's, replace
		}
			
	use HHCoNA_foodlevel_r_s1as, clear
	append using HHCoNA_foodlevel_r_s1bs
	append using HHCoNA_foodlevel_r_s1cs
	append using HHCoNA_foodlevel_r_s2s
	append using HHCoNA_foodlevel_r_s3s
	append using HHCoNA_foodlevel_r_s4s
	append using HHCoNA_foodlevel_r_s5s
	append using HHCoNA_foodlevel_r_s6s

	save HHCoNA_FoodLevel_r_scenarios, replace

		* Merge with main results
		use HHCoNA_foodlevel_r.dta, clear
		drop if year<2013
		cap drop _*
		gen scenario="s0"
		drop energy carbohydrate protein lipids vitA retinol vitC vitE thiamin ///
			riboflavin niacin vitB6 folate vitB12 calcium copper iron magnesium phosphorus selenium zinc sodium total_energy total_carbohydrate total_protein total_lipids total_vitA total_retinol total_vitC total_vitE total_thiamin total_riboflavin total_niacin total_vitB6 total_folate total_vitB12 total_calcium total_copper total_iron total_magnesium total_phosphorus total_selenium total_zinc total_sodium
		tempfile base
			save `base', replace
	use HHCoNA_FoodLevel_r_scenarios, clear
	append using `base'

		// Merge in svy vars and weights
		merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
			using MalawiIHPS_DietQualCost_HH, ///
			keepusing(ea_id reside pweight)
		drop if _merge==2 // urban households, no food prices
		drop _merge 
		
		// Fix food groups to match IHPS data 
		describe food_group
		lab drop foodgroup
			replace food_group=11 if food_group_name=="Oils & fats"
			replace food_group=12 if food_group_name=="Other fruit"
			replace food_group=13 if food_group_name=="Other vegetable"
			replace food_group=14 if food_group_name=="Roots & tubers"
			replace food_group=15 if food_group_name=="Salty snacks & fried foods"
			replace food_group=16 if food_group_name=="Sweets & confectionary"
			replace food_group=17 if food_group_name=="Vitamin-A rich fruits"
			replace food_group=18 if food_group_name=="Vitamin-A rich vegetables & tubers"
		tab food_group
		tab food_group_name
		
		cap lab drop foodgroup
		lab def foodgroup ///
			1 "Alcohol, stimulants, spices, condiments" ///
			2 "Caloric_beverages" ///
			3 "Cereals & cereal products" ///
			4 "Dark green leafy vegetables" ///
			5 "Eggs" ///
			6 "Fish & seafood" ///
			7 "Flesh meat" ///
			8 "Legumes" ///
			9 "Milk & milk products" ///
			10 "Nuts & seeds" ///
			11 "Oils & fats" ///
			12 "Other fruit" ///
			13 "Other vegetable" ///
			14 "Roots & tubers" ///
			15 "Salty snacks & friedfoods" ///
			16 "Sweets & confectionary" ///
			17 "Vitamin-A rich fruits" ///
			18 "Vitamin-A rich vegetables & tubers"
		lab val food_group foodgroup
		tab food_group
		tab food_group, nolabel
		tab food_group_name

	encode scenario, gen(scen_num)
	drop scenario
	tab scen_num, nolabel
	describe scen_num
	lab drop scen_num
	ren scen_num scenario
			lab def scen 1 "Base case" ///
			2 "Eggs -10%"  ///
			3 "Eggs -15%"  ///
			4 "Eggs -20%"  ///
			5 "Fish Available"  ///
			6 "Groundnuts Available -10%"  ///
			7 "Fresh milk -10%"  ///
			8 "Powdered milk Available"  ///
			9 "Selenium Soil Biofort (Maize)"
		lab val scenario scen
		
	* Generate percent cost by food group
	egen foodgroupcost=total(food_cost), by(case_id HHID y2_hhid y3_hhid food_group dateMY scenario)
	save HHCoNA_FoodLevel_r_scenarios, replace
		save "$finaldata\HHCoNA_FoodLevel_r_scenarios", replace
	
cap log close

