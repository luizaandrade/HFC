		
*-------------------------------------------------------------------------------
* 1. Check against the logbook
*-------------------------------------------------------------------------------

	**** Import and clean the logbook and put better labels
	
	preserve
	
		import excel using "$logbook", firstrow clear
		
		**** Fix if Date is string from Excel
		capture confirm numeric variable Date
        if _rc {
			split Date, parse("/") gen(Date_num)

			destring Date_num1, replace
			destring Date_num2, replace
			destring Date_num3, replace
			
			gen Date_num = mdy(Date_num1,Date_num2,Date_num3)
			drop Date
			rename Date_num Date
			
			drop Date_num*
			format 	Date %tdnn/dd/CCYY
		}
		
		
			drop if Date == .
			

		
		
# delimit ;
		rename (headid 
				interviewcompletedANDsentto 
				IfdroppedwhyReaso
				HHreplaced 
				HHcodelinkedtoreplacement 
				HHcodelinkedtoduplicate 
				backcheck_sample 
				backcheckcompletedANDsentt 
				backcheckresult0Notvisited 
				thirdvisitresult0Responden
				backcheckcorrectionsmadetosu
				id_11	id_12	id_13	id_14	id_09	id_08	id_07	id_06) 
		   
				(hhid 
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
				
		label var hhid	 	"HH ID"
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
		duplicates tag hhid, gen(duplicate)
		assert duplicate == 0 
		drop duplicate
	
		* Number of logged intervews
		egen day_count_log =count(_n), by(Date)
	
		* Save the logbook as a temp file
		tempfile logbook
		save `logbook'

	restore

	preserve
	
	**** Merge logbook and server
	merge 1:1 hhid using `logbook', gen(match_b)
	
	label define matched_log  1  "Server only" 2 "Logbook only" 3 "Both"
	
	label values match_b matched_log
	
	tab match_b
	
	
	
	**** Date fixes
	gen 	server_date = dofc( submissiondate )
	format 	server_date %tddd/Mon
	
	**** Get dates for interviews not in the logbook
	replace Date = server_date if Date==.
	
		
	tempfile match
	save `match'
	
	**** Graph comparing server with logbook
		gen 	in_log=0
		replace in_log=1 if match_b == 2 | match_b == 3		
		
		gen 	in_serv=0
		replace in_serv=1 if match_b == 1 | match_b == 3
		
		collapse (sum) in_log in_serv, by(Date)
		
		format 	Date %tddd/Mon
		
		label variable in_log "Logbook"
		label variable in_serv "Server"
		
		qui sum Date
		
		twoway (connected in_log in_serv Date), ///
				graphregion(color(white)) ///
				title(Number of submissions) ///
				xlabel(, labsize(small)) ///
				xtitle("") ytitle("")
	
		graph export "$HFC/Raw files/logbook_vs_server.png", replace
	
	restore
	
	preserve
	
		use `match', clear
		
		qui sum Date
		keep if Date == r(max)
		
		gen 	in_log = 1 if match_b == 2
		
		gen 	in_serv = 1 if match_b == 1
	
		
		gr 	bar in_log in_serv,	///
			blabel(total) title("Number of unmatched submissions" "on last survey day") ///
			ylabel(none) ///
			legend(order(1 "Only in logbook" 2 "Only in server")) graphregion(color(white))
		
		graph export "$HFC/Raw files/logbook_vs_server_unmatched.png", replace

	restore
	
	
	**** Matching issues table
	preserve
	
		* Keep only the first columns to make it simpler 
		keep Date match_b simid devicephonenum text_audit id_03 start_mod_a id_04 id_05 id_05_reenter pl_id_06 pl_sample pl_id_07 pl_id_08 pl_id_09	pl_id_11 pl_id_12 pl_hhhs pl_hhhs_id pl_hhsize pl_id_13 pl_id_14
		keep if (match_b == 1 | match_b == 2)
		order match_b
		export delimited "$fu2_eu_output\high_freq_check\duplicates\mismatch_list_`c(current_date)'", replace
		export delimited "$fu2_eu_output\high_freq_check\duplicates\mismatch_list_most_recent", replace
		
	restore
	
