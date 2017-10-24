/*******************************************************************************
				Rwanda Rural Feeder Road IE EU Follow-up Sept. 2017			   

	PURPOSE		: 	Run high frequency checks for the backchek survey
	
	INPUT		:	
				
	OUTPUT		:

	WRITEN BY	:	Leonardo Viotti
	DATE		:	Oct 2017
	 	  																			
*******************************************************************************/

		********** TO DO **********

		* Format Graphs
			* Legend labels
			* Bar colors
	

			
			
********************************************************************************
* PART 0. Load RAW data
********************************************************************************		

	use "$fu2_eu_raw/RFR_FU_backcheck_v3", clear
	
********************************************************************************
* 1. Check interview and quality
********************************************************************************	
	
	**** Iinterviewed at all
	tab bc_b_00
	
	* Label interview variable
	label variable bc_b_00 "Was your HH interviewed?"
	
	label define 			interview_lab 1 "Yes" 0 "No"
	label values bc_b_00	interview_lab
	
	* Yes no variable for the graph
	
	gen 		int_yes =0
	replace 	int_yes =1 if bc_b_00 == 1
	label var 	int_yes "Yes"
	
	
	gen 		int_no =0
	replace 	int_no =1 if bc_b_00 == 0
	label var 	int_no "No"
	
	
	**** Quality of the intervuew

	
	* Label quality variable
	destring bc_b_05, replace
	
	label variable bc_b_05 "Was there any concern"
	
	label define 			concern_lab 1 "It went well" 2 "No" 3 "Yes"
	label values bc_b_05 	concern_lab
	
	* Create quality variable for graphic
	
	gen 		int_good =0
	replace 	int_good =1 if bc_b_05 == 1 | bc_b_05 == 2
	label var 	int_good "No"
	
	
	gen 		int_bad =0
	replace 	int_bad =1 if bc_b_05 == 3
	label var 	int_bad "Yes"
	
	* Concern graphic
	
	**** Flag those with issues
	
********************************************************************************
* PART 1. Check against the the proper survey - Interview
********************************************************************************
	
	**** Merge with server
	merge 1:1 id_05 using "$fu2_eu_raw/RFR_FU2_EU_v1.6.dta", keep(1 3)
	

	***************************************
	**** Variable Settings
	global teamVar 			id_04 
	global enumeratorVar	id_03		
	
	* Team list
	levelsof ${teamVar}, local(teamsList)
	global teamsList = "`teamsList'"
	
	* HHs
	global HHVar			id_05
	global DistVar			pl_id_09
	
	* District list 
	levelsof ${DistVar}, local(DistList)
	global DistList  "`DistList'"
	
	
	**************************************
	
	
	**** Graphics of interview by original enumarator	
	
	
	preserve
			
			tempfile enumINT
			
				* Calculate average
				collapse (sum) int_yes int_no int_good int_bad,  by ($enumeratorVar $teamVar)

				
				* Order enumerators (so plot looks nice)
				sort 	$teamVar 
				by 		$teamVar: gen order = _n
				
			save `enumINT'
			
		* Plot average duration per enumerator, save one plot per team
		
		foreach team of global teamsList {
		
			* Load team's data
			use 	`enumINT', clear
			keep if $teamVar == `team'
			
			decode ${enumeratorVar}, gen(enumeratorName)
			labmask order, val(enumeratorName)
			
			* Calculate number of valid observations
			//qui count if mean != .
		
			**** Interviewd at all
			graph 	hbar (sum) int_yes int_no, over(id_03, label(labsize(small))) ytitle("Share of responses") graphregion(color(white)) ///
				title("Was your HH interviewed? - Total reposes yes/no per enumarator (Team `team')", size(small)) ///
				bar(1, color(green)) bar(2, color(red)) ///
				legend( label(1 "Yes") label(2 "No"))
				
			graph export "$fu2_eu_output/high_freq_check/interviwed_yesno_team`team'.png", replace	
			
			
			**** Interview quality graphic by original enumarator
			graph 	hbar (sum) int_good int_bad, over(id_03)  ytitle("Enumerator") graphregion(color(white)) ///
				title("Concern with the interview? - Total reposes yes/no per enumarator (Team `team')", size(small)) ///
				bar(1, color(green)) bar(2, color(red)) ///				
				legend( label(1 "No") label(2 "Yes"))
		
			graph export "$fu2_eu_output/high_freq_check/interviwed_concern_team`team'.png", replace

		}
		
			
		restore

	
	
	
