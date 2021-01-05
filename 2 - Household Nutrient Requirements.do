/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: 
	1. Define nutrient requirements
	2. Merge nutrient requirements with Malawi IHPS household data
*/

// PART 0 // FILE MANAGEMENT
global ihpsraw "MWI_IHPS_2010-2013-2016"
global otherrawdata "datafolder"
global analysis "workingfolder"
global NRs "\Supp1_NutrientRequirements_DRIs_2019.xlsx"
global whogrowth "\Supp2_WHO-growth-reference-tables_2006.xlsx"
global bf "\Supp3_NutrientRequirements_6-23months.xlsx"

* Working directory
cd "$analysis"
cap log close
log using "HH Nut Reqts_`c(current_date)'", replace
***Log of Do File #2 "02_Household Nutrient Requirements"
di "`c(current_date)' `c(current_time)'"

// PART 1 // IMPORT DRIs FROM EXCEL SPREADSHEET

* Micronutrients EAR 
clear 
import excel "$otherrawdata$NRs", sheet("Micronutrients_EAR") firstrow
	// Rename variables (nutr_no follows the "Units_Notes" sheet)
	gen ear1=.
	gen ear2=.
	gen ear3=.
	gen ear4=.
	gen ear5=.
	rename vitA ear6
	gen ear7=.
	rename vitC ear8
	rename vitE ear9
	rename thiamin ear10
	rename riboflavin ear11
	rename niacin ear12
	rename vitB6 ear13
	rename folate ear14
	rename vitB12 ear15
	rename calcium ear16
	rename copper ear17
	rename iron ear18
	rename magnesium ear19
	rename phosphorus ear20
	rename selenium ear21
	rename zinc ear22
	rename sodium ear23
	// Make sure all variables are numeric
	describe
	foreach v of varlist ear* {
		destring `v', replace
		}
	// Reshape long
	reshape long ear, i(lifestage sex age_lower_yrs age_upper_yrs) j(nutr_no)
	replace ear=. if nutr_no==3 // carbohydrates are repeated in macronutrients
	tempfile Micronutrients_EAR
		save `Micronutrients_EAR', replace

* Micronutrients UL 
clear
import excel "$otherrawdata$NRs", sheet("Micronutrients_UL") firstrow
	// Rename variables (nutr_no follows the "Units_Notes" sheet)
	forval i=1/5 {
		gen ul`i'=.
		}
	rename vitA ul6
	rename retinol ul7
	rename vitC ul8
	rename vitE ul9
	rename thiamin ul10
	rename riboflavin ul11
	rename niacin ul12
	rename vitB6 ul13
	rename folate ul14
	rename vitB12 ul15
	rename calcium ul16
	rename copper ul17
	rename iron ul18
	rename magnesium ul19
	rename phosphorus ul20
	rename selenium ul21
	rename zinc ul22
	rename sodium ul23
	// Make sure all variables are numeric
	describe
	forval i=6/23 {
		destring ul`i', replace
		}
	// Reshape to long form
	reshape long ul, i(age_sex_grp) j(nutr_no)
keep age_sex_grp nutr_no ul
tempfile Micronutrients_UL
	save `Micronutrients_UL', replace

* Macronutrients EAR 
clear 
import excel "$otherrawdata$NRs", sheet("Macronutrients_EAR") firstrow
drop lifestage sex age_lower_yrs age_upper_yrs
rename refweight_kg refweight_protein_kg
tempfile Macronutrients_EAR
	save `Macronutrients_EAR', replace

* Macronutrients AMDR
clear
import excel "$otherrawdata$NRs", sheet("Macronutrients_AMDR") firstrow
cap drop if age_sex_grp==.
	// Rename variables to reshape long
	rename lipids_lower amdr_lower5
	rename lipids_upper amdr_upper5
	rename carbohydrate_lower amdr_lower3
	rename carbohydrate_upper amdr_upper3
	rename protein_lower amdr_lower4
	rename protein_upper amdr_upper4
	reshape long amdr_lower amdr_upper, i(age_sex_grp lifestage sex age_lower_yrs age_upper_yrs) ///
		j(nutr_no)
keep age_sex_grp nutr_no amdr_lower amdr_upper
tempfile Macronutrients_AMDR
	save `Macronutrients_AMDR', replace

* Units Notes - imported long by nutrient, merge with UL keeping relevant variables only
clear
import excel "$otherrawdata$NRs", sheet("Units_Notes") firstrow
keep nutr_no ul_note unit amdr_unit
merge m:m nutr_no using `Micronutrients_UL'
drop _merge
order age_sex_grp nutr_no unit ul, first
tempfile Micronutrients_UL
	save `Micronutrients_UL', replace
	
* Energy - Import only relevant PAL levels for this analysis using WHO growth reference charts
	// By montly age from 0-60 months
	clear
	import excel "$otherrawdata\WHO based energy calculations by month and year", sheet("Median Wt Ht En Month 0-19") firstrow
	keep total_months energy* median_weight*
	ren total_months ageinmonths
	keep if ageinmonths<=60
	ren *_boys *0
	ren *_girls *1
	reshape long median_weight energy, i(ageinmonths) j(sex)
	tempfile energy0to5
		save `energy0to5', replace
	
	// By age in years aged 6 and up
	clear 
	import excel "$otherrawdata\WHO based energy calculations by month and year", sheet("Med Wt Ht En Year 5-19") firstrow
	keep year median_weight_m median_weight_f energy_m energy_f energy_lac0to6_f energy_lac7to12_f
	ren year age
	ren *_m *0
	ren *_f *1
	reshape long median_weight energy, i(age) j(sex)
	foreach v of varlist energy_lac* {
		replace `v'=. if sex==0
		}
	tempfile energy6up
		save `energy6up', replace
	
	// Active PAL for men 14-59 who are not engaged in manual labor
	clear 
	import excel "$otherrawdata\WHO based energy calculations by month and year", sheet("Med Wt Ht En Year M14-59 Active") firstrow
	keep year energy_m 
	ren year age
	ren energy_m energyactive
	gen sex=0
	drop if age==.
	tempfile energymactive
		save `energymactive', replace

// PART 2 // MERGE ALL
clear
* Merge datasets except energy
	use `Micronutrients_EAR'
	// Micronutrients ULs
	merge 1:1 age_sex_grp nutr_no using `Micronutrients_UL'
	distinct age_sex_grp nutr_no
	drop _merge
	// Macronutrients EAR
		* Note - need to replace the EAR variable from the master data with the protein and carb value from the using
	merge m:1 age_sex_grp using `Macronutrients_EAR'
	drop _merge 
		foreach v in protein protein_perkg carbohydrate {
			destring `v', replace
			}
		replace ear=protein if nutr_no==4
		replace ear=carbohydrate if nutr_no==3
		drop protein carbohydrate
	// Macronutrients AMDR
		* Note the macronutrients unit is % total calories
	merge m:1 age_sex_grp nutr_no using `Macronutrients_AMDR'
		di 25*3 // Check - should be matched
	drop _merge
	sort age_sex_grp nutr_no 

	* Make sure all variables are numeric
* describe
encode lifestage, gen(lifestage2)
	drop lifestage
	ren lifestage2 lifestage
tab sex
encode sex, gen(sex2)
	tab sex2, nolabel
	drop sex
	ren sex2 sex
	tab sex
	recode sex (2=0)
	replace sex=. if sex==3
	tab sex
	lab def sex 0 "Male" 1 "Female"
	lab val sex sex
foreach v in age* amdr* {
	destring `v', replace
	}
* Order and Sort
order age_sex_grp nutr_no ear ul amdr_lower amdr_upper, first
sort age_sex_grp nutr_no
	
* Label nutrients
gen nutr="."
replace nutr="Price" if nutr_no==1
replace nutr="Energy" if nutr_no==2
replace nutr="Carbohydrate" if nutr_no==3
replace nutr="Protein" if nutr_no==4
replace nutr="Lipids" if nutr_no==5
replace nutr="Vit_A" if nutr_no==6
replace nutr="Retinol" if nutr_no==7
replace nutr="Vit_C" if nutr_no==8
replace nutr="Vit_E" if nutr_no==9
replace nutr="Thiamin" if nutr_no==10
replace nutr="Riboflavin" if nutr_no==11
replace nutr="Niacin" if nutr_no==12
replace nutr="Vit_B6" if nutr_no==13
replace nutr="Folate" if nutr_no==14
replace nutr="Vit_B12" if nutr_no==15
replace nutr="Calcium" if nutr_no==16
replace nutr="Copper" if nutr_no==17
replace nutr="Iron" if nutr_no==18
replace nutr="Magnesium" if nutr_no==19
replace nutr="Phosphorus" if nutr_no==20
replace nutr="Selenium" if nutr_no==21
replace nutr="Zinc" if nutr_no==22
replace nutr="Sodium" if nutr_no==23
order nutr, after(nutr_no)
replace ear=0 if nutr=="Price"

order age_sex_grp nutr_no nutr ear ul amdr_lower amdr_upper unit, first
save DRIs, replace

* Merge with household data
use HH+Indiv, clear
cap drop __*
sum case_id HHID y2_hhid y3_hhid data_round date_consump
describe

* Sort
sort case_id HHID y2_hhid y3_hhid data_round
cap drop _*
unique case_id HHID y2_hhid y3_hhid data_round
sum hhxround
sort hhxround
tab age_sex_grp pal
cap drop _*
joinby age_sex_grp using DRIs
sort hhxround PID nutr_no

misstable sum age_sex_grp nutr_no nutr ear ul amdr_lower amdr_upper unit ///
	age_lower_yrs age_upper_yrs ul_note amdr_unit protein_perkg ///
	refweight_protein_kg lifestage sex

bys age_sex_grp: tab nutr_no if ear==.
bys age_sex_grp: tab nutr_no if ul==.
bys age_sex_grp: tab nutr_no if amdr_lower==. & inlist(nutr_no,3,4,5)
bys age_sex_grp: tab nutr_no if amdr_upper==. & inlist(nutr_no,3,4,5)

* Merge in energy
tab ageinmonths
tab age_rptd
tab age_rptd if age_rptd>=5 & age_rptd<=6 & ageinmonths==.
tab ageinmonths if age_rptd==5
merge m:1 ageinmonths sex using `energy0to5'
tab ageinmonths, sum(energy) // should have 85,560 observations
	misstable sum ageinmonths energy if inlist(age_sex_grp,2,3,4,5,6,7) & ageinmonths!=.
tab energy if ageinmonths==.
tab energy if ageinmonths!=., m
drop _merge
replace ear=energy if nutr_no==2 & ageinmonths!=.
	misstable sum ageinmonths energy if inlist(age_sex_grp,2,3,4,5,6,7) & ageinmonths!=.
	tab ear if nutr_no==2 & ageinmonths!=., m // should have 3,720 observations
	tab ageinmonths if ear==. & nutr_no==2 & ageinmonths!=.
ren energy energy0to5
ren median_weight median_weight0to5
tab energy0to5
gen age=age_rptd
	replace age=5 if age_rptd>5 & age_rptd<6
	replace age=. if ageinmonths<=60
tab age, m // missing should be 111,343
merge m:1 age sex using `energy6up'
	// not merged = age-genders not observed (all 93 years and up)
	tab age if _merge==2
	drop if _merge==2
	drop _merge
misstable sum protein_perkg median_weight
replace median_weight=median_weight0to5 if median_weight==. & ageinmonths!=.
tab age_sex_grp if protein_perkg==. // Missing are only infants 
	
tab2 nutr_no lactating if age!=. // checks for merging and energy replacement
browse if ear==. & nutr_no==2 & lactating!=1 & age!=.
replace ear=energy if ear==. & nutr_no==2 & lactating!=1 & age!=. // should make 23,312 replacements
tab bfchild_ageinmonths if lactating==1
replace ear=energy_lac0to61 if ear==. & nutr_no==2 & lactating==1 & bfchild_ageinmonths<=6
replace ear=energy_lac7to121 if ear==. & nutr_no==2 & lactating==1 & bfchild_ageinmonths>6
misstable sum ear if nutr_no==2
		tab age_rptd if ear==. & nutr_no==2
	// Missing is a breastfeeding mother only 12 years old herself
	tab bfchild_ageinmonths if ear==. & nutr_no==2
	replace ear=(energy+500-170) if ear==. & nutr_no==2 & lactating==1 // Manually increase energy requirement for 0-6 months postpartum lactation per DRIs
drop energy0to5 energy energy_lac0to61 energy_lac7to121 median_weight0to5

sort hhxround PID nutr_no
tab nutr_no // Should have 29,978 records per nutrient
tab age_sex_grp
tab nutr_no
tab2 age_sex_grp nutr_no
	// Replace nutrient needs for infants as missing
		* To preserve infants for household size but exclude from requirements becuase they do not eat food
		foreach v in ear ul amdr_lower amdr_upper {
			destring `v', replace
			replace `v'=. if age_sex_grp==1
			}

* Replace energy needs to active PAL for men 14-59 not engaged in manual labor	
merge m:1 age sex using `energymactive'
	replace ear=energyactive if nutr_no==2 & sex==0 & (age>=14 & age<=59) & pal==3			
	drop age energyactive _merge		
tab2 pal reside
tab2 pal sex
			
* Recalculate protein EAR for WHO reference weights
misstable sum ear protein_perkg median_weight if nutr_no==4 & age_sex_grp!=1
replace ear=protein_perkg*median_weight if nutr_no==4 & age_sex_grp!=1 // should be 29,408 replacements
tab age_sex_grp if nutr_no==4 & ear==.
sum HHID case_id y2_hhid y3_hhid bfchild_ageinmonths lactating PID sex ///
	district district_name market market_no year month date_consump region ///
	age_rptd ageinmonths age_sex_grp pal daysate_conv hhsize haz waz whz /// 
	stunted underweight wasted_overweight hhxround nutr_no nutr ear ul  ///
	amdr_lower amdr_upper unit age_lower_yrs age_upper_yrs ul_note amdr_unit ///
	protein_perkg refweight_protein_kg lifestage median_weight

* Reduce needs of children 6-23 months to only what is required from food
	// Note WHO recommends continued breastfeeding through 2 years
		* Mothers of children <2 are assumed to be breastfeeding
gen bf_match_id=.
	replace bf_match_id=1 if ageinmonths>=6 & ageinmonths<9
	replace bf_match_id=2 if ageinmonths>=9 & ageinmonths<12
	replace bf_match_id=3 if ageinmonths>=12 & ageinmonths<=23
	tab bf_match_id, sum(ageinmonths)
	
preserve
clear
	import excel using "$otherrawdata$bf", sheet("6-23mo_FoodNeeds") firstrow
	keep nutr_no pctfromfood bf_match_id
	destring, replace
	tempfile pctfromfood
		save `pctfromfood', replace
restore
	merge m:1 nutr_no bf_match_id using `pctfromfood'
	drop _merge
	replace pctfromfood=. if !inlist(age_sex_grp,2,3)
	replace ear=ear*(pctfromfood/100) if pctfromfood!=. & ear!=. & inlist(bf_match_id,1,2,3)
	drop bf_match_id
		
	// Generate variable with energy requirement for each individual
	gen kcal2=ear
	replace kcal2=. if nutr_no!=2
	bys PID data_round: egen kcal_perday=total(kcal2)
	* browse age_sex_grp nutr_no kcal kcal2
		drop kcal2
	lab var kcal_perday "Daily Individual Energy Needs"

* Generate kcal per week
gen kcal_perweek=kcal_perday*7
	tabstat kcal_perday kcal_perweek, by(age_sex_grp)
	
// Generate AMDRs per week
	* Replace AMDRs as grams of each macronutrient
		// Convert to percent
		foreach v in amdr_lower amdr_upper {
			replace `v'=`v'/100
			ren `v' `v'_pctkcal
			}
	gen amdr_lower_perweek=.
		lab var amdr_lower_perweek "Individual AMDR Lower Bound per week, grams"
	gen amdr_upper_perweek=.
		lab var amdr_upper_perweek "Individual AMDR Upper Bound perweek, grams"
	replace amdr_lower_perweek=(kcal_perweek*amdr_lower_pctkcal)/4 if inlist(nutr_no,3,4)
	replace amdr_lower_perweek=(kcal_perweek*amdr_lower_pctkcal)/9 if nutr_no==5
	replace amdr_upper_perweek=(kcal_perweek*amdr_upper_pctkcal)/4 if inlist(nutr_no,3,4)
	replace amdr_upper_perweek=(kcal_perweek*amdr_upper_pctkcal)/9 if nutr_no==5
	replace amdr_lower_perweek=. if !inlist(nutr_no,3,4,5)
	replace amdr_upper_perweek=. if !inlist(nutr_no,3,4,5)
	bys age_sex_grp: tabstat ear kcal_perweek amdr_l* amdr_up* if inlist(nutr_no,3,4,5), by(nutr) stats(mean n)
		// Note age-sex group 2 has protein ear but no amdr, so there are fewer records for amdrs than ear and calories
	// Result: total grams 
	replace amdr_unit="g" if inlist(nutr_no,3,4,5)
	
* Calculate each nutrient EAR & UL in terms of quantity per calorie
	// Calculate EAR per kcal for nutrients with an ear
	cap drop ear_perkcal
	gen ear_perkcal=.
	replace ear_perkcal=ear/kcal_perday if !inlist(nutr_no,2,5,7) & age_sex_grp!=1
	replace ear_perkcal=1 if nutr_no==2 & age_sex_grp!=1 // Stata rounding caused this to be .9999
	lab var ear_perkcal "EAR per kcal per day"
	tab nutr_no, sum(ear_perkcal) 
	
	// Calculate UL per kcal 
	gen ul_perkcal=ul/kcal_perday if ul!=.
	replace ul_perkcal=. if ul_note=="supplement" // these will be dropped in calculating the CoNA
	replace ul=. if ul_note=="supplement"
describe
sum

* Generate EARs and ULs per week
foreach v in ear ul {
	gen `v'_perweek=`v'*7
	}
	* Check
	tabstat ear_perweek kcal_perweek if nutr_no==2 & age_sex_grp!=1, stats(mean n) m

* Check sample size
cap drop if case_id==.
unique case_id HHID y2_hhid y3_hhid PID
distinct case_id HHID y2_hhid y3_hhid PID

* Label variables
lab var ear "Individual EAR per day"
lab var ul "Individual UL per day"
lab var ear_perweek "Individual EAR per week"
lab var ul_perweek "Individual UL per week"

* Make sure all needs for infants 0-6 months are 0 (all nutrients provided by breastfeeding per WHO recommendation)
foreach v in ear ul amdr_lower_pctkcal amdr_upper_pctkcal pctfromfood kcal_perday ///
	kcal_perweek amdr_lower_perweek amdr_upper_perweek ear_perkcal ul_perkcal ear_perweek ul_perweek {
	replace `v'=0 if age_sex_grp==1 & `v'>0 & `v'!=.
	}

cap drop _*

// PART 4 // GENERATE HOUSEHOLD NUTRIENT REQUIREMENTS - SHARING & TARGETING SCENARIOS
* Note the ULs/CDDR and AMDRs are used for the calculation of least cost diets only
* EARs are used for the adequacy ratios and least cost diets
	* Sodium is excluded from adequacy ratios

* Generate maximum nutrient needs per kcal
replace ear_perkcal=0 if ear_perkcal==.
preserve
	cap drop max_ear_perkcal
	cap drop if case_id==.
	// Exclude needs of children <2 to set household sharing requirements
	replace ear_perkcal=. if (ageinmonths>=6 & ageinmonths<=23)
	tab age_sex_grp, sum(ear_perkcal)
	cap drop _*
	bys case_id HHID y2_hhid y3_hhid data_round nutr_no: egen max_ear_perkcal=max(ear_perkcal)
	sort case_id HHID y2_hhid y3_hhid data_round nutr_no PID
	*browse case_id HHID y2_hhid y3_hhid data_round PID age_sex_grp nutr_no ear amdr* kcal_perday ear_perkcal max_ear_perkcal
	replace max_ear_perkcal=0 if ear_perkcal==0 | ear_perkcal==. // Infants not requiring nutrient from food
	browse if ear_perkcal>max_ear_perkcal & (ageinmonths>23 | ageinmonths==.) // Check confirmed no records
	bys nutr: tabstat ear_perkcal max_ear_perkcal ear_perweek ul_perweek, by(age_sex_grp)
	tempfile maxear
		save `maxear', replace
restore
cap drop if case_id==.
merge 1:1 case_id HHID y2_hhid y3_hhid data_round PID nutr_no using `maxear', keepusing(max_ear_perkcal)
	drop _merge
	
* Generate new EAR equal to the maximum EAR per kcal in the household times the individual energy needs
tab nutr_no if !inlist(age_sex_grp,1,2), sum(max_ear_perkcal)
tab nutr_no if !inlist(age_sex_grp,1,2,3), sum(ear_perkcal)

gen EAR_sharing=.
	replace EAR_sharing=kcal_perweek if nutr_no==2 // Keep individual energy needs (weekly)
	replace EAR_sharing=max_ear_perkcal*kcal_perweek if !inlist(nutr_no,1,2,5,7,23)
		// Excludes nutrients with no EAR & price
	/* Keep individual requirement for children 6-23 months because the are
		breastfeeding and usually do eat a different diet */
	replace EAR_sharing=ear_perweek if (ageinmonths>=6 & ageinmonths<=23) & ear_perweek!=.
	//Check 
	foreach v in EAR_sharing ear_perweek max_ear_perkcal {
		replace `v'=. if `v'==0
		}
	bys nutr: tabstat EAR_sharing ear_perweek, by(age_sex_grp)

	lab var nutr_no "Nutrient"
	lab var EAR_sharing "EAR per week - Sharing Scenario"
	order case_id HHID y2_hhid y3_hhid data_round nutr_no age_sex_grp PID, first
	sort case_id HHID y2_hhid y3_hhid data_round nutr_no data_round age_sex_grp

		// Document which group has maximum needs
		tab2 age_sex_grp nutr_no if ear_perkcal==max_ear_perkcal & ///
			!inlist(nutr_no,1,2,3,4,5,7,23)
			// WRAs 19-59 most often define the household needs, as do breastfeeding women 19-30
		// Document range of needs
		tabstat ear_perkcal if !inlist(nutr_no,1,2,3,4,5,7,23), stats(mean sd range min max) by(nutr) save
				// Widest spread: calcium, phosphorus, magnesium, to a lesser extent magnesium and folate

* Generate new UL - Goal is to take the lowest UL/kcal of any age-gender group in the hh
	bys nutr: tabstat ul_perkcal ul_perweek if ul!=., by(age_sex_grp)
	* Problem - some ULs < EAR - generate min, mean and max for flexibility
	preserve
		replace ul_perkcal=. if (ageinmonths>=6 & ageinmonths<=23)
		cap drop min_ul_perkcal mean_ul_perkcal max_ul_perkcal
		bys case_id HHID y2_hhid y3_hhid data_round nutr_no: egen min_ul_perkcal=min(ul_perkcal)
		bys case_id HHID y2_hhid y3_hhid data_round nutr_no: egen mean_ul_perkcal=mean(ul_perkcal)
		bys case_id HHID y2_hhid y3_hhid data_round nutr_no: egen max_ul_perkcal=max(ul_perkcal)
	tempfile uls
		save `uls', replace
	restore
	merge 1:1 case_id HHID y2_hhid y3_hhid data_round PID nutr_no using `uls', keepusing(min_ul_perkcal mean_ul_perkcal max_ul_perkcal)
	drop _merge
		
		// Determine minimum upper limit
		replace min_ul_perkcal=. if ul==. 
		bys nutr: tab age_sex_grp if ul_perkcal==min_ul_perkcal & min_ul_perkcal!=.
		tabstat min_ul_perkcal max_ear_perkcal if !inlist(nutr_no,1,2,5), stats(mean sd range n) by(nutr)
		
		// Determine nutrients with a conflict where UL < EAR
		tab nutr_no if min_ul_perkcal<=max_ear_perkcal & age_sex_grp!=1 & min_ul_perkcal!=. & max_ear_perkcal!=.
		tab nutr_no if ear_perkcal>min_ul_perkcal & age_sex_grp!=1
		tab2 ageinmonths nutr_no if ear_perkcal>min_ul_perkcal, m // only conflicts are <23 months so they keep own requirements
		tab2 age_sex_grp nutr_no if ear_perkcal>min_ul_perkcal & ear_perkcal!=. & min_ul_perkcal!=. & ageinmonths>23
			* No conflicts
				
	// Generate new UL for the household sharing level
		tab nutr, sum(ul_perkcal)
		tab nutr, sum(min_ul_perkcal)	
		cap drop UL_sharing
		gen UL_sharing=.
		replace UL_sharing=min_ul_perkcal*kcal_perweek
		tab nutr if UL_sharing!=.
		replace UL_sharing=ul_perweek if ageinmonths<=23 & age_sex_grp!=1
		replace UL_sharing=. if ul_note=="supplement"

	// Document Household UL densities
		tab nutr_no if min_ul_perkcal!=. & ul_note!="supplement"
		tabstat min_ul_perkcal if inlist(nutr_no,7,8,13,16,17,18,20,21,22,23), stats(mean sd range min max) by(nutr) 

		tab nutr_no if UL_sharing<EAR_sharing & EAR_sharing!=. & UL_sharing!=. // Check no conflicts
		
* Adjust for partial mealtaking
tab daysate_conv, m
tab age_sex_grp if daysate_conv==. // All infants
foreach v in kcal_perweek ear_perweek EAR_sharing ul_perweek UL_sharing ///
	amdr_lower_perweek amdr_upper_perweek {
	replace `v'=`v'*daysate_conv if daysate_conv!=1 & daysate_conv!=. // weights by total days eaten if not =7
	}
* Drop individuals who ate no meals in household in previous week
gen nomeals=1 if daysate_conv==0
replace nomeals=0 if daysate_conv!=0 & daysate_conv!=.
	
* Drop households with 0 calories eaten in previous week due to partial mealtakers
tempvar kcal_perweek_zero
egen `kcal_perweek_zero'=total(kcal_perweek), by(case_id HHID y2_hhid y3_hhid data_round)
sum if `kcal_perweek_zero'==0
unique case_id HHID y2_hhid y3_hhid if `kcal_perweek_zero'==0 // 15 households
tab hhsize daysate_conv if `kcal_perweek_zero'==0
drop if `kcal_perweek_zero'==0
		
save HHNeeds_IndivLevel, replace

* Generate Max and Min AMDR PCT kcals at household level before collapse
cap drop _*
preserve
replace amdr_lower_pctkcal=. if (ageinmonths>=6 & ageinmonths<=23) & inlist(age_sex_grp,1,2,3)
replace amdr_upper_pctkcal=. if (ageinmonths>=6 & ageinmonths<=23) & inlist(age_sex_grp,1,2,3)
bys case_id HHID y2_hhid y3_hhid data_round nutr_no: egen max_amdrlow_perkcal=max(amdr_lower_pctkcal)
bys case_id HHID y2_hhid y3_hhid data_round nutr_no: egen min_amdrup_perkcal=min(amdr_upper_pctkcal)
	tempfile amdrs
		save `amdrs', replace
restore
	merge 1:1 case_id HHID y2_hhid y3_hhid data_round PID nutr_no using `amdrs', ///
		keepusing(max_amdrlow_perkcal min_amdrup_perkcal)
	tab nutr_no if inlist(nutr_no,3,4,5), sum(max_amdrlow_perkcal)
	tab nutr_no if inlist(nutr_no,3,4,5), sum(min_amdrup_perkcal)
	tab nutr_no if max_amdrlow_perkcal==min_amdrup_perkcal & inlist(nutr_no,3,4,5) // Check confirms no conflicts
		
* Keep young children's own macronutrient needs
gen amdrlow_toddler_perweek=amdr_lower_perweek if (ageinmonths>=6 & ageinmonths<=23 & ageinmonths!=.)
gen amdrup_toddler_perweek=amdr_lower_perweek if (ageinmonths>=6 & ageinmonths<=23 & ageinmonths!=.)
	// Keep toddler energy needs to recalculate the rest of household's AMDRs below
	gen energytoddler=ear if (nutr_no==2 & (ageinmonths>=6 & ageinmonths<=23 & ageinmonths!=.))

* Inspect
tab nutr_no if EAR_sharing>=UL_sharing & EAR_sharing!=. & UL_sharing!=.
	tab2 age_sex_grp nutr_no if EAR_sharing>=UL_sharing & EAR_sharing!=. & UL_sharing!=. & EAR_sharing!=0 & UL_sharing!=0
	* No conflicts
	
* Drop individuals who ate no meals
unique PID data_round if nomeals==1 // 938 people
drop if nomeals==1
	
* Collapse to household level (sum EARs meeting needs of the neediest)
	tab nutr_no, sum(ear)
	tab nutr_no, sum(ul)
	tab nutr_no, sum(EAR_sharing)
	tab nutr_no, sum(UL_sharing)
	tab nutr_no, sum(amdr_lower_pctkcal)
	tab nutr_no, sum(amdr_upper_pctkcal)
	misstable sum case_id HHID y2_hhid y3_hhid EAR_sharing PID hhsize
	tab nutr_no if EAR_sharing==. 
		// Missing for price, lipids, retinol and sodium for all
		// Missing energy, protein,  only for infants 0-6 months // N=534
	// Collapse to household level
	* Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
			local l`v' "`v'"
			}
		}
	* Collapse
	collapse (sum) ear_perweek ul_perweek amdr_lower_perweek amdr_upper_perweek amdrlow_toddler_perweek ///
	amdrup_toddler_perweek energytoddler EAR_sharing UL_sharing kcal_perday kcal_perweek daysate_conv ///
	(first) max_amdrlow_perkcal min_amdrup_perkcal hhsize date_consump market market_no year month dropurban, ///
		by(case_id HHID y2_hhid y3_hhid data_round hhxround nutr_no)
	*Relabel
	foreach v of var * {
		label var `v' "`l`v''"
			}
	// Check
	tabstat ear_perweek EAR_sharing ul_perweek UL_sharing amdr_lower_perweek ///
		amdr_upper_perweek, by(nutr)
	tabstat EAR_sharing ear_perweek kcal_perweek if nutr_no==2 // Total energy should be the same
	tab hhsize
	sum EAR_sharing if nutr_no==2, d
	tab nutr if UL_sharing!=., sum(UL_sharing)
	replace UL_sharing=. if UL_sharing==0
	tab nutr if UL_sharing!=., sum(UL_sharing)
	
* Rename variables
ren daysate_conv daysate_hh_conv
lab var daysate_hh_conv "Total Household Days Eaten at home out of past 7 (Max val = 7*hhsize)"
ren kcal_perday KCAL_hh_perday
lab var KCAL_hh_perday "Total household calories per day"
rename ear_perweek EAR_targeting
rename ul_perweek UL_targeting
rename amdr_lower_perweek AMDRlow_targeting
rename amdr_upper_perweek AMDRup_targeting
rename kcal_perweek KCAL_hh_perweek
lab var EAR_targeting "Total household EAR per week - Targeting Scenario"
lab var EAR_sharing "Total household EAR per week - Sharing Scenario"
lab var UL_sharing "Total household UL per week - Sharing Scenario"
lab var UL_targeting "Total household UL per week - Targeting Scenario"
lab var KCAL_hh_perweek "Total household calories per week"
lab var AMDRlow_targeting "Household AMDR Lower per week - Targeting Scenario"
lab var AMDRup_targeting "Household AMDR Upper per week - Targeting Scenario"
	
* Inspect total household calories	
	sum KCAL_hh_perweek EAR_targeting EAR_sharing if nutr_no==2, d
	tab hhsize, sum(KCAL_hh_perweek)
		
	* Generate new AMDRs for household
		// For protein and lipids: highest low bound, lowest upper bound
	gen AMDRlow_sharing=.
		replace AMDRlow_sharing=((KCAL_hh_perweek-energytoddler)*max_amdrlow_perkcal)/4 if nutr_no==3
			// Same for all age-gender groups
		replace AMDRlow_sharing=((KCAL_hh_perweek-energytoddler)*max_amdrlow_perkcal)/4 if nutr_no==4 
		replace AMDRlow_sharing=((KCAL_hh_perweek-energytoddler)*max_amdrlow_perkcal)/9 if nutr_no==5 
			// Highest low bound of all age-gender groups
		* Add in toddlers
		replace AMDRlow_sharing=AMDRlow_sharing+amdrlow_toddler_perweek

	gen AMDRup_sharing=.
		replace AMDRup_sharing=((KCAL_hh_perweek-energytoddler)*min_amdrup_perkcal)/4 if nutr_no==3
			// Same for all age-gender groups
		replace AMDRup_sharing=((KCAL_hh_perweek-energytoddler)*min_amdrup_perkcal)/4 if nutr_no==4 
			// Highest of all age-gender groups
		replace AMDRup_sharing=((KCAL_hh_perweek-energytoddler)*min_amdrup_perkcal)/9 if nutr_no==5 
			// Lowest high bound of all age-gender groups		
		* Add in toddlers
		replace AMDRup_sharing=AMDRup_sharing+amdrup_toddler_perweek

	lab var AMDRlow_sharing "Household AMDR Lower per week - Sharing Scenario"
	lab var AMDRup_sharing "Household AMDR Upper per week - Sharing Scenario"
	
order hhxround case_id HHID y2_hhid y3_hhid data_round nutr_no EAR_targeting UL_targeting ///
	AMDRlow_targeting AMDRup_targeting EAR_sharing UL_sharing AMDRlow_sharing ///
	AMDRup_sharing KCAL_hh_perday KCAL_hh_perweek market_no year month date_consump ///
	hhsize market daysate_hh_conv

* Check and inspect requirements
tabstat EAR_sharing EAR_targeting if !inlist(nutr_no,1,3,5,7,23), by(nutr)
tabstat UL_sharing UL_targeting if inlist(nutr_no,7,8,13,17,18,20,21,22,23), by(nutr)
tabstat AMDRlow_sharing AMDRlow_targeting if inlist(nutr_no,3,4,5), by(nutr)
tabstat AMDRup_sharing AMDRup_targeting if inlist(nutr_no,3,4,5), by(nutr)

misstable sum AMDRlow_sharing AMDRlow_targeting AMDRup_sharing AMDRup_targeting if inlist(nutr_no,3,4,5)

* Inspect
tab nutr_no if AMDRlow_sharing>=AMDRup_sharing & inlist(nutr_no,3,4,5) & (AMDRlow_sharing!=. & AMDRup_sharing!=.)


	// EARs are higher under sharing
	// ULs are lower under sharing
	// Very slight differences in carb requirements due to rounding (theoretically equal)
	// Protein only very slightly higher lower bound because most age-gender groups are the same
	// Protein upper bound is about 30% lower under sharing tighter because of a 15% difference between lowest and highest upper bounds
	// Lipids lower bound is about 38% higher than under targeting
	// Lipids upper bound is only silghtly lower becuase of only a 5% difference in limit over age groups

* Sort
sort case_id HHID y2_hhid y3_hhid data_round nutr_no

* Replace EAR as missing for carbs, lipids, retinol and sodium
foreach v of varlist EAR_* {
	replace `v'=. if `v'==0 & inlist(nutr_no,3,5,7,23)
	}
* Replace ULs and AMDRs as missing if not applicable
foreach v of varlist UL* AMDR* {
	replace `v'=. if `v'==0
	}
	
save HHNeeds_HHLevel, replace

// PART 4 // SAVE DATASET TO MERGE WITH MARKET DATA FOR LINEAR PROGRAMMING - SHARING
use HHNeeds_HHLevel, clear
	* Keep only necessary data for CoNA calculation and rename variables for subsequent code
	drop if dropurban==1
	keep hhxround market_no nutr_no case_id HHID y2_hhid y3_hhid data_round ///
		nutr date_consump EAR_sharing UL_sharing AMDRlow_sharing AMDRup_sharing
	rename EAR_sharing ear
	rename UL_sharing ul
	rename AMDRlow_sharing amdr_lower
	rename AMDRup_sharing amdr_upper
	
	tab nutr_no, sum(ear)
	tab market_no, nolabel
	
	* Summarize sample size 
	unique case_id HHID y2_hhid y3_hhid 
	distinct case_id HHID y2_hhid y3_hhid 
	bys data_round: distinct case_id HHID y2_hhid y3_hhid 
	sum hhxround 
	
	// Households per market per data round
	forval i=1/29 {
		forval j=1/3 {
		di as text "Market Number is:" as result "`i'"
		di as text "Data Round is:" as result "`j'"
		sum hhxround if market_no==`i' & data_round==`j'
		}
	}
	
	* Markets not observed
	tab market_no // missing: 2,18,22,24 = URBAN
		* 4508 Household observations, 25 markets
		
	* Double check
	unique HHID case_id y2_hhid y3_hhid nutr_no
	unique HHID case_id y2_hhid y3_hhid 
	forval n=1/23 {
		di as text "Nutrient Number" as result "`n'"
		unique HHID case_id y2_hhid y3_hhid if nutr_no==`n'
		}

	sum ear ul amdr_lower amdr_upper
		di 90160/4508 // n NUT with an EAR
		di 45080/4508 // n UL
		di 13524/4508 // n macronutrients
		
	
* Checks for post-merge and after linear programming
tabstat ear ul amdr_lower amdr_upper, by(nutr_no) stats(mean sd min max count) c(s)

	save HHdata_tomerge_sharing, replace
	* Save in format that is readable by older versions of Stata
		// Stata 13 is available on Tufts high power cluster computer with interactive interface option
	saveold HHdata_tomerge_sharing_oldstata, replace

// PART 5 // SAVE DATASET TO MERGE WITH MARKET DATA FOR LINEAR PROGRAMMING - TARGETING
use HHNeeds_IndivLevel, clear
cap drop _*

	* Keep only necessary data for CoNA calculation and rename variables for subsequent code
	drop if dropurban==1
	keep hhxround market_no nutr_no case_id HHID y2_hhid y3_hhid data_round ///
		PID age_sex_grp nutr date_consump ear_perweek ul_perweek ///
		amdr_lower_perweek amdr_upper_perweek age_sex_grp daysate_conv
	ren ear_perweek ear
	ren ul_perweek ul
	ren amdr_lower_perweek amdr_lower
	ren amdr_upper_perweek amdr_upper
	tab nutr_no, sum(ear)
	tab market_no, nolabel
	egen hhxPIDxround=group(PID hhxround)
	sum hhxPIDxround
	sort hhxround PID

preserve
	* Check - recreate Household totals under targeting to compare with HH Level dataset
		ren ear ear_indiv
		egen EAR_targeting_fromindiv=total(ear), by(HHID case_id y2_hhid y3_hhid nutr_no)
		merge m:1 HHID case_id y2_hhid y3_hhid nutr_no using HHNeeds_HHLevel, keepusing(EAR_targeting)
			// Unmerged are urban
			drop if _merge==2
		bys nutr_no: tabstat EAR_targeting_fromindiv EAR_targeting
		* CONFIRMED
restore	

* Eliminate individuals who ate no meals in the household
tab daysate_conv
sum if daysate_conv==0
unique PID if daysate_conv==0
unique PID data_round if daysate_conv==0
drop if daysate_conv==0
drop daysate_conv

* Sort
sort hhxPIDxround nutr_no

* Replace EAR as missing for carbs, lipids, retinol and sodium
	replace ear=. if ear==0 & inlist(nutr_no,5,7,23)
	tab nutr_no, sum(ear)
	
* Replace ULs and AMDRs as missing if not applicable
foreach v of varlist ul amdr* {
	replace `v'=. if `v'==0
	}

* Drop infants (0-6 months) to simplify linear programming (since they have no diet cost)
drop if age_sex_grp==1
	
	* Summarize sample size 
	unique case_id HHID y2_hhid y3_hhid PID
	distinct case_id HHID y2_hhid y3_hhid PID
	bys data_round: distinct case_id HHID y2_hhid y3_hhid PID
	sum hhxPIDxround
	
	forval i=1/29 {
		forval j=1/3 {
		di as text "Market Number is:" as result "`i'"
		di as text "Data Round is:" as result "`j'"
		unique PID if market_no==`i' & data_round==`j'
		}
	}
	
	* Markets not observed
	tab market_no, nolabel // missing: 2,18,22,24 = URBAN
		* Market 27 has very few observations (Rumphi_boma)
		* 501,469 Individual observations, 25 markets, 10,293 individuals
			// Note the infants were dropped for the linear programming
		
	* Double check
	unique PID HHID case_id y2_hhid y3_hhid nutr_no
	forval n=1/23 {
		di as text "Nutrient Number" as result "`n'"
		unique PID date_consump if nutr_no==`n'
		}
	
	tabstat PID ear ul amdr_lower amdr_upper, stats(n mean) by(age_sex_grp)
		di 399725/21335 // n NUT, not exact due to infants 6 months-1 year
		di 216705/21335 // n UL, not exact due to infants 6 months-1 year
			tab nutr_no, sum(ul)
			* Group 2 will have fewer constraints:
				// They have no UL for copper, phosphorus, sodium, Vit B6, vit C 
				// Only ULs are: zinc, retinol, selenium, calcium
			* Note the linear programming will need to be run separately for this group 
				* because it will have fewer lines per loop
		di 62887/21803 // n macronutrients
			* Infants (group 2) have no AMDRs

	save HHdata_tomerge_targeting, replace
	* Save in format that is readable by older versions of Stata
		// Stata 13 is available on Tufts high power cluster computer with interactive interface option
	saveold HHdata_tomerge_targeting_oldstata, replace

// PART 6 // GENERATE HOUSEHOLD DATA WITH COUNT PER AGE-SEX-GROUP IN WIDE FORM
use HHNeeds_HHLevel, clear

* Collapse to household level (currently at household-nutrient level)
	* Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
			local l`v' "`v'"
			}
		}
collapse (first) EAR_sharing UL_sharing AMDRlow_sharing AMDRup_sharing EAR_targeting UL_targeting ///
	AMDRlow_targeting AMDRup_targeting KCAL_hh_perday KCAL_hh_perweek hhsize date_consump ///
	market market_no year month daysate_hh_conv, by(hhxround case_id HHID y2_hhid y3_hhid data_round)
	*Relabel
	foreach v of var * {
		label var `v' "`l`v''"
			}
merge 1:m case_id HHID y2_hhid y3_hhid data_round date_consump market_no year month ///
	using HH+Indiv, keepusing(PID age_sex_grp)
	unique case_id HHID y2_hhid y3_hhid data_round if _merge==2 // households dropped due to no food consumption
		drop if _merge==2
		drop _merge
* Drop nutrient specific variables
drop EAR_sharing UL_sharing AMDRlow_sharing AMDRup_sharing EAR_targeting UL_targeting ///
	AMDRlow_targeting AMDRup_targeting

* Collapse to age-sex groups
gen personcount=1	
	* Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
			local l`v' "`v'"
			}
		}
