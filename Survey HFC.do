/*******************************************************************************
*   					  SURVEY HIGH FREQUENCY CHECKS						   *
*   							   2017										   *
********************************************************************************
	
	** OUTLINE:		PART 1: Variables that should have no missing values
					PART 2: Identify variables that only have missing variables
					PART 3: Other values to recategorize
					PART 4: Outliers
				->	PART 5: Skip patterns and survey logic
				->	PART 6: Variables constraints
						
	** CREATES: 	
					
	** WRITEN BY:   

	** Last time modified: July 2017



********************************************************************************
* 		PART 1: Check variables that should have no missing values
*******************************************************************************/

	preserve
		
		clear
		
		gen missing_var = ""
		
		tempfile nomiss
		save	 `nomiss'
	
	restore
		
	foreach nomissVar of local nomissVarlist {
	
		cap assert mi(`nomissVar')
		if _rc {
		
			preserve 
			
				keep if `nomissVar' == .
				keep 	`enumVar' `dateVar' `hhVar'
				gen 	missing_var = "`nomissVar'"
				
				append 	using `nomiss'
				save 	`nomiss', replace
				
			restore
				
		}	
	}
	
	preserve
		
		use  `nomiss', clear
		sort  missing_var `enumVar'
		order missing_var `enumVar' `dateVar' `hhVar'
		
		dataout, save("$HFC/Raw files/delete_me") tex mid(1) replace
		filefilter 	"$HFC/Raw files/delete_me.tex" "$HFC/Raw files/nomiss.tex", 	///
					from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
					replace
	restore
	
	
********************************************************************************
* 		PART 2: Identify variables that only have missing variables
********************************************************************************

	local allmissVarList ""
	
	foreach allmissVar of varlist _all {
		cap assert mi(`allmissVar')
		if !_rc {
			local allmissVarList "`allmissVarList' `allmissVar'"
		}
	}
	
	preserve
		
		clear
		gen 	Variable = ""
		
		set obs `: word count `allmissVarList''
		
		forvalues varNo = 1/`: word count `allmissVarList'' {
			
			replace Variable = "`:word `varNo' of `allmissVarList''" in `varNo'
			
		}
		
		dataout, save("$HFC/Raw files/delete_me") tex mid(1) replace
		filefilter 	"$HFC/Raw files/delete_me.tex" "$HFC/Raw files/allmiss.tex", 	///
					from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
					replace
	restore 
		
		
	

********************************************************************************
* 						PART 3: Other values to recategorize
********************************************************************************
	
	foreach otherVar of local otherVarList {
		
		replace `otherVar' = "" if `otherVar' == "."
		
		cap assert mi(`otherVar')
		if _rc {
	
			local varLabel : var label `otherVar'
		
			eststo clear
			estpost tab `otherVar'
			esttab 	using "$HFC/Raw files/other_`otherVar'.tex", /// 
					cells   ("b(label(Frequency)) pct(fmt(%9.2f)label(Share))")  ///
					replace varlabels(`e(labels)') ///
					title(`varLabel') ///
					nonumbers nomtitles
					
		}
	}
	
********************************************************************************
* 							PART 4: Identify outliers
********************************************************************************

	foreach outliersVar of local outliersVarList {
	
		sum `outliersVar', detail
	
		hist 	`outliersVar', ///
				freq kdensity ///
				color(gs12) ///
				xline(`r(p99)', lcolor(red) lwidth(vthin)) ///
				xline(`r(p95)', lcolor(cranberry) lwidth(vthin) lpattern(shortdash)) ///
				note(Note: `r(obs)' observations.)
				
		graph export "$HFC/Raw files/outliers_`outliersVar'.png", width(5000) replace
				
	}
