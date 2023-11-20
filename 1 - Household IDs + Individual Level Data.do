/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: 
	1. Clean household identifiers data for each year to merge with household
			rosters
	2. Clean household rosters, merge with identifiers, merge at PID level across all years
	3. Classify all individuals by age and sex
	4. Generate household asset-based wealth index
*/

// PART 0 // FILE MANAGEMENT
global ihpsraw "MWI_IHPS_2010-2013-2016"
global otherrawdata "datafolder"
global analysis "workingfolder"

* Working directory
cd "$analysis"
cap log close
log using "HH+Indiv_`c(current_date)'", replace
* Log of Do File #1 "01_Household IDs + Individual Level Data
di "`c(current_date)' `c(current_time)'"

// PART 1 // MERGE HOUSEHOLD IDENTIFIERS + HOUSEHOLD ASSETS
* 2010
use "$ihpsraw\hh_mod_a_filt_10.dta", clear // Household - Identifiers, Date & Weights
	* Unique household identifier: case_id
		describe HHID case_id
		sum HHID case_id // 2010 N=1,619 Households
		destring case_id, replace
	* Encode panel group variable
	tab qx_type
	encode qx_type, gen(qx_type2)
	drop qx_type
	rename qx_type2 qx_type
	* Fix dates
		describe hh_a23_1 hh_a23_2
		tab qx_type
		bys qx_type: tab hh_a23_1 // Visit 1 date by panel group
		bys qx_type: tab hh_a23_2 // Visit 2 date by panel group
		gen date_visit1=hh_a23_1 
		format date_visit1 %tdDD-NN-YY
		lab var date_visit1 "Visit 1 Interview date (D-M-Y)"
		gen date_visit2=hh_a23_2 
		format date_visit2 %tdDD-NN-YY
		lab var date_visit2 "Visit 2 Interview date (D-M-Y)"
		order int_outcome_1 int_outcome_2 qx_type date_visit1 date_visit2, after(hh_a02b)
		gen date_HHq=.
		replace date_HHq=date_visit1 if qx_type==1 // Check: 815 changes
		replace date_HHq=date_visit2 if qx_type==2 // Check: 804 changes
		format date_HHq %tdDD-NN-YY
		tab date_HHq
		gen year=year(date_HHq)
		gen month=month(date_HHq)
		tab year, m
		tab month, m
		list date_visit1 date_visit2 if year==2011 // 3 outlier dates 
			/// NOTE LIKELY DATA ENTRY ERRORS
		gen date_consump=date_HHq // assume module G collected on date household questionnaire was administered
	gen data_round=1

	* Keep relevant variables for merge
	keep HHID case_id ea_id reside stratum hh_wgt hh_a01 hh_a02 hh_a02b qx_type ///
		date_visit1 date_visit2 hh_g09 year month date_consump data_round
		save HH_10, replace
		
	* Merge in assets
	use "$rawdata$ihpsraw\hh_mod_l_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		distinct HHID case_id
		* Merge in housing characteristics
		preserve
			use "$rawdata$ihpsraw\hh_mod_f_10", clear
			gen HQtoilet=.
			gen HQroof=.
			gen HQwall=.
			gen HQfloor=.
			
			tab hh_f41
			tab hh_f41, nolabel
			replace HQtoilet=1 if inlist(hh_f41,1,2) // HQ toilet defined as flush or VIP latrine
			replace HQtoilet=0 if HQtoilet==.

			tab hh_f08
			tab hh_f08, nolabel
			replace HQroof=1 if inlist(hh_f08,2,3,4) // HQ roof defined as iron sheets, clay tiles or concrete
			replace HQroof=0 if HQroof==.
			
			tab hh_f07
			tab hh_f07, nolabel
			replace HQwall=1 if inlist(hh_f07,4,5,6) // HQ wall defined as mud brick, burnt brick, concrete
			replace HQwall=0 if HQwall==.
	
			tab hh_f09
			tab hh_f09, nolabel
			replace HQfloor=1 if inlist(hh_f09,4,5,6) // HQ floor defined as smooth cement, tile
			replace HQfloor=0 if HQfloor==.

		keep HHID case_id HQ*	
		destring, replace
		tempfile house
		save `house', replace
		restore
		merge m:1 HHID case_id using `house', keepusing(HQ*)
		
	save HH_10_Assets, replace
	
* 2013
use "$ihpsraw\hh_mod_a_filt_13.dta", clear // Household - Identifiers & Weights
	describe occ y2_hhid HHID case_id ea_id stratum baseline_rural panelweight hh_wgt region district reside dist_to_IHS3location hhsize qx_type hh_a07a hh_a10a hh_a10b
	* Unique household identifier: y2_hhid
		// Baseline household identifier: case_id HHID
		// y2_hhid Identifies the roster number of household head in baseline roster
		destring case_id, replace
		sum y2_hhid HHID case_id // 2013 N=1,990
		keep y2_hhid HHID case_id ea_id stratum baseline_rural ///
			panelweight hh_wgt region district reside hhsize qx_type ///
			hh_a06 hh_a07a hh_a10a hh_a10b hh_g00_1 hh_g00_2 hh_g09
		tempfile IDs_13_p1
		save `IDs_13_p1', replace
	* Generate dates
	use "$ihpsraw\hh_meta_13.dta", clear // Metadata
		describe hh*day hh*month
		gen year="2013"
		foreach a in b f g h i j k l m n o p q r s t u v x {
			egen datestr`a'=concat(hh_`a'_start_day hh_`a'_start_month year), punct("-")
			gen date`a'=date(datestr`a', "DMY")
			format date`a' %tdDD-NN-YY
			}
	drop datestr*
	keep y2_hhid qx_type interview_status year date*
	merge 1:1 y2_hhid qx_type using `IDs_13_p1'
	drop _merge
	cap drop month
	gen month=month(dateg)
	cap drop year
	gen year=year(dateg)
	tab year, m
	* browse if year==.
	replace dateg=datef if dateg==. // NOTE: Assume food consumption collected on same date as preceding module in household questionnaire
	replace month=month(dateg) if month==.
	replace year=year(dateg) if year==.
	gen date_consump=dateg
	gen data_round=2 
		save HH_13, replace
		
	* Merge in Assets
	use "$rawdata$ihpsraw\hh_mod_l_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
distinct y2_hhid
destring, replace

		* Merge in housing characteristics
		preserve
			use "$rawdata$ihpsraw\hh_mod_f_13", clear
			gen HQtoilet=.
			gen HQroof=.
			gen HQwall=.
			gen HQfloor=.
			
			tab hh_f41
			tab hh_f41, nolabel
			replace HQtoilet=1 if inlist(hh_f41,1,2) // HQ toilet defined as flush or VIP latrine
			replace HQtoilet=0 if HQtoilet==.

			tab hh_f08
			tab hh_f08, nolabel
			replace HQroof=1 if inlist(hh_f08,2,3) // HQ roof defined as iron sheets, clay tiles 
			replace HQroof=0 if HQroof==.
			
			tab hh_f07
			tab hh_f07, nolabel
			replace HQwall=1 if inlist(hh_f07,4,5,6) // HQ wall defined as mud brick, burnt brick, concrete
			replace HQwall=0 if HQwall==.
	
			tab hh_f09
			tab hh_f09, nolabel
			replace HQfloor=1 if inlist(hh_f09,3,5) // HQ floor defined as smooth cement, tile
			replace HQfloor=0 if HQfloor==.

		keep y2_hhid HQ*	
		destring, replace
		tempfile house
		save `house', replace
		restore
		merge m:1 y2_hhid using `house', keepusing(HQ*)

