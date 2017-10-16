* This is part of the master dofile "MasterDofile_import_clean_check.do".


	* TO DO
	
		* DO SOMETHING ABOUT MULTIPLE LOGBOOKS !!!
		* EXPORT SOMTHING IF DUPLICATE IN THE LOGBOOK

*-------------------------------------------------------------------------------
* 0. Load RAW data
*-------------------------------------------------------------------------------		
		
	use "$fu2_eu_raw/RFR_FU2_EU_v1.6.dta", clear
	
	
	**** Minor fixes
	
	destring id_05 id_05_reenter, replace
		
*-------------------------------------------------------------------------------
* 1. Check against the logbook
*-------------------------------------------------------------------------------

	local logbook_date 


	**** Import and clean the logbook and put better labels
	
	preserve
	
		import excel using "$fu2_logbooks/Logbook of 15th Oct 2017.xlsx", firstrow clear
		
		
		drop if Date==. //Check this out !!!
		
# delimit ;
		rename (headid 
				interviewcompletedANDsentto 
				Reason1Permanentlymovedaway 
				HHreplaced 
				HHcodelinkedtoreplacement 
				HHcodelinkedtoduplicate 
				backcheck_sample 
				backcheckcompletedANDsentt 
				backcheckresult0Notvisited 
				thirdvisitresult0Responden
				backcheckcorrectionsmadetosu
				id_11	id_12	id_13	id_14	id_09	id_08	id_07	id_06) 
		   
				(id_05 
				complete 
				reason 
				replaced 
				linked_replacement 
				linked_duplicate 
				bc_sample 
				bc_completed 
				bc_notvisited 
				visit3_fail 
				bc_corrected
				pl_id_11	pl_id_12	pl_id_13	pl_id_14	pl_id_09	pl_id_08	pl_id_07	pl_id_06) ;

# delimit cr				
				
		label var id_05 	"HH ID"
		label var pl_id_06  "Village"
		label var pl_id_07  "Cell"
		label var pl_id_08  "Sector"
		label var pl_id_09  "District"
		label var pl_id_11  "HHH name"
		label var pl_id_12  "HHH national ID"
		label var pl_id_13  "Spouse name"
		label var pl_id_14  "Spouse national ID"
		
		
		
		**** Drop columns and lines not surveyed yet
		drop if missing(complete) // this is because the table has all the HHs	
		keep if complete == 1 
		
		
		* Make sure all HH ID is unique in the logbook
		duplicates tag id_05, gen(duplicate)
		assert duplicate == 0 
		drop duplicate
	
		* Number of logged intervews
		egen day_count_log =count(_n), by(Date)
	
		* Save the logbook as a temp file
		tempfile logbook
		save `logbook'

	restore

	
	**** Merge logbook and server
	merge 1:1 id_05 using `logbook', gen(match_b)
	
	label define matched_log  1  "Server only" 2 "Logbook only" 3 "Both"
	
	label values match_b matched_log
	
	tab match_b
	
	//webdoc do "$fu2_eu_output/high_freq_check/teste.html"

	* Keep track of HHs which is surveyed but not in the logbook (_merge == -1) 
	//tab _merge, gen(mismatch)  
