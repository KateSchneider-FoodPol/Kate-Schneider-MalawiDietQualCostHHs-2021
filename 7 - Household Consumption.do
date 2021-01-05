/*
Kate Schneider
kate.schneider@tufts.edu
Replication files for Kate Schneider 2021 PhD Thesis
Last modified: 3 Jan 2020
Purpose: 
	1. Determine nutrient composition of reported food consumption
	2. Calculate adequacy ratios of consumption relative to needs
	3. Calculate total food expenditure
	4. Calculate total expenditure (consumption aggregate)
*/

// PART 0 // FILE MANAGEMENT
global ihpsraw "MWI_IHPS_2010-2013-2016"
global otherrawdata "datafolder"
global analysis "workingfolder"
global nutrients energy carbohydrate protein lipids vitA retinol vitC vitE thiamin ///
	riboflavin niacin vitB6 folate vitB12 calcium copper iron magnesium ///
	phosphorus selenium zinc sodium

* Working directory
cd "$analysis"
cap log close
log using "07_Household Consumption_`c(current_date)'", replace
***Log of Do File #7 "07 Household Food Consumption, Nutrient Adequacy, and Consumption Aggregate"
di "`c(current_date)' `c(current_time)'"

// PART 1 // MERGE DATAFILES

*Merge identifiers into consumption datasets
use "$ihpsraw\hh_mod_g1_10.dta", clear 
	encode qx_type, gen(qx_type2)
	drop qx_type
	rename qx_type2 qx_type
	destring case_id, replace
merge m:1 HHID case_id qx_type ea_id using HH_10, force
drop _merge
keep HHID case_id hh_g* year month date_consump data_round
tempfile GHH_10
		save `GHH_10', replace

use "$ihpsraw\hh_mod_g1_13.dta", clear
merge m:1 qx_type y2_hhid using HH_13, force
tab dateg
drop _merge
keep HHID case_id y2_hhid hh_g* year month date_consump data_round district
tempfile GHH_13
		save `GHH_13', replace

use "$ihpsraw\hh_mod_g1_16.dta", clear 
merge m:1 y3_hhid qx_type using HH_16, force
drop _merge
keep HHID case_id y2_hhid y3_hhid hh_g* year month date_consump data_round district
tempfile GHH_16
		save `GHH_16', replace

* Merge all 3 years 
use `GHH_10', clear
append using `GHH_13'
	sort case_id HHID  y2_hhid
append using `GHH_16'
	sort case_id HHID  y2_hhid y3_hhid data_round
order HHID case_id y2_hhid y3_hhid data_round year month ///
	date_consump hh_g01 hh_g02 hh_g03a ///
	hh_g03b hh_g04a hh_g04b hh_g06a hh_g06b hh_g07a hh_g07b, first

* Merge in region
preserve 
	use HH+Indiv, clear
	keep HHID case_id data_round y2_hhid y3_hhid district region ///
		district_name hh_a02b ea_id reside market market_no ta_code ///
		year month date_consump pweight dropurban
	collapse (first) district region district_name hh_a02b ea_id ///
		reside market market_no ta_code pweight dropurban ///
		year month date_consump, by(HHID case_id data_round y2_hhid y3_hhid)
	unique HHID case_id data_round y2_hhid y3_hhid
	tempfile region
		save `region', replace
restore
merge m:1 HHID case_id data_round y2_hhid y3_hhid using `region'
tab district if _merge==1
unique case_id HHID y2_hhid y3_hhid data_round if _merge==1
bys data_round: distinct case_id
drop _merge
save HHFoodConsumption, replace

// PART 2 // CODE FOOD ITEMS CONSUMED TO MATCH WITH FCT
use HHFoodConsumption, clear