save HH_13_Assets, replace
		
* 2016
use "$ihpsraw\hh_mod_a_filt_16.dta", clear // Metadata
	describe y3_hhid y2_hhid HHID case_id ea_id panelweight_2016 panelweight_2013 hh_wgt region district ta_code reside dist_to_IHS3location dist_to_IHPSlocation hhsize qx_type mover interviewdate_v1 interviewdate_v2 consumption_date
	* Unique household identifier: y3_hhid
		sum y3_hhid y2_hhid HHID case_id // 2016 N=2,508
		destring case_id, replace
	* Fix dates
		tab interviewdate_v1, m
		gen date_visit1=date(interviewdate_v1, "YMD")
		format date_visit1 %tdDD-NN-YY
		lab var date_visit1 "Visit 1 Interview date (D-M-Y)"
		
		tab interviewdate_v2, m
		gen date_visit2=date(interviewdate_v2, "YMD")
		format date_visit2 %tdDD-NN-YY
		lab var date_visit2 "Visit 2 Interview date (D-M-Y)"
		
		tab consumption_date, m
		gen date_consump=date(consumption_date, "YMD")
		format date_consump %tdDD-NN-YY
		lab var date_consump "Consumption data collection date (D-M-Y)"
	
	keep y3_hhid y2_hhid HHID case_id ea_id panelweight_2016 ///
		panelweight_2013 hh_wgt region district ta_code reside ///
		hhsize qx_type hh_g09 date_consump date_visit1 date_visit2
	cap drop month year
	misstable sum date_consump
	* browse if date_consump==.
	replace date_consump=date_visit1 if date_consump==.
	gen month=month(date_consump)
	gen year=year(date_consump)
	gen date_HHq=date_consump
	tab year, m
	tab month, m
	gen data_round=3 
		save HH_16, replace
		
	* Merge in Assets
	use "$rawdata$ihpsraw\hh_mod_l_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
distinct y3_hhid
destring, replace
		* Merge in housing characteristics
		preserve
			use "$rawdata$ihpsraw\hh_mod_f_16", clear
			gen HQtoilet=.
			gen HQroof=.
			gen HQwall=.
			gen HQfloor=.
			
			tab hh_f41
			tab hh_f41, nolabel
			replace HQtoilet=1 if inlist(hh_f41,1,2) // HQ toilet defined as flush or VIP latrine
			replace HQtoilet=0 if HQtoilet==.

			tab hh_f08
			tab hh_f08, nolabel
			replace HQroof=1 if inlist(hh_f08,2,3) // HQ roof defined as iron sheets, clay tiles 
			replace HQroof=0 if HQroof==.
			
			tab hh_f07
			tab hh_f07, nolabel
			replace HQwall=1 if inlist(hh_f07,4,5,6) // HQ wall defined as mud brick, burnt brick, concrete
			replace HQwall=0 if HQwall==.
	
			tab hh_f09
			tab hh_f09, nolabel
			replace HQfloor=1 if inlist(hh_f09,3,5) // HQ floor defined as smooth cement, tile
			replace HQfloor=0 if HQfloor==.

		keep y3_hhid HQ*	
		destring, replace
		tempfile house
		save `house', replace
		restore
		merge m:1 y3_hhid using `house', keepusing(HQ*)
save HH_16_Assets, replace
	
// PART 2 // HOUSEHOLD ROSTERS
* 2010
use "$ihpsraw\hh_mod_b_10.dta", clear // Individual - Roster
	destring case_id, replace
	encode qx_type, gen(qx_type2)
	drop qx_type
	rename qx_type2 qx_type
	merge m:1 HHID case_id qx_type using HH_10, force
	drop _merge
	rename hh_a01 district
	rename hh_a02 ta_code 
	gen region=.
		replace region=1 if district==101 & region ==.
		replace region=1 if district==102 & region ==.
		replace region=1 if district==103 & region ==.
		replace region=1 if district==104 & region ==.
		replace region=2 if district==208 & region ==.
		replace region=2 if district==204 & region ==.
		replace region=2 if district==201 & region ==.
		replace region=2 if district==210 & region ==.
		replace region=2 if district==206 & region ==.
		replace region=2 if district==207 & region ==.
		replace region=2 if district==105 & region ==.
		replace region=2 if district==107 & region ==.
		replace region=2 if district==202 & region ==.
		replace region=2 if district==209 & region ==.
		replace region=2 if district==203 & region ==.
		replace region=2 if district==205 & region ==.
		replace region=3 if district==312 & region ==.
		replace region=3 if district==315 & region ==.
		replace region=3 if district==305 & region ==.
		replace region=3 if district==310 & region ==.
		replace region=3 if district==304 & region ==.
		replace region=3 if district==302 & region ==.
		replace region=3 if district==301 & region ==.
		replace region=3 if district==308 & region ==.
		replace region=3 if district==306 & region ==.
		replace region=3 if district==313 & region ==.
		replace region=3 if district==311 & region ==.
		replace region=3 if district==309 & region ==.
		replace region=3 if district==307 & region ==.
		replace region=3 if district==314 & region ==.
		replace region=3 if district==303 & region ==.
