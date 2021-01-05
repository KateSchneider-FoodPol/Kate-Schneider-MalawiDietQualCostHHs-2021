/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: Calculate individual least-cost diets
*/

// PART 0 // FILE MANAGEMENT
global ihpsraw "MWI_IHPS_2010-2013-2016"
global otherrawdata "datafolder"
global analysis "workingfolder"
global NRs "\NutrientRequirements_DRIs_2019_ks.xlsx"
global whogrowth "\WHO growth reference tables_2006_ks.xlsx"
global iCoNA "\ICoNA files"

* Working directory
cd "$analysis"
cap log close
log using "08_IndividualCoNAs_`c(current_date)'", replace
***Log of Do File #8 "Individual CoNAs"
di "`c(current_date)' `c(current_time)'"

// PART 1 // PREPARE DATA FOR LINEAR PROGRAMMING
use HHNeeds_IndivLevel, clear
sort market_no age_sex_grp pal

* Drop partial mealtakers
keep if daysate_conv==1

* Drop unmatched to markets (urban)
drop if dropurban==1

* Collapse to a single person of each age-sex group
	* Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
			local l`v' "`v'"
			}
		}
	collapse (first) amdr_lower_perweek amdr_upper_perweek ear_perweek ///
		ul_perweek nutr, by(age_sex_grp pal nutr_no)
		
	*Relabel
	foreach v of var * {
		label var `v' "`l`v''"
			}
* Replace EAR as missing for carbs, lipids, retinol and sodium
	replace ear=. if ear==0 & inlist(nutr_no,5,7,23)
	tab nutr_no, sum(ear)
	
* Replace ULs and AMDRs as missing if not applicable
foreach v of varlist ul amdr* {
	replace `v'=. if `v'==0
	}

save IndividualNutrientNeeds, replace
	
joinby nutr_no using CPIDataForCoNA_tomerge
preserve 
	* First create dataset with groups >1 year who have a 36 line loop for linear programming
	drop if age_sex_grp==2
	egen person=group(age_sex_grp pal market_no year month)
	sort person nutr_no
	sum person
	di 23*24*29*127 // nutrients by age-sex groups (plus 4 groups also at very active) by markets by months

	* Rename and reshape for linear programming
	rename ear NR1
		lab var NR1 "EAR" 
	rename ul NR2
		lab var NR2 "UL"
	rename amdr_lower NR3
		lab var NR3 "AMDR-lower"
	rename amdr_upper NR4
		lab var NR4 "AMDR-upper"

	reshape long NR, i(person nutr_no) j(NR_no)
	order NR_no, after(NR)
	lab drop domain
	replace NR=0 if nutr_no==1 & NR_no==1

	* Insert constraint signs
	gen rel=">="
	replace rel="=" if nutr_no==1 // Price=
	replace rel="=" if nutr_no==2 // Energy=
	replace rel="<=" if NR_no==2 // UL<=
	replace rel="<=" if NR_no==4 // AMDR upper bound<=
	tab nutr_no if NR==.
	tab nutr_no if NR==0
	drop if NR==. // Drops if there's no UL or AMDR
	sum // check
	sort person nutr_no NR_no
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

	drop person

	save iCoNA_LPInput, replace

restore
	* Then save a separate input dataset for infants 6-12 months who have a 10 line loop for linear programming
	keep if age_sex_grp==2
	drop pal
	egen person=group(age_sex_grp market_no year month)
	sort person nutr_no
	sum person
	di 23*1*29*127 // nutrients by age-sex groups (1) by markets by months

	* Rename and reshape for linear programming
	rename ear NR1
		lab var NR1 "EAR" 
	rename ul NR2
		lab var NR2 "UL"
	rename amdr_lower NR3
		lab var NR3 "AMDR-lower"
	rename amdr_upper NR4
		lab var NR4 "AMDR-upper"

	reshape long NR, i(person nutr_no) j(NR_no)
	order NR_no, after(NR)
	lab drop domain
	replace NR=0 if nutr_no==1 & NR_no==1

	* Insert constraint signs
	gen rel=">="
	replace rel="=" if nutr_no==1 // Price=
	replace rel="=" if nutr_no==2 // Energy=
	replace rel="<=" if NR_no==2 // UL<=
	replace rel="<=" if NR_no==4 // AMDR upper bound<=
	tab nutr_no if NR==.
	tab nutr_no if NR==0
	drop if NR==. // Drops if there's no UL or AMDR
	sum // check
	sort person nutr_no NR_no
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
	drop person
	save iCoNA_LPInput2, replace