* check change in variable for others across rounds
foreach v in hh_g03b_os hh_g04b_os hh_g06b_os hh_g07b_os hh_g03b_label ///
	hh_g03b_oth hh_g04b_label hh_g04b_oth hh_g06b_label hh_g06b_oth ///
	hh_g07b_label hh_g07b_oth {
		tab `v' data_round
		}
	// NOTE no "others" recorded in round 2 (panel only), confirmed in raw data

describe

* Recode consumed item to binary dummy
	tab hh_g01, m
	tab hh_g01, m nolabel // Consumed item
	recode hh_g01 (2=0)
	* browse if hh_g01==.
	drop if hh_g01==.
	lab def yesno 0 "No" 1 "Yes", replace
	lab val hh_g01 yesno
	
* Label foods added after baseline
tab hh_g02
cap lab drop foods
lab def foods ///
	100 "Cereals, Grains and Cereal Products" ///
	101 "Maize ufa mgaiwa (normal flour)" ///
	102 "Maize ufa refined (fine flour)" ///
	103 "Maize ufa madeya (bran flour)" ///
	104 "Maize grain (not as ufa)" ///
	105 "Green maize" ///
	106 "Rice" ///
	107 "Finger millet (mawere)" ///
	108 "Sorghum (mapira)" ///
	109 "Pearl millet (mchewere)" ///
	110 "Wheat flour" ///
	111 "Bread" ///
	112 "Buns, scones" ///
	113 "Biscuits" ///
	114 "Spaghetti, macaroni, pasta" ///
	115 "Breakfast cereal (Corn Flakes value used as reference)" ///
	116 "Infant feeding cereals" ///
	117 "Other (specify)" ///
	200 "Roots, Tubers, and Plantains" ///
	201 "Cassava tubers" ///
	202 "Cassava flour" ///
	203 "White sweet potato" ///
	204 "Orange sweet potato" ///
	205 "Irish potato" ///
	206 "Potato crisps" ///
	207 "Plantain, cooking banana" ///
	208 "Cocoyam (masimbi)" ///
	209 "Other (specify)" ///
	300 "Nuts and Pulses" ///
	301 "Bean, white" ///
	302 "Bean, brown" ///
	303 "Pigeonpea (nandolo)" ///
	304 "Groundnut" ///
	305 "Groundnut flour" ///
	306 "Soyabean flour" ///
	307 "Ground bean (nzama) (Pigeon pea flour value used as closest match)" ///
	308 "Cowpea (khobwe)" ///
	309 "Macademia nuts" ///
	310 "Other (specify)" ///
	311 "Groundnut (shelled)" ///
	312 "Groundnut (unshelled)" ///
	313 "Groundnut fresh (unshelled)" ///
	400 "Vegetables" ///
	401 "Onion" ///
	402 "Cabbage" ///
	403 "Rape (tanoposi)" ///
	404 "Pumpkin leaves (nkhwani)" ///
	405 "Chinese cabbage (pe-tsai)" ///
	406 "Other cultivated green leafy vegetables (Rape values used as reference)" ///
	407 "Gathered wild green leaves (Bonongwe/Amaranth values used as reference)" ///
	408 "Tomato" ///
	409 "Cucumber" ///
	410 "Pumpkin" ///
	411 "Okra / Therere" ///
	412 "Tinned vegetables (Specify)" ///
	413 "Mushroom" ///
	414 "Other vegetables (Specify)" ///
	500 "Meat, Fish and Animal products" ///
	501 "Eggs" ///
	502 "Dried fish (Rhamphochromis esox [native lake chiclid] value used as reference)" ///
	503 "Fresh fish (Oreochromis shiranus [chambo] used as reference)" ///
	504 "Beef" ///
	505 "Goat" ///
	506 "Pork" ///
	507 "Mutton" ///
	508 "Chicken" ///
	509 "Other poultry - guinea fowl, doves, etc. (Quail values used as reference)" ///
	510 "Small animal - rabbit, mice, etc. (rabbit values used as reference)" ///
	511 "Termites, other insects (eg Ngumbi, caterpillar)" ///
	512 "Tinned meat or fish" ///
	513 "Smoked fish (Rhamphochromis esox [native lake chiclid] value used as reference)" ///
	514 "Fish Soup/Sauce" ///
	515 "Other (specify)" ///
	522 "Chicken/Pieces" ///
	600 "Fruits" ///
	601 "Mango" ///
	602 "Banana" ///
	603 "Citrus - naartje, orange, etc. (Tangerine values used as reference)" ///
	604 "Pineapple" ///
	605 "Papaya" ///
	606 "Guava" ///
	607 "Avocado" ///
	608 "Wild fruit (masau, malambe, etc.) (Loquat [macau] value used as reference)" ///
	609 "Apple" ///
	610 "Other fruits (specify)" ///
	700 "Milk and Milk Products" ///
	701 "Fresh milk" ///
	702 "Powdered milk" ///
	703 "Margarine - Blue band" ///
	704 "Butter" ///
	705 "Chambiko - soured milk" ///
	706 "Yoghurt (Sweetened value used as reference)" ///
	707 "Cheese (Cheddar value used as reference)" ///
	708 "Infant feeding formula (for bottle)" ///
	709 "Other (specify)" ///
	800 "Sugar, Fats, and Oil" ///
	801 "Sugar (Fortified value used as reference)" ///
	802 "Sugar Cane" ///
	803 "Cooking oil (Fortified value used as reference)" ///
	804 "Other (specify)" ///
	809 "Spices & Miscellaneous" ///
	810 "Salt" ///
	811 "Spices" ///
	812 "Yeast, baking powder, bicarbonate of soda" ///
	813 "Tomato sauce (bottle) (Ketchup value used as reference)" ///
	814 "Hot sauce (Nali, etc.)" ///
	815 "Jam, jelly" ///
	816 "Sweets, candy, chocolates" ///
	817 "Honey" ///
	818 "Other (specify)" ///
	819 "Cooked Foods from Vendors" ///
	820 "Maize - boiled or roasted (vendor)" ///
	821 "Chips (vendor)" ///
	822 "Cassava - boiled (vendor)" ///
	823 "Eggs - boiled (vendor)" ///
	824 "Chicken (vendor)" ///
	825 "Meat (vendor) (Beef values used as reference)" ///
	826 "Fish (vendor)" ///
	827 "Mandazi, doughnut (vendor)" ///
	828 "Samosa (vendor)" ///
	829 "Meal eaten at restaurant" ///
	830 "Other (specify)" ///
	831 "Boiled sweet potatoes (White value used as reference)" ///
	832 "Roasted sweet potatoes (White value used as reference)" ///
	833 "Boiled groundnuts" ///
	834 "Roasted groundnuts" ///
	835 "Popcorn" ///
	836 "Banana amd maize cake (zikondamoyo/nkate)" ///
	837 "Other(specify)" ///
	838 "Cassava - roasted (vendor)" ///
	900 "Beverages" ///
	901 "Tea" ///
	902 "Coffee" ///
	903 "Cocoa, millo" ///
	904 "Squash (Sobo drink concentrate)" ///
	905 "Fruit juice" ///
	906 "Freezes (flavoured ice)" ///
	907 "Soft drinks (Coca-cola, Fanta, Sprite, etc.)" ///
	908 "Chibuku (commercial traditional-style beer)" ///
	909 "Bottled water" ///
	910 "Maheu" ///
	911 "Bottled / canned beer (Carlsberg, etc.)" ///
	912 "Thobwa (fermented cereal-based drink)" ///
	913 "Traditional beer (masese)" ///
	914 "Wine or commercial liquor" ///
	915 "Locally brewed liquor (kachasu)" ///
	916 "Other (specify)" ///
	5021 "Sun Dried fish (Large Variety) (Oreochromis shiranus [chambo] value used as reference)" ///
	5022 "Sun Dried fish (Medium Variety) (Rhamphochromis esox [native lake chiclid] value used as reference)" ///
	5023 "Sun Dried fish (Small Variety) (Copadichromis inornatus [utaka] value used as reference)" ///
	5031 "Fresh fish (Large Variety) (Oreochromis shiranus [chambo] value used as reference)" ///
	5032 "Fresh fish (Medium Variety) (Rhamphochromis ferox [native lake chiclid] value used as reference)" ///
	5033 "Fresh fish (Small Variety) (Copadichromis inornatus [utaka] value used as reference)" ///
	5121 "Smoked fish (Large Variety) (Oreochromis lidole, [chambo] value used as reference)" ///
	5122 "Smoked fish (Medium Variety) (Rhamphochromis esox [native lake chiclid] value used as reference)" ///
	5123 "Smoked fish (Small Variety) (Copadichromis inornatus [utaka] value used as reference)", replace
lab val hh_g02 foods
tab hh_g02
tab hh_g02 if inlist(hh_g02,100,200,300,400,500,600,700,800,809,819,900)
drop if inlist(hh_g02,100,200,300,400,500,600,700,800,809,819,900) // Headings

* Document consumption of foods that are not included in analysis
tab hh_g01 if hh_g02==708  // Infant formula: N=1
tab hh_g01 if hh_g02==829 // Restaurant meal: N=86
tab hh_g01 if hh_g02==910 // Maheu - lacks food composition data: N=53
gen foodexcluded=1 if inlist(hh_g02, 708,829,910)
	replace foodexcluded=0 if foodexcluded==.

* Code "Others" as possible to matching food or nearest match if defensibly nutritionally similar
tab hh_g02_os if (hh_g02_os!="." | hh_g02_os!="")
tab hh_g01_oth if (hh_g01_oth!="." | hh_g01_oth!="")
	replace hh_g02=831 if hh_g02_os=="BOILED SWEET POTATO"
	replace hh_g02=407 if hh_g02_os=="BONONGWE" | hh_g02_os=="CASSAVA LEAVES" ///
		| hh_g02_os=="POTATO LEAVES"
	replace hh_g02=522 if hh_g02_os=="CHICKEN PIECES"
	replace hh_g02=405 if hh_g02_os=="CHINESE"
	replace hh_g02=509 if hh_g02_os=="DUCK" 
	replace hh_g02=510 if hh_g02_os=="GOAT OFFALS" 
	replace hh_g02=827 if hh_g02_os=="MANDAZI" 
	replace hh_g02=5023 if hh_g02_os=="UTAKA (DRY)" 
	replace hh_g02=308 if hh_g01_oth=="COW PEAS" 
	replace hh_g02=107 if hh_g01_oth=="FINGERMILLETFLOUR" 
	replace hh_g02=101 if hh_g01_oth=="GRAINMILLUFA" 
	replace hh_g02=511 if hh_g01_oth=="GRASSHOPPERS" 
	replace hh_g02=708 if hh_g01_oth=="LIKUNOPHALA" 
	replace hh_g02=306 if hh_g01_oth=="SOYA" | hh_g01_oth=="SOYA PIECES" 
	replace hh_g02=914 if hh_g01_oth=="WINE" | hh_g01_oth=="SPIRITS" 
	replace hh_g02=911 if hh_g01_oth=="SACHETSBEER" 

* Combine other item variables renamed over rounds
describe hh_g01_oth
tab hh_g01_oth data_round
tab hh_g02_os data_round
replace hh_g02_os=hh_g01_oth if hh_g01_oth!="" & data_round==3
drop hh_g01_oth
replace hh_g03b_os=hh_g03b_oth if data_round==3 
replace hh_g04b_os=hh_g04b_oth if data_round==3 
replace hh_g06b_os=hh_g06b_oth if data_round==3 
replace hh_g07b_os=hh_g07b_oth if data_round==3 
drop hh_g0*b_oth

// Reshape long for food item by source
* Rename quantity and unit variables 
rename (hh_g03a hh_g04a hh_g06a hh_g07a) qty#, addnumber
rename (hh_g03b hh_g04b hh_g06b hh_g07b) unit#, addnumber
rename (hh_g03b_os hh_g04b_os hh_g06b_os hh_g07b_os) other_unit#, addnumber
rename (hh_g03b_label hh_g04b_label hh_g06b_label hh_g07b_label) unitlabel#, addnumber
rename (hh_g03c hh_g04c hh_g06c hh_g07c) subunit#, addnumber

* Drop repeat food items
	sort case_id HHID y2_hhid y3_hhid data_round hh_g02
	duplicates tag case_id HHID y2_hhid y3_hhid data_round hh_g02, gen(dups)
	tab dups
	list hh_g02 qty* *unit* if dups>=1
		drop if qty1==. & qty2==. & qty3==. & qty4==. & dups>=1 // Some have no quantity listed
		list HHID data_round hh_g02 qty* *unit* dups if dups>=1
		* Relabel duplicates tag after dropping the empty records
		replace dups=0 if HHID==271 & data_round==1 & dups==1
		replace dups=0 if HHID==306 & data_round==1 & dups==1
		replace dups=0 if HHID==613 & data_round==3 & dups==1
		replace dups=0 if HHID==1334 & data_round==1 & dups==1
		replace dups=0 if HHID==1670 & data_round==1 & dups==1
		replace dups=0 if HHID==2286 & data_round==3 & dups==1
		replace dups=0 if HHID==2470 & data_round==1 & dups==1
		replace dups=0 if HHID==2531 & data_round==3 & dups==1
		replace dups=0 if HHID==2552 & data_round==1 & dups==1
		replace dups=0 if HHID==2767 & data_round==1 & dups==1
		replace dups=0 if HHID==2960 & data_round==3 & dups==1
		replace dups=0 if HHID==3139 & data_round==3 & dups==1
		* Check remaining duplicates
		list HHID data_round hh_g02 qty* *unit* dups if dups>=1
			// Soyabean flour - both listed in nonstandard units, combine and note
			replace qty1=6 if HHID==484 & data_round==3 & dups==1 ///
				& unit1=="51"
			replace qty3=2 if HHID==484 & data_round==3 & dups==1 ///
				& unit1=="51"
			replace other_unit1="combined unit 51 & 25B" if HHID==484 & data_round==3 & dups==1 ///
				& unit1=="51"
			drop if HHID==484 & data_round==3 & dups==1 ///
				& unit1=="25B"
			// Beer - unspecified other unit, drop
			drop if HHID==1645 & data_round==3 & dups==1 & unit1=="23"
			// Chinese cabbage in 2 different units - drop the nonstandard
			drop if HHID==1775 & data_round==1 & dups==1 & unit1=="17"
			drop dups
* Reshape long for food item by source
reshape long qty unit unitlabel other_unit subunit, i(HHID case_id y2_hhid y3_hhid data_round date_consump hh_g02) j(source)
	lab def source 1 "Total" 2 "Buy" 3 "Own production" 4 "Gift/other"
	lab val source source
	lab var source "Source"

tab unit 
tab other_unit
	// Replace Round 2 Codes to eliminate the 0 in front and match other rounds
	forval n=1/10 {
		foreach v in unit other_unit {
			replace `v'="`n'" if `v'=="0`n'"
			replace `v'="`n'A" if `v'=="0`n'A"
			replace `v'="`n'B" if `v'=="0`n'B"
			replace `v'="`n'C" if `v'=="0`n'C"
			}
		}
	
	// Drop if item was not consumed
	tab hh_g02 if hh_g01==0, sum(qty) // 39 records say none eating with a non-zero quantity
	replace hh_g01=1 if qty!=0 & qty!=. // 20 changes made
	tab hh_g02 if hh_g01==0, sum(qty) // remaining 19 list 0 quantity
	drop if hh_g01==0
	tab hh_g02 if hh_g01==1 & qty==. | qty==0
	drop if qty==. | qty==0
	
* Units
tab unit
tab unitlabel
tab2 unit unitlabel
bys unit: tab other_unit // confirm all others do not have standard codes
tab other_unit

// Code other units into standard where possible
tab other_unit
replace unit="18" if other_unit=="(400G)PACKETS" | other_unit=="400GRAMSPACKET" | other_unit=="TIN400G"
	replace qty=qty*400 if other_unit=="(400G)PACKETS" | other_unit=="400GRAMSPACKET" | other_unit=="TIN400G"
replace unit="1" if other_unit=="1 KG" | other_unit=="KILOGRAM"
replace unit="18" if other_unit=="10GPACKET"
	replace qty=qty*10 if other_unit=="10GPACKET"
replace unit="18" if other_unit=="150G" | other_unit=="PACKET 150 GRAM" | other_unit=="SACHET (150 GRAM)"
	replace qty=qty*150 if other_unit=="150G" | other_unit=="PACKET 150 GRAM" | other_unit=="SACHET (150 GRAM)"
replace unit="18" if other_unit=="1PACKET20G" | other_unit=="20GRAMPACKET" | other_unit=="SATCHET (20 GRAM)" ///
	| other_unit=="20G PACKETS" | other_unit=="20GRAMPACKET"
	replace qty=qty*20 if other_unit=="1PACKET20G" | other_unit=="20GRAMPACKET" | other_unit=="SATCHET (20 GRAM)" | other_unit=="20G PACKETS"
replace unit="22" if other_unit=="1SACHET"
replace unit="9" if other_unit=="2"
	replace qty=qty*2 if other_unit=="2"
replace unit="9" if other_unit=="23 DOZEN"
	replace qty=qty*23*12 if other_unit=="23 DOZEN"
replace unit="18" if other_unit=="250GRAMTINS" | other_unit=="CONTAINER250G" | other_unit=="SATCHET (250 GRAM)"
	replace qty=qty*250 if other_unit=="250GRAMTINS" | other_unit=="CONTAINER250G" | other_unit=="SATCHET (250 GRAM)"
replace unit="18" if other_unit=="25G"
	replace qty=qty*25 if other_unit=="25G"
replace unit="19" if other_unit=="330 ML"
	replace qty=qty*330 if other_unit=="330 ML"
replace unit="18" if other_unit=="350GRAMS"
	replace qty=qty*350 if other_unit=="350GRAMS"
replace unit="9" if other_unit=="4"
	replace qty=qty*4 if other_unit=="4"
replace unit="18" if other_unit=="450GRAM" | other_unit=="450GRAMPACKET" ///
	| other_unit=="450GRAMSPACKET"
	replace qty=qty*450 if other_unit=="450GRAM" | other_unit=="450GRAMPACKET" ///
	| other_unit=="450GRAMSPACKET"	
replace unit="18" if other_unit=="48GRAMS"
	replace qty=qty*48 if other_unit=="48GRAMS"
replace unit="22" if other_unit=="4SACHETS"
	replace qty=qty*4 if other_unit=="4SACHETS"	
replace unit="15" if other_unit=="5 LITRES" | other_unit=="5L BUCKET"
	replace qty=qty*5 if other_unit=="5 LITRES" | other_unit=="5L BUCKET"
replace unit="18" if other_unit=="50 GRAM PACKET"
	replace qty=qty*50 if other_unit=="50 GRAM PACKET"
replace unit="2" if other_unit=="50 KG" | other_unit=="K50" | other_unit=="K50PACKET"
replace unit="19" if other_unit=="500 ML" | other_unit=="500MILLITRE" | other_unit=="500MLS" ///
	| other_unit=="MILILITRES (500)" | other_unit=="500MLPACKET"
	replace qty=qty*500 if other_unit=="500 ML" | other_unit=="500MILLITRE" ///
	| other_unit=="500MLS" | other_unit=="500MLPACKET"
replace unit="18" if other_unit=="500MGTIN"
	replace qty=qty*.5 if other_unit=="500MGTIN"
replace unit="18" if other_unit=="50GPACKET"
	replace qty=qty*50 if other_unit=="50GPACKET"
replace unit="22" if other_unit=="5SACHETS"
	replace qty=qty*5 if other_unit=="5SACHETS"	
replace unit="9" if other_unit=="60"
	replace qty=qty*60 if other_unit=="60"
replace unit="18" if other_unit=="60GPACKET"
	replace qty=qty*60 if other_unit=="60GPACKET"
replace unit="9" if other_unit=="7BUNS"
	replace qty=qty*7 if other_unit=="7BUNS"
replace unit="9" if other_unit=="8SUGARCANE"
	replace qty=qty*8 if other_unit=="8SUGARCANE"
replace unit="18" if other_unit=="90GRAMES"
	replace qty=qty*90 if other_unit=="90GRAMES"
* Assume unspecified bottles are 500mL // METHOD NOTE
	* affects 261 records
replace unit="19" if other_unit=="BOTTLE"
	replace qty=qty*500 if other_unit=="BOTTLE"
	replace other_unit="BOTTLE - ASSUMED TO BE 500ML" if other_unit=="BOTTLE"
replace unit="19" if other_unit=="BOTTLEOF300ML"
	replace qty=qty*300 if other_unit=="BOTTLEOF300ML"
replace unit="18" if other_unit=="BOTTLE250G"
	replace qty=qty*250 if other_unit=="BOTTLE250G"
replace unit="8" if other_unit=="BUNDLE" | other_unit=="BUNCH (SMALL)"
replace unit="9" if other_unit=="DOZEN"
	replace qty=qty*12 if other_unit=="DOZEN"
replace unit="18" if other_unit=="GRAMS"
replace unit="10" if other_unit=="HEAP"
replace unit="10C" if other_unit=="HEAP (LARGE)" | other_unit=="HEAP(LARGE)" | other_unit=="HEAPLARGE"
replace unit="10B" if other_unit=="HEAP (MEDIUM)" | other_unit=="HEAP(MEDIUN)"
replace unit="10A" if other_unit=="HEAP (SMALL)" | other_unit=="HEAP(SMALL)"
replace unit="15" if other_unit=="LITRES"
replace unit="9" if other_unit=="MICE"
replace unit="6" if other_unit=="NO. 10 PLATE"
replace unit="18" if other_unit=="PACKET (500G)" | other_unit=="SATCHET (500 GRAM)"
	replace qty=qty*500 if other_unit=="500G" | other_unit=="SATCHET (500 GRAM)"
replace unit="18" if other_unit=="PACKET 100 GRAM" | other_unit=="PACKET100G" | other_unit=="TIN100" | other_unit=="SATCHET/TUBE (100G)"
	replace qty=qty*100 if other_unit=="PACKET 100 GRAM" | other_unit=="PACKET100G" | other_unit=="TIN100" | other_unit=="SATCHET/TUBE (100G)"
replace unit="18" if other_unit=="PACKET 200 GRAM" | other_unit=="PACKET200G"
	replace qty=qty*200 if other_unit=="PACKET 200 GRAM" | other_unit=="PACKET200G"
replace unit="18" if other_unit=="PACKET 250 GRAM" | other_unit=="TIN (250G)"
	replace qty=qty*250 if other_unit=="PACKET 250 GRAM" | other_unit=="TIN (250G)"
replace unit="18" if other_unit=="PACKET 300 GRAM" 
	replace qty=qty*300 if other_unit=="PACKET 300 GRAM"
replace unit="18" if other_unit=="PACKET 750 GRAM" 
	replace qty=qty*750 if other_unit=="PACKET 750 GRAM"
replace unit="19" if other_unit=="PACKET(250ML)" 
	replace qty=qty*250 if other_unit=="PACKET(250ML)" 
replace unit="18" if other_unit=="PACKET50G"
	replace qty=qty*50 if other_unit=="PACKET50G"
replace unit="4" if other_unit=="PAIL (SMALL)"
replace unit="5" if other_unit=="PAIL (LARGE)" | other_unit=="PAIL(LARGE)"
replace unit="9" if other_unit=="PEICE" | other_unit=="PIECE" ///
	| other_unit=="PIECE (LARGE)" | other_unit=="PIECE (MEDIUM)" ///
	| other_unit=="PIECE (SMALL)" | other_unit=="PIECE(MEDIUM)" ///
	| other_unit=="PIECES" | other_unit=="PIECES(SMALL)"
replace unit="22" if other_unit=="SACHET/MEDIUM" | other_unit=="SACHETUBELARGE" | ///
	other_unit=="SACHETUBESMALL" | other_unit=="SARCHETORTUBE" | other_unit=="SATCHERT" ///
	| other_unit=="SATCHET (LARGE)" | other_unit=="SATCHET (MEDIUM)" | other_unit=="SATCHET (SMALL)" ///
	| other_unit=="SATCHET/TUBE" | other_unit=="SATCHET/TUBE(LARGE)" | other_unit=="SATCHET/TUBE(MEDIUM)" ///
	| other_unit=="SUCHET"
replace unit="18" if other_unit=="SATCHET (5 GRAM)"
	replace qty=qty*5 if other_unit=="SATCHET (5 GRAM)"
replace unit="20" if other_unit=="TABLESPOON"
	replace qty=qty*3 if other_unit=="TABLESPOON"
replace unit="9" if other_unit=="WHOLE"

* Code bread loaves into grams
tab unit if hh_g02==111
tab2 unit unitlabel if hh_g02==111
replace unit="18" if unit=="31" & hh_g02==111
	replace qty=qty*300 if unit=="31" & hh_g02==111
replace unit="18" if unit=="32" & hh_g02==111
	replace qty=qty*600 if unit=="32" & hh_g02==111
replace unit="18" if unit=="33" & hh_g02==111
	replace qty=qty*700 if unit=="33" & hh_g02==111
	
* Conversion factors for kg/g/mg units
gen kg_convwt=.
	replace kg_convwt=1 if unit=="1"
	replace kg_convwt=.001 if unit=="18" // gram
	replace kg_convwt=(1/50) if unit=="2" // 50 kg
	
* Recode units if given a subunit that is not an allowable combination
bys hh_g02: tab unit
replace unit="6" if inlist(unit,"6A","6B") & inlist(hh_g02,101,102,103,104,105,106,107,108)
replace unit="5" if inlist(unit,"5A","5B","5C") & inlist(hh_g02,101,102,103,104,106)
replace unit="9" if inlist(unit,"9A","9B","9C") & inlist(hh_g02,101,102,103,104,106)
replace unit="10" if inlist(unit,"10A","10B","10C") & inlist(hh_g02,101,102,103,104,106)
	
* New food item variable to match with conversion factors for items added after baseline
gen item_match=hh_g02
replace item_match=502 if inlist(hh_g02,5021,5022,5023)
replace item_match=503 if inlist(hh_g02,5031,5032,5033)
replace item_match=513 if inlist(hh_g02,5131,5132,5133)
	
preserve
			
	* Merge in Conversion factors
		// Import conversion factors to Stata format
		* Conversion factors primarily from the LSMS guidebook are used (note these differ from the IHS3 document that appears to be pulled down but was available on the internet before Dec 2019)
			* accessed from: http://surveys.worldbank.org/publications/use-non-standard-units-collection-food-quantity
			* Supplemented by additional conversion factors provided in the IHS3 documentation
				* Accessed at: https://siteresources.worldbank.org/INTLSMS/Resources/3358986-1233781970982/5800988-1271185595871/Malawi_IHS3_Food_Item_Conversion_Factors.pdf
			* Where the item-unit conversion factor disagrees, the World Bank Annex II document is used as default
		clear
		import excel using "$ihpsraw\IHS3_UnitConversionFactors", firstrow sheet("MalawiIHS3_AppendixD")
		destring, replace
		drop E
		gen datasource=0
		save "IHS3_UnitConversionFactors", replace

		clear
		import excel using "$ihpsraw\Annex II Malawi - Conversion factors & Allowable units.xlsx", firstrow sheet("ConsumpCF_formatted")
		ren (North Central South) (region1 region2 region3)
		reshape long region, i(hh_g02 unit) j(kg_convwt)
		ren region kg_convwt2
		ren kg_convwt region
		ren kg_convwt2 kg_convwt
		tab region
		destring, replace
		gen datasource=1
		save "Annex II Malawi - Conversion factors & Allowable units", replace
		
		append using IHS3_UnitConversionFactors
		sort hh_g02 unit region
		reshape wide kg_convwt, i(hh_g02 unit region) j(datasource)
		
		save UnitConversionFactors, replace

restore

merge m:1 hh_g02 unit region using UnitConversionFactors
replace kg_convwt=kg_convwt1 if kg_convwt==. & kg_convwt1!=.
replace kg_convwt=kg_convwt0 if kg_convwt==. & kg_convwt1==. & kg_convwt0!=.
drop if _merge==2
drop _merge

* Generate conversion factors for liquid volumes to kg 
 //  Using Aqua-Calc conversion factors, based on USDA standard food reference database

tab hh_g02 if inlist(unit,"15","19","20"), sum(hh_g02)
* Labeled as Item // Closest matching item used for converstion factor
	* Maize normal/fine flour // Corn flour, masa, unenriched, white
	replace kg_convwt=0.48 if inlist(hh_g02,101,102) & unit=="15" & kg_convwt==. 
	replace kg_convwt=0.48/1000 if inlist(hh_g02,101,102) & unit=="19" & kg_convwt==.
	replace kg_convwt=0.002409 if inlist(hh_g02,101,102) & unit=="20" & kg_convwt==.

	* Maize bran flour // Corn flour, whole=grain, white
	replace kg_convwt=0.49 if hh_g02==103 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.49/1000 if hh_g02==103 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.002472 if hh_g02==103 & unit=="20" & kg_convwt==.

	* Finger millet // Millet, raw
	replace kg_convwt=0.845 if hh_g02==107 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.845/1000 if hh_g02==107 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0042 if hh_g02==107 & unit=="20" & kg_convwt==.
	
	* Fresh milk // Milk, whole, 3.25% milkfat, without added vitamin A and vitamin D
	replace kg_convwt=1.014 if hh_g02==701 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.014/1000 if hh_g02==701 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0051 if hh_g02==701 & unit=="20" & kg_convwt==.

	* Powdered milk // Milk, dry, whole, without added vitamin D
	replace kg_convwt=0.541 if hh_g02==702 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.541/1000 if hh_g02==702 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0027 if hh_g02==702 & unit=="20" & kg_convwt==.
	replace kg_convwt=0.01 if hh_g02==702 & unit=="59" & kg_convwt==.

	* Margarine // Margarine, regular, 80% fat, composite, stick, without salt
	replace kg_convwt=0.96 if hh_g02==703 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.96/1000 if hh_g02==703 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0048 if hh_g02==703 & unit=="20" & kg_convwt==.
	
	* Butter // Butter
	replace kg_convwt=0.959 if hh_g02==704 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.959/1000 if hh_g02==704 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0047 if hh_g02==704 & unit=="20" & kg_convwt==.

	* Chambiko // Milk, buttermilk, fluid, whole
	replace kg_convwt=1.036 if hh_g02==705 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.036/1000 if hh_g02==705 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0052 if hh_g02==705 & unit=="20" & kg_convwt==.

	* Yogurt // Yogurt, plain, whole milk (cup (8 fl oz))
	replace kg_convwt=1.036 if hh_g02==706 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.036/1000 if hh_g02==706 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0052 if hh_g02==706 & unit=="20" & kg_convwt==.

	* Sugar // Sugar, granulated, white
	replace kg_convwt=0.845 if hh_g02==801 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.845/1000 if hh_g02==801 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0042 if hh_g02==801 & unit=="20" & kg_convwt==.

	* Cooking oil // Oil, sunflower, high oleic (70% and over)
	replace kg_convwt=0.947 if hh_g02==803 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.947/1000 if hh_g02==803 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0047 if hh_g02==803 & unit=="20" & kg_convwt==.

	* Salt // Salt, table
	replace kg_convwt=1.217 if hh_g02==810 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.217/1000 if hh_g02==810 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0061 if hh_g02==810 & unit=="20" & kg_convwt==.

	* Yeast, baking powder, bicarbonate of soda // Leavening agents, baking soda
	replace kg_convwt=0.933 if hh_g02==812 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.933/1000 if hh_g02==812 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0046 if hh_g02==812 & unit=="20" & kg_convwt==.

	* Tomato sauce // Catsup
	replace kg_convwt=1.15 if hh_g02==813 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.15/1000 if hh_g02==813 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0057 if hh_g02==813 & unit=="20" & kg_convwt==.

	* Hot sauce // Sauce, ready-to-serve, pepper or hot
	replace kg_convwt=0.954 if hh_g02==814 & unit=="15" & kg_convwt==.
	replace kg_convwt=0.954/1000 if hh_g02==814 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0047 if hh_g02==814 & unit=="20" & kg_convwt==.

	* Honey // Honey
	replace kg_convwt=1.42 if hh_g02==817 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.42/1000 if hh_g02==817 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0071 if hh_g02==817 & unit=="20" & kg_convwt==.

	* Fruit Juice //  Orange juice, canned, unsweetened
	replace kg_convwt=1.052 if hh_g02==905 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.052/1000 if hh_g02==905 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0052 if hh_g02==905 & unit=="20" & kg_convwt==.

	* Soft drink //  Beverages, carbonated, orange
	replace kg_convwt=1.048 if hh_g02==907 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.048/1000 if hh_g02==907 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0052 if hh_g02==907 & unit=="20" & kg_convwt==.

	* Bottled water //  Water, bottled, generic
	replace kg_convwt=1.002 if hh_g02==909 & unit=="15" & kg_convwt==.
	replace kg_convwt=1.002/1000 if hh_g02==909 & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0050 if hh_g02==909 & unit=="20" & kg_convwt==.
	
	* Beer // Alcoholic beverage, beer, regular, all
	replace kg_convwt=1.004 if inlist(hh_g02,911,912,913) & unit=="15" & kg_convwt==.
	replace kg_convwt=1.004/1000 if inlist(hh_g02,911,912,913) & unit=="19" & kg_convwt==.
	replace kg_convwt=0.0050 if inlist(hh_g02,911,912,913) & unit=="20" & kg_convwt==.

	* Wine & Liquor // Alcoholic beverage, distilled, all (gin, rum, vodka, whiskey) 80 proof
	replace kg_convwt=0.94 if inlist(hh_g02,914,915) & unit=="15" & kg_convwt==.
	replace kg_convwt=0.94/1000 if inlist(hh_g02,914,915) & unit=="19" 
	replace kg_convwt=0.0047 if inlist(hh_g02,914,915) & unit=="20" 
	
	* Irish potato // convert 5 liters to kg - use sweet potato as the only record with conversion
	replace kg_convwt=2.81 if hh_g02==205 & unitlabel==26 

* Generate quantity in kg variable
gen qty_kg=.
replace qty_kg=qty*kg_convwt if qty_kg==. & kg_convwt!=.

tab hh_g02 unitlabel if qty_kg==.
tab unitlabel if qty_kg==.

	replace unit="18" if unitlabel==34 & kg_convwt==.
		replace qty=qty*150 if unitlabel==34 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==34 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==34 & kg_convwt==.
	replace unit="18" if unitlabel==35 & kg_convwt==.
		replace qty=qty*400 if unitlabel==35 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==35 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==35 & kg_convwt==.
	replace unit="18" if unitlabel==36 & kg_convwt==.
		replace qty=qty*500 if unitlabel==36 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==36 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==36 & kg_convwt==.
	replace unit="1" if unitlabel==37 & kg_convwt==.
		replace kg_convwt=1 if unitlabel==37 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==37 & kg_convwt==.
	replace unit="18" if unitlabel==41 & kg_convwt==.
		replace qty=qty*25 if unitlabel==41 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==41 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==41 & kg_convwt==.
	replace unit="18" if unitlabel==42 & kg_convwt==.
		replace qty=qty*50 if unitlabel==42 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==42 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==42 & kg_convwt==.
	replace unit="18" if unitlabel==43 & kg_convwt==.
		replace qty=qty*100 if unitlabel==43 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==43 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==43 & kg_convwt==.
	replace unit="18" if unitlabel==65 & kg_convwt==.
		replace qty=qty*250 if unitlabel==65 & kg_convwt==.
		replace kg_convwt=.001 if unitlabel==65 & kg_convwt==.
		replace qty_kg=qty*kg_convwt if unitlabel==65 & kg_convwt==.
	
sum if qty==.
sum if qty_kg==.

gen convertedtokg=1 if qty_kg!=. 
replace convertedtokg=0 if qty_kg==. & qty!=. & qty!=0
tab convertedtokg
tab hh_g02 if convertedtokg

* Identify foods that could not be converted to kg units:
	tab hh_g02 if convertedtokg==0
	* METHOD NOTE:
		* If subunit given where no subunit conversion rate is available, remove subunit
		* Where no subunit given and one is required, assume medium or if necessary apply midpoint between multiple sizes
		* Standard units converted where possible using volume to weight calculator accessed via Aqua-calc.com per above
			* Food item used is reported where relevant in the code
			* Cup - assumes 1 US cup	
		* Fish items added after baseline use the less disaggregated conversion factors (e.g. item 5021, 5022, and 5023 use the 502 conversion factor - done in the spreadsheet)
		* Groundnut - shelled and unshelled in later rounds, use conversion factor from IHS3 which was unspecified
		// Maize
		* 101
		tab2 unit unitlabel if hh_g02==101 & convertedtokg==0, m
		tab unitlabel if hh_g02==101 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==101 & convertedtokg==0
			* 5 Litre bucket - 5 liters corn flour, unenriched = 2.41 kg
			replace kg_convwt=2.41 if hh_g02==101 & convertedtokg==0 & unit=="26" & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if hh_g02==101 & convertedtokg==0 & unit=="26" & qty_kg==. & kg_convwt!=.
			replace unit="1" if hh_g02==101 & convertedtokg==0 & unit=="26" & qty_kg!=. & kg_convwt!=.
			replace convertedtokg=1 if hh_g02==101 & convertedtokg==0 & unit=="1" & qty_kg!=. & kg_convwt!=.
			* Pail - assume medium
			replace unit="4B" if hh_g02==101 & convertedtokg==0 & unit=="23" & inlist(other_unit,"PAIL","PAIL (MEDIUM)")& qty_kg==. & kg_convwt==.
		tab2 unit unitlabel if hh_g02==101 & convertedtokg==0
			* Cup - 1 US cup = 0.11 kg
			replace kg_convwt=0.11 if hh_g02==101 & convertedtokg==0 & unit=="23" & other_unit=="CUP" & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if hh_g02==101 & convertedtokg==0 & unit=="23" & other_unit=="CUP" & qty_kg==. & kg_convwt!=.
			replace convertedtokg=1 if hh_g02==101 & convertedtokg==0 & unit=="23" & other_unit=="CUP" & qty_kg!=. & kg_convwt!=.	
		* 102
		tab2 unit unitlabel if hh_g02==102 & convertedtokg==0, m
		tab unitlabel if hh_g02==102 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==102 & convertedtokg==0
			* 5 liter bucket
			replace kg_convwt=2.41 if hh_g02==102 & convertedtokg==0 & unit=="26" & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if hh_g02==102 & convertedtokg==0 & unit=="26" & qty_kg==. & kg_convwt!=.
			replace unit="1" if hh_g02==102 & convertedtokg==0 & unit=="26" & qty_kg!=. & kg_convwt!=.
			replace convertedtokg=1 if hh_g02==102 & convertedtokg==0 & unit=="1" & qty_kg!=. & kg_convwt!=.
		tab other_unit if unit=="23" & hh_g02==102 & convertedtokg==0
			* Medium pail
			replace unit="4B" if hh_g02==102 & convertedtokg==0 & unit=="23" & other_unit!="SLICE" & qty_kg==. & kg_convwt==.
			* Pail and plate - remove subunits
			replace unit="5" if unit=="5D" & hh_g02==102 & convertedtokg==0 & qty_kg==. & kg_convwt==.		
			replace unit="7" if unit=="7B" & hh_g02==102 & convertedtokg==0 & qty_kg==. & kg_convwt==.		
		* 103
		tab2 unit unitlabel if hh_g02==103 & convertedtokg==0, m
		tab unitlabel if hh_g02==103 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==103 & convertedtokg==0
			* Pail unspecified - assume medium
			replace unit="4B" if unit=="23" & other_unit=="PAIL" & hh_g02==103 & convertedtokg==0 & kg_convwt!=. & qty_kg==. & kg_convwt==.		
		* 104
		tab2 unit unitlabel if hh_g02==104 & convertedtokg==0
		tab other_unit if unit=="23" & hh_g02==104 & convertedtokg==0
			* Cup
			replace unit="16" if hh_g02==104 & convertedtokg==0 & unit=="23" & other_unit=="CUP" & qty_kg==. & kg_convwt==.
			* No. 12 plate - remove subunit
			replace unit="7" if inlist(unit,"7A","7C") & hh_g02==104 & convertedtokg==0 & kg_convwt!=. & qty_kg==. & kg_convwt==.		
			* Pail - assume medium if unspecified
			replace unit="4B" if unit=="23" & other_unit=="PAIL" & hh_g02==104 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Plate - unspecified, assume midpoint between No. 10 and No. 12
			replace kg_convwt=0.265 if region==1 & unit=="23" & inlist(other_unit,"1 PLATE MAIZE","MAIZE PLATE","PLATE") & hh_g02==104 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.23 if region==2 & unit=="23" & inlist(other_unit,"1 PLATE MAIZE","MAIZE PLATE","PLATE") & hh_g02==104 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.285 if region==3 & unit=="23" & inlist(other_unit,"1 PLATE MAIZE","MAIZE PLATE","PLATE") & hh_g02==104 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & inlist(other_unit,"1 PLATE MAIZE","MAIZE PLATE","PLATE") & hh_g02==104 & qty_kg==. & kg_convwt!=.
			replace other_unit="PLATE - MIDPOINT BETWEEN 10 AND 12 WHERE NOT SPECIFIED" if unit=="23" & inlist(other_unit,"1 PLATE MAIZE","MAIZE PLATE","PLATE") & hh_g02==104 & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if unit=="23" &  other_unit=="PLATE - MIDPOINT BETWEEN 10 AND 12 WHERE NOT SPECIFIED" & hh_g02==104 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* TINA - condense unit codes
			replace unit="25" if unit=="23" & inlist(other_unit,"TINA(FLAT)","TINA(SMALL)") & hh_g02==104 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unitlabel=25 if unit=="25" & inlist(other_unit,"TINA(FLAT)","TINA(SMALL)") & hh_g02==104 & convertedtokg==0 & qty_kg==. & kg_convwt==.		* 105
		* 105
		tab2 unit unitlabel if hh_g02==105 & convertedtokg==0,m
			*Assume medium piece
			replace unit="9B" if (unit=="9") & hh_g02==105 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Rice
		tab2 unit unitlabel if hh_g02==106 & convertedtokg==0, m
		tab other_unit if unit=="23" & hh_g02==106 & convertedtokg==0	
			* 5L bucket: 5 liters=4.12 kg
			tab unitlabel if unit=="26" & hh_g02==106 & convertedtokg==0 & qty_kg==. & kg_convwt==., sum(unitlabel)
			replace unit="1" if unit=="26" & hh_g02==106 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			tab2 unit unitlabel if hh_g02==106 & convertedtokg==0 & qty_kg==. & kg_convwt==., m
			* 4A - replace with unit 4
			tab unitlabel if unit=="4A" & hh_g02==106 & convertedtokg==0 & qty_kg==. & kg_convwt==., sum(unitlabel)
			replace unit="4" if unit=="4A" & hh_g02==106 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Cup -Rice, white, long-grain, regular, raw, unenriched 1 US cup = 0.19kg
			replace kg_convwt=0.19 if unit=="23" & other_unit=="CUP" & hh_g02==106 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="CUP" & hh_g02==106 & qty_kg==. & kg_convwt!=. & convertedtokg==0
			replace unit="1" if unit=="23" & other_unit=="CUP" & hh_g02==106 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.
			replace convertedtokg=1 if unit=="1" & other_unit=="CUP" & hh_g02==106 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.
		// Finger millet
		tab2 unit unitlabel if hh_g02==107 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==107 & convertedtokg==0	
			* Plate - unspecified, assume midpoint between No. 10 and No. 12
			replace kg_convwt=0.21 if region==1 & unit=="23" & other_unit=="PLATE" & hh_g02==107 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.17 if region==2 & unit=="23" & other_unit=="PLATE" & hh_g02==107 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.115 if region==3 & unit=="23" & other_unit=="PLATE" & hh_g02==107 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="PLATE" & hh_g02==107 & qty_kg==. & kg_convwt!=.
			replace other_unit="PLATE - MIDPOINT BETWEEN 10 AND 12 WHERE NOT SPECIFIED" if unit=="23" & other_unit=="PLATE" & hh_g02==107 & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if unit=="23" &  other_unit=="PLATE - MIDPOINT BETWEEN 10 AND 12 WHERE NOT SPECIFIED" & hh_g02==107 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Sorghum 
		tab2 unit unitlabel if hh_g02==108 & convertedtokg==0,m
		tab unitlabel if hh_g02==108 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==108 & convertedtokg==0	
			* 5 L bucket: Sorghum grain, 5L=0.81kg
			replace kg_convwt=0.81 if  unit=="26" & unitlabel==26 & hh_g02==108 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="26" & unitlabel==26 & hh_g02==108 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unit=="26" & unitlabel==26 & hh_g02==108 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
			replace convertedtokg=1 if unit=="1" & unitlabel==26 & hh_g02==108 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* Plate described as medium - assume midpoint between No. 10 and No. 12
			replace kg_convwt=1.4 if unit=="23" & other_unit!="CUP" & hh_g02==108 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit!="CUP" & hh_g02==108 & qty_kg==. & kg_convwt!=.
			replace other_unit="PLATE - MIDPOINT BETWEEN 10 AND 12 WHERE NOT SPECIFIED" if unit=="23" & other_unit!="CUP" & hh_g02==108 & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if unit=="23" &  other_unit=="PLATE - MIDPOINT BETWEEN 10 AND 12 WHERE NOT SPECIFIED" & hh_g02==108 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* Cup: 1 US cup =0.19 kg
			replace kg_convwt=0.19 if  unit=="23" & other_unit=="CUP" & hh_g02==108 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="CUP" & hh_g02==108 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unit=="23" & other_unit=="CUP" & hh_g02==108 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
			replace convertedtokg=1 if unit=="1" & other_unit=="CUP" & hh_g02==108 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Pearl millet
		tab2 unit unitlabel if hh_g02==109 & convertedtokg==0,m
		tab unitlabel if hh_g02==109 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="10" & hh_g02==109 & convertedtokg==0	
			* Pail 4A - remove subunit
			replace unit="4" if unit=="4A" & hh_g02==109 & convertedtokg==0 & kg_convwt==. & qty_kg==.			
		// Wheat flour
		tab2 unit unitlabel if hh_g02==110 & convertedtokg==0,m		
		// Bread
		tab2 unit unitlabel if hh_g02==111 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==111 & convertedtokg==0	
			* Piece - remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==111 & kg_convwt==. & qty_kg==.  
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==111 & kg_convwt==. & qty_kg==.  
			* Loaf - assume medium (600g)
			replace kg_convwt=.6 if unit=="23" & hh_g02==111 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & hh_g02==111 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unit=="23" & hh_g02==111 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
			replace convertedtokg=1 if unit=="1" & hh_g02==111 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Buns/scones
		tab2 unit unitlabel if hh_g02==112 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==112 & convertedtokg==0	
			* Piece - remove subunit
			replace unit="9" if ((inlist(unit,"9A","9B","9C")) | (unit=="23" & other_unit!="N/A")) & hh_g02==112  & kg_convwt==. & qty_kg==.  
		// Biscuits
		tab2 unit unitlabel if hh_g02==113 & convertedtokg==0,m
		tab unitlabel if hh_g02==113 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==113 & convertedtokg==0,m	
			* Convert to grams
			replace kg_convwt=.15 if unit=="18" & unitlabel==34 & hh_g02==113 & convertedtokg==0
			replace kg_convwt=.25 if unit=="18" & unitlabel==65 & hh_g02==113 & convertedtokg==0
			replace kg_convwt=.4 if unit=="18" & unitlabel==35 & hh_g02==113 & convertedtokg==0
			replace kg_convwt=.5 if unit=="18" & unitlabel==36 & hh_g02==113 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if unit=="18"  & hh_g02==113 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unit=="18" & inlist(unitlabel,34,35,36,65) & hh_g02==113 & qty_kg!=. & kg_convwt!=.
			replace convertedtokg=1 if unit=="1" & inlist(unitlabel,34,35,36,65) & hh_g02==113 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* Assume unspecified packets are a sachet/tube
			replace unit="22" if unit=="23" & inlist(other_unit,"PACKET","PACKET(SMALL)","PACKETS") & hh_g02==113 & kg_convwt==. & qty_kg==.
			* Remove piece subunit
			replace unit="9" if unit=="9A" & hh_g02==113 & kg_convwt==. & qty_kg==.
		// Spaghetti/macaroni
		tab2 unit unitlabel if hh_g02==114 & convertedtokg==0,m
		tab unitlabel if hh_g02==114 & convertedtokg==0,m
		tab unitlabel if hh_g02==114 & convertedtokg==0, sum(unitlabel) 
		tab other_unit if unit=="23" & hh_g02==114 & convertedtokg==0,m	
			* Convert to kg
			replace kg_convwt=.15 if unitlabel==34 & hh_g02==114 & convertedtokg==0
			replace kg_convwt=.4 if unitlabel==35 & hh_g02==114 & convertedtokg==0
			replace kg_convwt=.5 if unitlabel==36 & hh_g02==114 & convertedtokg==0
			replace kg_convwt=.25 if unitlabel==65 & hh_g02==114 & convertedtokg==0
			replace kg_convwt=1 if unitlabel==37 & hh_g02==114 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if inlist(unitlabel,34,35,36,65,37) & hh_g02==114 & qty_kg==. & kg_convwt!=.
			replace unit="1" if inlist(unitlabel,34,35,36,65,37) & hh_g02==114 & qty_kg!=. & kg_convwt!=.
			replace convertedtokg=1 if unit=="1" & inlist(unitlabel,34,35,36,65,37) & hh_g02==114 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Breakfast cereal
		tab2 unit unitlabel if hh_g02==115 & convertedtokg==0,m
		tab unitlabel if hh_g02==115 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unitlabel==23 & hh_g02==115 & convertedtokg==0,m	
			* 5 L corn flakes = 0.59 kg
			replace kg_convwt=.59 if inlist(other_unit,"5 LITRES","5L BUCKET") & hh_g02==115 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if inlist(other_unit,"5 LITRES","5L BUCKET") & hh_g02==115 & qty_kg==. & kg_convwt!=.
			replace unit="1" if inlist(other_unit,"5 LITRES","5L BUCKET") & hh_g02==115 & convertedtokg==0 & qty_kg!=. & kg_convwt!=.
			replace convertedtokg=1 if unit=="1" & inlist(other_unit,"5 LITRES","5L BUCKET") & hh_g02==115 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* Convert to kg
			replace kg_convwt=.4 if unitlabel==35 & hh_g02==115 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if unitlabel==35 & hh_g02==115 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unitlabel==35 & hh_g02==115 & convertedtokg==0 & qty_kg!=. & kg_convwt!=.
			replace convertedtokg=1 if unit=="1" & unitlabel==35 & hh_g02==115 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Cassava tubers
		tab2 unit unitlabel if hh_g02==201 & convertedtokg==0,m
			* Pail - remove subunit
			replace unit="4" if inlist(unit,"4A","4B") & hh_g02==201 & kg_convwt==. & qty_kg==.
			* Heap - use conversion factor from IHS3 documentation
			replace kg_convwt=0.98 if region==1 & hh_g02==201 & inlist(unit,"10","10A","10B","10C") & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=1.2 if region==2 & hh_g02==201 & inlist(unit,"10","10A","10B","10C") & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=1.12 if region==3 & hh_g02==201 & inlist(unit,"10","10A","10B","10C") & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if hh_g02==201 & inlist(unit,"10","10A","10B","10C") & qty_kg==. & kg_convwt!=.
			replace convertedtokg=1 if hh_g02==201 & inlist(unit,"10","10A","10B","10C") & convertedtokg==0 & kg_convwt!=. & qty_kg!=.									
		// Cassava flour
		tab2 unit unitlabel if hh_g02==202 & convertedtokg==0,m
		tab other_unit if unitlabel==23 & hh_g02==202 & convertedtokg==0,m	
			* Pail 4C - assume means large pail and recode as 5 (Pail -large)
			replace unit="5" if unit=="4C" & hh_g02==202 & kg_convwt==. & qty_kg==.
		// White sweet potato
		tab2 unit unitlabel if hh_g02==203 & convertedtokg==0,m
			* 4A and C - take midpoint between 4 and 4B
			replace kg_convwt=8.17 if inlist(unit,"4A","4C") & hh_g02==203 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if inlist(unit,"4A","4C") & hh_g02==203  & qty_kg==. & kg_convwt!=.
			replace other_unit="PAIL - MIDPOINT BETWEEN SMALL AND MEDIUM WHERE NOT SPECIFIED" if inlist(unit,"4A","4C") & hh_g02==203 & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if inlist(unit,"4A","4C") & hh_g02==203 &  other_unit=="PAIL - MIDPOINT BETWEEN SMALL AND MEDIUM WHERE NOT SPECIFIED" & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* 5A and C - remove subunits
			replace unit="5" if inlist(unit,"5A","5C") & hh_g02==203 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Orange sweet potato
		tab2 unit unitlabel if hh_g02==204 & convertedtokg==0,m
			* Remove subunit
			replace unit="4" if inlist(unit,"4A","4B","4C") & hh_g02==204 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Irish potato
		tab2 unit unitlabel if hh_g02==205 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==205 & convertedtokg==0,m	
			* Heap - remove subunit
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==205 & kg_convwt==. & qty_kg==.
			* Recode basin
			replace unit="21" if unit=="23" & other_unit=="BASIN" & hh_g02==205 & kg_convwt==. & qty_kg==.
		// Crisps
		tab2 unit unitlabel if hh_g02==206 & convertedtokg==0,m
		tab unitlabel if hh_g02==206 & convertedtokg==0,m
		tab unitlabel if hh_g02==206 & convertedtokg==0, sum(unitlabel)
			replace unit="22" if inlist(unitlabel,41,43,51,54,55)
		// Plantain
		tab2 unit unitlabel if hh_g02==207 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==207 & convertedtokg==0
			* Cluster - assume this is the same meaning as bunch
			replace unit="8A" if unit=="44A" & hh_g02==207 & kg_convwt==. & qty_kg==.
			replace unit="8C" if unit=="44C" & hh_g02==207 & kg_convwt==. & qty_kg==.
			* 8B - take midpoint between 8A and 8C
			replace kg_convwt=5.55 if region==1 & inlist(unit,"8","8B","44B") & hh_g02==207 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=5.485 if region==2 & inlist(unit,"8","8B","44B") & hh_g02==207 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=5.39 if region==3 & inlist(unit,"8","8B","44B") & hh_g02==207 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if inlist(unit,"8","8B","44B") & hh_g02==207 & qty_kg==. & kg_convwt!=.
			replace other_unit="BUNCH - MIDPOINT BETWEEN SMALL AND LARGE WHERE NOT SPECIFIED" if inlist(unit,"8","8B","44B") & hh_g02==207 & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if inlist(unit,"8","8B","44B") & hh_g02==207  &  other_unit=="BUNCH - MIDPOINT BETWEEN SMALL AND LARGE WHERE NOT SPECIFIED" & hh_g02==207 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
			* Piece - remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==207 & kg_convwt==. & qty_kg==.
		// Cocoyam
		tab2 unit unitlabel if hh_g02==208 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==208 & convertedtokg==0
			* Heap and piece -remove subunit
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==208 & kg_convwt==. & qty_kg==.
			replace unit="9" if unit=="9B" & hh_g02==208 & kg_convwt==. & qty_kg==.
		// White bean
		tab2 unit unitlabel if hh_g02==301 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==301 & convertedtokg==0
			* Plates - remove subunits
			replace unit="6" if inlist(unit,"6A","6B") & hh_g02==301 & kg_convwt==. & qty_kg==.
			replace unit="7" if inlist(unit,"7A","7B") & hh_g02==301 & kg_convwt==. & qty_kg==.
			* Relabel cup entered as other
			replace unit="16" if unit=="23" & other_unit=="CUP" & hh_g02==301 & kg_convwt==. & qty_kg==.
		// Brown bean - TINA: 924
		tab2 unit unitlabel if hh_g02==302 & convertedtokg==0, m
		tab unitlabel if hh_g02==302 & convertedtokg==0, sum(unitlabel)
			* No. 12 plate - remove subunit, assume "12" is a No. 12 plate
			replace unit="7" if inlist(unit, "7A","7B","7C","12") & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Basin - remove subunit
			replace unit="21" if unit=="27D" & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Heap - remove subunit
			replace unit="10" if inlist(unit, "10A","10B","10C") & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Cup - relabel
			replace unit="16" if unit=="23" & other_unit=="CUP" & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Unspecified plate - use midpoint between all plates (No. 10, heaped, flat, No. 12)
			replace kg_convwt=0.195 if region==1 & unit=="23" & other_unit=="PLATE" & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.19 if region==2 & unit=="23" & other_unit=="PLATE" & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.19 if region==3 & unit=="23" & other_unit=="PLATE" & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="PLATE" & hh_g02==302 & qty_kg==. & kg_convwt!=.
			replace other_unit="Midpoint between plate options assumed for unspecified" if unit=="23" & other_unit=="PLATE" & hh_g02==302 & convertedtokg==0 & qty_kg!=.
			replace convertedtokg=1 if other_unit=="Midpoint between plate options assumed for unspecified" & hh_g02==302 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
			* PAIL - remove subunit
			replace unit="4" if unit=="4A" & hh_g02==302 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Pigeonpea
		tab2 unit unitlabel if hh_g02==303 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==303 & convertedtokg==0
			* Plate - remove subunit
			replace unit="7" if inlist(unit,"7A","7B","7C") & hh_g02==303 & kg_convwt==. & qty_kg==.
			* Relabel cup entered as other
			replace unit="16" if unit=="23" & other_unit=="CUP" & hh_g02==303 & kg_convwt==. & qty_kg==.
			* Plate unspecified- take midpoint	
			replace kg_convwt=0.18 if region==1 & unit=="23" & other_unit=="PLATE" & hh_g02==303 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.13 if region==2 & unit=="23" & other_unit=="PLATE" & hh_g02==303 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.195 if region==3 & unit=="23" & other_unit=="PLATE" & hh_g02==303 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="PLATE" & hh_g02==303 & qty_kg==. & kg_convwt!=.
			replace other_unit="PLATE - MIDPOINT BETWEEN ALL WHERE NOT SPECIFIED" if unit=="23" & other_unit=="PLATE" & hh_g02==303  & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if unit=="23" & hh_g02==303  &  other_unit=="PLATE - MIDPOINT BETWEEN ALL WHERE NOT SPECIFIED" & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Groundnut
		tab2 unit unitlabel if inlist(hh_g02,304,311,312) & convertedtokg==0,m
		tab unitlabel if inlist(hh_g02,304,311,312) & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & inlist(hh_g02,304,311,312) & convertedtokg==0
			* Remove subunits
			replace unit="4" if inlist(unit,"4A","4B","4C") & inlist(hh_g02,304,311,312)& kg_convwt==. & qty_kg==.
			replace unit="7" if inlist(unit,"7A","7B","7C") & inlist(hh_g02,304,311,312) & kg_convwt==. & qty_kg==.
			replace unit="10" if inlist(unit,"10A","10B","10C") & inlist(hh_g02,304,311,312) & kg_convwt==. & qty_kg==.
			replace unit="6" if unit=="6C" & inlist(hh_g02,304,311,312) & kg_convwt==. & qty_kg==.
			replace unit="21" if unitlabel==27 & inlist(hh_g02,304,311,312) & kg_convwt==. & qty_kg==.
		// Groundnut flour 
		tab2 unit unitlabel if hh_g02==305 & convertedtokg==0, m
		tab unitlabel if hh_g02==305 & convertedtokg==0, sum(unitlabel)
			* Pail - remove subunit
			replace unit="4" if inlist(unit, "4A","4B") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* No. 10 plate - take midpoint between flat and heaped for unspecified or unallowable subunit
			replace kg_convwt=0.065 if region==1 & inlist(unit,"6","6C") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.08 if region==2 & inlist(unit,"6","6C") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.06 if region==3 & inlist(unit,"6","6C") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if inlist(unit,"6","6C") & hh_g02==305 & qty_kg==. & kg_convwt!=.
			replace other_unit="Midpoint in flat/heaped No. 10 plate where unspecified" if inlist(unit,"6","6C") & hh_g02==305 & convertedtokg==0 & qty_kg!=.
			replace unit="23" if inlist(unit,"6","6C") & hh_g02==305 & convertedtokg==0 & qty_kg!=.
			replace convertedtokg=1 if unit=="23" & other_unit=="Midpoint in flat/heaped No. 10 plate where unspecified" & hh_g02==305 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.
			* No. 12 plate - remove subunit
			replace unit="7" if inlist(unit, "7A","7B","7C") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			*Heap - remove subunit
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Unspecified plate - assume midpoint of all plate options
		tab other_unit if unit=="23" & hh_g02==305 & convertedtokg==0
			replace kg_convwt=0.15 if region==1 & unit=="23" & inlist(other_unit,"NSIMA PLATE","PLATE","PLATE NSIMA","RELISH PLATE") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.095 if region==2 & unit=="23" & inlist(other_unit,"NSIMA PLATE","PLATE","PLATE NSIMA","RELISH PLATE") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.15 if region==3 & unit=="23" & inlist(other_unit,"NSIMA PLATE","PLATE","PLATE NSIMA","RELISH PLATE") & hh_g02==305 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & inlist(other_unit,"NSIMA PLATE","PLATE","PLATE NSIMA","RELISH PLATE") & hh_g02==305 & qty_kg==. & kg_convwt!=.
			replace other_unit="Midpoint of all plates where unspecified" if unit=="23" & inlist(other_unit,"NSIMA PLATE","PLATE","PLATE NSIMA","RELISH PLATE") & hh_g02==305 & convertedtokg==0 & qty_kg!=.
			replace convertedtokg=1 if unit=="23" & other_unit=="Midpoint of all plates where unspecified" & hh_g02==305 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.
		// Soyabean flour
		tab2 unit unitlabel if hh_g02==306 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==306 & convertedtokg==0
			* Remove subunits
			replace unit="7" if unit=="7A" & hh_g02==306 & kg_convwt==. & qty_kg==.
			replace unit="6" if inlist(unit,"6A","6B") & hh_g02==306 & kg_convwt==. & qty_kg==.
			* Ambiguous plate - take midpoint
			replace kg_convwt=0.21 if region==1 & unit=="23" & inlist(other_unit,"PLATE","RELISH PLATE") & hh_g02==306 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.265 if region==2 & unit=="23" & inlist(other_unit,"PLATE","RELISH PLATE") & hh_g02==306 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.21 if region==3 & unit=="23" & inlist(other_unit,"PLATE","RELISH PLATE") & hh_g02==306 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & inlist(other_unit,"PLATE","RELISH PLATE") & hh_g02==306 & qty_kg==. & kg_convwt!=.
			replace other_unit="PLATE - MIDPOINT BETWEEN ALL WHERE NOT SPECIFIED" if unit=="23" & inlist(other_unit,"PLATE","RELISH PLATE") & hh_g02==306  & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if unit=="23" & hh_g02==306 & other_unit=="PLATE - MIDPOINT BETWEEN ALL WHERE NOT SPECIFIED" & convertedtokg==0 & kg_convwt!=. & qty_kg!=.						
		// Ground bean
		tab2 unit unitlabel if hh_g02==307 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==307 & convertedtokg==0
			* Remove subunits
			replace unit="7" if inlist(unit,"7A","7B") & hh_g02==307 & kg_convwt==. & qty_kg==.
			replace unit="6" if inlist(unit,"6A","6B") & hh_g02==307 & kg_convwt==. & qty_kg==.
		// Cowpea
		tab2 unit unitlabel if hh_g02==308 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==308 & convertedtokg==0
			* Remove subunits
			replace unit="7" if inlist(unit,"7A","7B") & hh_g02==308 & kg_convwt==. & qty_kg==.
			replace unit="6" if inlist(unit,"6A","6B") & hh_g02==308 & kg_convwt==. & qty_kg==.
			replace unit="10" if inlist(unit,"10A","10B") & hh_g02==308 & kg_convwt==. & qty_kg==.
			* Relabel cup
			replace unit="16" if unit=="23" & other_unit=="CUP" & hh_g02==308 & kg_convwt==. & qty_kg==.
		// Onion
		tab2 unit unitlabel if hh_g02==401 & convertedtokg==0, m
		tab unitlabel if hh_g02==401 & convertedtokg==0, sum(unitlabel)
			* Heap - remove subunit
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==401 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Bunch and piece - assume medium when non specified
			replace unit="8B" if inlist(unit,"8","8E") & hh_g02==401 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="9B" if unit=="9" & hh_g02==401 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Cabbage
		tab2 unit unitlabel if hh_g02==402 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==402 & convertedtokg==0
			* Relabel "head" as piece
			replace unit="9" if unit=="23" & other_unit!="" & hh_g02==402 & kg_convwt==. & qty_kg==.
		// Rape
		tab2 unit unitlabel if hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==., m
		tab unitlabel if hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==., sum(unitlabel)
			* Bunch - assume medium when not specified
			tab hh_g02 if unit=="8" & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="8B" if unit=="8" & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Piece and heap - remove subunit
			tab2 unit unitlabel if inlist(unit,"9A","9B","9C","29") & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==., m
			tab unitlabel if inlist(unit,"9A","9B","9C","29") & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==., sum(unitlabel)
			tab hh_g02 if inlist(unit,"9A","9B","9C","29")  & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="9" if inlist(unit,"9A","9B","9C","29") & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==.			
			tab2 unit unitlabel if inlist(unit,"10A","10B","10C","38","39","40") & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==., m
			tab unitlabel if inlist(unit,"10A","10B","10C","38","39","40") & hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==., sum(unitlabel)
			replace unit="10" if inlist(unit,"10A","10B","10C","38","39","40") ///
				& hh_g02==403 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Nkhwani
		tab2 unit unitlabel if hh_g02==404 & convertedtokg==0,m
		tab unitlabel if hh_g02==404 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==404 & convertedtokg==0
			* Remove subunits
			replace unit="8" if inlist(unit,"8A","8B","8C") & hh_g02==404 & kg_convwt==. & qty_kg==.
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==404 & kg_convwt==. & qty_kg==.
			replace unit="9" if inlist(unitlabel,29,30) & hh_g02==404 & kg_convwt==. & qty_kg==.
			replace unit="10" if inlist(unitlabel,38,39,40) & hh_g02==404 & kg_convwt==. & qty_kg==.
		// Chinese cabbage
		tab2 unit unitlabel if hh_g02==405 & convertedtokg==0, m
		tab unitlabel if hh_g02==405 & convertedtokg==0, sum(unitlabel)
			* Remove subunits
			replace unit="10" if inlist(unit,"10A","10B","10C","38","39")  & hh_g02==405 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==405 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="8" if inlist(unit,"8A","8B","8C") & hh_g02==405 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Gathered wild green leaves
		tab2 unit unitlabel if hh_g02==407 & convertedtokg==0,m
		tab unitlabel if hh_g02==407 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==407 & convertedtokg==0
			* Recode heaps
			replace unit="10A" if unitlabel==38 & hh_g02==404 & kg_convwt==. & qty_kg==.
			replace unit="10B" if unitlabel==39 & hh_g02==404 & kg_convwt==. & qty_kg==.
			replace unit="10C" if unitlabel==40 & hh_g02==404 & kg_convwt==. & qty_kg==.
		// Tomato
		tab2 unit unitlabel if hh_g02==408 & convertedtokg==0,m
		tab unitlabel if hh_g02==408 & convertedtokg==0,m
		tab unitlabel if hh_g02==408 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==408 & convertedtokg==0
			* Recode heap
			replace unit="10A" if unitlabel==38 & hh_g02==408 & kg_convwt==. & qty_kg==.
			replace unit="10B" if unitlabel==39 & hh_g02==408 & kg_convwt==. & qty_kg==.
			replace unit="10C" if unitlabel==40 & hh_g02==408 & kg_convwt==. & qty_kg==.
			* Recode piece
			replace unit="9A" if unitlabel==28 & hh_g02==408 & kg_convwt==. & qty_kg==.
			replace unit="9B" if unitlabel==29 & hh_g02==408 & kg_convwt==. & qty_kg==.
			replace unit="9C" if unitlabel==30 & hh_g02==408 & kg_convwt==. & qty_kg==.
		// Cucumber
		tab2 unit unitlabel if hh_g02==409 & convertedtokg==0,m
		tab unitlabel if hh_g02==409 & convertedtokg==0, sum(unitlabel)
			* Recode piece
			replace unit="9" if inlist(unitlabel,9,28,29,30) & hh_g02==409 & kg_convwt==. & qty_kg==.
		// Pumpkin
		tab2 unit unitlabel if hh_g02==410 & convertedtokg==0,m
		tab unitlabel if hh_g02==410 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==410 & convertedtokg==0
			* Recode piece, assume "heads" = piece
			replace unit="9" if inlist(unitlabel,28,29,30) & hh_g02==410 & kg_convwt==. & qty_kg==.
			replace unit="9" if unit=="23" & other_unit=="HEADS" & hh_g02==410 & kg_convwt==. & qty_kg==.
		// Okra
		tab2 unit unitlabel if hh_g02==411 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==411 & convertedtokg==0
			* Recode piece
			replace unit="9A" if unitlabel==28 & hh_g02==411 & kg_convwt==. & qty_kg==.
			replace unit="9B" if unitlabel==29 & hh_g02==411 & kg_convwt==. & qty_kg==.
			replace unit="9" if (unitlabel==30 | unit=="9C") & hh_g02==411 & kg_convwt==. & qty_kg==.
			* Recode heap
			replace unit="10A" if unitlabel==38 & hh_g02==411 & kg_convwt==. & qty_kg==.
			replace unit="10B" if unitlabel==39 & hh_g02==411 & kg_convwt==. & qty_kg==.
			replace unit="10C" if unitlabel==40 & hh_g02==411 & kg_convwt==. & qty_kg==.
		// Mushroom
		tab2 unit unitlabel if hh_g02==413 & convertedtokg==0,m
		tab unitlabel if hh_g02==413 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==413 & convertedtokg==0
			* Recode piece
			replace unit="9" if inlist(unitlabel,28,30) & hh_g02==413 & kg_convwt==. & qty_kg==.
			replace unit="9" if unit=="23" & other_unit=="MUSHROOMS" & hh_g02==413 & kg_convwt==. & qty_kg==.
			* Recode heap
			replace unit="10" if inlist(unitlabel,38,39,40) & hh_g02==413 & kg_convwt==. & qty_kg==.
		// Eggs
		tab2 unit unitlabel if hh_g02==501 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==501 & convertedtokg==0
			* Recode piece
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==501 & kg_convwt==. & qty_kg==.		
			replace unit="9" if other_unit=="SMALLPIECE" & hh_g02==501 & kg_convwt==. & qty_kg==.
		// Dried fish
		tab2 unit unitlabel if inlist(hh_g02,502,5021,5022,5023) & convertedtokg==0,m
			* Recode piece
			replace unit="9" if inlist(unit,"9E","9F") & inlist(hh_g02,502,5021,5022,5023) & kg_convwt==. & qty_kg==.		
		// Fresh fish
		tab2 unit unitlabel if inlist(hh_g02,503,5031,5032,5033) & convertedtokg==0,m
		tab other_unit if unit=="23" & inlist(hh_g02,503,5031,5032,5033) & convertedtokg==0
			* Recode piece
			replace unit="9" if unit=="9E" & inlist(hh_g02,503,5031,5032,5033) & kg_convwt==. & qty_kg==.		
		// Chicken
		tab2 unit unitlabel if hh_g02==508 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==508 & convertedtokg==0
			* Recode piece
			replace unit="9" if inlist(unit,"9A","9C") & hh_g02==508 & kg_convwt==. & qty_kg==.		
			replace unit="9" if other_unit=="WHOLE CHICKEN" & hh_g02==508 & kg_convwt==. & qty_kg==.		
		// Insects
		tab2 unit unitlabel if hh_g02==511 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==511 & convertedtokg==0
			* Plate and heap - remove subunit
			replace unit="6" if unit=="6A" & hh_g02==511 & kg_convwt==. & qty_kg==.		
			replace unit="10" if unit=="10C" & hh_g02==511 & kg_convwt==. & qty_kg==.		
			* Ambiguous plate - take midpoint
			replace kg_convwt=0.115 if region==1 & unit=="23" & other_unit=="PLATE" & hh_g02==511 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.105 if region==2 & unit=="23" & other_unit=="PLATE" & hh_g02==511 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.085 if region==3 & unit=="23" & other_unit=="PLATE" & hh_g02==511 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="PLATE" & hh_g02==511 & qty_kg==. & kg_convwt!=.
			replace other_unit="PLATE - MIDPOINT BETWEEN ALL WHERE NOT SPECIFIED" if unit=="23" & other_unit=="PLATE" & hh_g02==511 & kg_convwt!=. & qty_kg!=.  
			replace convertedtokg=1 if unit=="23" & hh_g02==511 & other_unit=="PLATE - MIDPOINT BETWEEN ALL WHERE NOT SPECIFIED" & convertedtokg==0 & kg_convwt!=. & qty_kg!=.									
			* Combine TINA
			replace unit="25" if other_unit=="TINA(SMALL)" & hh_g02==511 & kg_convwt==. & qty_kg==.	
		// Tinned meat/fish
		tab2 unit unitlabel if hh_g02==512 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==512 & convertedtokg==0
			* Recode piece as tin
			replace unit="17" if unit=="9" & hh_g02==512 & kg_convwt==. & qty_kg==.		
		// Smoked fish
		tab2 unit unitlabel if inlist(hh_g02,513,5121,5122,5123) & convertedtokg==0,m
			* Heap unspecified - assume medium
			replace unit="10B" if inlist(unit,"10","10C","10D","10E","10F") & inlist(hh_g02,513,5121,5122,5123) & kg_convwt==. & qty_kg==.		
		// Mango
		tab2 unit unitlabel if hh_g02==601 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==601 & convertedtokg==0
			* Remove subunits
			replace unit="4" if unit=="4A" & hh_g02==601 & kg_convwt==. & qty_kg==.		
			replace unit="8" if inlist(unit,"8A","8C") & hh_g02==601 & kg_convwt==. & qty_kg==.		
			* Recode pail
			replace unit="4" if inlist(other_unit,"MEDIUMPALL","PAIL","PAIL (MEDIUM)") & unit=="23" & hh_g02==601 & kg_convwt==. & qty_kg==.		
		// Banana
		tab2 unit unitlabel if hh_g02==602 & convertedtokg==0,m 
		tab unitlabel if hh_g02==602 & convertedtokg==0, sum(unitlabel)
			* Treat cluster as equivalent to bunch - METHOD NOTE
			replace unit="8A" if unit=="44A" & hh_g02==602 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="8B" if unit=="44B" & hh_g02==602 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="8C" if unit=="44C" & hh_g02==602 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Select medium bunch and piece where unspecified
			replace unit="8B" if unit=="8" & hh_g02==602 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="9B" if unit=="9" & hh_g02==602 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Heap - remove subunit
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==602 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Citrus
		tab2 unit unitlabel if hh_g02==603 & convertedtokg==0,m 
		tab other_unit if unit=="23" & hh_g02==603 & convertedtokg==0, sum(unitlabel)
			* Piece - remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==603 & kg_convwt==. & qty_kg==.		
		// Pineapple
		tab2 unit unitlabel if hh_g02==604 & convertedtokg==0,m 
		tab other_unit if unit=="23" & hh_g02==604 & convertedtokg==0, sum(unitlabel)
		// Papaya
		tab2 unit unitlabel if hh_g02==605 & convertedtokg==0,m 
			* Piece - remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==605 & kg_convwt==. & qty_kg==.		
		// Guava
		tab2 unit unitlabel if hh_g02==606 & convertedtokg==0,m 
		// Avocado
		tab2 unit unitlabel if hh_g02==607 & convertedtokg==0,m 
			* Piece - remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==607 & kg_convwt==. & qty_kg==.		
		// Wild fruit
		tab2 unit unitlabel if hh_g02==608 & convertedtokg==0,m 
		tab other_unit if unit=="23" & hh_g02==608 & convertedtokg==0, sum(unitlabel)
			* Piece - remove subunit
			replace unit="9" if unit=="9B" & hh_g02==608 & kg_convwt==. & qty_kg==.		
		// Apple
		tab2 unit unitlabel if hh_g02==609 & convertedtokg==0,m 
			* Piece - remove subunit
			replace unit="9" if inlist(unit,"9A","9C") & hh_g02==609 & kg_convwt==. & qty_kg==.		
		// Powdered milk
		tab2 unit unitlabel if hh_g02==702 & convertedtokg==0,m 
		tab unitlabel if hh_g02==702 & convertedtokg==0,m 
			* Recode packet assuming equivalent to a sachet/tube
			replace unit="22" if inlist(unit,"51","60") & hh_g02==702 & kg_convwt==. & qty_kg==.
		// Margarine
		tab2 unit unitlabel if hh_g02==703 & convertedtokg==0,m 
		tab other_unit if unit=="23" & hh_g02==703 & convertedtokg==0, sum(unitlabel)
			* Recode satchet to grams specified
			replace kg_convwt=0.15 if unit=="23" & other_unit=="SATCHET (150 GRAM)" & hh_g02==703 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="SATCHET (150 GRAM)" & hh_g02==703 & qty_kg==. & kg_convwt!=.
			replace unit="1" if other_unit=="SATCHET (150 GRAM)" & hh_g02==703 & kg_convwt!=. & qty_kg!=.
			replace convertedtokg=1 if unit=="1" & other_unit=="SATCHET (150 GRAM)" & hh_g02==703 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.									
			* Recode tin
			replace unit="17" if other_unit=="TIN" & hh_g02==703 & kg_convwt==. & qty_kg==.
		// Sugar
		tab2 unit unitlabel if hh_g02==801 & convertedtokg==0,m
		tab unitlabel if hh_g02==801 & convertedtokg==0,m
		tab unitlabel if hh_g02==801 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==801 & convertedtokg==0, sum(unitlabel)
			* Remove subunits
			replace unit="6" if inlist(unit,"6A","6B") & hh_g02==801 & kg_convwt==. & qty_kg==.		
			replace unit="7" if unit=="7C" & hh_g02==801 & kg_convwt==. & qty_kg==.		
			replace unit="22" if inlist(unit,"22A","22B","22C") & hh_g02==801 & kg_convwt==. & qty_kg==.		
			* Recode others - assume satchet=packet
			replace unit="16" if unit=="23" & other_unit=="CUP" & hh_g02==801 & kg_convwt==. & qty_kg==.
			replace unit="22" if unit=="23" & inlist(other_unit,"PACKET","PACKET (SMALL)","PACKET(SMALL)","TUBE (MEDIUM)","TUBE /SACHET") & hh_g02==801 & kg_convwt==. & qty_kg==.
			replace unit="22" if unit=="60" & hh_g02==801 & kg_convwt==. & qty_kg==.
			* Recode sachet into grams wehre specified
			replace kg_convwt=0.025 if unitlabel==41 & hh_g02==801 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unitlabel==41 & hh_g02==801 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unitlabel==41 & hh_g02==801 & kg_convwt!=. & qty_kg!=.
			replace convertedtokg=1 if unit=="1" & unitlabel==41 & hh_g02==801 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.									
			replace kg_convwt=0.05 if unitlabel==42 & hh_g02==801 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unitlabel==42 & hh_g02==801 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unitlabel==42 & hh_g02==801 & kg_convwt!=. & qty_kg!=.
			replace convertedtokg=1 if unit=="1" & unitlabel==42 & hh_g02==801 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.									
			replace kg_convwt=0.1 if unitlabel==43 & hh_g02==801 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unitlabel==43 & hh_g02==801 & qty_kg==. & kg_convwt!=.
			replace unit="1" if unitlabel==43 & hh_g02==801 & kg_convwt!=. & qty_kg!=.
			replace convertedtokg=1 if unit=="1" & unitlabel==43 & hh_g02==801 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.									
			* Combine TINA
			replace unit="25" if unit=="23" & inlist(other_unit,"TINA(FLAT)","TINA(SMALL") & hh_g02==801 & kg_convwt==. & qty_kg==.			
		// Sugar cane
		tab2 unit unitlabel if hh_g02==802 & convertedtokg==0,m
		tab unitlabel if hh_g02==802 & convertedtokg==0, sum(unitlabel)
			* Piece - Remove subunit
			replace unit="9" if (inlist(unit,"9A","9B","9C") | (unit=="23" & other_unit=="MEDIUMPEACE")) & hh_g02==802 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Satchet - remove subunit
			replace unit="22" if inlist(unit,"22A","22B") & hh_g02==802 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Cooking oil
		tab unit if hh_g02==803 & convertedtokg==0
		tab other_unit if unit=="23" & hh_g02==803 & convertedtokg==0
			* Assume medium if sachet size is not listed
			replace unit="22B" if unit=="22" & hh_g02==803 & convertedtokg==0
			* Recode others, assume medium if size is not specified
			replace unit="22A" if unit=="23" & other_unit=="PACKET (SMALL)" & hh_g02==803 & convertedtokg==0
			replace unit="22B" if unit=="23" & inlist(other_unit,"MIDEUMSACHET","SATCHETTUBE(MEDIUM)","TUBE","TUBE (MEDIUM)","TUBE /SACHET","TUBES(MEDIUM)" )& hh_g02==803 & convertedtokg==0
			replace unit="22C" if unit=="23" & other_unit=="TUBE (LARGE)" & hh_g02==803 & convertedtokg==0
			* Milligrams
			replace kg_convwt=0.00001 if unit=="23" & inlist(other_unit,"MILIGRAM","MILLIGRAM") & hh_g02==803 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if unit=="23" & inlist(other_unit,"MILIGRAM","MILLIGRAM") & hh_g02==803 & qty_kg==. & kg_convwt!=.
			replace unit="23" if unit=="23" & inlist(other_unit,"MILIGRAM","MILLIGRAM") & hh_g02==803  & convertedtokg==0 & qty_kg!=.
			replace other_unit="milligram" if unit=="23" & inlist(other_unit,"MILIGRAM","MILLIGRAM") & hh_g02==803  & convertedtokg==0 & qty_kg!=.
			replace convertedtokg=1 if unit=="23" & inlist(other_unit,"MILIGRAM","MILLIGRAM") & hh_g02==803  & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
		// Salt
		tab2 unit unitlabel if hh_g02==810 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==810 & convertedtokg==0	
		tab other_unit if unit=="6" & hh_g02==810 & convertedtokg==0, sum(unitlabel)	
			* Heap - remove subunit
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==810 & convertedtokg==0 & kg_convwt!=. & qty_kg==. & kg_convwt==.		
			* No 12 plate - remove subunit
			replace unit="7" if inlist(unit,"7A","7B","7C") & hh_g02==810 & convertedtokg==0 & kg_convwt!=. & qty_kg==. & kg_convwt==.	
			* Tablespoon - metric tablespoon = 0.02 kg
			replace kg_convwt=0.02 if unit=="59" & hh_g02==810 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if unit=="59" & hh_g02==810 & qty_kg==. & kg_convwt!=.
			replace unit="23" if unit=="59" & hh_g02==810 & convertedtokg==0 & qty_kg!=.
			replace other_unit="tablespoon" if unit=="23" & hh_g02==810 & convertedtokg==0 & qty_kg!=.
			replace convertedtokg=1 if unit=="23" & hh_g02==810 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.
			* No. 10 plate flat/heaped unspecified - assume midpoint
			replace kg_convwt=0.185 if region==1 & inlist(unit,"6","6C") & hh_g02==810 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.215 if region==2 & inlist(unit,"6","6C") & hh_g02==810 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.205 if region==3 & inlist(unit,"6","6C") & hh_g02==810 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if inlist(unit,"6","6C") & hh_g02==810 & qty_kg==. & kg_convwt!=.
			replace convertedtokg=1 if inlist(unit,"6","6C") & hh_g02==810 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
			* Other plate (small) - assume No. 10 plate 
			replace unit="6" if unit=="23" & other_unit=="PLATE (SMALL)" & hh_g02==810 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Cup - 1 US cup = 0.26 kg
			replace kg_convwt=0.26 if unit=="23" & other_unit=="CUP" & hh_g02==810 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="CUP" & hh_g02==810 & qty_kg==. & kg_convwt!=.
			replace convertedtokg=1 if unit=="23" & other_unit=="CUP" & hh_g02==810 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.
			* Teaspoon
			replace kg_convwt=0.01 if unit=="23" & other_unit=="TEASPOON" & hh_g02==810 & convertedtokg==0
			replace qty_kg=qty*kg_convwt if unit=="23" & other_unit=="TEASPOON" & hh_g02==810 & qty_kg==. & kg_convwt!=.
			replace convertedtokg=1 if unit=="23" & other_unit=="TEASPOON" & hh_g02==810 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
		// Maize from vendor
		tab2 unit unitlabel if hh_g02==820 & convertedtokg==0,m
			* Piece - Remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==820 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Chips from vendor
		tab2 unit unitlabel if hh_g02==821 & convertedtokg==0,m
		tab unitlabel if hh_g02==821 & convertedtokg==0, sum(unitlabel)
		tab other_unit if unit=="23" & hh_g02==821 & convertedtokg==0	
			* Remove subunits
			replace unit="6" if inlist(unit,"6A","6B","6C") & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="7" if unit=="7B" & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace unit="10" if inlist(unit,"10A","10B","10C") & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Combine TINA
			replace unit="25" if inlist(unitlabel,57,58) & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			* Code unspecified plate and bag as midpoint of plates
			replace kg_convwt=0.265 if region==1 & unit=="23" & inlist(other_unit,"JUMBO","PLASTIC","PLATE","PLATES","POLYTHENE BAG","POLYTHENE BAG (SMALL)","SMALL JUMBO") & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.275 if region==2 & unit=="23" & inlist(other_unit,"JUMBO","PLASTIC","PLATE","PLATES","POLYTHENE BAG","POLYTHENE BAG (SMALL)","SMALL JUMBO") & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace kg_convwt=0.235 if region==3 & unit=="23" & inlist(other_unit,"JUMBO","PLASTIC","PLATE","PLATES","POLYTHENE BAG","POLYTHENE BAG (SMALL)","SMALL JUMBO") & hh_g02==821 & convertedtokg==0 & qty_kg==. & kg_convwt==.
			replace qty_kg=qty*kg_convwt if unit=="23" & inlist(other_unit,"JUMBO","PLASTIC","PLATE","PLATES","POLYTHENE BAG","POLYTHENE BAG (SMALL)","SMALL JUMBO") & hh_g02==821 & qty_kg==. & kg_convwt!=.
			replace convertedtokg=1 if unit=="23" & inlist(other_unit,"JUMBO","PLASTIC","PLATE","PLATES","POLYTHENE BAG","POLYTHENE BAG (SMALL)","SMALL JUMBO") & hh_g02==821 & convertedtokg==0 & kg_convwt!=. & qty_kg!=.			
			replace other_unit="Bags and plates coded as midpoint between No. 10 and No. 12 plate" if unit=="23" & inlist(other_unit,"JUMBO","PLASTIC","PLATE","PLATES","POLYTHENE BAG","POLYTHENE BAG (SMALL)","SMALL JUMBO") & hh_g02==821
		// Cassava from vendor
		tab2 unit unitlabel if hh_g02==822 & convertedtokg==0,m
			* Piece - Remove subunit
			replace unit="9" if inlist(unit,"9A","9B") & hh_g02==822 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Chicken from vendor
		tab2 unit unitlabel if hh_g02==824 & convertedtokg==0,m
			* Piece - Remove subunit
			replace unit="9" if unit=="9A" & hh_g02==824 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Meat from vendor
		tab2 unit unitlabel if hh_g02==825 & convertedtokg==0,m
		tab other_unit if unit=="23" & hh_g02==825 & convertedtokg==0	
			* Piece - Remove subunit
			replace unit="9" if unit=="9C" & hh_g02==825 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Fish from vendor
		tab2 unit unitlabel if hh_g02==826 & convertedtokg==0,m
			* Piece - Remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==826 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Mandazi from vendor
		tab2 unit unitlabel if hh_g02==827 & convertedtokg==0,m
			* Piece - Remove subunit
			replace unit="9" if inlist(unit,"9A","9B","9C") & hh_g02==827 & convertedtokg==0 & qty_kg==. & kg_convwt==.
		// Samosa from vendor
		tab2 unit unitlabel if hh_g02==828 & convertedtokg==0,m
			* Piece - Remove subunit
			replace unit="9" if unit=="9A" & hh_g02==828 & convertedtokg==0 & qty_kg==. & kg_convwt==.

* Use cup as the closest approximation for TINA
	replace unit="16" if inlist(unit,"25","25A","25B") & convertedtokg==0 & qty_kg==. & kg_convwt==.
	replace unit="16" if inlist(unitlabel,15,57,58) & convertedtokg==0 & qty_kg==. & kg_convwt==.
	
* Create new variable for item merge to combine groundnut and fishes disaggregated into more items in later rounds
ren hh_g02 food_no // Renames for subsequent use preserving labels
gen hh_g02=food_no // creates a copy for the purposes of final matches to converstion factors
replace hh_g02=304 if inlist(food_no,311,312)
replace hh_g02=502 if inlist(food_no,5021,5022,5023)
replace hh_g02=503 if inlist(food_no,5031,5032,5033)
replace hh_g02=503 if inlist(food_no,5121,5122,5123)
		
* Merge conversion factors in again for updated items
drop kg_convwt1 kg_convwt0
merge m:1 hh_g02 unit region using UnitConversionFactors
drop if _merge==2
drop _merge
replace kg_convwt=kg_convwt1 if kg_convwt==. & kg_convwt1!=.
replace kg_convwt=kg_convwt0 if kg_convwt==. & kg_convwt1==. & kg_convwt0!=.
replace qty_kg=qty*kg_convwt if qty_kg==. & kg_convwt!=.
replace convertedtokg=1 if qty_kg!=.

tab convertedtokg, m
tab hh_g02 if convertedtokg==0, sum(hh_g02)
tab hh_g02 if convertedtokg==0
tab unit if convertedtokg!=1
tab hh_g02 unitlabel if convertedtokg!=1
tab unitlabel if convertedtokg!=1, sum(unitlabel)
tab unitlabel if convertedtokg!=1
tab other_unit if unit=="23" & convertedtokg!=1

* Keep converting - Conversion factors from Aqua-Calc per above
	// Kg
	replace kg_convwt=1 if unit=="1" & convertedtokg==0
		replace qty_kg=qty if unit=="1" & convertedtokg==0
		replace convertedtokg=1 if unit=="1" & convertedtokg==0 & qty_kg!=.
	// Cup - 1 metric cup used
	* Maize flour - corn flour unenriched, white
	tab hh_g02 if convertedtokg==0 & unit=="16", sum(food_no)
	replace kg_convwt=0.12 if unit=="16" & inlist(food_no,101,102) & convertedtokg==0
		replace qty_kg=qty if unit=="16" & inlist(food_no,101,102)  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & inlist(food_no,101,102) & convertedtokg==0 & qty_kg!=.
	* Sorghum grain
	replace kg_convwt=0.2 if unit=="16" & food_no==108  & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==108  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==108 & convertedtokg==0 & qty_kg!=.
	* Pearl millet
	replace kg_convwt=0.21 if unit=="16" & food_no==109  & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==109  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==109 & convertedtokg==0 & qty_kg!=.
	* Breakfast cereal - corn flakes
	replace kg_convwt=0.03 if unit=="16" & food_no==115 & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==115  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==115 & convertedtokg==0 & qty_kg!=.
	* Soybean flour - soy flour, full fat, raw
	replace kg_convwt=0.09 if unit=="16" & food_no==306 & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==306  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==306 & convertedtokg==0 & qty_kg!=.
	* Fresh milk - milk, whole, without added vitamins
	replace kg_convwt=0.25 if unit=="16" & food_no==701 & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==701  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==701 & convertedtokg==0 & qty_kg!=.
	* Boiled groundnuts - peanuts, boiled in shell
	replace kg_convwt=0.07 if unit=="16" & food_no==833 & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==833  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==833 & convertedtokg==0 & qty_kg!=.
	* popcorn - peanuts, boiled in shell
	replace kg_convwt=0.01 if unit=="16" & food_no==835 & convertedtokg==0
		replace qty_kg=qty if unit=="16" &  food_no==835  & convertedtokg==0
		replace convertedtokg=1 if unit=="16" & food_no==835 & convertedtokg==0 & qty_kg!=.

* Check rationality of reported total consumption
	tempvar qty_tot_kg_rptd2
	gen `qty_tot_kg_rptd2'=qty_kg 
		replace `qty_tot_kg_rptd2'=0 if source!=1
	tempvar qty_tot_kg_rptd
		egen `qty_tot_kg_rptd'=total(`qty_tot_kg_rptd2'), by(HHID case_id y2_hhid y3_hhid data_round date_consump hh_g02) 
	tempvar totalcheck2
		gen `totalcheck2'=qty_kg
		replace `totalcheck2'=0 if source==1
	tempvar totalcheck
		egen `totalcheck'=total(`totalcheck2'), by(HHID case_id y2_hhid y3_hhid data_round date_consump hh_g02)
	// Scale reported quantities by source so that the total sums to reported total -- METHOD NOTE
	tab hh_g02 if `totalcheck'>`qty_tot_kg_rptd' & source==1
		tempvar sourcescale
			bys HHID case_id y2_hhid y3_hhid data_round date_consump hh_g02: ///
				gen `sourcescale'=(`totalcheck'/`qty_tot_kg_rptd')
			replace qty_kg=qty_kg/`sourcescale' if source!=1 ///
				& `totalcheck'>`qty_tot_kg_rptd'
	tab hh_g02 if `totalcheck'<`qty_tot_kg_rptd' & source==1 // May have reported total but unknown source, do not correct
	gen source_uncertain=0
		replace source_uncertain=1 if `totalcheck'<`qty_tot_kg_rptd'
		lab var source_uncertain "Sources Un- or Under-Reported"
	tab2 hh_g02 source_uncertain 