tempfile roster10
	save `roster10', replace

	* Merge in education
	merge m:1 PID using "$ihpsraw\hh_mod_c_10.dta", keepusing(PID hh_c06 hh_c08 hh_c09)
	drop _merge
	save `roster10', replace
	
	* Merge in breakfast yesterday
	merge m:1 PID using "$ihpsraw\hh_mod_d_10.dta", ///
		keepusing(hh_d38) force
		drop _merge
	
	* Merge in occupation
	merge m:1 PID using "$ihpsraw\hh_mod_e_10.dta", ///
		keepusing(hh_e05-hh_e15 hh_e18-hh_e20b hh_e22-hh_e24 hh_e32-hh_e34b ///
		hh_e36-hh_e38 hh_e46-hh_e48b hh_e50-hh_e52 hh_e56-hh_e58 ///
		hh_e60-hh_e63 hh_e65) force
		drop _merge
		
	* Merge in child anthropomentry
	merge m:1 PID using "$ihpsraw\hh_mod_v_10.dta", keepusing(PID hh_v04a hh_v04b ///
		hh_v05 hh_v06 hh_v08 hh_v09 hh_v10 hh_v14)
	drop _merge
	/* misstable sum hh_v04a hh_v04b
	replace hh_v04a=0 if hh_v04a==. // assume under 1 year if years is missing
	replace hh_v04b=0 if hh_v04b==. // round to year if months is not recorded
	gen ageinmonths=(hh_v04a*12)+hh_v04b
		tab ageinmonths
		replace ageinmonths=. if ageinmonths>60
		// Explore data
		tab hh_v09 if ageinmonths<60, m
		tab2 hh_v09 hh_v10
		misstable sum ageinmonths hh_v09 hh_v08 hh_b03 if ageinmonths<60
		*/
	save `roster10', replace 

*2013
use "$ihpsraw\hh_mod_b_13.dta", clear // Individual - Roster 
	merge m:1 y2_hhid qx_type using HH_13, force
	drop _merge
	keep y2_hhid PID qx_type hhmember baselinemember hhsize baselinemembercount ///
		individualmover moverbasehh hh_b01 hh_b03 hh_b04 hh_b05a hh_b05b ///
		hh_b06a hh_b06b hh_b06_1 hh_b06_2 hh_b06_3a hh_b06_3b hh_b07 ///
		hh_b08 hh_b09 hh_b11 hh_b16 hh_b19 hh_b22 hh_b22_3 HHID case_id ///
		ea_id stratum baseline_rural panelweight hh_wgt region district ///
		reside hh_a07a hh_a10a hh_a10b hh_g00_1 hh_g00_2 hh_g09 month year ///
		date_consump data_round
	rename hh_b01 id_code
	rename hh_a10a ta_code
	rename hh_a10b TA_name
tempfile roster13
	save `roster13', replace

	* Merge in education
	merge m:1 PID using "$ihpsraw\hh_mod_c_13.dta", keepusing(PID hh_c06 hh_c08 hh_c09)
	drop _merge
		save `roster13', replace
		
	* Merge in breakfast yesterday
	merge m:1 PID using "$ihpsraw\hh_mod_d_13.dta", ///
		keepusing(hh_d38) force
		drop _merge
	
	* Merge in occupation
	merge m:1 PID using "$ihpsraw\hh_mod_e_13.dta", ///
		keepusing(hh_e05-hh_e15 hh_e18-hh_e20b hh_e22-hh_e24 hh_e32-hh_e34b ///
		hh_e36-hh_e38 hh_e46-hh_e48b hh_e50-hh_e52 hh_e56-hh_e58 ///
		hh_e60-hh_e63 hh_e65) force
		drop _merge
		
	* Merge in child anthropomentry
	merge m:1 PID using "$ihpsraw\hh_mod_v_13.dta", keepusing(PID hh_v04a hh_v04b ///
		hh_v05 hh_v06 hh_v08 hh_v09 hh_v10 hh_v14)
		// Note 2 people that do not merge are 16 and 21 years old
		list HHID hh_b05a hh_b06_3a hh_v04a hh_b04 ///
			if _merge==1
	drop _merge
	save `roster13', replace

*2016/17
use "$ihpsraw\hh_mod_b_16.dta", clear // Individual - Roster
	merge m:m y3_hhid qx_type using HH_16
	drop _merge
	rename hh_b19b hh_b19
tempfile roster16
	save `roster16', replace

	* Merge in education
	merge m:1 PID using "$ihpsraw\hh_mod_c_16.dta", keepusing(PID hh_c06 hh_c08 hh_c09)
	drop _merge
	save `roster16', replace
	
	* Merge in breakfast yesterday
	merge m:1 PID using "$ihpsraw\hh_mod_d_16.dta", ///
		keepusing(hh_d38) force
		drop _merge
	
	* Merge in occupation
	merge m:1 PID using "$ihpsraw\hh_mod_e_16.dta", ///
		keepusing(hh_e05-hh_e06_8b hh_e07a-hh_e14 hh_e19a-hh_e20b hh_e22-hh_e24_1 ///
		hh_e29 hh_e32-hh_e34_code hh_e36-hh_e38_1 hh_e47a-hh_e48b hh_e50-hh_e52_1 ///
		hh_e57 hh_e58 hh_e60-hh_e63 hh_e65) force
		gen hh_e07=. // to match with prior rounds
		replace hh_e07=1 if (hh_e07a>=0 & hh_e07a!=.) ///
			& hh_e07==. & data_round==3
		drop _merge
	
	* Merge in child anthropomentry
	merge m:1 PID using "$ihpsraw\hh_mod_v_16.dta", keepusing(PID ///
		hh_v05 hh_v06 hh_v08 hh_v09 hh_v10 hh_v14)
	drop _merge
	save `roster16', replace

*Append all years (PID is the individual identifier, the panel variable)
use `roster10', clear
append using `roster13', force
append using `roster16', force
sort  PID data_round

* Clean up data - Label and rename variables
	lab var hhsize ""
	format date_consump %tdDD-NN-YY
	replace id_code=hh_b01 if id_code==.
	lab var hh_b19 "Mother ID Code"

* Generate Household x Round variable
cap drop hhxround
foreach v in y2_hhid y3_hhid {
	replace `v'="00000" if `v'==""
	}
egen hhxround=group(case_id HHID y2_hhid y3_hhid data_round)
foreach v in y2_hhid y3_hhid {
	replace `v'="" if `v'=="00000"
	}	
	
* Save household and individual data
save HH+Indiv_merged, replace

// PART 3 // CLASSIFY INDIVIDUALS BY AGE AND SEX
use HH+Indiv_merged, clear
* Calculate age in years and months
sort case_id PID data_round
* browse HHID PID data_round date_consump hh_b04 hh_b05a ///
	* hh_b05b hh_b06_3a hh_b06_3b hh_b06a hh_b06b
	// Reported age in months
		* Note: Panel A completed HH questionnaire in Visit 1
	sum hh_b05a hh_b05b hh_b06_3a hh_b06_3b
	* histogram hh_b05a
	sum hh_b05b if hh_b05a==0
	sum hh_b05b if hh_b05a!=0
	sum hh_b05a if hh_b05b!=0 & hh_b05b!=. // Months reported <5 years only
	
	// Note missing ages
	misstable sum hh_b05a hh_b05b if qx_type==1
			* 408 missing ages in visit 1 for Panel A
	misstable sum hh_b06_3a hh_b06_3b if qx_type==2
			* 3,984 missing ages in visit 2 for Panel B
	* Examine reported year born for people without ages
	sum hh_b06b if missing(hh_b05a) & qx_type==1 // 401 have a year
	sum hh_b06b if missing(hh_b06_3a) & qx_type==2 // All have a year
		* Note: for households with members missing ages
				* To maximize sample size:
					* Use age at other visit instead if observed
					* For Panel B, only drop if the person is >1 year at visit 2
	gen age_rptd=.
		lab var age_rptd "Age in years, reported age"
		* First use reported age and convert all to years
		replace age_rptd=hh_b05a if qx_type==1 ///
			& (hh_b05b==0 | hh_b05b==.)
		replace age_rptd=hh_b06_3a if qx_type==2 ///
			& (hh_b06_3b==0 | hh_b06_3b==.)
		replace age_rptd=(hh_b05a+(hh_b05b/12)) if qx_type==1 ///
			& hh_b05b!=0 & hh_b05b!=.
		replace age_rptd=(hh_b05b/12) if qx_type==1 & hh_b05b!=0 ///
			& hh_b05b!=. & (hh_b05a==0 | hh_b05a==.)
		replace age_rptd=(hh_b06_3a+(hh_b06_3b/12)) if qx_type==2 ///
			& hh_b06_3b!=0 & hh_b06_3b!=. 
		replace age_rptd=(hh_b06_3b/12) if qx_type==2 & hh_b06_3b!=0 ///
			& hh_b06_3b!=. & (hh_b06_3a==0 | hh_b06_3a==.)

		* For missing ages, first try replacing with the other visit
		replace age_rptd=hh_b05a if qx_type==2 ///
			& (hh_b05b==0 | hh_b05b==.) & age_rptd==.
		replace age_rptd=hh_b06_3a if qx_type==1 ///
			& (hh_b06_3b==0 | hh_b06_3b==.) & age_rptd==.
		replace age_rptd=(hh_b05a+(hh_b05b/12)) if qx_type==2 ///
			& hh_b05b!=0 & hh_b05b!=. & age_rptd==.
		replace age_rptd=(hh_b06_3a+(hh_b06_3b/12)) if qx_type==1 ///
			& hh_b06_3b!=0 & hh_b06_3b!=. & age_rptd==.
	sum age_rptd, d
	* histogram age_rptd
	misstable sum age_rptd // 5 missing
		* Use calculation from year born for 5 missing?
		* browse PID year hh_b06b if age_rptd==. // None have data
		* browse PID HHID id_code year hh_b06b hh_b04-hh_b08 hh_b06_2-hh_b06_3b hh_b05_2_1 if age_rptd==.
		* browse if age_rptd==.
			* No information on these 5 people & only observed at baseline
			drop if age_rptd==. // NOTE 5 PEOPLE DROPPED FOR LACK OF AGE AND OTHER CONSUMPTION-RELATED DATA
	// Examine birthdays relative to reported age
	tab age_rptd 
	* histogram hh_b06b
	gen ageinmonths=age_rptd*12 if age_rptd<=5
	tab ageinmonths
	