//	label mismatch1 "Surveyed but not in the logbook"
//	label variable mismatch1 "Server only"
//	label variable mismatch2 "Logbook only"
//	drop mismatch3
	
	**** Matching issues table
	preserve
		* Keep only the first columns to make it simpler 
		keep Date match_b simid devicephonenum text_audit id_03 start_mod_a id_04 id_05 id_05_reenter pl_id_06 pl_sample pl_id_07 pl_id_08 pl_id_09	pl_id_11 pl_id_12 pl_hhhs pl_hhhs_id pl_hhsize pl_id_13 pl_id_14
		keep if (match_b == 1 | match_b == 2)
		order match_b
		export delimited "$fu2_eu_output\high_freq_check\duplicates\mismatch_list_`c(current_date)'", replace
		export delimited "$fu2_eu_output\high_freq_check\duplicates\mismatch_list_most_recent'", replace
	restore
	
	**** Check duplicates
	duplicates tag id_05, gen(duplicate)
	assert duplicate == 0 
	tab duplicate
	
	**** Show how many duplicates daily in a graph
	
	if	duplicate > 0 {
		hist duplicate, freq ytitle("Number of HHs") xtitle("Number of duplicates") title("Frequency of duplicates") note(`c(current_date)' `c(current_time)')
		graph export "$fu2_eu_output\high_freq_check\duplicates\duplicates_numbers.png", replace
 
	
	
	**** Graph comparing server with logbook
	preserve
		gen 	in_log=0
		replace in_log=1 if match_b == 2 | match_b == 3
		label variable in_log "Logbook"
		
		
		gen 	in_serv=0
		replace in_serv=1 if match_b == 1 | match_b == 3
		label variable in_serv "Server"
		
		collapse (sum) in_log in_serv, by(Date)
		
		twoway (connected in_log in_serv Date)
	
		graph export "$fu2_eu_output\high_freq_check\logbook_vs_server.png", replace

	restore

	**** Spit out a list of HH that are duplicated
	preserve
		keep if duplicate > 0
		order duplicate
		save "$fu2_eu_output\high_freq_check\duplicates\duplicates_list_`c(current_date)'.dta", replace
		export delimited "$fu2_eu_output\high_freq_check\duplicates\duplicates_list_`c(current_date)'", replace
	restore
	
	}
	else {
		di "No duplicates"
	}
	
	
	**** Graph comparing server with logbook
	
//	egen day_count_serv =count(_n), by(Date)
	
//	twoway (connected day_count_serv day_count_log Date)
	
//	graph export "$fu2_eu_output\high_freq_check\logbook_vs_server.png", replace
	
	* keep running tab of number of HHs replaced (could be moved, deceased, refused) by village and by enumerator

	
		**** Week variable
		//g week=ceil((starttime-svystart)/7)
		//assert week!=.
		//su week
	
*------------------
* 2. Check missings for whole modules
*------------------	
/*	
	* All observations are missings (there is a comand for that)
	* missings tag (number od missings) - gen a variable to see if == to N
	
	qui nmissing, min(*)	
	tempname 	all_missings
	cap file close 	`all_missings'	
	file open  	`all_missings' using "$fu2_eu_output/all_missings.txt", text write replace
		
		*Add some text to the file
		file write  `all_missings' ///
			"`r(varlist)'"
		
		*Closing the file
		file close 		`all_missings'
	
	
		**** Create data set with a list of variables with missings in all entries
	
	local allmissVarList ""
	
	foreach allmissVar of varlist _all {
		cap assert mi(`allmissVar')
		if !_rc {
			local allmissVarList "`allmissVarList' `allmissVar'"
		}
	}
	
	preserve
		
		tempfile All_Missings
		
		clear
		gen 	Variable = ""
		
		set obs `: word count `allmissVarList''
		
		forvalues varNo = 1/`: word count `allmissVarList'' {
			
			replace Variable = "`:word `varNo' of `allmissVarList''" in `varNo'
			
		}
		
		
		//dataout, save("$HFC/Raw files/delete_me") tex mid(1) replace
		//filefilter 	"$HFC/Raw files/delete_me.tex" "$HFC/Raw files/allmiss.tex", 	///
		//			from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
		//			replace
		
		save `All_Missings', replace
	restore 
	
	
	**** Create data set with a list of all variables
	preserve		
		tempfile All_Variables
		
		* Local with all variables
		qui ds
		local allVarList `r(varlist)'
		
		* Create a data frame with only the names (Thank you Stata)
		clear
		gen 	Variable = ""
		
		set obs `: word count `allVarList''
		
		forvalues varNo = 1/`: word count `allVarList'' {
			
			replace Variable = "`:word `varNo' of `allVarList''" in `varNo'
			
		}
	
		merge 1:1 Variable using `All_Missings', gen(_miss)
		
	
		* Module variable
		gen module = ""
		
		// Gambiarra: This is terrible, I know.
		//replace module="B" if inlist(Variable, "b_start_note", "b_start_noteadd", "pl_member_1", "pl_member_2", "pl_member_3", "pl_member_4", "pl_member_5", "pl_member_6", "pl_member_7", "pl_member_8", "pl_member_9", "pl_member_10", "pl_member_11", "pl_member_12", "pl_member_13", "pl_member_14", "pl_member_15", "pl_age_1", "pl_age_2", "pl_age_3", "pl_age_4", "pl_age_5", "pl_age_6", "pl_age_7", "pl_age_8",	"pl_age_9",	"pl_age_10",	"pl_age_11",	"pl_age_12",	"pl_age_13",	"pl_age_14",	"pl_age_15",	"pl_ovr18_1",	"pl_ovr18_2",	"pl_ovr18_3",	"pl_ovr18_4",	"pl_ovr18_5",	"pl_ovr18_6",	"pl_ovr18_7",	"pl_ovr18_8",	"pl_ovr18_9",	"pl_ovr18_10",	"pl_ovr18_11",	"pl_ovr18_12",	"pl_ovr18_13",	"pl_ovr18_14",	"pl_ovr18_15",	"pl_sex_1",	"pl_sex_2",	"pl_sex_3",	"pl_sex_4",	"pl_sex_5",	"pl_sex_6",	"pl_sex_7",	"pl_sex_8",	"pl_sex_9",	"pl_sex_10",	"pl_sex_11",	"pl_sex_12",	"pl_sex_13",	"pl_sex_14",	"pl_sex_15",	"b_moved1",	"ros_01",	"ROS_01_a",	"ROS_01_b",	"ROS_01_b1",	"b_moved1",	"b_moved2",	"ROS_01_b_fu",	"no_frompl",	"no_left",	"ROS_01_b1_fu",	"ROS_01_c_fu",	"b_moved2",	"ROS_02_a",	"ROS_02_a1",	"old_hhmember",	"new_hhmember",	"new_hhsize",	"hh_type",	"curr_roster",	"curr_index",	"pl_id",	"name_old",	"sex_old",	"curr_new",	"new_count",	"add_notefu",	"add_note",	"ros_03g1",	"ros_03s1",	"name_new",	"id_22",	"ROS_02_c",	"sex_new",	"curr_new",	"curr_name",	"ros_04",	"curr_roster",	"hh_member_1",	"hh_member_2",	"hh_member_3",	"hh_member_4",	"hh_member_5",	"hh_member_6",	"hh_member_7",	"hh_member_8",	"hh_member_9",	"hh_member_10",	"hh_member_11",	"hh_member_12",	"hh_member_13",	"hh_member_14",	"hh_member_15",	"pid_1",	"pid_2",	"pid_3",	"pid_4",	"pid_5",	"pid_6",	"pid_7",	"pid_8",	"pid_9",	"pid_10",	"pid_11",	"pid_12",	"pid_13",	"pid_14",	"pid_15",	"sex_1",	"sex_2",	"sex_3",	"sex_4",	"sex_5",	"sex_6",	"sex_7",	"sex_8",	"sex_9",	"sex_10",	"sex_11",	"sex_12",	"sex_13",	"sex_14",	"sex_15",	"ros_note1",	"ros_note2",	"b",	"ros_03p",	"d3_name",	"b_grpold",	"pid_stillhere",	"pl_age",	"pl_ovr18_orig",	"ros_05_fu",	"ros_05_fu_fix",	"check_1_fu",	"ros_05_01_fu",	"pl_ovr18",	"ros_05_old",	"drop_down_old",	"b_grpold",	"b_grpadd",	"ros_05_new",	"check_1",	"ros_05_01_new",	"ovr_18",	"drop_down_add",	"b_grpadd",	"d3_age",	"d3_ovr18",	"ros_06",	"ros_07",	"b_g1",	"b_r2",	"season_id5",	"season_name5",	"b_01",	"b_02",	"b_03",	"check_2",	"b_05",	"check_3",	"b_07",	"b_08",	"b_08_01",	"b_09",	"check_4",	"b_11",	"check_5",	"b_13",	"b_14",	"b_14_01",	"b_15",	"check_6",	"b_17",	"check_7",	"b_g1",	"b",	"age_1",	"age_3",	"age_4",	"age_5",	"age_6",	"age_7",	"age_8",	"age_9",	"age_10",	"age_11",	"age_12",	"age_13",	"age_14",	"age_15",	"age_check_1",	"age_check_2",	"age_check_3",	"age_check_4",	"age_check_5",	"age_check_6",	"age_check_7",	"age_check_8",	"age_check_9",	"age_check_10",	"age_check_11",	"age_check_12",	"age_check_13",	"age_check_14",	"age_check_15",	"b_r3",	"season_idb",	"season_nameb",	"b_18",	"b_18_01",	"b_18_01o",	"b_r3",	"b2",	"b2_p",	"b2_name",	"b2",	"id_19")

		
		
		
		//Module B: Household Roster
	
		save `All_Variables', replace
	
	restore
	
	*/

*------------------
* 2. Check progress
*------------------
	
	* Number of surveys done per village
	
	* Number of surveys done per enumerator
	
*------------------
* 3. Duration check
*------------------

	* average interview length by day
	* average interview length by enumerator
	

*--------------------------------------
* 4. Compare backchecks to survey data
*--------------------------------------

	* most important - did HH report being interviewed? bc_b_00
	* then compare responses for the repeated questions
	* flag discrepancies
	* if more than 2 discrepancies then third visit is required so this goes back to field
	

	
	
/*-------------------
below here lower priority

*--------------------
* 4. HH roster checks
*--------------------

	* Number of HH members
	* Number of HHs no longer part of sample and why
	*
	
*-------------------
* 5. Number of crops
*-------------------

// This is Dena's code. The var names are same so it runs. But the output shoudl be graphs. 
// this matters because reducing number of crops reduces survey length; check by enumerator

	preserve
		*br d_02_1-d_02_11
		* Permanent crops
			egen tot_perm=rowtotal(d_02_1-d_02_11), missing
			reg tot_perm i.id_03
			egen sd_perm=sd(tot_perm)
			egen mn_perm=mean(tot_perm)
			table id_03, c(mean tot_perm p50 tot_perm n tot_perm) col format(%5.0g)
		* Seasonal crops
			egen tot_seas=rowtotal(d_05_1-d_05_14), missing
			reg tot_seas i.id_03
			table id_03, c(mean tot_seas p50 tot_seas n tot_seas) col format(%5.0g)
			egen sd_seas=sd(tot_seas)
			egen mn_seas=mean(tot_seas)
			g n=1
			collapse (sum) n  (mean) d_n_1 d_01 sd_seas sd_perm mn_seas mn_perm mn_enum_seas=tot_seas mn_enum_perm=tot_perm (p50) med_enum_seas=tot_seas med_enum_perm=tot_perm, by(id_03)
			g flag_seas=1 if mn_enum_seas<mn_seas-sd_seas
			g flag_perm=1 if mn_enum_perm<mn_perm-sd_perm
			tab1 flag*
			label var n "# of surveys"
			label var d_01 "perm crops (y/n)"
			label var d_n_1 "seasonal crops (y/n)"
			label var mn_enum_perm "Enumerator avg # of crops"
			label var med_enum_seas "Enumerator avg # of crops"
			
			egen mn_d_n_1= mean(d_n_1)
			egen mn_d_01= mean(d_01)
			label var mn_d_01 "mean sample perm crops (y/n)"
			label var mn_d_n_1 "mean sample seasonal crops (y/n)"
			g notes=""
			replace notes="Unusually low share of households responding yes" if d_01<.3 | d_n_1<.3
		cap export excel id_03 *d_01 *d_n_1 mn_enum_seas mn_seas mn_enum_perm mn_perm notes using "$temp/enum_summary_fromNL" if d_01<.3 | d_n_1<.3,first(varl) sheetreplace sheet(crops)
	restore

*----------------------------------
* 6. Check on the livestock section
*----------------------------------

	* Distribution of livestock 
	
	* Distribution of livestock products
	
*--------------------------
* 7. 4 most common expenses
*--------------------------

// !! To leo, this is dena's code. The var names are the same so the code seeems to work but please check!
// I also think that the result shoudl be graphed not a table. 
		//recode negatives
		recode e_04_?? (-66=.)  (-88=.)
		recode e_04_? (-66=.) (-88=.)
		table id_03, c(mean e_04_6 mean e_04_8 mean e_04_12 mean e_04_28) row
		/*logit e_04_8 i.id_03 
		logit e_04_28 i.id_03 
		logit e_04_12 i.id_03 
		logit e_04_6 i.id_03 
		*/
		preserve
			collapse e_04_6 e_04_8 e_04_12 e_04_28 ,by(id_03)
			foreach x in 6 8 12 28 {
				egen mn_e_04_`x'=mean(e_04_`x')
			}
			*export excel using "$temp/enum_summary_fromNL" ,first(varl) sheetreplace sheet(expenditures)
		
		restore

*-------------------------------------- 		
* 8. Appropriate Age of Main Respondent
*-------------------------------------- 
	
*-----------------------------------------------------
* 9. Check if the income section was filled out at all
*-----------------------------------------------------
	