* rename
drop hh_g02 
lab var region "Region"

save FoodItems_Conversion, replace

// PART 3 // MERGE WITH NUTRIENT PROFILES
* Merge with household data
destring, replace
misstable sum case_id HHID y2_hhid y3_hhid data_round, all
merge m:m food_no using FoodComp // m:m necessary because there are 2 values for infant formula for 2 age groups
tab2 food_no _merge if _merge==2 | _merge==1 // Other foods, maheu, thobwa - missing food compostion
	// Only drop food items from CPI data
	drop if case_id==. // introduced by import excel
drop _merge hh_g01 USDA_code USDA_name MW_code MW_name FCT_note MW_source FCT_Source_Primary ///
	other_name FoodEx2_code FoodEx2_name volume note note2 COICOP_code COICOP_name kg_convwt ///
	FCT_source_filter vitA_source retinol_source refusal_pct qty unit
sort case_id HHID y2_hhid y3_hhid data_round food_no source
* Change the nutrients composition data to be unit per kg (now is per 100g)
	foreach v in $nutrients {
		replace `v'=`v'*10
		lab var `v' "`v' per kg"
		}

// PART 4 // CALCULATE TOTAL HOUSEHOLD INTAKES
* Rename nutrients variables
sum $nutrients
rename ($nutrients) (nutr#), addnumber(2)
sum nutr*
gen nutr1=. // Nutrient #1 is price in the least cost diet, added here so the numbering stays the same through reshapes etc
order case_id HHID y2_hhid y3_hhid date_consump data_round food_no source, first
order nutr*, after(source)
order nutr1, before(nutr2)
order region qty_kg source_uncertain, before(nutr1)

gen energy_perkg=nutr2
reshape long nutr, i(case_id HHID y2_hhid y3_hhid date_consump data_round food_no ///
	source) j(nutr_no)
	
	ren nutr nutr_perkg
	lab var nutr_perkg "Nutrient composition per kg - in specified nutrient unit"

gen nutr_dens=nutr_perkg if !inlist(nutr_no,1,2)
	lab var nutr_dens "Nutrient density of food item, per nutrient"
	
* Generate total nutrient intakes by food item and source
	gen tot_nutr_byfood_bysource=qty_kg*nutr_perkg 
	drop nutr_perkg
	
order case_id HHID y2_hhid y3_hhid date_consump data_round region year month ///
	hh_g09 district hh_g00_1 hh_g00_2

* Reshape wide by source
cap drop __*
drop convertedtokg other_unit unitlabel subunit kg_convwt0 kg_convwt1
reshape wide tot_nutr_byfood_bysource qty_kg, ///
	i(case_id HHID y2_hhid y3_hhid date_consump data_round food_no formula_agegroup nutr_no) j(source)

ren qty_kg1 qty_kg_total
	lab var qty_kg_total "Total food item quantity (kg) consumed"
ren qty_kg2 qty_kg_buy
	lab var qty_kg_buy "Total food item quantity (kg) reported from purchases"
ren qty_kg3 qty_kg_ownprod
	lab var qty_kg_ownprod "Total food item quantity (kg) reported from own production"
ren qty_kg4 qty_kg_giftoth
	lab var qty_kg_giftoth "Total food item quantity (kg) reported from gifts/other"
ren tot_nutr_byfood_bysource1 tot_nutr_byfood_total
	lab var tot_nutr_byfood_total "Total nutrient quantity (nutrient unit) consumed per food item"
ren tot_nutr_byfood_bysource2 tot_nutr_byfood_buy
	lab var tot_nutr_byfood_buy "Total nutrient quantity (nutrient unit) reported from purchase per food item"
ren tot_nutr_byfood_bysource3 tot_nutr_byfood_ownprod
	lab var tot_nutr_byfood_ownprod "Total nutrient quantity (nutrient unit) reported from own production per food item"
ren tot_nutr_byfood_bysource4 tot_nutr_byfood_giftoth
	lab var tot_nutr_byfood_giftoth "Total nutrient quantity (nutrient unit) reported from gifts/other per food itemr"
order qty*, after(food_no)
order tot_nut* nutr_dens, after(nutr_no)
drop energy_perkg

* Generate unit costs
gen unit_cost=hh_g05/qty_kg_buy
	lab var unit_cost "Unit cost, MWK per kg"
	tab food_no, sum(unit_cost)
	
* Generate market dependence measure per food item (percent purchased)
gen pct_buy=qty_kg_buy/qty_kg_total
	lab var pct_buy "Percent of quantity (in kg) from purchases out of total kg consumed"
	tab food_no, sum(pct_buy)
	
save HHIntakes_fooditem, replace

* Collapse to nutrient level (note source is still long)
use HHIntakes_fooditem, clear

drop qty_kg_total qty_kg_buy qty_kg_ownprod qty_kg_giftoth formula_agegroup ///
	hh_g05 fooditem food_group food_group_name MWI_food_group ///
	MWI_food_group_name unit_cost 
		
	* Save labels
	foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
		}
	}
	* Collapse
	collapse (sum) tot_nutr* (mean) pct_buy nutr_dens source_uncertain ///
		(first) region year month hh_g09 district hh_g00_1 hh_g00_2, ///
		by(case_id HHID y2_hhid y3_hhid date_consump data_round nutr_no)
			