* Check sex variable
tab hh_b03, m
tab hh_b03, nolabel
lab var hh_b03 "Sex 1=male 2=female"
	
* Code person-level data into IOM age-sex groups, excluding pregnant and lactating
tab2 age_rptd hh_b03
cap drop age_sex_grp
gen age_sex_grp=.
	replace age_sex_grp=1 if age_rptd>=0 & ageinmonths<6
	replace age_sex_grp=2 if ageinmonths>=6 & age_rptd<1
	replace age_sex_grp=3 if age_rptd>=1 & age_rptd<3
	replace age_sex_grp=4 if age_rptd>=3 & age_rptd<4 & hh_b03==1
	replace age_sex_grp=5 if age_rptd>=3 & age_rptd<4 & hh_b03==2
	replace age_sex_grp=6 if age_rptd>=4 & age_rptd<9 & hh_b03==1 
	replace age_sex_grp=7 if age_rptd>=4 & age_rptd<9 & hh_b03==2
	replace age_sex_grp=8 if age_rptd>=9 & age_rptd<14 & hh_b03==1 
	replace age_sex_grp=9 if age_rptd>=14 & age_rptd<19 & hh_b03==1 
	replace age_sex_grp=10 if age_rptd>=19 & age_rptd<31 & hh_b03==1 
	replace age_sex_grp=11 if age_rptd>=31 & age_rptd<51 & hh_b03==1 
	replace age_sex_grp=12 if age_rptd>=51 & age_rptd<70 & hh_b03==1 
	replace age_sex_grp=13 if age_rptd>=70 & hh_b03==1 
	replace age_sex_grp=14 if age_rptd>=9 & age_rptd<14 & hh_b03==2 
	replace age_sex_grp=15 if age_rptd>=14 & age_rptd<19 & hh_b03==2 
	replace age_sex_grp=16 if age_rptd>=19 & age_rptd<31 & hh_b03==2 
	replace age_sex_grp=17 if age_rptd>=31 & age_rptd<51 & hh_b03==2 
	replace age_sex_grp=18 if age_rptd>=51 & age_rptd<70 & hh_b03==2 
	replace age_sex_grp=19 if age_rptd>=70 & hh_b03==2 
tab age_sex_grp, m
tab age_sex_grp hh_b03
tab age_sex_grp, sum(age_rptd)
lab var age_sex_grp "Age-Sex Nutrient Requirements Group"

lab def nrgroup ///
	1	"(1) Infant (all) 0-6 months" ///
	2	"(2) Infant (all) 6 months-1 year" ///
	3	"(3) Child (all) 1-3 years" ///
	4	"(4) Child (Male) 3 years" ///
	5	"(5) Child (Female) 3 years" ///
	6	"(6) Child (Male) 4-8 years" ///
	7	"(7) Child (Female) 4-8 years" ///
	8	"(8) Adolescent	(Male) 9-13 years" ///
	9	"(9) Adolescent (Male) 14-18 years" ///
	10	"(10) Adult (Male) 19-30 years" ///
	11	"(11) Adult (Male) 31-50" ///
	12	"(12) Adult	(Male) 51-70 years" ///
	13	"(13) Older Adult (Male) 70+ years" ///
	14	"(14) Adolescent (Female) 9-13 years" ///
	15	"(15) Adolescent (Female) 14-18 years" ///
	16	"(16) Adult (Female) 19-30 years" ///
	17	"(17) Adult (Female) 31-50 years" ///
	18	"(18) Adult (Female) 51-70 years" ///
	19	"(19) Older Adult (Female) 70+ years" ///	.
	20	"(20) Pregnancy	(Female) 14-18 years" ///
	21	"(21) Pregnancy	(Female) 19-30 years" ///
	22	"(22) Pregnancy	(Female) 31-50 years" ///
	23	"(23) Lactation	(Female) 14-18 years" ///
	24	"(24) Lactation	(Female) 19-30 years" ///
	25	"(25) Lactation	(Female) 31-50 years"
lab val age_sex_grp nrgroup

	// Change sex variable to dummy
	rename hh_b03 sex
	recode sex (1=0) (2=1)
	lab var sex "Sex (0=Male, 1=Female)"
	lab def sex 0 "Male" 1 "Female"
	lab val sex sex
	tab sex

* Code individuals in pal categories
	// Most individuals coded as active (pal=3), which is the amount of physical 
		// activity recommended for health
	// Use occupation and labor information to determine which men 14-59 engage
		// in physically demanding work and require a higher pal
		// Defined as any agricultural or construction labor, engaged in at least
			// 1 month, 1 week and more than the median hours in the weeks during
			// which the job was worked
			// Ganyu considered demanding (typically manual day labor)
gen pal=.
replace pal=3 if !inlist(age_sex_grp,9,10,11,12)
tempvar manuallabor
	gen `manuallabor'=.
	replace `manuallabor'=1 if `manuallabor'==. &  inlist(age_sex_grp,9,10,11,12) ///
		& age_rptd<=59 & (hh_e07>0 | (hh_e10>0 & reside==2) | ///
		inlist(hh_e19b,62,63,71,93,95,99) | (inlist(hh_e34b, 62,63,71,93,95) ///
		& hh_e36>0 & hh_e37>0 & hh_e38>20) | (inlist(hh_e47b,62,95) & hh_e50>0 & ///
		hh_e51>0 & hh_e52>11) | (hh_e56>0 & hh_e57>0 & hh_e58>=4) | ///
		hh_e60==1 | hh_e06_1==1 | hh_e06_6==1 | inlist(hh_e06_8a,3,5) | ///
		inlist(hh_e06_8a,3,5) | inlist(hh_e06_8b,3,5) | inlist(hh_e13_1a,3,5) | ///
		inlist(hh_e13_1b,3,5) | hh_e06_1a==1 | hh_e06_1b==1 | hh_e06_1c==1)
