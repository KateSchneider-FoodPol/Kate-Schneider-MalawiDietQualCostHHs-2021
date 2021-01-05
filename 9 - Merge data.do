/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: Merge datasets into final formats.
Datasets produced: Produces datasets at the person-nutrient, person, 
	household-nutrient, household, asset, and food item levels. Least-cost diet
	datasets are monthly for the fully period.
	
* LEAST-COST DIET RESULTS CREATED IN THIS DATASET ARE FOR ARCHIVE PURPOSES ONLY *
* MERGED DATA FILES FOR LEAST-COST DIETS WITH THE REVISED NUTRIENT REQUIREMENTS
	ARE COMPILED IN THE REVISED VERSION OF DO FILE 9. *
* HOUSEHOLD DATASETS UNAFFECTED BY NUTRIENT REQUIREMENTS ARE ONLY CREATED IN THIS
	VERSION OF THE DO FILE SO BOTH MUST BE RUN TO REPLICATE CHAPTERS 5 AND 6 
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

********************************************************************************
* Input datasets final cleaning and saving to final folder

	// Household and Individual Identifiers and Sociodemographics
	use HH+Indiv, clear
			save "$finaldata\HH+Indiv", replace
			
	// Nutrient Requirements
	use HHNeeds_HHLevel, clear
		save "$finaldata\HHNeeds_HHLevel", replace
	use HHNeeds_IndivLevel, clear
		save "$finaldata\HHNeeds_IndivLevel", replace
	use HH_NRGroups, clear 
		save "$finaldata\HH_NRgroups", replace

	// Household Adequacy Ratios
	use HHAdequacyRatios_IndivLevel, clear
		save "$finaldata\HHAdequacyRatios_IndivLevel", replace

	// Household Consumption
	use HHConsumption_FoodItemLevel, clear
		save "$finaldata\HHConsumption_FoodItemLevel", replace
	use HHConsumptionAggregate, clear
		save "$finaldata\HHConsumptionAggregate", replace
	use FoodItems_Conversion, clear
		save "$finaldata\FoodItems_Conversion", replace
	
	// HH Assets //
	use HHAssets, clear
		save "$finaldata\HHAssets", replace

	// Market price data //
	use CPIDataForCoNA, clear
		save "$finaldata\CPIDataForCoNA", replace

	// CoNA results
	use HHCoNA_sharing, clear // Full time series
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
			save HHCoNA_sharing, replace
		save "$finaldata\HHCoNA_sharing", replace
	use HHCoNA, clear // Applicable dates (time series)
			* Fix time summary indicators 
			drop CoNA_sharing_*
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
			save HHCoNA, replace
			save "$finaldata\HHCoNA", replace
	use HHCoNA_sharing_foodlevel, clear
			save "$finaldata\HHCoNA_sharing_foodlevel", replace
	use HHCoNA_sharing_totalnutrients, clear
			save "$finaldata\HHCoNA_sharing_totalnutrients", replace
	use iCoNA, clear // iCoNA full time series (age-sex group x market x dateMY X food)
			save "$finaldata\iCoNA_food", replace
			collapse (first) iCoNA*, by(age_sex_grp market_no pal dateMY)
			save "$finaldata\iCoNA", replace
			
	// Semi-elasticities results
	use HH_SemiElasticities_sharing, clear // Shadow prices results, in nominal MWK
		// Applicable dates long by constraints
		use HHCoNA_ShadowPrices, clear
			save "$finaldata\HHCoNA_ShadowPrices", replace
		
	// Create Denton Method Time Series of PPP conversion factors //
	use iCoNA, clear
	collapse (first) dateMY, by(year month)
	set obs 128
	replace month = 8 in 128
	set obs 129
	replace month = 9 in 129
	set obs 130
	replace month = 10 in 130
	set obs 131
	replace month = 11 in 131
	set obs 132
	replace month = 12 in 132
	replace year=2017 if year==.
	replace dateMY=ym(year, month) if dateMY==.
	gen MWK=1
	drop if dateMY==.
	sum
	tsset dateMY
	tempfile dentonprep
		save `dentonprep', replace
		
	use ppp_annual, clear
	tsset year
	denton PPP using PPP_Denton, interp(MWK) stock ///
		from(`dentonprep') gen(PPP_month_interpolated)
	use PPP_Denton, clear
		merge 1:1 dateMY using `dentonprep'
		drop _merge
		egen PPP2=total(PPP), by(year)
		drop PPP
		ren PPP2 PPP
		replace PPP_month_interpolated=PPP if PPP_month_interpolated==. & year==2007 // No interpolation for the first year
	save "$finaldata\PPP_Denton", replace

********************************************************************************
cap log close
log using "9_Merge+Descriptives_`c(current_date)'", replace
***Log of Do File #9 "09_Data Combination & Creation of Final Datasets"
di "`c(current_date)' `c(current_time)'"

* This do file merges the above input datasets into several compiled
* files at combinations of levels including nutrient, individual, household,
* asset, and food item

// MERGE ALL //
* Start with household and individual
use HH+Indiv, clear

recode reside (1=0) (2=1)
lab def reside 1 "Rural" 0 "Urban"
lab val reside reside
lab var reside "Rural (%)"
	unique case_id HHID y2_hhid y3_hhid data_round
	unique case_id HHID y2_hhid y3_hhid data_round PID

cap drop _*
joinby case_id data_round HHID y2_hhid y3_hhid date_consump PID ///
		using HHAdequacyRatios_IndivLevel
cap drop _*

	unique case_id HHID y2_hhid y3_hhid data_round
	unique case_id HHID y2_hhid y3_hhid data_round PID
	unique case_id HHID y2_hhid y3_hhid data_round PID nutr_no

* Merge in consumption
merge m:1 case_id data_round HHID y2_hhid y3_hhid ///
	date_consump using HHConsumptionAggregate
	// Drop 15 unmatched households: These were dropped in HH+Indiv because no one
	// ate any meals at home in the prior 7 days
	drop if _merge==2
	drop _merge
	
	unique case_id HHID y2_hhid y3_hhid data_round
	unique case_id HHID y2_hhid y3_hhid data_round PID
	unique case_id HHID y2_hhid y3_hhid data_round PID nutr_no

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
cap drop _*

* Label Nutrients
cap drop _*

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