* Rename and relabel
	* Relabel
	foreach v of var * {
 	label var `v' "`l`v''"
		}
	lab var source_uncertain "Percentage of all foods with un/under-reported sources"
	lab var pct_buy "Average percentage of all foods from purchase"
	lab var nutr_dens "Average nutrient density over all foods in the diet, per nutrient"

	ren tot*_byfood_* tot*_*
	ren tot_nutr_total hh_tot_intake
		lab var hh_tot_intake "Household total nutrient intake (nutrient unit)"
	lab var tot_nutr_buy "Total nutrient intake (nutrient unit) from purchases)"
	lab var tot_nutr_ownprod "Total nutrient intake (nutrient unit) from own production)"
	lab var tot_nutr_giftoth "Total nutrient intake (nutrient unit) from gifts/other)"
	
* Generate percentage of each nutrient by source
gen pct_nutr_buy=tot_nutr_buy/hh_tot_intake
	lab var pct_nutr_buy "Percent of nutrient reported from purchases"

tab nutr_no, sum(hh_tot_intake)
tab nutr_no, sum(pct_nutr_buy)
sum pct_buy, d // average total foods from purchase
tab nutr_no, sum(nutr_dens) // average density of observed diets in each nutrient

save HHIntakes, replace

// PART 5 // MERGE WITH HOUSEHOLD NUTRIENT NEEDS
use HHNeeds_HHLevel, clear // check using data
sum case_id HHID y2_hhid y3_hhid data_round nutr_no date_consump
unique case_id HHID y2_hhid y3_hhid data_round nutr_no date_consump
distinct case_id HHID y2_hhid y3_hhid data_round nutr_no

use HHIntakes, clear
sum case_id HHID y2_hhid y3_hhid data_round nutr_no date_consump
unique case_id HHID y2_hhid y3_hhid data_round nutr_no date_consump
distinct case_id HHID y2_hhid y3_hhid data_round nutr_no

merge 1:1 case_id HHID y2_hhid y3_hhid data_round nutr_no date_consump using HHNeeds_HHLevel
	unique case_id HHID y2_hhid y3_hhid data_round if _merge==1 // 10 households
drop if _merge==1 // household with no consumption date
drop _merge

* Reduce the bioavailability assumption of iron and zinc
	/* Iron
	Reduce Iron bioavailability assumption to 10% (from 18%)
		o 18% assumption is relevant to mixed North American diet with more ASFs
		o 10% assumption better estimates the more basic, high phytate and low ASF diet in rural Malawi
		o Justification of 10% selection:	
			- IOM (2006, p. 334): IOM DRIs assume 10% bioavailablity for children <2,
				characterizing their diet as one with few animal-source foods and 
				highly cereal-based, a description consistent with the rural
				population in developing countries
			- WHO (2004, p. 270): For developing country populations two levels of
				bioavailability are likely appropriate 5% and 10% based largely on
				the presence of meat or not. A more western-diet is characterized by
				12-15% bioavailability. Absorption increases with lower stores, but
				phytates strongly inhibit absorption, both of which characterize
				rural agricultural populations and their diets. 
				-- Given the objective of the CoNA to estimate a healthy diet, the 
					unhealthy diet characterized by 5% bioavailability would not be 
					an appropriate benchmark. 
		o In practice: multiply the EAR by .18 to derive the absorbed iron needs
			- Then divide the absorbed requirement by 1.1 to estimate revised dietary intake 
	// Zinc
	Increase dietary zinc requirement to reflect a lower bioavailability assumption of 22% (from assumed 30-40%)
		o 30-40% assumption is relevant to mixed North American diet with more ASFs
		o 22% assumption better estimates the more basic, high phytate and low ASF diet in rural Malawi
		o Justification of 22% selection:	
			For zinc, the IOM describes 3 bioavailability scenarios (low, medium, high) 
			and diets characterizing each scenario in an identical manner to the UN. 
			The more specific methodological documentation (IOM 2001 pp.464–467) notes that 
			the dietary zinc requirement is based on a 4-step process and results in a
			fractional absorption (bioavailability) percentage as follows:
				Lifestage (age-gender)	Fractional absorption
				Children <14	0.3
				Adolescents (14-18)	0.4
				Adult men	0.41
				Adult women (non-pregnant)	0.48
				Pregnant women	0.27
			The studies upon which the requirements are based are thought to reflect 
			diets with favorable zinc bioavailability (IOM 2001, p.473). Furthermore, 
			the IOM notes that vegetarian diets may require up to 50% more dietary zinc
			intake to account for the high phytate:zinc ratio and low or no consumption 
			of zinc in its more bioavailable forms (IOM 2001, p.480; 2006, p.405). 
			The UN defines the scenarios by percent bioavailability of dietary zinc 
			at 15% for low, 30% for moderate, and 50% for high (2004, p.237). In both 
			documents, the description of non-vegetarian diets common among the poor 
			in developing countries are those characterized as low or between the low 
			and moderate bioavailability scenarios. 
			
			METHOD NOTE: to recalculate the absorbed zinc requirement, multiply by .35 
				the average percent over age-gender groups, then divide by .22 again
				the average percent over groups with lower bioavailablity in the diet. */
				
	foreach v in EAR_sharing EAR_targeting {
		gen iron_18pct_`v'=`v' if nutr_no==18
		replace `v'=(`v'*(.18))/(.1) if nutr_no==18 // absorbed iron requirement
		gen zinc_40pct_`v'=`v' if nutr_no==22
		replace `v'=(`v'*(.35))/(.22) if nutr_no==22 // absorbed zinc requirement

	}
	sum EAR_sharing if nutr_no==18, d
	sum iron_18pct_EAR_sharing if nutr_no==18, d
	sum EAR_sharing if nutr_no==22, d
	sum zinc_40pct_EAR_sharing if nutr_no==22, d