replace pal=4 if inlist(age_sex_grp,9,10,11)
replace pal=3 if inlist(age_sex_grp,9,10,11,12) & `manuallabor'!=1
replace pal=4 if age_sex_grp==12 & age_rptd<=59 & pal==.
replace pal=3 if age_sex_grp==12 & age_rptd>59

tab pal, m
tab2 pal reside

* Identify lactating as mother in household of all children <2 years
	* Identified as mother by id_code in child observation
tab hh_b19 if inlist(age_sex_grp,1,2,3), m
tab hh_b19 if ageinmonths<=23
bys data_round: distinct HHID case_id y2_hhid y3_hhid
gen breastfeeding=1 if ageinmonths<=23 ///
		& hh_b19!=. & !inlist(hh_b19,97,98,99) & !inlist(hh_b19a,97,98,99) // Excludes if mother is dead/outside house/not known/missing
tab breastfeeding, m
tab ageinmonths if breastfeeding==1

* No way to identify pregnant women
cap drop _merge
preserve
 unique case_id HHID y2_hhid y3_hhid data_round id_code

	* Change age-sex group to lactating for identified mothers
	tab id_code, m
	tab2 ageinmonths breastfeeding
	unique hh_b19 HHID y2_hhid y3_hhid data_round case_id if breastfeeding==1 
		* Note there are multiple breastfeeding children in 19 households
	keep if breastfeeding==1
	keep case_id HHID y2_hhid y3_hhid data_round hh_b19 breastfeeding date_consump ageinmonths
	distinct HHID y2_hhid y3_hhid data_round case_id hh_b19 breastfeeding
	unique HHID y2_hhid y3_hhid case_id data_round hh_b19
	sort case_id HHID y2_hhid y3_hhid data_round hh_b19
	tab ageinmonths
	ren ageinmonths bfchild_ageinmonths
	keep case_id HHID y2_hhid y3_hhid data_round hh_b19 breastfeeding bfchild_ageinmonths
		// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (first) hh_b19 breastfeeding (min) bfchild_ageinmonths, by(case_id HHID y2_hhid y3_hhid data_round)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
		// METHOD NOTE: for mothers nursing more than one child, energy needs are based on the youngest child
	rename hh_b19 id_code
	unique case_id HHID y2_hhid y3_hhid data_round id_code
	ren breastfeeding lactating
	tempfile lactating
		save `lactating', replace
restore
merge m:1 case_id HHID y2_hhid y3_hhid data_round id_code using `lactating'
	bys data_round: tab HHID if _merge==2, sum(id_code)
	bys data_round: tab y2_hhid if _merge==2, sum(id_code)
	drop if _merge==2 // 3 children could not be matched back to breastfeeding mother
	drop _merge
lab var id_code "Person-level line ID"

tab age_sex_grp if lactating==1
tab age_sex_grp if lactating==1 // Check
tab age_rptd if lactating==1
	replace lactating=0 if age_rptd>59 // METHOD NOTE: Only impute breastfeeding for women <59
	replace lactating=0 if sex==1 & age_rptd>=14 & age_rptd<=59 & lactating!=1
	replace lactating=. if age_rptd<14 & lactating!=1
	replace lactating=. if sex==0
replace age_sex_grp=23 if inlist(age_sex_grp,14,15) & lactating==1
replace age_sex_grp=24 if age_sex_grp==16 & lactating==1
replace age_sex_grp=25 if inlist(age_sex_grp,17,18) & lactating==1
distinct breastfeeding
tab lactating
tab2 age_sex_grp lactating, m
drop breastfeeding

* Identify any members that didn't eat in the household in the last 7 days
bys year: tab hh_b08
* browse hh_b04 hh_b04_os year PID sex hh_b07 hh_b08 hh_g09 hh_w01 hhmember baselinemember ///
	*baselinemembercount-hh_b06_1 hh_a07a ind_respondent age_rptd age_sex_grp if hh_b08==0 
tab id_code
* histogram hh_b08
	// Generate a conversion factor for people who ate in house less than 7 days
	gen daysate_conv=hh_b08/7
	lab var daysate_conv "Conversion factor for partial weekly meal consumption in household"
	tab daysate_conv, m
	
	* Assume person ate all meals in household if they have not been away
	foreach v in hh_b07 hh_b11 hh_b12 {
		tab `v' if daysate_conv==.
		}
	replace daysate_conv=0 if daysate_conv==. & hh_b07==0 
	replace daysate_conv=1 if daysate_conv==. & hh_b11==1
	replace daysate_conv=1 if daysate_conv==. & hh_b07!=0 // assumes 13 people ate at home when no info was provided 
	tab age_sex_grp if daysate_conv==.
	
	* Replace as 0 for all infants
	replace daysate_conv=. if age_sex_grp==1
		// Check
		tab age_sex_grp
		tab age_sex_grp if daysate_conv==.
		
	* Adjust for meals fed to non-household members
	tab hh_g09
	unique case_id data_round if hh_g09==1
	ren hh_g09 fed_others
		// NOTE: 1,860 household instances fed others
		* Note limitation, this introduces uncertainty in adequacy
		* 	estimate since no information is available to make adjustments

* Child Anthropometry
	cap drop haz waz whz
	egen haz=zanthro(hh_v09,ha,WHO), xvar(ageinmonths) gender(sex) ///
		gencode(male=0, female=1) ageunit(month) 
		lab var haz "Length/height-for-age z-score, WHO 2006 growth reference (stunting)"
	egen waz=zanthro(hh_v08,wa,WHO), xvar(ageinmonths) gender(sex) ///
		gencode(male=0, female=1) ageunit(month) 
		lab var waz "Weight-for-age z-score, WHO 2006 growth reference (underweight)"
	egen whz=zanthro(hh_v08,wh,WHO), xvar(hh_v09) gender(sex) ///
		gencode(male=0, female=1) nocutoff
		replace whz=. if ageinmonths<23 | ageinmonths>60
		tempvar lhz
		egen `lhz'=zanthro(hh_v08,wl,WHO), xvar(hh_v09) gender(sex) ///
		gencode(male=0, female=1) 
		replace `lhz'=. if ageinmonths>23
		replace whz=`lhz' if whz==. & ageinmonths<24
		lab var whz "Weight-for-height/length z-score, WHO 2006 growth reference (wasting/obesity)"
	* Classify
	cap drop stunted underweight wasted_overweight
	gen stunted=.
		tab haz
		replace stunted=0 if haz>=-2.000 & stunted==. & haz!=.
		replace stunted=1 if haz<-2.000 & haz >=-3.000 & stunted==. & haz!=.
		replace stunted=2 if haz<-3 & stunted==. & haz!=.
		lab def stunt 0 "Not stunted" 1 "Moderate stunting" 2 "Severe stunting"
		lab val stunted stunt
	gen underweight=.
		replace underweight=0 if waz>=-2 & underweight==. & waz!=.
		replace underweight=1 if waz<-2 & waz >=-3 & underweight==. & waz!=.
		replace underweight=2 if waz<-3 & underweight==. & waz!=.
		lab def under 0 "Not underweight (Normal)" ///
			1 "Moderately underweight" 2 "Severely underweight"
		lab val underweight under
	gen wasted_overweight=.
		replace wasted_overweight=3 if whz>=-2 & whz<=2 & wasted_overweight==. & whz!=.
		replace wasted_overweight=2 if haz<=-2 & haz >-3 & wasted_overweight==. & whz!=.
		replace wasted_overweight=1 if haz<-3 & wasted_overweight==. & whz!=.
		replace wasted_overweight=4 if haz>2 & haz<=3 & wasted_overweight==. & whz!=.
		replace wasted_overweight=5 if haz>3 & wasted_overweight==. & whz!=.
		lab def wasteow 1 "Severe wasting" 2 "Moderate wasting" ///
			3 "Normal" 4 "Overweight" 5 "Obese"
		lab val wasted_overweight wasteow
	foreach v in stunted underweight wasted_overweight {
		bys data_round: tab `v' // remember this isn't applying survey weights, not comparable to national indicators
		}
	