save IHPS_AdequacyExpenditure, replace

* Merge in CoNA
preserve
	collapse (first) date_consump_MY, by(case_id HHID y2_hhid y3_hhid data_round)
	tempfile IHPSdates
		save `IHPSdates', replace
	use HHCoNA, clear
		merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
			using `IHPSdates'
			drop if _merge==2 // Urban markets
			drop _merge
			sum CoNA*, d
			* Save only date matching HH survey for analysis
			keep if dateMY==date_consump_MY
			unique case_id HHID y2_hhid y3_hhid data_round
			save HHCoNA_IHPSdates, replace
restore
merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
	using HHCoNA_IHPSdates
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
	TA_name UL_sharing age_sex_grp age_rptd ageinmonths date_consump date_consump_MY ///
	daysate_hh_conv sex haz head_ed hnar_share_Eadjusted lactating market market_no ///
	month nutr_dens nutr_no pct_buy pct_nutr_buy pctnut_buy pctnut_own spouse_ed stunted ///
	tot_nutr_buy tot_nutr_giftoth tot_nutr_ownprod underweight wasted_overweight ///
	waz wealth wealth_quintile whz, after(y3_hhid)
order pweight hh_tot_intake source_uncertain ///
	CoNA*, after(hhsize)
destring, replace	
	
// PERSON - NUTRIENT LEVEL DATASET //
cap drop _* 
	// Prevalence of insufficient
	gen hnar_share_PIA=0 if hnar_share>=1 
		replace hnar_share_PIA=1 if hnar_share<1
		lab var hnar_share_PIA "Prevalence if inadequacy, shared diet, reported intakes"
	gen hnar_share_Eadjusted_PIA=0 if hnar_share_Eadjusted>=1 
		replace hnar_share_Eadjusted_PIA=1 if hnar_share_Eadjusted<1
		lab var hnar_share_Eadjusted_PIA "Prevalence if inadequacy, shared diet, energy-adjusted"
cap drop _* 
	
	gen ratio=hnar_share/hnar_share_Eadjusted if nutr_no==2

		// Prevalence of excess
		gen exceedshare=exceedUL_share if inlist(nutr_no,7,8,13,16,17,18,20,21,22,23)
			replace exceedshare=exceedAMDR_share if inlist(nutr_no,3,4,5)
			replace exceedshare=1 if hnar_share>1 & nutr_no==2
			replace exceedshare=0 if hnar_share<=1 & nutr_no==2
		lab var exceedshare "Probability of Excess Intake, shared diet, reported intakes"
cap drop _* 
		gen exceedshare_Eadjusted=exceedUL_share_Eadjusted if inlist(nutr_no,7,8,13,16,17,18,20,21,22,23)
			replace exceedshare_Eadjusted=exceedAMDR_share_Eadjusted if inlist(nutr_no,3,4,5)
			replace exceedshare_Eadjusted=0 if exceedshare_Eadjusted==.
		lab var exceedshare "Probability of Excess Intake, shared diet, energy-adjusted"
cap drop _* 

save MalawiIHPS_DietQualCost_Nut_PID, replace
save "$finaldata\MalawiIHPS_DietQualCost_Nut_PID", replace

// PERSON LEVEL DATASET //
* Reshape nutrient-level variables wide to person-level 
use MalawiIHPS_DietQualCost_Nut_PID, clear
sort case_id HHID y2_hhid y3_hhid PID data_round nutr_no
cap drop _*
drop iron_18pct_EAR_sharing zinc_40pct_EAR_sharing iron_18pct_EAR_targeting ///
	zinc_40pct_EAR_targeting amdrlow_toddler_perweek amdrup_toddler_perweek ///
	energytoddler max_amdrlow_perkcal min_amdrup_perkcal

foreach v in hh_tot_intake tot_nutr_buy tot_nutr_ownprod tot_nutr_giftoth ///
	pctnut* nutr_dens pct_nutr_buy EAR* UL* AMDR* hnar* amdr* ear* ul* ///
	exceed* m*perkcal {
		ren `v' `v'_
		}

	tab nutr_no
	drop if nutr_no==1
	misstable sum case_id HHID y2_hhid y3_hhid PID hhxround data_round nutr_no

	unique case_id HHID y2_hhid y3_hhid data_round
	unique case_id HHID y2_hhid y3_hhid data_round PID
	unique case_id HHID y2_hhid y3_hhid data_round PID nutr_no
drop ratio
	
reshape wide hh_tot_intake_ tot_nutr_buy_ tot_nutr_ownprod_ tot_nutr_giftoth_ ///
	nutr_dens_ EAR* UL* AMDR* amdr* ear* ul* m*perkcal_ hnar* pctnut* ///
	exceed* pct_nutr_buy_, i(case_id HHID y2_hhid y3_hhid data_round PID) j(nutr_no)

* Reorder nutrient level variables to end, key variables to beginning
order hh_tot_intake_2-pctnut_buy_23, last
order data_round pweight sex hh_b04 district-hh_a02b year-region TA_name ///
	age_rptd-daysate_hh_conv date_consump_MY head_ed-dateMY CoNA*, after(y3_hhid)
cap drop __*

save MalawiIHPS_DietQualCost_PID, replace

// MERGE SHADOW PRICES INTO NUTRIENT LEVEL DATASET //
use IHPS_AdequacyExpenditure, clear
	collapse (first) date_consump_MY, by(case_id HHID y2_hhid y3_hhid data_round nutr_no)
	tempfile IHPSdates
		save `IHPSdates', replace	
	use HHCoNA_ShadowPrices, clear
	merge m:1 case_id HHID y2_hhid y3_hhid data_round nutr_no ///
		using `IHPSdates'
		drop if _merge==2
		drop _merge
			* Save only date matching HH survey for analysis
			sum if dateMY==date_consump_MY
			keep if dateMY==date_consump_MY
			save HHCoNAShadowPrices_IHPSdates, replace

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
	using MalawiIHPS_DietQualCost_Nut_PID
	// Unmerged are urban with no food price data
drop _merge

save MalawiIHPS_DietQualCost_Nut, replace
save "$finaldata\MalawiIHPS_DietQualCost_Nut", replace
	
// HOUSEHOLD-NUTRIENT LEVEL DATASET //
use MalawiIHPS_DietQualCost_Nut, clear
cap drop _*
	* Save labels
	foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
		}
	}