// PART 6 // GENERATE ADEQUACY RATIOS

tab nutr_no, sum(EAR_sharing)
tab nutr_no, sum(hh_tot_intake)

* Sharing
	* Nutrient Adequacy Ratio
		cap drop hnar_share
		gen hnar_share=.
		forval n=2/23 {
			replace hnar_share=hh_tot_intake/EAR_sharing if nutr_no==`n'
			}
		replace hnar_share=. if inlist(nutr_no,1,7)
		// Define macronutrients as adequate (HNAR=1) if in AMDR range
		* If insufficient, ratio below minium (AMDR lower bound as denominator)
		* If excess, ratio above maximum (AMDR upper bound as upper bound)
			replace hnar_share=1 if inlist(nutr_no,3,4,5) ///
				& hh_tot_intake>=AMDRlow_sharing & hh_tot_intake<=AMDRup_sharing
			replace hnar_share=hh_tot_intake/AMDRlow_sharing if hh_tot_intake<AMDRlow_sharing & inlist(nutr_no,3,4,5)
			replace hnar_share=hh_tot_intake/AMDRup_sharing if hh_tot_intake>AMDRup_sharing & inlist(nutr_no,3,4,5)
		tab nutr_no, sum(hnar_share)
		tab nutr_no if hnar_share>=1, sum(hnar_share)
			lab var hnar_share "HNAR, sharing"
		* Energy adjusted
		tempvar Eadj1
		gen `Eadj1'=hnar_share
		replace `Eadj1'=. if nutr_no!=2
		tempvar Eadj2
		bys case_id HHID y2_hhid y3_hhid data_round: egen `Eadj2'=total(`Eadj1')
		cap drop hnar_share_Eadjusted
		gen hnar_share_Eadjusted=hnar_share/`Eadj2'
		lab var hnar_share_Eadjusted "Energy-adjusted HNAR, sharing"
			tab nutr_no, sum(hnar_share_Eadjusted)
			
* Individualized
		* Nutrient Adequacy Ratio
		cap drop hnar_target
		gen hnar_target=.
		forval n=2/23 {
			replace hnar_target=hh_tot_intake/EAR_targeting if nutr_no==`n'
			}
		replace hnar_target=. if inlist(nutr_no,1,7)
		// Define macronutrients as adequate (HNAR=1) if in AMDR range
		* If insufficient, ratio below minium (AMDR lower bound as denominator)
		* If excess, ratio above maximum (AMDR upper bound as upper bound)
			replace hnar_target=1 if inlist(nutr_no,3,4,5) ///
				& hh_tot_intake>=AMDRlow_targeting & hh_tot_intake<=AMDRup_sharing
			replace hnar_target=hh_tot_intake/AMDRlow_targeting if hh_tot_intake<AMDRlow_targeting & inlist(nutr_no,3,4,5)
			replace hnar_target=hh_tot_intake/AMDRup_targeting if hh_tot_intake>AMDRup_targeting & inlist(nutr_no,3,4,5)
				tab nutr_no, sum(hnar_target)
		tab nutr_no if hnar_target>=1, sum(hnar_target)
		lab var hnar_target "HNAR, targeting"