* Drop ambiguous and unnecessary variables
drop hh_b10b hh_b13 hh_b13_os hh_b14 hh_b15b hh_b24 hh_b25 hh_b26a ///
hh_b26b hh_b26c hh_b26d hh_b27 hh_b28 interview_status ind_respondent i_HHID i_pid ///
hh_b04_1b hh_b04a hh_b05_2 hh_b05_2_1 hh_b10_oth hh_b10a hh_b13_oth hh_b15a ///
hh_b15b_oth hh_b22_oth hh_b24_1 hh_b24_1_oth hh_b24_2 hh_b26a_1 hh_b26b_1 hh_b26b_2 ///
hh_b26c_1 hh_b26c_2 hh_v04a hh_v04b hh_v05 hh_v06 hh_v08 hh_v09 hh_v10 hh_v14

save HH+Indiv_merged_individ, replace

**************************************************************************
**Run do file 3 with market data and then return to merge with household**
**************************************************************************

// PART 4 // MERGE IN MARKET DATA
use HH+Indiv_merged_individ, clear
* Check sample size before dropping urban markets
unique HHID case_id y2_hhid y3_hhid PID
distinct HHID case_id y2_hhid y3_hhid PID

* Label district data
unique district region
distinct district region
lab def dis ///
	101	"Chitipa" ///
	102	"Karonga" ///
	103	"Nkhatabay" ///
	104	"Rumphi" ///
	105	"Mzimba" ///
	106	"Likoma" ///
	107	"Mzuzu City" ///
	201	"Kasungu" ///
	202	"Nkotakota" ///
	203	"Ntchisi" ///
	204	"Dowa" ///
	205	"Salima" ///
	206	"Lilongwe Non-City" ///
	207	"Mchinji" ///
	208	"Dedza" ///
	209	"Ntcheu" ///
	210	"Lilongwe City" ///
	301	"Mangochi" ///
	302	"Machinga" ///
	303	"Zomba Non-City" ///
	304	"Chiradzulu" ///
	305	"Blantyre Non-City" ///
	306	"Mwanza" ///
	307	"Thyolo" ///
	308	"Mulanje" ///
	309	"Phalombe" ///
	310	"Chikwawa" ///
	311	"Nsanje" ///
	312	"Balaka" ///
	313	"Neno" ///
	314	"Zomba City" ///
	315	"Blantyre City"
	lab val district dis

* Merge in market variable	
merge m:1 district using market_match, keepusing(district_name market market_no)
	tab district if _merge==1
	
		// Unmatched markets are the urban areas where we do not have price data
		// And also Neno district
			distinct case_id if district==313 // 5 households
			unique case_id data_round if district==313 // These are all different households
	
	// Unmatched to market: drop urban markets (& Neno district if it cannot be matched to a market)
	unique HHID case_id y2_hhid y3_hhid PID if _merge==1
	distinct HHID case_id y2_hhid y3_hhid PID if _merge==1
	gen dropurban=1 if _merge==1
		replace dropurban=0 if dropurban==.
			drop _merge
	unique HHID case_id y2_hhid y3_hhid
	distinct HHID case_id y2_hhid y3_hhid PID

	tab market
	tab market_no
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

order district_name market market_no, after(district)

// PART 5 // Survey Weights
* Survey weights
tab data_round
bys data_round: sum hh_wgt panelweight*
	* Note hh_wgt and panelweight in 2010 and 2013 data need to be replaced
	* Per World Bank guidance, use rereleased weights from the 2016 dataset
sort PID data_round 
	// Use rereleased survey weights from 2016 dataset for all rounds
		* note the old 2013 weights were dropped by the hh_wgt variable from earlier rounds is still present but incorrect
replace hh_wgt=. if data_round!=3 // baseline weights recorded in 2010 & 2013
drop panelweight // 2013 weights

gen pweight1=hh_wgt if data_round==3
gen pweight2=panelweight_2013 if data_round==3
gen pweight3=panelweight_2016 if data_round==3
egen pweight11=total(pweight1), by(PID)
egen pweight22=total(pweight2), by(PID)
egen pweight33=total(pweight3), by(PID)
gen pweight=.
	replace pweight=pweight11 if data_round==1
	replace pweight=pweight22 if data_round==2
	replace pweight=pweight33 if data_round==3
	// Preserve round-specific weights for multilevel model
	rename (pweight11 pweight22 pweight33) (pweight_r1 pweight_r2 pweight_r3)
	order pweight*, after(y3_hhid)
	bys data_round: sum pweight
	sum pweight if pweight==.
	drop pweight1 pweight2 pweight3 ///
		pweight_r1 pweight_r2 pweight_r3 ///
		panelweight_2016 panelweight_2013 hh_wgt

* Strata - Urban and Rural only after reduced EA's
bys data_round: tabstat stratum reside baseline_rural, stats(N)
tab reside, m nolabel
sum PID
tab market if reside==1 // Note IHPS classifies some households as urban who reside nearest rural markets (boma markets)

* Set survey
svyset ea_id [pweight=pweight], strata(reside) singleunit(centered)

* Save weights and geographic variables dataset
preserve
	keep pweight case_id HHID y2_hhid y3_hhid ea_id reside  ///
		district district_name ta_code region market market_no ///
		data_round year month date_consump
			// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (first) pweight ea_id reside district district_name ///
				market market_no ta_code year month date_consump region, ///
				by(case_id HHID y2_hhid y3_hhid data_round)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
	save HH_pweights, replace
restore
save HH+Indiv_merged_individ_markets, replace

// PART 6 // OTHER SOCIODEMOGRAPHIC VARIABLES
use HH+Indiv_merged_individ_markets, clear
* Household size 
bys data_round: tab hhsize
rename hhsize hhsize_rptd
lab var hhsize_rptd "Reported household size - collected in rounds 2 and 3 only"
cap destring PID, replace
unique PID data_round
unique case_id HHID y2_hhid y3_hhid
distinct case_id HHID y2_hhid y3_hhid
preserve
	bys case_id HHID y2_hhid y3_hhid data_round: egen hhsize=count(PID)
	tab hhsize
		// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (first) hhsize, by(case_id HHID y2_hhid y3_hhid data_round)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
	tempfile hhsize
		save `hhsize', replace
restore
merge m:1 case_id HHID y2_hhid y3_hhid data_round using `hhsize'
drop _merge 