collapse (first) sp_* se_* e_* reside ///
	year month CoNA* market_no date_consump date_consump_MY hh_round date_seq  ///
	 obs_date_tag AMDR* EAR* KCAL* TA_name UL* daysate_hh_conv head_ed hnar*  ///
	 market nutr_dens *buy *own spouse_ed *giftoth *ownprod wealth* district*  ///
	 ta_code hh_a02b hhsize pweight hh_tot_intake source_uncertain ///
	 hhxround ea_id fed_others region baseline_rural dropurban education dependency_ratio  ///
	 fem_male_ratio hh_g09 iron* zinc* totalexp_* totalexpenditure pctfoodexp, ///
		by(case_id HHID y2_hhid y3_hhid data_round dateMY nutr_no)

	* Relabel
	foreach v of var * {
 	label var `v' "`l`v''"
		}	
save MalawiIHPS_DietQualCost_Nut_HH, replace
save "$finaldata\MalawiIHPS_DietQualCost_Nut_HH", replace

// HOUSEHOLD LEVEL DATASET //
use MalawiIHPS_DietQualCost_PID, clear
	* Save labels
	foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
		}
	}

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
	
save MalawiIHPS_DietQualCost_HH, replace

// FOOD ITEM LEVEL DATASETS //	
** FOOD ITEMS IN CONA
use HHCoNA_sharing_foodlevel, clear
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
		using MalawiIHPS_DietQualCost_HH, ///
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
		
save MalawiIHPS_DietQualCost_FoodCoNA, replace
save "$finaldata\MalawiIHPS_DietQualCost_FoodCoNA", replace

**FOOD ITEMS IN HOUSEHOLD EXPENDITURE
* Food-Nutrient Level dataset
use HHIntakes_fooditem, clear

recode reside (1=0) (2=1)
lab def reside 1 "Rural" 0 "Urban"
lab var reside "Rural (%)"

	// Fix food group data
	drop food_group food_group_name MWI_food_group MWI_food_group_name
preserve
	clear
	import excel using "$finaldata\IHPS_Foods+FCT", firstrow
	keep fooditem food_group MWI_food_group	MWI_food_group_name
	ren fooditem food_no
	tempfile foodgroups
	save `foodgroups', replace
restore
	merge m:m food_no food_no using `foodgroups'
	* browse if _merge==1 // Restaurant meal, other, infant formula
	drop if _merge!=3
	drop _merge
			
	// Label Malawi food groups
	replace MWI_food_group="0" if MWI_food_group=="."
	destring MWI_food_group, replace
	tab MWI_food_group
	cap lab drop fgmwi
	lab def fgmwi 0 "Excluded" ///
		1 "Animal_foods" ///
		2 "Fats_oils" ///
		3 "Fruits" ///
		4 "Legumes_Nuts" ///
		5 "Staples" ///
		6 "Vegetables"
	lab val MWI_food_group fgmwi
	replace MWI_food_group=. if MWI_food_group==0
	tab MWI_food_group
	
	// Destring food_group
	ren food_group food_group_name
	gen food_group=.
		replace food_group=1 if food_group_name=="Alcohol, stimulants, spices & condiments"
		replace food_group=2 if food_group_name=="Caloric beverages"
		replace food_group=3 if food_group_name=="Cereals & cereal products"
		replace food_group=4 if food_group_name=="Dark green leafy vegetables"
		replace food_group=5 if food_group_name=="Eggs"
		replace food_group=6 if food_group_name=="Fish & seafood"
		replace food_group=7 if food_group_name=="Flesh meat"
		replace food_group=8 if food_group_name=="Legumes"
		replace food_group=9 if food_group_name=="Milk & milk products"
		replace food_group=10 if food_group_name=="Nuts & seeds"
		replace food_group=11 if food_group_name=="Oils & fats"
		replace food_group=12 if food_group_name=="Other fruit"
		replace food_group=13 if food_group_name=="Other vegetable"
		replace food_group=14 if food_group_name=="Roots & tubers"
		replace food_group=15 if food_group_name=="Salty snacks & fried foods"
		replace food_group=16 if food_group_name=="Sweets & confectionary"
		replace food_group=17 if food_group_name=="Vitamin-A rich fruits"
		replace food_group=18 if food_group_name=="Vitamin-A rich vegetables & tubers"

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
	
	// Generate total nutrients per household
	egen totalnut_hh=total(tot_nutr_byfood_total), by(case_id HHID y2_hhid y3_hhid data_round nutr_no)
	// Generate percent of nutrient total from each food item
	gen pcthhtotalnut_perfood=tot_nutr_byfood_total/totalnut_hh

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

save MalawiIHPS_DietQualCost_FoodNUT_HHExp, replace
save "$finaldata\MalawiIHPS_DietQualCost_FoodNUT_HHExp", replace

* Food Item Level
use HHConsumption_FoodItemLevel, clear
cap drop _*
recode reside (1=0) (2=1)
lab def reside 1 "Rural" 0 "Urban"
lab var reside "Rural (%)"

	// Fix food group data
	drop food_group food_group_name MWI_food_group MWI_food_group_name
preserve
	clear
	import excel using "$otherrawdata\IHPS_Foods+FCT", firstrow
	keep fooditem food_group MWI_food_group	MWI_food_group_name
	ren fooditem food_no
	tempfile foodgroups
	save `foodgroups', replace
restore
	merge m:m food_no food_no using `foodgroups'
	* browse if _merge==1 // Restaurant meal, other, infant formula
	drop if _merge!=3
	drop _merge
			
	// Label Malawi food groups
	replace MWI_food_group="0" if MWI_food_group=="."
	destring MWI_food_group, replace
	tab MWI_food_group
	cap lab drop fgmwi
	lab def fgmwi 0 "Excluded" ///
		1 "Animal_foods" ///
		2 "Fats_oils" ///
		3 "Fruits" ///
		4 "Legumes_Nuts" ///
		5 "Staples" ///
		6 "Vegetables"
	lab val MWI_food_group fgmwi
	replace MWI_food_group=. if MWI_food_group==0
	tab MWI_food_group
	
	// Destring food_group
	ren food_group food_group_name
	gen food_group=.
		replace food_group=1 if food_group_name=="Alcohol, stimulants, spices & condiments"
		replace food_group=2 if food_group_name=="Caloric beverages"
		replace food_group=3 if food_group_name=="Cereals & cereal products"
		replace food_group=4 if food_group_name=="Dark green leafy vegetables"
		replace food_group=5 if food_group_name=="Eggs"
		replace food_group=6 if food_group_name=="Fish & seafood"
		replace food_group=7 if food_group_name=="Flesh meat"
		replace food_group=8 if food_group_name=="Legumes"
		replace food_group=9 if food_group_name=="Milk & milk products"
		replace food_group=10 if food_group_name=="Nuts & seeds"
		replace food_group=11 if food_group_name=="Oils & fats"
		replace food_group=12 if food_group_name=="Other fruit"
		replace food_group=13 if food_group_name=="Other vegetable"
		replace food_group=14 if food_group_name=="Roots & tubers"
		replace food_group=15 if food_group_name=="Salty snacks & fried foods"
		replace food_group=16 if food_group_name=="Sweets & confectionary"
		replace food_group=17 if food_group_name=="Vitamin-A rich fruits"
		replace food_group=18 if food_group_name=="Vitamin-A rich vegetables & tubers"

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

	// Generate percentage variables
	egen totalexp_foodgroup=total(item_expenditure), ///
		by(case_id HHID y2_hhid y3_hhid data_round food_group)
	egen totalexp_foodgroup_MWI=total(item_expenditure), ///
		by(case_id HHID y2_hhid y3_hhid data_round MWI_food_group)
	
	// Percent of spending per food group
	gen foodgroup_pctfoodexp=(totalexp_foodgroup/totalexp_food_weekly)
	lab var foodgroup_pctfoodexp "Percent total food spending on food group"
	gen foodgroupMWI_pctfoodexp=(totalexp_foodgroup_MWI/totalexp_food_weekly)
	lab var foodgroupMWI_pctfoodexp "Percent total food spending on food group"
	
	save MalawiIHPS_DietQualCost_FoodHHExp, replace
	save "$finaldata\MalawiIHPS_DietQualCost_FoodHHExp", replace

// TOTAL NUTRIENTS IN CONA DIETS MERGED WITH REQUIREMENTS //
	use HHCoNA_sharing_totalnutrients, clear
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
	save HHCoNA_sharing_totalnutrients_MWKnominal_applicabledates, replace
	
	use HHNeeds_HHLevel, clear
	drop year month hhxround 
	drop if nutr_no==1 // price
	drop if dropurban==1
	merge 1:m case_id HHID y2_hhid y3_hhid data_round nutr_no market_no date_consump ///
		using HHCoNA_sharing_totalnutrients_MWKnominal_applicabledates
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
	
	save HHCoNA_sharing+HHNeeds_HHLevel, replace
	save "$finaldata\HHCoNA_sharing+HHNeeds_HHLevel", replace
	
// ASSETS LEVEL DATASET //
use HHAssets, clear
drop ea_id reside region district ta_code
merge m:1 case_id HHID y2_hhid y3_hhid using MalawiIHPS_DietQualCost_HH, ///
	keepusing(data_round pweight ea_id reside region district ta_code)
distinct case_id HHID y2_hhid y3_hhid if _merge==1 // HHs dropped for lack of food consumption
	drop if _merge==1
	drop _merge
	
save MalawiIHPS_DietQualCost_Assets, replace
save "$finaldata\MalawiIHPS_DietQualCost_Assets", replace

// CONA TIME SERIES WITH HOUSEHOLD DATA //
use HHCoNA, clear 
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
	
save MalawiIHPS_DietQualCost_CoNAseries, replace
save "$finaldata\MalawiIHPS_DietQualCost_CoNAseries", replace

// iCONA TIME SERIES WITH HOUSEHOLD DATA //
* Import population shares for generic individuals
use MalawiIHPS_DietQualCost_PID, clear
svyset ea_id [pweight=pweight], strata(reside) singleunit(centered)
 
svy: tab age_sex_grp
mat list e(b)
mat popshare=e(b)

use iCoNA, clear
drop if age_sex_grp==3
preserve
	use iCoNA_gr3, clear
	tempfile g3
	save `g3', replace
restore
append using `g3'

* Collapse to person level
collapse (first)  iCoNA  iCoNA_solution dateMY, ///
	by(age_sex_grp market_no year month person pal)
gen popshare=.
forval i=2/19 {
	replace popshare=popshare[1,`i'] if age_sex_grp==`i'
	}