* Energy adjusted HNAR
		tempvar Eadj1_l
		gen `Eadj1_l'=hnar_target
		replace `Eadj1_l'=. if nutr_no!=2
		tempvar Eadj2_l
		bys case_id HHID y2_hhid y3_hhid data_round: egen `Eadj2_l'=total(`Eadj1_l')
		cap drop hnar_target_Eadjusted
		gen hnar_target_Eadjusted=hnar_target/`Eadj2_l'
		lab var hnar_target_Eadjusted "Energy-adjusted HNAR, targeting"
			tab nutr_no, sum(hnar_target_Eadjusted)
			
sum hnar* 
tabstat hnar_share, by(nutr_no) stats(mean sd p50 min max)
cap drop __*

* Calculate excessive intakes indicator
cap drop exceedUL_share
gen exceedUL_share=.
replace exceedUL_share=1 if hh_tot_intake>UL_sharing
replace exceedUL_share=0 if hh_tot_intake<=UL_sharing
tab nutr_no, sum(exceedUL_share)

gen exceedAMDR_share=.
replace exceedAMDR_share=1 if hh_tot_intake>AMDRup_sharing
replace exceedAMDR_share=0 if hh_tot_intake<=AMDRup_sharing

	* Energy adjusted
	tempvar Eadj1
	gen `Eadj1'=hnar_share
	replace `Eadj1'=. if nutr_no!=2
	tempvar Eadj2
	bys case_id HHID y2_hhid y3_hhid data_round: egen `Eadj2'=total(`Eadj1')
	cap drop hh_tot_intake_Eadjusted
	tempvar hh_tot_intake_Eadjusted
		gen `hh_tot_intake_Eadjusted'=hh_tot_intake/`Eadj2'