collapse (sum) personcount (first) KCAL_hh_perday KCAL_hh_perweek hhsize ///
	date_consump market market_no year month daysate_hh_conv, ///
	by(hhxround case_id HHID y2_hhid y3_hhid data_round age_sex_grp)
	*Relabel
	foreach v of var * {
		label var `v' "`l`v''"
			}

* Reshape
ren personcount age_sex_grp_
reshape wide age_sex_grp_, i(hhxround case_id HHID y2_hhid y3_hhid data_round) j(age_sex_grp)

lab var age_sex_grp_1 "(1) Infant (all) 0-6 months" 
lab var age_sex_grp_2	"(2) Infant (all) 6 months-1 year" 
lab var age_sex_grp_3	"(3) Child (all) 1-3 years" 
lab var age_sex_grp_4	"(4) Child (Male) 3 years" 
lab var age_sex_grp_5	"(5) Child (Female) 3 years"
lab var age_sex_grp_6	"(6) Child (Male) 4-8 years" 
lab var age_sex_grp_7	"(7) Child (Female) 4-8 years" 
lab var age_sex_grp_8	"(8) Adolescent	(Male) 9-13 years" 
lab var age_sex_grp_9	"(9) Adolescent (Male) 14-18 years" 
lab var age_sex_grp_10	"(10) Adult (Male) 19-30 years" 
lab var age_sex_grp_11	"(11) Adult (Male) 31-50" 
lab var age_sex_grp_12	"(12) Adult	(Male) 51-70 years" 
lab var age_sex_grp_13	"(13) Older Adult (Male) 70+ years"
lab var age_sex_grp_14	"(14) Adolescent (Female) 9-13 years" 
lab var age_sex_grp_15	"(15) Adolescent (Female) 14-18 years" 
lab var age_sex_grp_16	"(16) Adult (Female) 19-30 years" 
lab var age_sex_grp_17	"(17) Adult (Female) 31-50 years" 
lab var age_sex_grp_18	"(18) Adult (Female) 51-70 years" 
lab var age_sex_grp_19	"(19) Older Adult (Female) 70+ years" 	
lab var age_sex_grp_23	"(23) Lactation	(Female) 14-18 years" 
lab var age_sex_grp_24	"(24) Lactation	(Female) 19-30 years" 
lab var age_sex_grp_25	"(25) Lactation	(Female) 31-50 years"

save HH_NRgroups, replace
	
log close