forval i=23/25 {
	replace popshare=popshare[1,(`i'-3)] if age_sex_grp==`i'
	}
tab age_sex_grp, sum(popshare)

* Generate monthly cost and annualized average cost
sum iCoNA, d
lab var iCoNA "Individual CoNA per week"

	gen iCoNA_pd=iCoNA/7
		lab var iCoNA_pd "iCoNA per day, month level"
	gen iCoNA_month=.
		replace iCoNA_month=iCoNA_pd*28 if month==2 & !inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*29 if month==2 & inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*30 if inlist(month,4,6,11)
		replace iCoNA_month=iCoNA_pd*31 if iCoNA_month==.
		lab var iCoNA_month "iCoNA per month"
tab age_sex_grp, sum(iCoNA_solution)
	
save MalawiIHPS_DietQualCost_iCoNA, replace
save "$finaldata\MalawiIHPS_DietQualCost_iCoNA", replace

* Merge iCoNA into person level dataset
use MalawiIHPS_DietQualCost_PID, clear
replace dateMY=date_consump_MY if dateMY==.
merge m:1 age_sex_grp market_no pal dateMY using MalawiIHPS_DietQualCost_iCoNA, ///
	keepusing(iCoNA)
	drop if _merge==2 // markets and months not observed
	tab market_no if _merge==1 & age_sex_grp!=1, m
	drop _merge
	replace iCoNA=iCoNA*daysate_conv

sum iCoNA, d
lab var iCoNA "Individual CoNA per week"

	gen iCoNA_pd=iCoNA/7
		lab var iCoNA_pd "iCoNA per day, month level"
	gen iCoNA_month=.
		replace iCoNA_month=iCoNA_pd*28 if month==2 & !inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*29 if month==2 & inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*30 if inlist(month,4,6,11)
		replace iCoNA_month=iCoNA_pd*31 if iCoNA_month==.
		lab var iCoNA_month "iCoNA per month"
gen iCoNA_solution=1 if iCoNA!=.
replace iCoNA_solution=0 if iCoNA==.
tab age_sex_grp, sum(iCoNA_solution)
sum CoNA*, d
gen personcheck=1 if age_sex_grp!=1
egen countforhhicona=total(personcheck), by(case_id HHID y2_hhid y3_hhid data_round year)
replace iCoNA_solution=. if age_sex_grp==1
egen countsolution=total(iCoNA_solution), by(case_id HHID y2_hhid y3_hhid data_round year)
tab2 countforhhicona countsolution

egen iCoNA_HH_pd=total(iCoNA_pd), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
	replace iCoNA_HH_pd=. if countforhhicona!=countsolution

cap drop _*
save MalawiIHPS_DietQualCost_PID, replace
save "$finaldata\MalawiIHPS_DietQualCost_PID", replace
	
	* save labels
		foreach v of var * {
		local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
			}
		}
	collapse (firstnm) iCoNA_HH_pd, by(case_id HHID y2_hhid y3_hhid data_round)
	* Relabel
	foreach v of var * {
	label var `v' "`l`v''"
		}
				
	tempfile iconashh
		save `iconashh', replace

* Merge iCoNA into household level datasets
use MalawiIHPS_DietQualCost_HH, clear
cap drop iCoNA*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round using `iconashh'
	drop _merge
lab var pctfoodexp "Food Spending Share of Total Expenditures"

save MalawiIHPS_DietQualCost_HH, replace
save "$finaldata\MalawiIHPS_DietQualCost_HH", replace

// Merge sharing and individual time series 
use MalawiIHPS_DietQualCost_iCoNA, clear
	cap drop _*
	gen data_round=1 if year<=2012
	replace data_round=2 if year>=2013 & year<=2015
	replace data_round=3 if year>=2016
	
	tempfile icona
		save `icona', replace
use MalawiIHPS_DietQualCost_PID, clear
	keep PID age_sex_grp case_id HHID y2_hhid y3_hhid data_round pweight hhsize pal daysate_conv ea_id reside market market_no
	drop if reside!=1
	drop if market_no==.
joinby age_sex_grp market_no pal data_round using `icona'
cap drop _*
drop iCoNA_pd iCoNA_month
replace iCoNA=iCoNA*daysate_conv
	gen iCoNA_pd=iCoNA/7
		lab var iCoNA_pd "iCoNA per day, month level"
	gen iCoNA_month=.
		replace iCoNA_month=iCoNA_pd*28 if month==2 & !inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*29 if month==2 & inlist(year,2008,2012,2016)
		replace iCoNA_month=iCoNA_pd*30 if inlist(month,4,6,11)
		replace iCoNA_month=iCoNA_pd*31 if iCoNA_month==.
		lab var iCoNA_month "iCoNA per month"
tab2 dateMY data_round
egen solutionscount=count(iCoNA_month), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
tab2 hhsize solutionscount
	replace PID=. if age_sex_grp==1
	egen hhsizeminusinfant=count(PID), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
		tab hhsizeminusinfant
egen iCoNA_HH_pd=total(iCoNA_pd), by(case_id HHID y2_hhid y3_hhid data_round dateMY)
	replace iCoNA_pd=. if hhsizeminusinfant!=solutionscount
	lab var iCoNA_HH_pd "Household iCoNA per day, month level"
	gen iCoNA_solutionallHH=1 if iCoNA_pd!=.
		replace iCoNA_solutionallHH=0 if iCoNA_pd==.
	tab iCoNA_solutionallHH
	* save labels
		foreach v of var * {
		local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
			}
		}
collapse (first) iCoNA_pd iCoNA_month iCoNA_HH_pd iCoNA_solutionallHH, ///
	by(case_id HHID y2_hhid y3_hhid data_round dateMY)
	* Relabel
	foreach v of var * {
	label var `v' "`l`v''"
		}

tempfile iCoNA
	save `iCoNA', replace

use MalawiIHPS_DietQualCost_CoNAseries, clear
merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
	using MalawiIHPS_DietQualCost_HH, keepusing(reside ea_id pweight)
drop if _merge==2 // No price data
drop _merge
merge 1:1 case_id HHID y2_hhid y3_hhid data_round dateMY using `iCoNA'
	tab reside if _merge==1 // all urban
	drop _merge
cap drop _*

merge m:1 dateMY using PPP_Denton
drop if _merge==2 // Aug-Dec 2017 not observed
drop _merge

foreach v in CoNA_sharing_pd CoNA_sharing_month ///
	iCoNA_pd iCoNA_month iCoNA_HH_pd {
	gen `v'_ppp=`v'/PPP_month_interpolated
	}
	
lab var CoNA_sharing_pd_ppp "Daily Household CoNA (2011 US$), food sharing, month level"
lab var CoNA_sharing_month_ppp "Monthly Household CoNA (2011 US$), food sharing"
lab var iCoNA_pd_ppp "Daily Individual CoNA (2011 US$), month level"
lab var iCoNA_month_ppp "Monthly Individual CoNA (2011 US$)"
lab var iCoNA_HH_pd_ppp "Daily Household total Individual CoNAs (2011 US$), month level"

save MalawiIHPS_DietQualCost_CoNAiCoNAseries, replace
save "$finaldata\MalawiIHPS_DietQualCost_CoNAiCoNAseries", replace

// Merge PPP into iCoNA //
use MalawiIHPS_DietQualCost_iCoNA, clear
cap drop _*
merge m:1 dateMY using PPP_denton
drop if _merge==2
drop _merge
foreach v in iCoNA iCoNA_month iCoNA_pd  {
		gen `v'_ppp=`v'/PPP_month_interpolated
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

	* Merge in region
	preserve
		use CPIDataForCoNA, clear
			* save labels
		foreach v of var * {
		local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
			}
		}
		collapse (first) region, by(market_no)
		* Relabel
		foreach v of var * {
		label var `v' "`l`v''"
			}
		tempfile region
			save `region'
	restore
	merge m:1 market_no using `region'
	drop _merge
	
	save MalawiIHPS_DietQualCost_iCoNA, replace
	save "$finaldata\MalawiIHPS_DietQualCost_iCoNA", replace

// PART // POLICY SCENARIOS
* Main CoNA results

	// Policy scenarios
		* Revised nutrient requirements - Main CoNA
			HHCoNA_sharing_s1a // Eggs -10%
			HHCoNA_sharing_s1b // Eggs -15%
			HHCoNA_sharing_s1c // Eggs -20%
			HHCoNA_sharing_s2 // Fishes
			HHCoNA_sharing_s3 // Groundnuts
			HHCoNA_sharing_s4 // Fresh milk
			HHCoNA_sharing_s5 // Powdered milk
			HHCoNA_sharing_s6 // Selenium soil biofortification of maize
		* Revised nutrient requirements - Shadow prices
			HHCoNA_ShadowPrices_s1a
			HHCoNA_ShadowPrices_s1b
			HHCoNA_ShadowPrices_s1c
			HHCoNA_ShadowPrices_s2
			HHCoNA_ShadowPrices_s3
			HHCoNA_ShadowPrices_s4
			HHCoNA_ShadowPrices_s5
			HHCoNA_ShadowPrices_s6
			
* Ran off cluster while fixing shadowprices 6r
foreach s in a b c {
	use HHCoNA_sharing_s1`s', clear
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
	// Generate an annual mean CoNA per household
		tempvar CoNA365
			gen `CoNA365'=CoNA_sharing_pd_s1`s'*365
		egen CoNA_sharing_annual_s1`s'=mean(`CoNA365'), by(case_id HHID y2_hhid y3_hhid year)
			lab var CoNA_sharing_annual_s1`s' "Annualized average HH CoNA, food sharing s1`s'"
		gen CoNA_sharing_perday_s1`s'=CoNA_sharing_annual_s1`s'/365
			lab var CoNA_sharing_perday_s1`s' "Annualized average HH CoNA, food sharing, perday s1`s'"
	save HHCoNA_s1`s', replace
}	

forval s=2/6 {
	use HHCoNA_sharing_s`s', clear
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
	// Generate an annual mean CoNA per household
		tempvar CoNA365
			gen `CoNA365'=CoNA_sharing_pd_s`s'*365
		egen CoNA_sharing_annual_s`s'=mean(`CoNA365'), by(case_id HHID y2_hhid y3_hhid year)
			lab var CoNA_sharing_annual_s`s' "Annualized average HH CoNA, food sharing s`s'"
		gen CoNA_sharing_perday_s`s'=CoNA_sharing_annual_s`s'/365
			lab var CoNA_sharing_perday_s`s' "Annualized average HH CoNA, food sharing, perday s`s'"
	save HHCoNA_s`s', replace
}	

use HHCoNA_s1a, clear
cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	using HHCoNA_s1b
	cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	using HHCoNA_s1c
	cap drop _*
forval s=2/6 {
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	using HHCoNA_s`s'
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

save HHCoNA_scenarios, replace

* Merge with main CoNA series
use MalawiIHPS_DietQualCost_CoNAseries, clear
cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no date_consump dateMY date_consump_MY ///
	using HHCoNA_scenarios
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
		using MalawiIHPS_DietQualCost_HH, ///
		keepusing(ea_id reside pweight)
	drop if _merge==2 // urban households, no food prices

svyset ea_id [pweight=pweight], strata(reside) singleunit(centered)
svy: mean *diff*
	
drop if year<2013
	
save "$finaldata\MalawiIHPS_DietQualCost_CoNAseries_scenarios", replace

// Shadow prices policy scenarios
foreach s in a b c {
	use HHCoNA_ShadowPrices_s1`s', clear
	drop _*
	ren shadowprice_sharing sp_sharing
	ren semielasticity_sharing se_sharing
	ren elasticity_sharing e_sharing
	foreach v in sp_* se_* e_* {
		ren `v' `v'_s1`s'
		}
		save HHCoNA_ShadowPrices_s1`s', replace
		}
forval s=2/6 {
	use HHCoNA_ShadowPrices_s`s', clear
	drop _*
	ren shadowprice_sharing sp_sharing
	ren semielasticity_sharing se_sharing
	ren elasticity_sharing e_sharing

	foreach v in sp_* se_* e_* {
		ren `v' `v'_s`s'
		}
		save HHCoNA_ShadowPrices_s`s', replace
		}

use HHCoNA_ShadowPrices_s1a, clear
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_s1b
	cap drop _*
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_s1c
	cap drop _*
forval s=2/6 {
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY date_consump_MY hh_round date_seq obs_date_tag ///
	nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_s`s'
	cap drop _*
}
save HHCoNA_ShadowPrices_scenarios, replace

use HHCoNA_ShadowPrices, clear
merge 1:1 case_id HHID y2_hhid y3_hhid data_round year month market_no ///
	date_consump dateMY nutr_no constraint_type rel rhs using HHCoNA_ShadowPrices_scenarios
	drop _*
	drop if year<2013
	
	// Generate comparison relative to main results
	foreach s in a b c {
	gen sp_diff_s1`s'=((sp_sharing_s1`s'-sp_sharing)/sp_sharing)*100
	}
	forval s=2/6 {
	gen sp_diff_s`s'=((sp_sharing_s`s'-sp_sharing)/sp_sharing)*100
	}