bys nutr_no: sum `hh_tot_intake_Eadjusted'
tab nutr_no, sum(UL_sharing)

cap drop exceedUL_share_Eadjusted
gen exceedUL_share_Eadjusted=.
replace exceedUL_share_Eadjusted=1 if `hh_tot_intake_Eadjusted'>UL_sharing
replace exceedUL_share_Eadjusted=0 if `hh_tot_intake_Eadjusted'<=UL_sharing
tab nutr_no, sum(exceedUL_share_Eadjusted)

gen exceedAMDR_share_Eadjusted=.
replace exceedAMDR_share_Eadjusted=1 if `hh_tot_intake_Eadjusted'>AMDRup_sharing
replace exceedAMDR_share_Eadjusted=0 if `hh_tot_intake_Eadjusted'<=AMDRup_sharing
 

* Calculate nutrient source percents
gen pctnut_own=tot_nutr_ownprod/hh_tot_intake
	replace pctnut_own=pctnut_own*100
	lab var pctnut_own "Percent of total intake from own production"
gen pctnut_buy=tot_nutr_buy/hh_tot_intake
	replace pctnut_buy=pctnut_buy*100
	lab var pctnut_buy "Percent of total intake from purchases"
		
merge 1:m case_id HHID y2_hhid y3_hhid date_consump data_round nutr_no using ///
	HHNeeds_IndivLevel, keepusing(age_sex_grp PID kcal_perday amdr_lower_perweek amdr_upper_perweek ///
	 ear_perweek ul_perweek nomeals AME HH_AME_total indivfoodshare *perkcal)

lab var amdr_lower_perweek "Individual AMDR Lower bound"
lab var amdr_upper_perweek "Individual AMDR Upper bound"
lab var ear_perweek "Individual EAR"
lab var ul_perweek "Individual UL"

save HHAdequacyRatios_IndivLevel, replace

// PART 8 // Consumption Aggregate - Food
use HHIntakes_fooditem, clear

* Collapse to food item level (now food x nutrient)
	* Save labels
	foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
		}
	}
	* Collapse
	collapse (first) qty_kg_total-pct_buy, ///
		by(case_id HHID y2_hhid y3_hhid date_consump data_round food_no)
			
* Rename and relabel
	* Relabel
	foreach v of var * {
 	label var `v' "`l`v''"
		}

ren unit_cost unitcost_hh
	// Generate Year-month variable
	cap drop dateMY
	gen dateMY=ym(year, month)
	format dateMY %tmCCYY-NN
	tab dateMY, m
		lab var dateMY "Date (Month-Year)"
sort food_no dateMY ea_id ta_code district region

