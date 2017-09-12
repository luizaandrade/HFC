/*******************************************************************************
*   					  SURVEY HIGH FREQUENCY CHECKS						   *
*   							   2017										   *
********************************************************************************
	
	** OUTLINE:		PART 1: List uploaded surveys by enumerator on last survey day		
					PART 2: Total number of surveys completed by enumerator
					PART 3: Average survey duration by enumerator
					PART 4: Share of don't knows and refusals
					PART 5: Percentage of survey refusals
					PART 6: Check the percentage giving each answer for key filter questions 
						
	** CREATES: 	
					
	** WRITEN BY:   

	** Last time modified: July 2017
	

*******************************************************************************/


********************************************************************************
* 		PART 1: List uploaded surveys by enumerator on last suvey day
********************************************************************************

	* We will create a data set where variable names are enumerators names
	* and variable values are the list of hhids they submitted in the last
	* day of survey. We will then export this data set as a table.
		
	* Loop over teams -- save one table per team
	foreach team of local teamsList {
			
		* Create a table that has enumerators names as columns names
		* ----------------------------------------------------------
		
		* Get list of enumerators in the team
		levelsof `enumeratorVar' if `teamVar' == `team', local(enumeratorsList)
		
		* Set enumerators names as columns names
		preserve
		
			clear
			set obs 1
			
			foreach enumerator of local enumeratorsList {
		
				gen `enumerator' = .
			
			}
			
			* Save tempfile															// We will alternate between the raw data and this table to fill it
			tempfile submitted
			save	`submitted', replace
				
		restore	
		
		* Fill each enumerator's column with the list of HHIDs they submitted
		* -------------------------------------------------------------------
		foreach enumerator of local enumeratorsList {
		
			* Get list of households
			levelsof `hhVar' if `enumeratorVar' == "`enumerator'" & `dateVar' == `lastDay', local(hhidList)
			
			* Count number of households submitted
			local totalHhs `: word count `hhidList''
			
			preserve
				
				* Open the table
				use `submitted', clear
				
				* We need to have as many rows as submitted households,
				* so we'll increase the number of observations in the data set
				* in case they don't fit
				if `totalHhs' > _N	{
					set obs `totalHhs'
				}
				
				* Now will fill the row values with the list of households
				forvalues obs = 1/`totalHhs' {
					replace `enumerator' = `: word `obs' of `hhidList'' if _n == `obs'
				}
			
				* Save table, then go back to survey data for next enumerator
				save `submitted', replace
		
			restore
			
		}
		
		preserve
		
			* Export team's table, then go back to survey data for next team
			* --------------------------------------------------------------
			use `submitted', clear
			dataout, save("$HFC/Raw files/delete_me") tex mid(1) replace
			filefilter 	"$HFC/Raw files/delete_me.tex" "$HFC/Raw files/team`team'_hhid_list.tex", 	///
						from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
						replace
				
			
		restore 
	}

	
********************************************************************************
* 				PART 2: Number of surveys completed by enumerator
********************************************************************************

	preserve
		
		* Calculate number of surveys per enumerator and identify lower and upper
		* percentiles
		* ----------------------------------------------------------------------
		tempfile submissions
		
			* Count number of surveys submitted
			collapse (count) `hhVar' if `dateVar' == `lastDay', by(`enumeratorVar' `teamVar')

			* Identify enumerators in critical percentiles
			centile `hhVar', centile(`lowerPctile' `upperPctile')
			
			gen 	flag_bottom = 1 if `hhVar' < `r(c_1)'
			gen 	flag_top = 1 	if `hhVar' > `r(c_2)'
			
			* Order enumerators (so plot looks nice)
			sort 	`teamVar' `hhVar'
			by 		`teamVar': gen order = _n
			
		save `submissions'
		
		* Plot number of surveys per enumerator, save one plot per team
		* -------------------------------------------------------------
		foreach team of local teamsList {
		
			* Load team's data
			use 	`submissions', clear
			keep if `teamVar' == `team'
			
			* Order variable will now be a factor labeled with enumerator's name
			labmask order, val(`enumeratorVar')
			
			* Calculate number of valid observations
			qui count if `hhVar' != .
			
			* Create graph
			twoway 	(bar `hhVar' order if `teamVar' == `team' & flag_bottom == 1, color(orange)) ///
					(bar `hhVar' order if `teamVar' == `team' & flag_bottom != 1 & flag_top!= 1, color(stone)) ///
					(bar `hhVar' order if `teamVar' == `team' & flag_top == 1,	color(ebblue)), ///
					legen(off) xla(1/`r(N)', valuelabel labsize(small)) yscale(range(0)) ///
					ytitle(Number of surveys submitted) ///
					xtitle("")
					
			* Export graph
			graph export "$HFC/Raw files/team`team'_hhid_count_total.png", width(5000) replace
					
		
		}
	restore 
	
********************************************************************************
* 				PART 3: Average survey duration by enumerator
********************************************************************************
	
	* Loop over selected duration variables
	foreach durationVar of varlist `durationList' {
	
		local durationVarLabel: var label `durationVar'
		
		preserve
			
			tempfile duration
			
				* Calculate average
				collapse (mean) mean =`durationVar' ///
						 (sd) 	sd 	 =`durationVar' if `dateVar' == `lastDay', ///
						 by		(`enumeratorVar' `teamVar')
				
				* Calculate confidence interval
				gen upper = mean + sd
				gen lower = mean - sd
				
				* Identify enumerators in critical percentiles
				centile mean, centile(`lowerPctile' `upperPctile')	
				
				gen flag_bottom = 1 	if mean < `r(c_1)'
				gen flag_top = 1 		if mean > `r(c_2)'
				
				* Order enumerators (so plot looks nice)
				sort 	`teamVar' `durationVar'
				by 		`teamVar': gen order = _n
				
			save `duration'
			
		* Plot average duration per enumerator, save one plot per team
		* -------------------------------------------------------------
		foreach team of local teamsList {
		
			* Load team's data
			use 	`duration', clear
			keep if `teamVar' == `team'
			
			* Order variable will now be a factor labeled with enumerator's name
			labmask order, val(`enumeratorVar')
			
			* Calculate number of valid observations
			qui count if mean != .
		
			* Create graph
			twoway 	(bar mean order if `teamVar' == `team' & flag_bottom == 1, color(orange)) ///
					(bar mean order if `teamVar' == `team' & flag_bottom != 1 & flag_top!= 1, color(stone)) ///
					(bar mean order if `teamVar' == `team' & flag_top == 1, color(ebblue)) ///
					(rcap upper lower order, color(black)), ///
					legen(off) xla(1/`r(N)', valuelabel labsize(small)) yscale(range(0)) ///
					ytitle(`durationVarLabel') ///
					xtitle("") 
					
			* Export graph
			graph export "$HFC/Raw files/team`team'_`durationVar'.png", width(5000) replace
		
		}
			
		restore
	}
	

********************************************************************************
* 				PART 4: Share of don't knows and refusals
********************************************************************************

	preserve
	
		keep `teamVar' `enumVar' `dateVar' `checkMissVars'
		
		egen dkCount = anycount(`checkMissVars'), values(`dkCodes')
		egen refCount = anycount(`checkMissVars'), values(`refCodes')
		
		gen  varCount = `: word count `checkMissVars''
		
		egen dkShare = dkCount/varCount
		egen refShare = refCount/varCount
		
		foreach missType in dk ref {
		
			if "`missType'" == "dk"	 	local label don't know
			if "`missType'" == "ref"	local label refuse to answer
		
			collapse (mean) mean = `missType'Share ///
					 (sd) 	sd	 = `missType'Share 	if `dateVar' == `lastDay', ///
					 by		(`enumeratorVar' `teamVar')
					 
			* Calculate confidence interval
			gen upper = mean + sd
			gen lower = mean - sd
					
			* Identify enumerators in critical percentiles
			centile mean, centile(`lowerPctile' `upperPctile')	
					
			gen flag_bottom = 1 	if mean < `r(c_1)'
			gen flag_top = 1 		if mean > `r(c_2)'
					
			* Order enumerators (so plot looks nice)
			sort 	`teamVar' `durationVar'
			by 		`teamVar': gen order = _n
			
			tempfile	`missType'
			save		``missType''
			
		* Plot average duration per enumerator, save one plot per team
		* -------------------------------------------------------------
		foreach team of local teamsList {
		
			* Load team's data
			use 	`missType', clear
			keep if `teamVar' == `team'
			
			* Order variable will now be a factor labeled with enumerator's name
			labmask order, val(`enumeratorVar')
			
			* Calculate number of valid observations
			qui count if mean != .
		
			* Create graph
			twoway 	(bar mean order if `teamVar' == `team' & flag_bottom == 1, color(orange)) ///
					(bar mean order if `teamVar' == `team' & flag_bottom != 1 & flag_top!= 1, color(stone)) ///
					(bar mean order if `teamVar' == `team' & flag_top == 1, color(ebblue)) ///
					(rcap upper lower order, color(black)), ///
					legen(off) xla(1/`r(N)', valuelabel labsize(small)) yscale(range(0)) ///
					ytitle(Share of `label' per enumerator) ///
					xtitle("") 
					
			* Export graph
			graph export "$HFC/Raw files/team`team'_`missType'.png", width(5000) replace
		
		}			
	}

********************************************************************************
* 					PART 5: Percentage of survey refusals
********************************************************************************
	
	preserve
			
		tempfile refusals
		
			* Count interview attempts and consents
			collapse (sum) 		consent =`consentVar' ///
					 (count) 	total 	=`hhVar' if `dateVar' == `lastDay', ///
					 by		(`enumeratorVar' `teamVar')
			
			* Calculate share of refusal
			gen refusals = ((total - consent)/total)*100
			
			* Identify enumerators in critical percentiles
			centile refusals, centile(`lowerPctile' `upperPctile')	
			
			gen flag_bottom = 1 	if refusals < `r(c_1)'
			gen flag_top = 1 		if refusals > `r(c_2)'
			
			* Order enumerators (so plot looks nice)
			sort 	`teamVar' refusals
			by 		`teamVar': gen order = _n
			
		save `refusals'
		
	* Plot average duration per enumerator, save one plot per team
	* -------------------------------------------------------------
	foreach team of local teamsList {
	
		* Load team's data
		use 	`refusals', clear
		keep if `teamVar' == `team'
		
		* Order variable will now be a factor labeled with enumerator's name
		labmask order, val(`enumeratorVar')
		
		* Calculate number of valid observations
		qui count if refusals != .
	
		* Create graph
		twoway 	(bar refusals order if `teamVar' == `team' & flag_bottom == 1, color(orange)) ///
				(bar refusals order if `teamVar' == `team' & flag_bottom != 1 & flag_top!= 1, color(stone)) ///
				(bar refusals order if `teamVar' == `team' & flag_top == 1, color(ebblue)) ///
				legen(off) xla(1/`r(N)', valuelabel labsize(small)) yscale(range(0)) ///
				ytitle(Share of survey refusals (%)) ///
				xtitle("") 
				
		* Export graph
		graph export "$HFC/Raw files/team`team'_refusals.png", width(5000) replace
	
	}
		
	restore

********************************************************************************
* 	PART 6: Check the percentage giving each answer for key filter questions 
********************************************************************************

	* Loop over selected duration variables
	foreach checkVar of varlist `checkVarList' {
	
		preserve
		
			tempfile share
			
				local varLabel: var label `checkVar'
			
				collapse 	(count) count = `hhVar' if `dateVar' == `lastDay', ///
							by (`enumeratorVar' `teamVar' `checkVar')
							
				bys `enumeratorVar': egen total = total(count)
				gen percent = (count/total)* 100
				
				* Order enumerators (so plot looks nice)
				by 		`teamVar': gen order = _n
							
			save `share'
			
			foreach team of local teamsList {
			
				* Load team's data
				use 	`share', clear
				keep if `teamVar' == `team'
				
				* Order variable will now be a factor labeled with enumerator's name
				labmask order, val(`enumeratorVar')
				
				* Calculate number of valid observations
				qui count if share != .
			
				* Create graph
				gr	bar percent, ///
					over(`checkVar') over(`enumeratorVar') ///
					asyvars stack ///
					ytitle(Share of valid answers (%)) ///
					title(Check of blebleble) ///
					subtitle(`varLabel')
						
				* Export graph
				graph export "$HFC/Raw files/team`team'_share`checkVar'.png", width(5000) replace
			
			}
			
		restore
	}

	
********************************************************************************
* 					PART 7: Check average skips per enumerator
********************************************************************************

	