********************************************************************************
* PART 2. Check against the the proper survey - Number of discrepancies
******************************************************************************** 
	
	**** Check if the same person was interviewed
	
	gen 	flag_respondent = 0 if bc_b_01 ==1 									//bc_b_01: Were you the person who was interviewed?
	replace flag_respondent = 1 if bc_b_01 ==0
	
	**** Module B: Household Roster
	
	* Number of hh members
	destring new_hhsize, replace //Fix this
	
	gen 	flag_roster1 = 0
	replace	flag_roster1 = 1 if bc_b_07 != new_hhsize

	* How many HH members have left since this time last year?
	gen 	flag_roster2 = 0
	replace	flag_roster2 = 1 if bc_b_08 != ros_01_b1							
	
	* Sum of roster flags
	egen roster_flags=rowtotal(flag_roster1 flag_roster2)
	
	
	**** Module C: Land market
	
	* Have you or any other HH member sold any land in the last 12 months?
	gen 	flag_land1 = 0
	replace	flag_land1 = 1 if bc_c_01 != c_00_1a 
	
	* Have you or any other HH member purchased any land in the last 12 months?
	gen 	flag_land2 = 0
	replace	flag_land2 = 1 if bc_c_03 !=  c_00_1b 
	
	* Have you (or any other HH member) rented in any land over the last 12 months?
	gen 	flag_land3 = 0
	replace	flag_land3 = 1 if bc_c_05 != c_00_2 
	
	* Have you (or any other HH member) rented out any land over the last 12 months?
	gen 	flag_land4 = 0
	replace	flag_land4 = 1 if bc_c_06 != c_00_3 
	
	* Sum of land market flags
	egen land_flags=rowtotal(flag_land1 flag_land2 flag_land3 flag_land4)

	
	
	**** Module D1: Crop Production and Access to Markets
	
	* Did your HH cultivate any permanent crops in the last 12 months? / Do you have any permanent crops in your plots?
	gen 	flag_crop1 = 0
	replace	flag_crop1 = 1 if bc_d_01_yn !=  d_01

	// This stuff is a string of numbers - check out how to compare that
	//bc_d_01 != d_02 //What [permanent crops] did your hh grow in the last 12 months?
	
	* Different questions
	//bc_d_02_yn!=d_n_1	// Did your HH cultivate any seasonal crops during Season 2017B? / Did the household grow seasonal crops (including vegetables & tree crops) from season 16C - 17B? This includes Season 16C (July 2016-August 2016), Season 17A (September 2016 - February 2017) and Season 17B (March 2017 - June 2017).

	* Different questions
	//bc_d_02	!=  //Did you cultivate any of these seasonal crops on your plots in Season 17B?

	* Have you owned any of these livestock over the period from July 2016 to June 2017? Please select all that apply. // d_61	Which livestock have you owned during the period of past 12 months?
	gen 	flag_crop5 = 0
	replace	flag_crop5 = 1 if bc_d_04 != d_61 

	* Diferent questions - FIGURE WHICH NUMBER IN d2_02_03 IS FERTILIZER TO COMPARE
	//bc_d_06	!= d2_02_03 //Did you use any fertilizer in Season 17B? / Which type of inputs did you use during Sesaon 17B?
	
	
	* Sum of crop flags
	egen crop_flags=rowtotal(flag_crop1 flag_crop5)
	
	
	
	**** Module E: Income_Expenditure
	
	* Has anyone in your HH accessed a health center in the past 12 months? / Has anyone in your HH accessed this service in the past 12 months? ${service_name}
	gen 	flag_exp1 = 0
	replace	flag_exp1 = 1 if bc_e_01 != e_05_6 									// 6 is Health Center in preload services_list
	
	* What is the main mode of transport used to access the service facility?
	gen 	flag_exp2 = 0
	replace	flag_exp2 = 1 if bc_e_02	!= e_07_6
		
	* Sum of expenditure flags
	egen exp_flags=rowtotal(flag_exp1 flag_exp2)
	

	**** Total flags per enumerator
	egen tot_flags=rowtotal(roster_flags  land_flags crop_flags exp_flags)
	
	****************************************************************************
	**** Number of discrepancies per enumerator
	
	
	preserve
			
			tempfile enumflags
			
				* Calculate average
				collapse (sum) roster_flags  land_flags crop_flags exp_flags tot_flags,  by ($enumeratorVar $teamVar)

				
				* Order enumerators (so plot looks nice)
				sort 	$teamVar 
				by 		$teamVar: gen order = _n
				
			save `enumflags'
			
		* Plot average duration per enumerator, save one plot per team
		
		foreach team of global teamsList {
		
			* Load team's data
			use 	`enumflags', clear
			keep if $teamVar == `team'
			
			decode ${enumeratorVar}, gen(enumeratorName)
			labmask order, val(enumeratorName)
			
			* Calculate number of valid observations
			//qui count if mean != .
		
			graph hbar (mean) roster_flags  land_flags crop_flags exp_flags, over($enumeratorVar) ///
				ytitle("Enumerator") graphregion(color(white)) ///
				title("Number of differences Beckchecks and Server - Team `team'", size(small)) ///
				legend( label(1 "Roster") label(2 "Land market") label(3 "Crop Production") label(4 "Income and Expenditure") size(small))
				
			* Export graph
			graph export "$fu2_eu_output/high_freq_check/bc_differences_team`team'.png", width(5000) replace
				
			graph hbar (sum) tot_flags , over($enumeratorVar) ///
				ytitle("Enumerator") graphregion(color(white)) ///
				title(" Total number of flags per enumerator - Team `team'", size(small)) ///
				bar(1, color(red))
		
			* Export graph
			graph export "$fu2_eu_output/high_freq_check/bc_totflags_team`team'.png", width(5000) replace
				
			
		}
		
			
		restore

		
	****************************************************************************
	**** Number of discrepancies per HH
	
		
	preserve
			
			tempfile HHflags
			
				* Calculate average
				collapse (sum) roster_flags  land_flags crop_flags exp_flags tot_flags,  by ($HHVar $DistVar)

				
				* Order enumerators (so plot looks nice)
				sort 	$DistVar 
				by 		$DistVar: gen order = _n
				
			save `HHflags'
			
		* Plot average duration per enumerator, save one plot per team
		
		foreach dist of global DistList {

			* Load team's data
			use 	`HHflags', clear
			keep if $DistVar == "`dist'"
			
			* Calculate number of valid observations
			//qui count if mean != .
	
				
				di "Total number of flags per Household - `dist'"
			graph hbar (sum) tot_flags, over($HHVar) ///
				ytitle("Household ID") graphregion(color(white)) ///
				title("Total number of flags per Household - `dist'", size(small)) ///
				bar(1, color(red))
		
		
			* Export graph
			graph export "$fu2_eu_output/high_freq_check/bc_totflags_HH_`dist'.png", width(5000) replace
				
			
		}
		
			
	restore