* Education 
	// Education variables
	describe hh_c06 hh_c08 hh_c09 hh_b21 hh_b04
	foreach v in hh_c06 hh_c08 hh_c09 hh_b21 hh_b04 {
		tab `v'
		tab `v', nolabel
		}
	misstable sum hh_c06 hh_c08 hh_c09 hh_b21 hh_b04
		* Ever attended school
		recode hh_c06 (2=0)
		lab def yesno 0 "No" 1 "Yes", replace
		lab val hh_c06 yesno
		* Highest grade
		tab hh_c08 if hh_b04==1
		tab hh_c08 if hh_b04==1, nolabel
		* New education variable including 0 as none
		cap drop education
		gen education=.
			replace education=0 if hh_c06==0
			replace education=hh_c08 if hh_c08!=.
				// Note only completing preschool is counted as 0 years education
		tab education, m
		tab education if hh_b04==1, m // Head
		tab education if hh_b04==2, m // Spouse

		tempvar head_ed_t
			gen `head_ed_t'=.
				replace `head_ed_t'=education if hh_b04==1
			bys HHID case_id y2_hhid y3_hhid data_round: egen head_ed=total(`head_ed_t')
		tempvar sp_ed_t
			gen `sp_ed_t'=.
				replace `sp_ed_t'=education if hh_b04==2
			bys HHID case_id y2_hhid y3_hhid data_round: egen spouse_ed=total(`sp_ed_t')
		lab var spouse_ed "Spouse Education (Years)"
		lab var head_ed "Head Education (Years)"

* Household Dependency Ratios
preserve
	* Collapse out assets
		// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (first) sex age_rptd case_id HHID y2_hhid y3_hhid ///
			hhxround, by(PID data_round)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
	sum PID
	tab age_rptd
	sum PID if (age_rptd<14 | age_rptd>=70)
	sum PID if (age_rptd>=14 & age_rptd<70)
		tempvar dependent
			gen `dependent'=1 if (age_rptd<15 | age_rptd>64)
			replace `dependent'=0 if (age_rptd>=15 & age_rptd<=64)
			tab `dependent'
		tempvar workingage
			gen `workingage'=`dependent'
			recode `workingage' (1=0) (0=1)
			tab `workingage'
		tempvar tot_dep
				egen `tot_dep'=total(`dependent'), by(hhxround)
				sum `tot_dep', d
		tempvar tot_wa
				egen `tot_wa'=total(`workingage'), by(hhxround)
				sum `tot_wa', d
	bys hhxround: gen dependency_ratio=(`tot_dep'/`tot_wa')
	lab var dependency_ratio "Dependency Ratio (<15 or >64 defined as dependent)"
	tab dependency_ratio
	* Generate Female : Male working age adults ratio
	tab sex if `workingage'==1
		tempvar males
			gen `males'=sex
			recode `males' (0=1) (1=0)
			tab `males'
		tempvar tot_males
			egen `tot_males'=total(`males') if `workingage'==1, by(hhxround)
			sum `tot_males', d
		tempvar tot_females
			egen `tot_females'=total(sex) if `workingage'==1, by(hhxround)
			sum `tot_females', d
	by hhxround: gen fem_male_ratio=`tot_females'/`tot_males'
	lab var fem_male_ratio "Female-to-Male working age (15-64) adult ratio"
	tab fem_male_ratio
	sum fem_male_ratio, d
		// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (first) *ratio, by(case_id HHID y2_hhid y3_hhid data_round hhxround)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
		tempfile hhdepratio
			save `hhdepratio', replace
restore
merge m:1 case_id HHID y2_hhid y3_hhid data_round hhxround using `hhdepratio'
drop _merge

* Label for tables
lab var hhsize "Household size"
lab var head_ed "Head Education (Years completed)"
lab var spouse_ed "Spouse Education (Years completed)"

* Urban households coded to rural markets
tab reside
tab reside, nolabel

save HH+Indiv, replace  

// PART 8 // ASSET BASED WEALTH INDEX
use HH_10_Assets, clear
append using HH_13_Assets, force
append using HH_16_Assets, force
* Explore data
	describe
	tab hh_l02, sum(hh_l03)
	tabstat hh_l03, stats(mean n min max sd) by(hh_l02) 
	tab hh_l02, nolabel
	* recode asset 5081 to 508 - it is a radio with capabilities of CD player
	replace hh_l02=508 if hh_l02==5081

* Replace quantity of 0 for assets not owned
	tab hh_l01, m 
	replace hh_l03=0 if hh_l03==. & hh_l01==2
	tab hh_l01 if hh_l03==. // 5 Items owned with no quantity recorded
		tab hh_l02 if hh_l01==1 & hh_l03==.
			// assume HH owns 0 if no quantity specified
			replace hh_l03=0 if hh_l01==1 & hh_l03==.
			
// RURAL
* Identify assets owned by >5% of households for inclusion
		unique case_id HHID y2_hhid y3_hhid if reside==2
		di `r(unique)'*.05
		local fivepct=round(`r(unique)'*.05)
			di `fivepct'
		bys hh_l02: sum hh_l03 if reside==2
		cap drop num_hh_owning_rur
		egen num_hh_owning_rur=count(hh_l02) if hh_l03>0 & reside==2 ///
			& hh_l03!=., by(hh_l02)
			tab hh_l02 if reside==2, sum(num_hh_owning_rur)
		unique case_id HHID y2_hhid y3_hhid if reside==2
		di `r(unique)'*.05
		local fivepct=round(`r(unique)'*.05)
			di `fivepct'
		gen asset_included_rural=1 if num_hh_owning_rur>=`fivepct' & num_hh_owning_rur!=. 
			replace asset_included_rural=0 if (num_hh_owning_rur<`fivepct'  ///
				| num_hh_owning_rur!=.) & asset_included_rural==. 
			tab hh_l02 if reside==2, sum(asset_included_rural)
			tab asset_included_rural if reside==2
			// Assets included and number owning each
			tab hh_l02 if asset_included_rural==1 & reside==2, sum(num_hh_owning_rur)
			replace hh_l03=. if reside==2 & asset_included_rural==0		
		// Summary statistics
		tab hh_l02 data_round if asset_included_rural==1 & reside==2
		tabstat hh_l03 if asset_included_rural==1 & reside==2, ///
			stats(n mean sd) by(hh_l02) // Note this is unweighted
		tabstat HQ* if reside==2, stats(n mean sd) // toilet to be excluded for rural

// URBAN
* Identify assets owned by >5% of households for inclusion
		unique case_id HHID y2_hhid y3_hhid if reside==1
		di `r(unique)'*.05
		local fivepct=round(`r(unique)'*.05)
			di `fivepct'
		bys hh_l02: sum hh_l03 if reside==1
		cap drop num_hh_owning_urb
		egen num_hh_owning_urb=count(hh_l02) if hh_l03>0 & reside==1 ///
			& hh_l03!=., by(hh_l02)
			tab hh_l02 if reside==1, sum(num_hh_owning_urb)
		unique case_id HHID y2_hhid y3_hhid if reside==1
		di `r(unique)'*.05
		local fivepct=round(`r(unique)'*.05)
			di `fivepct'
		gen asset_included_urban=1 if num_hh_owning_urb>=`fivepct' & num_hh_owning_urb!=. 
			replace asset_included_urban=0 if (num_hh_owning_urb<`fivepct'  ///
				| num_hh_owning_urb!=.) & asset_included_urban==. 
			tab hh_l02 if reside==1, sum(asset_included_urban)
			tab asset_included_urban if reside==1
			// Assets included and number owning each
			tab hh_l02 if asset_included_urban==1 & reside==1
			replace hh_l03=. if reside==1 & asset_included_urban==0		

		// Summary statistics
		tab hh_l02 data_round if asset_included_urban==1 & reside==1
		tabstat hh_l03 if asset_included_urban==1 & reside==1, ///
			stats(n mean sd) by(hh_l02) // Note this is unweighted
		tabstat HQ* if reside==1, stats(n mean sd)