*****
* Run linear programming
*****
	* Read R result back to Stata
	clear
	insheet using "$analysis$iCoNA\iCoNALPResult.csv"
	tempfile iCoNA_LPResult
	save "`iCoNA_LPResult'", replace

	* Generate market number, year and month
	clear
	use "$analysis$iCoNA\iCoNA_LPInput", clear
	drop nutr
	collapse (mean) nutr_no, by(age_sex_grp pal market_no year month)
	egen v1=seq() 
	order v1, before(age_sex_grp)
	drop nutr_no

	* Add linear programming food intakes 
	merge 1:1 v1 using "`iCoNA_LPResult'"
	drop v1 _merge
	forvalues i=2/52 {
	rename v`i' F`=`i'-1'
	}
	gen nutr_no=0
	gen nutr="Intake"
	order nutr, before(F1)
	order nutr_no, before(nutr)

	* Add food price data
	append using "$analysis$iCoNA\iCoNA_LPInput"
	drop rel rhs
	egen person=group(age_sex_grp pal market_no year month)
	sort person nutr_no
	tab nutr_no
	drop nutr
	drop if nutr_no>1 // Keep only price & intake
	rename F* F*_
	reshape wide F*_, i(person age_sex_grp pal market_no year month) j(nutr_no)
	forvalues i=1/51 {  
	rename F`i'_* N*_`i'
	}
	reshape long N0_ N1_, i(age_sex_grp pal market_no year month) j(food_no)
	rename N*_ N*
	rename N0 intake
	rename N1 price
	lab var intake "Intake in grams"
	lab var price "Price in nominal MWK per gram"
	tab food_no if price==.
	tab food_no if price==0

	* Generate food_cost=intake*price
	bys food_no: sum intake, d
	gen food_cost=price*intake
	tab food_no if food_cost==0
	tab food_no if intake==0
	sum food_cost, d
	
	* Generate CoNA
	egen iCoNA=total(food_cost), by(person age_sex_grp pal market_no year month)
	label var iCoNA "Individual CoNA"
	bys age_sex_grp: sum iCoNA, d
	sum if iCoNA==.

	* Identify age-sex groups and market-months with no linear programming solution
	sum age_sex_grp market_no year month if iCoNA==0
	replace iCoNA=. if iCoNA==0 
	
	* Save for merging with all groups
	save "$analysis$iCoNA\iCoNA", replace

	// Repeat for group 2 and then append
			* Read R result back to Stata
			clear
			insheet using "$analysis$iCoNA\iCoNALPResult2.csv"
			tempfile iCoNA_LPResult2
			save "`iCoNA_LPResult2'", replace

			* Generate market number, year and month
			clear
			use "$analysis$iCoNA\iCoNA_LPInput2", clear
			drop nutr
			collapse (mean) nutr_no, by(age_sex_grp market_no year month)
			egen v1=seq() 
			order v1, before(age_sex_grp)
			drop nutr_no

			* Add linear programming food intakes 
			merge 1:1 v1 using "`iCoNA_LPResult2'"
			drop v1 _merge
			forvalues i=2/52 {
			rename v`i' F`=`i'-1'
			}
			gen nutr_no=0
			gen nutr="Intake"
			order nutr, before(F1)
			order nutr_no, before(nutr)

			* Add food price data
			append using "$analysis$iCoNA\iCoNA_LPInput2"
			drop rel rhs
			egen person=group(age_sex_grp market_no year month)
			sort person nutr_no
			tab nutr_no
			drop nutr
			drop if nutr_no>1 // Keep only price & intake
			rename F* F*_
			reshape wide F*_, i(person age_sex_grp market_no year month) j(nutr_no)
			forvalues i=1/51 {  
			rename F`i'_* N*_`i'
			}
			reshape long N0_ N1_, i(age_sex_grp market_no year month) j(food_no)
			rename N*_ N*
			rename N0 intake
			rename N1 price
			lab var intake "Intake in grams"
			lab var price "Price in nominal MWK per gram"
			tab food_no if price==.
			tab food_no if price==0

			* Generate food_cost=intake*price
			bys food_no: sum intake, d
			gen food_cost=price*intake
			tab food_no if food_cost==0
			tab food_no if intake==0
			sum food_cost, d
			
			* Generate CoNA
			egen iCoNA=total(food_cost), by(person age_sex_grp market_no year month)
			label var iCoNA "Individual CoNA"
			bys age_sex_grp: sum iCoNA, d
			sum if iCoNA==.

			* Identify age-sex groups and market-months with no linear programming solution
			sum market_no year month if iCoNA==0
			replace iCoNA=. if iCoNA==0 
			
			* Replace pal variable for merging with other groups
			gen pal=3
			
			* Save for merging with all groups
			tempfile iCoNA2
			save `iCoNA2', replace
			
append using "$analysis$iCoNA\iCoNA"
gen iCoNA_solution=1 if iCoNA!=.
replace iCoNA_solution=0 if iCoNA==.

lab var iCoNA "Individual CoNA per week"

	// Generate Year-month variable
	cap drop dateMY
	gen dateMY=ym(year, month)
	format dateMY %tmCCYY-NN
	tab dateMY, m
	lab var dateMY "Date (Month-Year)"

save "$analysis$iCoNA\iCoNA", replace

* Merge in needs
		use "$analysis$iCoNA\iCoNA", clear
		* Calculate total nutrient intakes
	   merge m:1 food_no using CPIDataForCoNA_foodcomp 
	   drop _merge
			// Convert nutrient contents to match (per gram) // FCTs are nutrients per 100g
			global nutrients energy carbohydrate protein lipids vitA retinol ///
				vitC vitE thiamin riboflavin niacin vitB6 folate vitB12 ///
				calcium copper iron magnesium phosphorus selenium zinc sodium
			foreach v in $nutrients {
				replace `v'=`v'/100 
				lab var `v' "Amount per gram"
			}
		ren ($nutrients) nutr_no#, addnumber(2)
		reshape long nutr_no, i(person age_sex_grp pal market_no year month food_no food_item) 
		ren nutr_no nutrient_pergram 
		ren _j nutr_no
		gen nutr_perfood=nutrient_pergram*intake
		save "$analysis$iCoNA\iCoNA_foodlevel", replace
		
		collapse (sum) nutr_perfood (first) iCoNA*, by(person age_sex_grp pal market_no year month nutr_no)
		ren nutr_perfood total_nutrient_intake
		
		* Merge in needs
		merge m:1 age_sex_grp pal nutr_no using IndividualNutrientNeeds
		drop if _merge==2
		drop _merge
			
		sort person nutr_no
		save "$analysis$iCoNA\iCoNA_nutrientlevel", replace
	
// PART 2 // SENSITIVITY ANALYSIS FOR GROUP 3
use iCoNA_LPInput, clear
	keep if age_sex_grp==3
	* Increase AMDR upper limits by 25%
	replace rhs=rhs*1.25 if age_sex_grp==3 & rel=="<=" & inlist(nutr_no,3,4,5)
	save iCoNA_LPInput_g3_test, replace
	*** Does not result in any solutons
use iCoNA_LPInput, clear
	keep if age_sex_grp==3
	* Increase AMDR upper limits by 25%
	replace rhs=rhs*1.5 if rel=="<=" & inlist(nutr_no,3,4,5)
	save iCoNA_LPInput_g3_test, replace
	*** Does not result in any solutons
	
***
* Linear programming
***
			* Read R result back to Stata
			clear
			insheet using iCoNA_LPResult_g3.csv
			tempfile iCoNA_LPResultg3
			save "`iCoNA_LPResultg3'", replace

			* Generate market number, year and month
			clear
			use iCoNA_LPInput_g3_test, clear
			drop nutr
			collapse (mean) nutr_no, by(age_sex_grp pal market_no year month)
			egen v1=seq() 
			order v1, before(age_sex_grp)
			drop nutr_no

			* Add linear programming food intakes 
			merge 1:1 v1 using "`iCoNA_LPResultg3'"
			drop v1 _merge
			forvalues i=2/52 {
			rename v`i' F`=`i'-1'
			}
			gen nutr_no=0
			gen nutr="Intake"
			order nutr, before(F1)
			order nutr_no, before(nutr)

			* Add food price data
			append using iCoNA_LPInput_g3_test
			drop rel rhs
			egen person=group(age_sex_grp pal market_no year month)
			sort person nutr_no
			tab nutr_no
			drop nutr
			drop if nutr_no>1 // Keep only price & intake
			rename F* F*_
			reshape wide F*_, i(person age_sex_grp pal market_no year month) j(nutr_no)
			forvalues i=1/51 {  
			rename F`i'_* N*_`i'
			}
			reshape long N0_ N1_, i(person age_sex_grp pal market_no year month) j(food_no)
			rename N*_ N*
			rename N0 intake
			rename N1 price
			lab var intake "Intake in grams"
			lab var price "Price in nominal MWK per gram"
			tab food_no if price==.
			tab food_no if price==0

			* Generate food_cost=intake*price
			bys food_no: sum intake, d
			gen food_cost=price*intake
			tab food_no if food_cost==0
			tab food_no if intake==0
			sum food_cost, d
			
			* Generate CoNA
			egen iCoNA=total(food_cost), by(person age_sex_grp market_no year month)
			label var iCoNA "Individual CoNA"
			bys age_sex_grp: sum iCoNA, d
			sum if iCoNA==.

			* Identify age-sex groups and market-months with no linear programming solution
			sum market_no year month if iCoNA==0
			replace iCoNA=. if iCoNA==0 
			
			gen iCoNA_solution=1 if iCoNA!=.
			replace iCoNA_solution=0 if iCoNA==.
			
			// Generate Year-month variable
			cap drop dateMY
			gen dateMY=ym(year, month)
			format dateMY %tmCCYY-NN
			tab dateMY, m
			lab var dateMY "Date (Month-Year)"
	
			save iCoNA_gr3, replace
			
			* Calculate total nutrient intakes
		   merge m:1 food_no using CPIDataForCoNA_foodcomp 
		   drop _merge
				// Convert nutrient contents to match (per gram) // FCTs are nutrients per 100g
				global nutrients energy carbohydrate protein lipids vitA retinol ///
					vitC vitE thiamin riboflavin niacin vitB6 folate vitB12 ///
					calcium copper iron magnesium phosphorus selenium zinc sodium
				foreach v in $nutrients {
					replace `v'=`v'/100 
					lab var `v' "Amount per gram"
				}
			ren ($nutrients) nutr_no#, addnumber(2)
			reshape long nutr_no, i(person age_sex_grp pal market_no year month food_no food_item) 
			ren nutr_no nutrient_pergram 
			ren _j nutr_no
			gen nutr_perfood=nutrient_pergram*intake
			save iCoNA_foodlevel_gr3, replace
			
			collapse (sum) nutr_perfood (first) iCoNA*, by(person age_sex_grp pal market_no year month nutr_no)
			ren nutr_perfood total_nutrient_intake
			
			* Merge in needs
			merge m:1 age_sex_grp pal nutr_no using IndividualNutrientNeeds
			drop if _merge==2
			drop _merge
			
			* Investigate nutrients exceeding upper amdr
			browse if total_nutrient_intake> amdr_upper_perweek & inlist(nutr_no,3,4,5)
				**** It's all protein!
		
			sort person nutr_no
			save iCoNA_nutrientlevel_gr3, replace


// PART 3 // SENSITIVITY ANALYSIS FOR ALL GROUPS
* Sequentially relax each upper bound constraint
use iCoNA_LPInput, clear
	tab nutr if rel=="<="
	tab nutr_no if rel=="<="

foreach n in 3 4 5 7 8 13 16 17 18 20 21 22 23 {	
	* Increase constraint by 25%
	use iCoNA_LPInput, clear
	replace rhs=rhs*1.25 if nutr_no==`n' & rel=="<="
	save iCoNA_LPInput_relax`n'25pct, replace	
	* Increase constraint by 50%
	use iCoNA_LPInput, clear
	replace rhs=rhs*1.5 if nutr_no==`n' & rel=="<="
	save iCoNA_LPInput_relax`n'50pct, replace
}	

***
* Linear programming
***
	foreach n in 3 4 5 7 8 13 16 17 18 20 21 22 23 {	

			* Read R result back to Stata
			clear
			insheet using iCoNALPResult_relax`n'25pct.csv
			tempfile iCoNA_LPResult
			save "`iCoNA_LPResult'", replace

			* Generate market number, year and month
			clear
			use iCoNA_LPInput_relax`n'25pct, clear
			drop nutr
			collapse (mean) nutr_no, by(age_sex_grp pal market_no year month)
			egen v1=seq() 
			order v1, before(age_sex_grp)
			drop nutr_no

			* Add linear programming food intakes 
			merge 1:1 v1 using "`iCoNA_LPResult'"
			drop v1 _merge
			forvalues i=2/52 {
			rename v`i' F`=`i'-1'
			}
			gen nutr_no=0
			gen nutr="Intake"
			order nutr, before(F1)
			order nutr_no, before(nutr)

			* Add food price data
			append using iCoNA_LPInput_relax`n'25pct
			drop rel rhs
			egen person=group(age_sex_grp pal market_no year month)
			sort person nutr_no
			tab nutr_no
			drop nutr
			drop if nutr_no>1 // Keep only price & intake
			rename F* F*_
			reshape wide F*_, i(person age_sex_grp pal market_no year month) j(nutr_no)
			forvalues i=1/51 {  
			rename F`i'_* N*_`i'
			}
			reshape long N0_ N1_, i(person age_sex_grp pal market_no year month) j(food_no)
			rename N*_ N*
			rename N0 intake
			rename N1 price
			lab var intake "Intake in grams"
			lab var price "Price in nominal MWK per gram"
			tab food_no if price==.
			tab food_no if price==0

			* Generate food_cost=intake*price
			bys food_no: sum intake, d
			gen food_cost=price*intake
			tab food_no if food_cost==0
			tab food_no if intake==0
			sum food_cost, d
			
			* Generate CoNA
			egen iCoNA=total(food_cost), by(person age_sex_grp market_no year month)
			label var iCoNA "Individual CoNA"
			bys age_sex_grp: sum iCoNA, d
			sum if iCoNA==.

			* Identify age-sex groups and market-months with no linear programming solution
			sum market_no year month if iCoNA==0
			replace iCoNA=. if iCoNA==0 
			
			gen iCoNA_solution=1 if iCoNA!=.
			replace iCoNA_solution=0 if iCoNA==.

			// Generate Year-month variable
			cap drop dateMY
			gen dateMY=ym(year, month)
			format dateMY %tmCCYY-NN
			tab dateMY, m
			lab var dateMY "Date (Month-Year)"

			save iCoNA_relax`n'25pct, replace
			
			* Calculate total nutrient intakes
		   merge m:1 food_no using CPIDataForCoNA_foodcomp 
		   drop _merge
				// Convert nutrient contents to match (per gram) // FCTs are nutrients per 100g
				global nutrients energy carbohydrate protein lipids vitA retinol ///
					vitC vitE thiamin riboflavin niacin vitB6 folate vitB12 ///
					calcium copper iron magnesium phosphorus selenium zinc sodium
				foreach v in $nutrients {
					replace `v'=`v'/100 
					lab var `v' "Amount per gram"
				}
			ren ($nutrients) nutr_no#, addnumber(2)
			reshape long nutr_no, i(person age_sex_grp pal market_no year month food_no food_item) 
			ren nutr_no nutrient_pergram 
			ren _j nutr_no
			gen nutr_perfood=nutrient_pergram*intake
			save iCoNA_foodlevel_relax`n'25pct, replace
			
			collapse (sum) nutr_perfood (first) iCoNA*, by(person age_sex_grp pal market_no year month nutr_no)
			ren nutr_perfood total_nutrient_intake
			
			* Merge in needs
			merge m:1 age_sex_grp pal nutr_no using IndividualNutrientNeeds
			drop if _merge==2
			drop _merge
		
			sort person nutr_no
			save iCoNA_nutrientlevel_relax`n'25pct, replace
	}
	foreach n in 3 4 7 8 13 16 17 18 20 21 22 23 {	

			* Read R result back to Stata
			clear
			insheet using iCoNALPResult_relax`n'50pct.csv
			tempfile iCoNA_LPResult
			save "`iCoNA_LPResult'", replace

			* Generate market number, year and month
			clear
			use iCoNA_LPInput_relax`n'50pct, clear
			drop nutr
			collapse (mean) nutr_no, by(age_sex_grp pal market_no year month)
			egen v1=seq() 
			order v1, before(age_sex_grp)
			drop nutr_no

			* Add linear programming food intakes 
			merge 1:1 v1 using "`iCoNA_LPResult'"
			drop v1 _merge
			forvalues i=2/52 {
			rename v`i' F`=`i'-1'
			}
			gen nutr_no=0
			gen nutr="Intake"
			order nutr, before(F1)
			order nutr_no, before(nutr)

			* Add food price data
			append using iCoNA_LPInput_relax`n'50pct
			drop rel rhs
			egen person=group(age_sex_grp pal market_no year month)
			sort person nutr_no
			tab nutr_no
			drop nutr
			drop if nutr_no>1 // Keep only price & intake
			rename F* F*_
			reshape wide F*_, i(person age_sex_grp pal market_no year month) j(nutr_no)
			forvalues i=1/51 {  
			rename F`i'_* N*_`i'
			}
			reshape long N0_ N1_, i(person age_sex_grp pal market_no year month) j(food_no)
			rename N*_ N*
			rename N0 intake
			rename N1 price
			lab var intake "Intake in grams"
			lab var price "Price in nominal MWK per gram"
			tab food_no if price==.
			tab food_no if price==0

			* Generate food_cost=intake*price
			bys food_no: sum intake, d
			gen food_cost=price*intake
			tab food_no if food_cost==0
			tab food_no if intake==0
			sum food_cost, d
			
			* Generate CoNA
			egen iCoNA=total(food_cost), by(person age_sex_grp market_no year month)
			label var iCoNA "Individual CoNA"
			bys age_sex_grp: sum iCoNA, d
			sum if iCoNA==.

			* Identify age-sex groups and market-months with no linear programming solution
			sum market_no year month if iCoNA==0
			replace iCoNA=. if iCoNA==0 
			
			gen iCoNA_solution=1 if iCoNA!=.
			replace iCoNA_solution=0 if iCoNA==.
	
			// Generate Year-month variable
			cap drop dateMY
			gen dateMY=ym(year, month)
			format dateMY %tmCCYY-NN
			tab dateMY, m
			lab var dateMY "Date (Month-Year)"
			
			save iCoNA_relax`n'50pct
			
			* Calculate total nutrient intakes
		   merge m:1 food_no using CPIDataForCoNA_foodcomp 
		   drop _merge
				// Convert nutrient contents to match (per gram) // FCTs are nutrients per 100g
				global nutrients energy carbohydrate protein lipids vitA retinol ///
					vitC vitE thiamin riboflavin niacin vitB6 folate vitB12 ///
					calcium copper iron magnesium phosphorus selenium zinc sodium
				foreach v in $nutrients {
					replace `v'=`v'/100 
					lab var `v' "Amount per gram"
				}
			ren ($nutrients) nutr_no#, addnumber(2)
			reshape long nutr_no, i(person age_sex_grp pal market_no year month food_no food_item) 
			ren nutr_no nutrient_pergram 
			ren _j nutr_no
			gen nutr_perfood=nutrient_pergram*intake
			save iCoNA_foodlevel_relax`n'50pct, replace
			
			collapse (sum) nutr_perfood (first) iCoNA*, by(person age_sex_grp pal market_no year month nutr_no)
			ren nutr_perfood total_nutrient_intake
			
			* Merge in needs
			merge m:1 age_sex_grp pal nutr_no using IndividualNutrientNeeds
			drop if _merge==2
			drop _merge
		
			sort person nutr_no
			save iCoNA_nutrientlevel_relax`n'50pct, replace
	}
	
* Document impact of relaxing upper bounds on successful results
// Actual Requirements as Defined
putexcel set "Sensitivity UpperBounds iCoNA", modify sheet(DefinedRequirements, modify)
use iCoNA, clear
	table dateMY age_sex_grp, contents(mean iCoNA_solution) format(%4.2f) replace	
	ren table1 iCoNA_pctsolutions
	replace iCoNA_pctsolutions=round((iCoNA_pctsolutions*100), 0.1)
	reshape wide iCoNA_pctsolutions, i(dateMY) j(age_sex_grp)
	ren iCoNA_pctsolutions* age_sex_grp_*
	mkmat dateMY age_sex_grp_*, matrix(a) 

	putexcel A1="Sensitivity Analysis to Upper Bound Constraints", font(garamond, 14 bold)
	putexcel A2="Number of Solutions Found with Nutrient Requirements As Defined", font(garamond, 14 bold)
	putexcel A3="", font(garamond, 11 bold)
		* Dates by Age-Sex Group
		putexcel B4:F4, overwritefmt merge hcenter
		putexcel B4="Solutions per Month-Year by Age-Sex Group", font(garamond, 12, white) bold hcenter fpattern(solid, gray) overwritefmt
		putexcel B5="Date", font(garamond, 11, black)
		putexcel C5="(1) Infant (all) 0-6 months"
		putexcel D5="(2) Infant (all) 6 months-1 year" 
		putexcel E5="(3) Child (all) 1-3 years" 
		putexcel F5="(4) Child (Male) 3 years" 
		putexcel G5="(5) Child (Female) 3 years" 
		putexcel H5="(6) Child (Male) 4-8 years" 
		putexcel I5="(7) Child (Female) 4-8 years" 
		putexcel J5="(8) Adolescent (Male) 9-13 years" 
		putexcel K5="(9) Adolescent (Male) 14-18 years"
		putexcel L5="(10) Adult (Male) 19-30 years"
		putexcel M5="(11) Adult (Male) 31-50" 
		putexcel N5="(12) Adult (Male) 51-70 years" 
		putexcel O5="(13) Older Adult (Male) 70+ years" 
		putexcel P5="(14) Adolescent (Female) 9-13 years" 
		putexcel Q5="(15) Adolescent (Female) 14-18 years" 
		putexcel R5="(16) Adult (Female) 19-30 years" 
		putexcel S5="(17) Adult (Female) 31-50 years" 
		putexcel T5="(18) Adult (Female) 51-70 years"
		putexcel U5="(19) Older Adult (Female) 70+ years" 
		putexcel V5="(23) Lactation (Female) 14-18 years" 
		putexcel W5="(24) Lactation (Female) 19-30 years" 
		putexcel X5="(25) Lactation (Female) 31-50 years"
		putexcel B6=matrix(a), right font(garamond, 11, black) 
		putexcel B6="Jan-07", right font(garamond, 11, black) 
		putexcel B7="Feb-07", right font(garamond, 11, black) 

use iCoNA, clear
	table dateMY market_no, contents(mean iCoNA_solution) format(%4.2f) replace	
	ren table1 iCoNA_pctsolutions
	replace iCoNA_pctsolutions=round((iCoNA_pctsolutions*100), 0.1)
	reshape wide iCoNA_pctsolutions, i(dateMY) j(market_no)
	ren iCoNA_pctsolutions* market_*
	mkmat dateMY market_*, matrix(b) 
		* Dates by Market
		putexcel B134:F134, overwritefmt merge hcenter
		putexcel B134="Solutions per Month-Year by Market", font(garamond, 12, white) bold hcenter fpattern(solid, gray) overwritefmt
		putexcel B135="Date", font(garamond, 11, black)
		putexcel C135="Market 1", font(garamond, 11, black)
		putexcel B136=matrix(b), right font(garamond, 11, black) 
		putexcel B136="Jan-07", right font(garamond, 11, black) 
		putexcel B137="Feb-07", right font(garamond, 11, black) 

// Relaxing requirements by 25% 
putexcel set "Sensitivity UpperBounds iCoNA", modify sheet(Relax 25%, replace)
putexcel A1="Sensitivity Analysis to Upper Bound Constraints", font(garamond, 14 bold)
	putexcel A2="Number of Solutions Found with Nutrient Requirements As Defined", font(garamond, 14 bold)
	putexcel A3="", font(garamond, 11 bold)
		* Dates by Age-Sex Group
		putexcel B4:F4, overwritefmt merge hcenter
		putexcel B4="Solutions per Month-Year by Age-Sex Group", font(garamond, 12, white) bold hcenter fpattern(solid, gray) overwritefmt
		putexcel B5="Date", font(garamond, 11, black)
		putexcel C5="(1) Infant (all) 0-6 months"
		putexcel D5="(2) Infant (all) 6 months-1 year" 
		putexcel E5="(3) Child (all) 1-3 years" 
		putexcel F5="(4) Child (Male) 3 years" 
		putexcel G5="(5) Child (Female) 3 years" 
		putexcel H5="(6) Child (Male) 4-8 years" 
		putexcel I5="(7) Child (Female) 4-8 years" 
		putexcel J5="(8) Adolescent (Male) 9-13 years" 
		putexcel K5="(9) Adolescent (Male) 14-18 years"
		putexcel L5="(10) Adult (Male) 19-30 years"
		putexcel M5="(11) Adult (Male) 31-50" 
		putexcel N5="(12) Adult (Male) 51-70 years" 
		putexcel O5="(13) Older Adult (Male) 70+ years" 
		putexcel P5="(14) Adolescent (Female) 9-13 years" 
		putexcel Q5="(15) Adolescent (Female) 14-18 years" 
		putexcel R5="(16) Adult (Female) 19-30 years" 
		putexcel S5="(17) Adult (Female) 31-50 years" 
		putexcel T5="(18) Adult (Female) 51-70 years"
		putexcel U5="(19) Older Adult (Female) 70+ years" 
		putexcel V5="(23) Lactation (Female) 14-18 years" 
		putexcel W5="(24) Lactation (Female) 19-30 years" 
		putexcel X5="(25) Lactation (Female) 31-50 years"

cap log close
log using "iCoNA Sensitivity Analyses", replace
use iCoNA, clear
	table dateMY age_sex_grp, contents(mean iCoNA_solution) format(%4.2f) 	
	table dateMY market_no, contents(mean iCoNA_solution) format(%4.2f) 	

foreach n in 3 4 5 7 8 13 16 17 18 20 21 22 23 {
	use iCoNA_nutrientlevel_relax`n'25pct
	table dateMY age_sex_grp, contents(mean iCoNA_solution) format(%4.2f)
	table dateMY market_no, contents(mean iCoNA_solution) format(%4.2f)	
	}

foreach n in 3 4 5 7 8 13 16 17 18 20 21 22 23 {
	use iCoNA_nutrientlevel_relax`n'50pct
	table dateMY age_sex_grp, contents(mean iCoNA_solution) format(%4.2f)
	table dateMY market_no, contents(mean iCoNA_solution) format(%4.2f)	
	}
log close