* Merge in svy vars and weights
	merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
		using MalawiIHPS_DietQualCost_HH, ///
		keepusing(ea_id reside pweight)
	drop if _merge==2 // urban households, no food prices

drop if nutr_no==1
svyset ea_id [pweight=pweight], strata(reside) singleunit(centered)
svy, subpop(if constraint_type==3): mean *diff*, over(nutr_no)
svy, subpop(if constraint_type==3): mean e_*, over(nutr_no)
	
save "$finaldata\MalawiIHPS_DietQualCost_SPseries_scenarios", replace


// Food item policy scenarios
	foreach s in a b c {
		use HHCoNA_foodlevel_s1`s', clear
		drop if year<2013
		gen scenario="s1`s'"
		save HHCoNA_foodlevel_s1`s's, replace
		}
			
	forval s=2/6 {
		use HHCoNA_foodlevel_s`s', clear
		drop if year<2013
		gen scenario="s`s'"
		save HHCoNA_foodlevel_s`s's, replace
		}
			
	use HHCoNA_foodlevel_s1as, clear
	append using HHCoNA_foodlevel_s1bs
	append using HHCoNA_foodlevel_s1cs
	append using HHCoNA_foodlevel_s2s
	append using HHCoNA_foodlevel_s3s
	append using HHCoNA_foodlevel_s4s
	append using HHCoNA_foodlevel_s5s
	append using HHCoNA_foodlevel_s6s

	save HHCoNA_FoodLevel_scenarios, replace

		* Merge with main results
		use HHCoNA_foodlevel.dta, clear
		drop if year<2013
		cap drop _*
		gen scenario="s0"
		drop energy carbohydrate protein lipids vitA retinol vitC vitE thiamin ///
			riboflavin niacin vitB6 folate vitB12 calcium copper iron magnesium phosphorus selenium zinc sodium total_energy total_carbohydrate total_protein total_lipids total_vitA total_retinol total_vitC total_vitE total_thiamin total_riboflavin total_niacin total_vitB6 total_folate total_vitB12 total_calcium total_copper total_iron total_magnesium total_phosphorus total_selenium total_zinc total_sodium
		tempfile base
			save `base', replace
	use HHCoNA_FoodLevel_scenarios, clear
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
		
	* Generate percent cost by food group
	egen foodgroupcost=total(food_cost), by(case_id HHID y2_hhid y3_hhid food_group dateMY scen_num)
	save HHCoNA_FoodLevel_scenarios, replace
	save "$finaldata\HHCoNA_FoodLevel_scenarios", replace
		graph pie food_cost, over(food_group) by(scen_num) legend(size(tiny))

// HOUSEHOLD COMPOSITION TYPES //
use HH_NRgroups, clear
egen kids3andunder=rowtotal(age_sex_grp_2 age_sex_grp_3 age_sex_grp_4 age_sex_grp_5)
egen kids4to13=rowtotal(age_sex_grp_6 age_sex_grp_7 age_sex_grp_8 age_sex_grp_14)
egen teens=rowtotal(age_sex_grp_9 age_sex_grp_15)
egen workingagemen=rowtotal(age_sex_grp_10 age_sex_grp_11 age_sex_grp_12)
egen workingagewomen=rowtotal(age_sex_grp_16 age_sex_grp_17 age_sex_grp_18 age_sex_grp_24 age_sex_grp_25)
egen elderly=rowtotal(age_sex_grp_13 age_sex_grp_19)
gen breastfeeding=1 if age_sex_grp_23==1 | age_sex_grp_24==1 | age_sex_grp_25==1
	replace breastfeeding=0 if breastfeeding==.
egen familycomposition_withnum=concat(kids3andunder kids4to13 teens workingagemen workingagewomen elderly breastfeeding)
foreach v in kids3andunder kids4to13 teens workingagemen workingagewomen elderly breastfeeding {
	gen `v'_dum=1 if `v'>=1 & `v'!=.
	replace `v'_dum=0 if `v'_dum==.
	}
egen familycomposition=concat(kids3andunder_dum kids4to13_dum teens_dum workingagemen_dum workingagewomen_dum elderly_dum breastfeeding_dum)
unique familycomposition_withnum
unique familycomposition
tab familycomposition, sort
merge 1:1 case_id HHID y2_hhid y3_hhid data_round using MalawiIHPS_DietQualCost_HH, ///
	keepusing(pweight reside ea_id district district_name hhsize market market_no)
	drop _merge
gen kids=1 if kids3andunder_dum==1 | kids4to13_dum==1 | breastfeeding_dum==1 | teens_dum==1
	replace kids=0 if kids==.
tab familycomposition, sort
gen familytype=1 if familycomposition=="0111100"
	replace familytype=2 if familycomposition=="0101100"
	replace familytype=3 if familycomposition=="1101101"
	replace familytype=4 if familycomposition=="1101100"
	replace familytype=5 if familycomposition=="1111101"
	replace familytype=6 if familycomposition=="1111100"
	replace familytype=7 if familycomposition=="1001101"
	replace familytype=8 if familycomposition=="0001100"
	replace familytype=9 if familycomposition=="1001100"
	replace familytype=10 if familycomposition=="0001000"
	replace familytype=11 if familycomposition=="0011100"
	replace familytype=12 if familycomposition=="0110100"
	replace familytype=13 if familycomposition=="0100100"
	replace familytype=14 if familycomposition=="0101101"
	replace familytype=15 if familycomposition=="0000100"
	replace familytype=16 if familycomposition=="1100101"
	replace familytype=17 if familycomposition=="1100100"
	replace familytype=18 if familycomposition=="0001101"
	replace familytype=19 if familycomposition=="0010100"
	replace familytype=20 if familycomposition=="0011000"
	replace familytype=21 if familycomposition=="0000010"
	replace familytype=22 if familycomposition=="0111101"
	replace familytype=23 if familycomposition=="1011100"
	replace familytype=24 if familycomposition=="0100010"
	replace familytype=25 if familycomposition=="1011101"
	replace familytype=26 if familycomposition=="1110100"
	replace familytype=27 if familycomposition=="0110110"
	replace familytype=28 if familycomposition=="0000110"
	replace familytype=29 if familycomposition=="1001001"
	replace familytype=30 if familycomposition=="1110101"
	replace familytype=31 if familycomposition=="0111110"
	replace familytype=32 if familycomposition=="0001110"
	replace familytype=33 if familycomposition=="0100110"
	replace familytype=34 if familycomposition=="0110010"
	replace familytype=35 if familycomposition=="0001001"
	replace familytype=36 if familycomposition=="1000101"
	replace familytype=37 if familycomposition=="0101110"
	replace familytype=38 if familycomposition=="0010010"
	replace familytype=39 if familycomposition=="0010110"
	replace familytype=40 if familycomposition=="0011110"
	replace familytype=41 if familycomposition=="0111000"
	replace familytype=42 if familycomposition=="1111111"
	replace familytype=43 if familycomposition=="1101111"
	replace familytype=44 if familycomposition=="1000100"
	replace familytype=45 if familycomposition=="1011000"
	replace familytype=46 if familycomposition=="0010000"
	replace familytype=47 if familycomposition=="1101110"
	replace familytype=48 if familycomposition=="0101000"
	replace familytype=49 if familycomposition=="1111110 "
	replace familytype=50 if familycomposition=="0001010"	
	replace familytype=99 if familytype==.
	
lab def famtype ///
	1 "Older kid(s) (4-13), teen(s), working age parents" ///
	2 "Older kid(s) (4-13), working age parents" ///
	3 "Young kid(s) (3 and under), older kid(s) (4-13), working age parents, breastfeeding" ///
	4 "Young kid(s) (3 and under), older kid(s) (4-13), working age parents" ///
	5 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), working age parents, breastfeeding" ///
	6 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), working age parents" ///
	7 "Young kid(s) (3 and under), working age parents, breastfeeding" ///
	8 "Working age couple" ///
	9 "Young kid(s) (3 and under), working age parents" ///
	10 "Working age male(s), no family" ///
	11 "Teen(s), working age parents" ///
	12 "Older kid(s) (4-13), teen(s), working age female(s)" ///
	13 "Older kid(s) (4-13), working age female(s)" ///
	14 "Infant, older kid(s) (4-13), working age parents, breastfeeding" ///
	15 "Working age female(s)" ///
	16 "Young kid(s) (3 and under), older kid(s) (4-13), working age female(s), breastfeeding" ///
	17 "Young kid(s) (3 and under), older kid(s) (4-13), working age female(s)" ///
	18 "Infant, working age parents, breastfeeding" ///
	19 "Teen(s), female adult" ///
	20 "Teen(s), male adult" ///
	21 "Older adult(s)" ///
	22 "Older kid(s) (4-13), teen(s), working age parents, breastfeeding" ///
	23 "Young kid(s) (3 and under), teen(s), working age parents" ///
	24 "Older kid(s) (4-13), older adult(s)" ///
	25 "Young kid(s) (3 and under), teen(s), working age parents, breastfeeding" ///
	26 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), working age female(s)" ///
	27 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), older adult(s)" ///
	28 "Working age female(s), older adult(s)" ///
	29 "Young kid(s) (3 and under), teen(s), breastfeeding" ///
	30 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), working age female(s), breastfeeding" ///
	31 "Older kid(s) (4-13), teen(s), working age parents, older adult(s)" ///
	32 "Working age couple, older adult(s)" ///
	33 "Older kid(s) (4-13), working age female(s), older adult(s)" ///
	34 "Older kid(s) (4-13), teen(s), older adult(s)" ///
	35 "Teen(s), breastfeeding" ///
	36 "Young kid(s) (3 and under), working age female(s), breastfeeding" ///
	37 "Teen(s), working age parents, older adult(s)" ///
	38 "Teen(s), older adult(s)" ///
	39 "Teen(s), working age female(s), older adult(s)" ///
	40 "Teen(s), working age parents, older adult(s)" ///
	41 "Older kid(s) (4-13), teen(s), working age male(s)" ///
	42 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), working age parents, older adult(s), breastfeeding" ///
	43 "Young kid(s) (3 and under), older kid(s) (4-13), working age parents, older adult(s), breastfeeding" ///
	44 "Young kid(s) (3 and under), working age female(s)" ///
	45 "Young kid(s) (3 and under), teen(s), working age male(s)" ///
	46 "Teen(s)" ///
	47 "Young kid(s) (3 and under), older kid(s) (4-13), working age parents, older adult(s)" ///
	48 "Older kid(s) (4-13), working age male(s)" ///
	49 "Young kid(s) (3 and under), older kid(s) (4-13), teen(s), working age parents, older adult(s)" ///
	50 "Working age male(s), older adult(s)" ///
	99 "Other"