preserve
keep case_id HHID y2_hhid y3_hhid hh_l* asset_included* HQ* ///
	num_hh_owning* reside ea_id district ta_code region
save HHAssets, replace
restore
	* Generate dummy variable for each asset
		tab hh_l02, sum(hh_l03)
		tab hh_l02, sum(hh_l02)
		tab hh_l02, gen(asset)
		// Recode asset labels to 1-32 (from 501-532) to match asset dummies
		describe hh_l02
		lab val hh_l02 .
		tostring hh_l02, replace format(%03.0f)
		tab hh_l02
		gen asset_label=real(substr(hh_l02,2,2))
		tab asset_label
			tab hh_l02, sum(asset_label)
			tab2 hh_l02 asset_label
			tab hh_l02 if asset_included_rural==1, sum(asset_label)
			tab hh_l02 if asset_included_urban==1, sum(asset_label)
preserve			
// RURAL
keep if reside==2 
* Generate new standardized values for asset ownership
	forval i=1/32 {
		gen asset`i'_mean=.
		gen asset`i'_sd=.
		}
	forval i=1/32 {
		sum hh_l03 if asset_label==`i'
		replace asset`i'_mean=`r(mean)' if asset_label==`i' 
		replace asset`i'_sd=`r(sd)' if asset_label==`i'
		}
	forval i=1/32 {
		gen z_asset`i'=((hh_l03-asset`i'_mean)/asset`i'_sd) ///
			if asset_label==`i' 
		}
	* Housing 
		sum HQtoilet
		gen asset33_mean=`r(mean)' 
		gen asset33_sd=`r(sd)'
		gen z_asset33=((HQroof-asset33_mean)/asset33_sd) 

		sum HQroof 
		gen asset34_mean=`r(mean)' 
		gen asset34_sd=`r(sd)'
		gen z_asset34=((HQroof-asset34_mean)/asset34_sd) 
		
		sum HQwall 
		gen asset35_mean=`r(mean)' 
		gen asset35_sd=`r(sd)'
		gen z_asset35=((HQwall-asset35_mean)/asset35_sd) 
		
		sum HQfloor 
		gen asset36_mean=`r(mean)' 
		gen asset36_sd=`r(sd)'
		gen z_asset36=((HQfloor-asset36_mean)/asset36_sd) 

	sum z_asset*
	* Drop excluded for <5% owning
	tab hh_l02, sum(asset_included_rural)
	drop *asset5* *asset6* *asset10* *asset11* *asset12* *asset13* *asset14* *asset15* 
	drop *asset17* *asset18* *asset19* *asset20* *asset21* *asset24* *asset26*
	drop *asset29* *asset30* *asset32* *asset33*
	
	* Collapse to HH level
		// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (firstnm) *asset* reside, by(case_id HHID y2_hhid y3_hhid data_round)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
	
	* Asset-based wealth index
	sum z_asset*
	order z_asset*, first
	alpha z_asset*, asis
	correlate z_asset*, covariance
	pca z_asset*, components(1) cov
	cap drop wealth
	predict wealth
	sum wealth
	lab var wealth "Wealth (Asset index)"
	sktest wealth
	kdensity wealth
		graph export "kdensity_wealth_rural.png", replace
	xtile wealth_quintile=wealth, nq(5)
		* Label wealth quintiles          
		lab def wealth 1 "Poorest" 2 "Second quintile" 3 "Middle" 4 "Fourth quintile" 5 "Wealthiest"
		lab val wealth_quintile wealth
order case_id HHID y2_hhid y3_hhid data_round, first
cap drop _merge
	tempfile wealth_rural
	save `wealth_rural', replace
restore
	
// URBAN
keep if reside==1 
* Generate new standardized values for asset ownership
	forval i=1/32 {
		gen asset`i'_mean=.
		gen asset`i'_sd=.
		}
	forval i=1/32 {
		sum hh_l03 if asset_label==`i'
		replace asset`i'_mean=`r(mean)' if asset_label==`i' 
		replace asset`i'_sd=`r(sd)' if asset_label==`i'
		}
	forval i=1/32 {
		gen z_asset`i'=((hh_l03-asset`i'_mean)/asset`i'_sd) ///
			if asset_label==`i' 
		}
	* Housing 
		sum HQtoilet
		gen asset33_mean=`r(mean)' 
		gen asset33_sd=`r(sd)'
		gen z_asset33=((HQroof-asset33_mean)/asset33_sd) 

		sum HQroof 
		gen asset34_mean=`r(mean)' 
		gen asset34_sd=`r(sd)'
		gen z_asset34=((HQroof-asset34_mean)/asset34_sd) 
		
		sum HQwall 
		gen asset35_mean=`r(mean)' 
		gen asset35_sd=`r(sd)'
		gen z_asset35=((HQwall-asset35_mean)/asset35_sd) 
		
		sum HQfloor 
		gen asset36_mean=`r(mean)' 
		gen asset36_sd=`r(sd)'
		gen z_asset36=((HQfloor-asset36_mean)/asset36_sd) 

	sum z_asset*
	* Drop excluded for <5% owning
	tab hh_l02, sum(asset_included_urban)
	drop *asset6* *asset10* *asset11* *asset12* *asset15* *asset17* *asset19* 
	drop *asset20* *asset21* *asset26* *asset31* *asset32* 
	
	* Collapse to HH level
		// Save labels
		foreach v of var * {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
		// Collapse
		collapse (firstnm) *asset* reside, by(case_id HHID y2_hhid y3_hhid data_round)
		// Relabel
		foreach v of var * {
			label var `v' "`l`v''"
			}
	
	* Asset-based wealth index
	sum z_asset*
	order z_asset*, first
	alpha z_asset*, asis
	correlate z_asset*, covariance
	pca z_asset*, components(1) cov
	cap drop wealth
	predict wealth
	sum wealth
	lab var wealth "Wealth (Asset index)"
	sktest wealth
	kdensity wealth
		graph export "kdensity_wealth_urban.png", replace
	xtile wealth_quintile=wealth, nq(5)
		* Label wealth quintiles          
		lab def wealth 1 "Poorest" 2 "Second quintile" 3 "Middle" 4 "Fourth quintile" 5 "Wealthiest"
		lab val wealth_quintile wealth
order case_id HHID y2_hhid y3_hhid data_round, first
cap drop _merge
	append using `wealth_rural'
	* double check sample size
	bys data_round: distinct case_id HHID y2_hhid y3_hhid 
tab wealth_quintile
tab2 wealth_quintile reside
	
save HH_wealth, replace

* Merge into HH+Indiv
use HH+Indiv, clear
cap drop _merge
merge m:1 case_id HHID y2_hhid y3_hhid data_round ///
	using HH_wealth, keepusing(wealth*)
	drop if _merge==2 // Urban markets
	drop _merge
	
* Summarize sample size 
cap drop _*
unique HHID case_id y2_hhid y3_hhid PID
distinct HHID case_id y2_hhid y3_hhid PID

save HH+Indiv, replace 

* Save reduced dataset for CoNA calculation
	// Drop Urban Households
	drop if dropurban==1
saveold HH+Indiv_oldstata, replace

log close