* Generate median prices by geographic aggregate, by month-year date
tab food_no, sum(unitcost_hh)
bys food_no: sum unitcost_hh, d
	egen unitcost_ea=median(unitcost_hh), by(food_no dateMY ea_id)
		tempvar eacost_count
			egen `eacost_count'=count(unitcost_hh), by(food_no dateMY ea_id)
				tab food_no, sum(`eacost_count')
				tab food_no if `eacost_count'<=5 | `eacost_count'==.
			replace unitcost_ea=. if (`eacost_count'<=5 | `eacost_count'==.) ///
				& unitcost_hh==.
	egen unitcost_ta=median(unitcost_hh), by(food_no dateMY ta_code)
		tempvar tacost_count
			egen `tacost_count'=count(unitcost_hh), by(food_no dateMY ta_code)
				tab food_no, sum(`tacost_count')
				tab food_no if `tacost_count'<=5 | `tacost_count'==. 
			replace unitcost_ta=. if (`tacost_count'<=5 | `tacost_count'==.) ///
				& (unitcost_ea==. & unitcost_hh==.)
	egen unitcost_district=median(unitcost_hh), by(food_no dateMY district)
		tempvar districtcost_count
			egen `districtcost_count'=count(unitcost_hh), by(food_no dateMY ta_code)
				tab food_no, sum(`districtcost_count')
				tab food_no if (`districtcost_count'<=5 | `districtcost_count'==.) & ///
					(unitcost_ta==. & unitcost_ea==.)
				replace unitcost_district=. if (`districtcost_count'<=5 | `districtcost_count'==.) & ///
					(unitcost_ta==. & unitcost_ea==. & unitcost_hh==.)
	egen unitcost_region=median(unitcost_hh), by(food_no dateMY region)
		tempvar regioncost_count
			egen `regioncost_count'=count(unitcost_hh), by(food_no dateMY region)
				tab food_no, sum(`regioncost_count')
				tab food_no if (`regioncost_count'<=5 | `regioncost_count'==.) & ///
					(unitcost_hh==. & unitcost_ta==. & unitcost_ea==. & unitcost_district==.)
				replace unitcost_region=. if (`regioncost_count'<=5 | `regioncost_count'==.) & ///
					(unitcost_ta==. & unitcost_ea==. & unitcost_hh==. & unitcost_district==.)
	egen unitcost_urbanrural=median(unitcost_hh), by(food_no reside dateMY)
		tempvar urbanrural_count
			egen `urbanrural_count'=count(unitcost_hh), by(food_no reside dateMY)
				tab food_no, sum(`urbanrural_count')
				tab food_no if (`urbanrural_count'<=5 | `urbanrural_count'==.) & ///
					(unitcost_hh==. & unitcost_ea==. & unitcost_ta==. & unitcost_district==. ///
					& unitcost_region==.)
				replace unitcost_urbanrural=. if (`urbanrural_count'<=5 | `urbanrural_count'==.) & ///
					(unitcost_hh==. & unitcost_ea==. & unitcost_ta==. & unitcost_district==. ///
					& unitcost_region==.)
	egen unitcost_date=median(unitcost_hh), by(food_no dateMY)
				
* Generate unit cost & document the price source by food item
	gen unitcost=.
	gen unitcost_source=.
	replace unitcost=unitcost_hh if unitcost_hh!=. & qty_kg_total!=0 & qty_kg_total!=.
		replace unitcost_source=1 if unitcost_hh!=. & unitcost!=.
	replace unitcost=unitcost_ea if unitcost==. & unitcost_ea!=. & ///
		qty_kg_total!=0 & qty_kg_total!=.
		replace unitcost_source=2 if unitcost_hh==. & unitcost_ea!=. & unitcost!=.
	misstable sum unitcost if qty_kg_total!=0 & qty_kg_total!=.
	tab food_no if qty_kg_total!=0 & qty_kg_total!=. & unitcost==.
	replace unitcost=unitcost_ta if unitcost==. & unitcost_ea==. ///
		& unitcost_ta!=. & qty_kg_total!=0 & qty_kg_total!=.
		replace unitcost_source=3 if unitcost_hh==. & unitcost_ea==. & unitcost_ta!=. ///
			& unitcost!=.
	replace unitcost=unitcost_district if unitcost==. & unitcost_ea==. ///
		& unitcost_ta==. & unitcost_district!=. & ///
		qty_kg_total!=0 & qty_kg_total!=.
		replace unitcost_source=4 if unitcost_hh==. & unitcost_ea==. & unitcost_ta==. ///
			& unitcost_district!=. & unitcost!=.
	replace unitcost=unitcost_region if unitcost==. & unitcost_ea==. ///
		& unitcost_ta==. & unitcost_district==. & unitcost_region!=. & ///
		qty_kg_total!=0 & qty_kg_total!=.
		replace unitcost_source=5 if unitcost_hh==. & unitcost_ea==. & unitcost_ta==. ///
			& unitcost_district==. & unitcost_region!=. & unitcost!=.
	replace unitcost=unitcost_urbanrural if unitcost==. & unitcost_ea==. ///
		& unitcost_ta==. & unitcost_district==. & unitcost_region==. ///
			& unitcost_urbanrural!=. & qty_kg_total!=0 & qty_kg_total!=.
		replace unitcost_source=6 if unitcost_hh==. & unitcost_ea==. & unitcost_ta==. ///
			& unitcost_district==. & unitcost_region==. & unitcost_urbanrural!=. & unitcost!=.
	cap lab drop costsource
	lab def costsource 1 "HH" 2 "EA" 3 "TA" 4 "District" 5 "Region" 6 "Urban/Rural"
		lab var unitcost_source costsource
tab food_no, sum(unitcost)
bys unitcost_source: tab food_no, sum(unitcost)
tab food_no if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
	* Replace with national median by date and month if nothing else
	replace unitcost=unitcost_date if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
tab food_no if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
	// 422 records still cannot be priced - use district by year
	egen unitcost_district_year=median(unitcost_hh), by(food_no district year)
		replace unitcost=unitcost_district_year if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
tab food_no if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
	// 132 records still cannot be priced - use national (urban/rural) by year
		egen unitcost_urbanrural_year=median(unitcost_hh), by(food_no reside year)
		replace unitcost=unitcost_urbanrural_year if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
tab food_no if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
	// 38 records still cannot be priced - use urban/rural over all years
		egen unitcost_urbanrural_all=median(unitcost_hh), by(food_no reside)
		replace unitcost=unitcost_urbanrural_all if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
tab food_no if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
	// 17 records remain - use all records all years
		egen unitcost__all=median(unitcost_hh), by(food_no)
		replace unitcost=unitcost__all if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
tab food_no if unitcost==. & qty_kg_total!=. & qty_kg_total!=0
	
	// Trim outliers following NSO [Malawi] 2018 "Methodology for Poverty Measurement (2016/2017)"
	* Replace outliers (defined as >5sds from mean) with 95th and 5th percentiles
	sum unitcost, d
		tempvar outlierhi
		gen `outlierhi'=r(mean)+(5*r(sd))
		tempvar outlierlo
		gen `outlierlo'=r(mean)-(5*r(sd))
		replace unitcost=r(p95) if unitcost>=`outlierhi' & unitcost!=.
		replace unitcost=r(p5) if unitcost<=`outlierlo'
	sum qty_kg_total, d
		tempvar outlierhi
		gen `outlierhi'=r(mean)+(5*r(sd))
		tempvar outlierlo
		gen `outlierlo'=r(mean)-(5*r(sd))
		replace qty_kg_total=r(p95) if qty_kg_total>=`outlierhi' & qty_kg_total!=.
		replace qty_kg_total=r(p5) if qty_kg_total<=`outlierlo'

* Generate total expenditure
gen item_expenditure=qty_kg_total*unitcost
preserve
		collapse (sum) item_expenditure, by(case_id HHID ///
			y2_hhid y3_hhid date_consump data_round)
		gen totalexp_food=item_expenditure*52
		drop item_expenditure 
			lab var totalexp_food "Annualized Expenditure - Food"
		save HHConsumption_Food, replace
restore

egen totalexp_food_weekly=total(item_expenditure), by(case_id HHID ///
	y2_hhid y3_hhid date_consump data_round)
	lab var totalexp_food_weekly "Total Weekly Food Expenditure"
gen totalexp_food=totalexp_food_weekly*52
	lab var totalexp_food "Annualized Expenditure - Food"

save HHConsumption_FoodItemLevel, replace

// PART 8 // Consumption Aggregate - Non-Food
* Durable Goods
use HH_10_Assets, clear
append using HH_13_Assets, force
append using HH_16_Assets, force

tab hh_l02, sum(hh_l02)

	// Calculate the average age of the good
	* Average age
	egen avg_asset_age=mean(hh_l04), by(hh_l02 data_round)
	bys data_round: tab hh_l02, sum(avg_asset_age)
	lab var avg_asset_age "Average Age (Years), by data round)
	* Remaining lifetime
	gen remaining_life=(2*avg_asset_age)-hh_l04
		// Cars & motorcycles:
		replace remaining_life=3*hh_l04 if inlist(hh_l02, 517, 518)
		// Replace if negative
		replace remaining_life=2 if remaining_life<=0 & remaining_life!=.
	* Annual use value
	gen annual_use_value=hh_l05/remaining_life
	gen annual_use_value_total=annual_use_value*hh_l03
	
	// Total consumption
	collapse (sum) annual_use_value_total, ///
		by(case_id HHID y2_hhid y3_hhid date_consump data_round)
	ren annual_use_value_total totalexp_durables

save HHConsumption_Durables, replace

* Non-food consumables
	// Past Week
	use "$rawdata$ihpsraw\hh_mod_i1_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		tab hh_i02
		tempfile consumables_week_10
			save `consumables_week_10', replace
	use "$rawdata$ihpsraw\hh_mod_i1_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		tempfile consumables_week_13
			save `consumables_week_13', replace
	use "$rawdata$ihpsraw\hh_mod_i1_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace
	append using `consumables_week_10', force
	append using `consumables_week_13', force
	
	collapse (sum) hh_i03, by(case_id HHID y2_hhid y3_hhid date_consump data_round)
	gen totalexp_consumables=hh_i03*52
		lab var totalexp_consumables "Annualized Expenditure - Consumables"
		sort case_id HHID data_round 
	drop hh_i03
	bys data_round: sum totalexp_consumables, d
	
	tempfile consumables_week
		save `consumables_week', replace
	
	// Past month
	use "$rawdata$ihpsraw\hh_mod_i2_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		tab hh_i05
		tempfile consumables_month_10
			save `consumables_month_10', replace
	use "$rawdata$ihpsraw\hh_mod_i2_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		tempfile consumables_month_13
			save `consumables_month_13', replace
	use "$rawdata$ihpsraw\hh_mod_i2_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace
	append using `consumables_month_10', force
	append using `consumables_month_13', force
		
	collapse (sum) hh_i06, ///
		by(case_id HHID y2_hhid y3_hhid date_consump data_round)
	gen totalexp_consumables=hh_i06*12
		sort case_id HHID data_round 
		drop hh_i06
	bys data_round: sum totalexp_consumables, d
	
	tempfile consumables_month
		save `consumables_month', replace

	// Past 3 months
	use "$rawdata$ihpsraw\hh_mod_j_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		tab hh_j02
		tempfile consumables_3months_10
			save `consumables_3months_10', replace
	use "$rawdata$ihpsraw\hh_mod_j_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		tempfile consumables_3months_13
			save `consumables_3months_13', replace
	use "$rawdata$ihpsraw\hh_mod_j_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace
	append using `consumables_3months_10', force
	append using `consumables_3months_13', force
		
	collapse (sum) hh_j03, ///
		by(case_id HHID y2_hhid y3_hhid date_consump data_round)
	gen totalexp_consumables=hh_j03*4
	sort case_id HHID data_round 
	drop hh_j03
	bys data_round: sum totalexp_consumables, d

	tempfile consumables_3months
		save `consumables_3months', replace
	
	// Past year
	use "$rawdata$ihpsraw\hh_mod_k_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		tab hh_k02
		tempfile consumables_year_10
			save `consumables_year_10', replace
	use "$rawdata$ihpsraw\hh_mod_k_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		tempfile consumables_year_13
			save `consumables_year_13', replace
	use "$rawdata$ihpsraw\hh_mod_k1_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace	
	append using `consumables_year_10', force
	append using `consumables_year_13', force
		* Drop items excluded from consumption aggregate
		tab hh_k02, sum(hh_k02)
		drop if inlist(hh_k02,415,416,417,418)
	collapse (sum) hh_k03, ///
		by(case_id HHID y2_hhid y3_hhid date_consump data_round)
	ren hh_k03 totalexp_consumables
	sort case_id HHID data_round 
	bys data_round: sum totalexp_consumables, d
	tempfile consumables_year
		save `consumables_year', replace

use `consumables_year', clear
append using `consumables_3months', force
append using `consumables_month', force
append using `consumables_week', force
collapse (sum) totalexp_consumables, ///
	by(case_id HHID y2_hhid y3_hhid date_consump data_round)
lab var totalexp_consumables "Annualized Expenditure - Consumables"

save HHConsumption_Consumables, replace

* Imputed rent & utilities
	use "$rawdata$ihpsraw\hh_mod_f_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		// Fix rent variable to merge with future rounds
		tab hh_f04b, sum(hh_f04b)
		tempfile rentutil_10
			save `rentutil_10', replace
	use "$rawdata$ihpsraw\hh_mod_f_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		// Fix rent variable to merge with future rounds
		tab hh_f04b, sum(hh_f04b)
		tempfile rentutil_13
			save `rentutil_13', replace
	use "$rawdata$ihpsraw\hh_mod_f_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace
		// Fix rent variable to merge with future rounds
	append using `rentutil_10', force
	append using `rentutil_13', force

	// Generate rent variables
	gen annualrent=.
		replace annualrent=hh_f04a if hh_f04b==6
		replace annualrent=hh_f04a*12 if hh_f04b==5
		replace annualrent=hh_f04a*52 if hh_f04b==4
		replace annualrent=hh_f04a*365 if hh_f04b==3
	gen estimatedrent=.
		replace estimatedrent=hh_f03a if hh_f03b==6
		replace estimatedrent=hh_f03a*12 if hh_f03b==5
		replace estimatedrent=hh_f03a*52 if hh_f03b==4
		replace estimatedrent=hh_f03a*365 if hh_f03b==3
	gen time=hh_f03b if hh_f03a!=. & hh_f01!=6
		replace time=hh_f04b if hh_f04a!=. & hh_f01==6
			tab time, m
			lab def time 1 "?" 3 "Daily" 4 "Weekly" 5 "Monthly" 6 "Annual"
			lab val time time
	tab time
		* Address missing data (time period)
		sum annualrent, d // Reported rent
		sum estimatedrent, d // Estimated rent that could be received
		tab hh_f01
		tab hh_f01, sum(hh_f01)
		sum case_id if annualrent==. & estimatedrent==.
		sum hh_f03a hh_f03b hh_f04a hh_f04b hh_f04_4 ///
			if annualrent==. & estimatedrent==.
		sum hh_f03a if annualrent==. & estimatedrent==.
		sum annualrent
		replace estimatedrent=hh_f03a*12 ///
			if estimatedrent==. & annualrent==.
		replace estimatedrent=hh_f04a*12 ///
			if estimatedrent==. & annualrent==.
		sum hh_f03a hh_f03b hh_f04a hh_f04b hh_f04_4 ///
			if annualrent==. & estimatedrent==.
	
	// Hedonic rent model
		* Combine reported rent and estimated rental value
			gen rent=annualrent if annualrent!=.
			replace rent=estimatedrent if annualrent==.
			tab rent, m
				lab var rent "Annualized Value - Rent"
		* Log rent
		gen logrent=log(rent)
		* Included attributes of housing:
			// Number of rooms, wall, roof, floor
			// Services available: type of drinking water, toilet, electricity
			// Region and time fixed effects (urban, region, district, year, month)
		reg logrent hh_f10 hh_f07 hh_f08 hh_f09 hh_f36 hh_f40 ///
			hh_f41 hh_f19 hh_f27 reside region district year month		
		predict renthat_log
		gen renthat=exp(renthat_log)
		sum renthat, d
		* Insufficient observations to impute rent, replace with outlier bounds instead
		sum rent, d
			tempvar outlierlow
				gen `outlierlow'=r(mean)-(5*r(sd))
				scalar def oboundlo=r(mean)-(5*r(sd))
			tempvar outlierhi
				gen `outlierhi'=r(mean)+(5*r(sd))	
				scalar def oboundhi=r(mean)+(5*r(sd))
		replace rent=oboundhi if (rent>=`outlierhi') 
		replace rent=oboundlo if (rent<=`outlierlow')
	
	// Utilities
	gen water=hh_f37*12
		lab var water "Annualized expenditure - Water"
	gen firewood=hh_f18*52
		lab var firewood "Annualized expenditure - Firewood"
	tab hh_f26a 
	tab hh_f26b
	tab hh_f26b, sum(hh_f26b)
	gen electricity=hh_f25*12 if hh_f26b==5
		replace electricity=hh_f25*52 if hh_f26b==4
		replace electricity=hh_f25*365 if hh_f26b==3
		lab var electricity "Annualized expenditure - Electricity"
	gen phone=hh_f35*12
		lab var phone  "Annualized expenditure - Phone"

keep water phone firewood electricity rent case_id ///
	HHID y2_hhid y3_hhid data_round
	
generate totalexp_utilities=water+phone+firewood+electricity
ren rent totalexp_housing

drop water phone firewood electricity
		 
save HHConsumption_HousingUtilities, replace
	
* Health expenses
	use "$rawdata$ihpsraw\hh_mod_d_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		tempfile health_10
			save `health_10', replace
	use "$rawdata$ihpsraw\hh_mod_d_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		tempfile health_13
			save `health_13', replace
	use "$rawdata$ihpsraw\hh_mod_d_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace	
	append using `health_10', force
	append using `health_13', force
	
	// Spending in last 4 weeks
	egen health_month_PID=rowtotal(hh_d10 hh_d11 hh_d12)
	// Spending in last 12 months
	egen health_12month_PID=rowtotal(hh_d12_1 hh_d14 hh_d15 ///
		hh_d16 hh_d19 hh_d20 hh_d21)
	gen totalexp_health=(health_month_PID*12)+health_12month_PID
	collapse (first) totalexp_health, ///
		by(case_id HHID y2_hhid y3_hhid data_round)
	lab var totalexp_health "Annualized Expenditure - Health"
	sort case_id HHID data_round 
	bys data_round: sum totalexp_health, d

save HHConsumption_Health, replace

* Education expenses
	use "$rawdata$ihpsraw\hh_mod_c_10", clear
		sum HHID
		destring case_id, replace
		merge m:1 case_id HHID using HH_10, force
		misstable sum HHID data_round // check
		drop _merge
		tempfile edu_10
			save `edu_10', replace
	use "$rawdata$ihpsraw\hh_mod_c_13", clear
		count if y2_hhid!=""
		merge m:1 y2_hhid using HH_13
		drop _merge
		distinct y2_hhid
		destring case_id, replace
		tempfile edu_13
			save `edu_13', replace
	use "$rawdata$ihpsraw\hh_mod_c_16", clear
	count if y3_hhid!=""
	merge m:1 y3_hhid using HH_16
		drop _merge
		distinct y3_hhid
		destring, replace	
	append using `edu_10', force
	append using `edu_13', force
		* Check reported total
		tempvar totalcheck
			egen `totalcheck'=rowtotal(hh_c22a-hh_c22i) 	
			sum if `totalcheck'!=hh_c22j
		* Replace calculated total
		egen totalexp_edu=rowtotal(hh_c22a-hh_c22i)
	misstable sum case_id HHID y2_hhid y3_hhid data_round
	collapse (sum) totalexp_edu hh_c22j, ///
		by(case_id HHID y2_hhid y3_hhid data_round)
	lab var totalexp_edu "Annualized Expenditure - Education"
	lab var hh_c22j "Reported total expenditure - Education"
	sort case_id HHID data_round 
	bys data_round: sum totalexp_edu, d
	bys data_round: sum hh_c22j, d
	drop hh_c22j

save HHConsumption_Education, replace

* Merge Consumption Aggregate
use HHConsumption_Food
merge m:1 case_id HHID y2_hhid y3_hhid data_round using HHConsumption_Durables
drop _merge
merge m:1 case_id HHID y2_hhid y3_hhid data_round using HHConsumption_Consumables
drop _merge
merge m:1 case_id HHID y2_hhid y3_hhid data_round using HHConsumption_HousingUtilities
drop _merge 
merge m:1 case_id HHID y2_hhid y3_hhid data_round using HHConsumption_Health
drop _merge
merge m:1 case_id HHID y2_hhid y3_hhid data_round using HHConsumption_Education
drop _merge

* Generate consumption aggregate
egen totalexpenditure=rowtotal(totalexp_food totalexp_durables ///
	totalexp_consumables totalexp_housing ///
	totalexp_utilities totalexp_health totalexp_edu)
	
* Percent budget on food
gen pctfoodexp=totalexp_food/totalexpenditure
sum pctfoodexp, d

save HHConsumptionAggregate, replace
	
log close