lab val familytype famtype
lab var familytype "Family composition"

egen aggfamilytype=concat(kids workingagemen_dum workingagewomen_dum elderly_dum)
tab aggfamilytype, sort
gen aggfamilytype2=1 if aggfamilytype=="1110"
	replace aggfamilytype2=2 if aggfamilytype=="1010"
	replace aggfamilytype2=3 if aggfamilytype=="0110"
	replace aggfamilytype2=4 if aggfamilytype=="1100"	
	replace aggfamilytype2=5 if aggfamilytype=="0100"
	replace aggfamilytype2=6 if aggfamilytype=="1111"
	replace aggfamilytype2=7 if aggfamilytype=="1011"
	replace aggfamilytype2=8 if aggfamilytype=="1001"
	replace aggfamilytype2=9 if aggfamilytype2==.
cap lab drop familytype2
lab def familytype2 1 "Kid/teen, Adult couple" ///
	2 "Kid/teen, Adult female" ///
	3 "Couple" ///
	4 "Kid/teen, Adult male" ///
	5 "Adult male" ///
	6 "Kid/teen, adult couple, older adult" ///
	7 "Kid/teen, adult female, older adult" ///
	8 "Kid/teen, older adult" ///
	9 "Other"
lab val aggfamilytype2 familytype2
lab var aggfamilytype2 "Family composition"

* Generate total number of different age-sex groups
foreach v of varlist age_sex_grp* {
	gen `v'dum=1 if `v'>=1
	replace `v'dum=0 if `v'==. | `v'==0
	}
egen individualtypes=rowtotal(age_sex*dum)
tab individualtypes
	
save HHComposition, replace
save "$finaldata\HHComposition", replace
		
***** Save files of Household Survey data Only *****
use MalawiIHPS_DietQualCost_PID, clear
	drop *CoNA* market* personcheck countsolution countforhhicona ///
		dropurban date_seq obs_date_tag
	save "$finaldata\MalawiIHPS_DietQual_PID", replace
use MalawiIHPS_DietQualCost_FoodHHExp, clear
	drop dropurban market*
	save "$finaldata\MalawiIHPS_DietQual_FoodHHExp", replace
use MalawiIHPS_DietQualCost_HH, clear
	drop *CoNA* market* dropurban
	save "$finaldata\MalawiIHPS_DietQual_HH", replace
use MalawiIHPS_DietQualCost_Nut_PID, clear
	drop *CoNA* market* dropurban date_seq obs_date_tag
	save "$finaldata\MalawiIHPS_DietQual_Nut_PID", replace
use MalawiIHPS_DietQualCost_FoodNUT_HHExp, clear
	drop market* dropurban
	save "$finaldata\MalawiIHPS_DietQual_FoodNUT_HHExp", replace
		
cap log close

