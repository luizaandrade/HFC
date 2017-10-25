/*******************************************************************************
*   					  SURVEY HIGH FREQUENCY CHECKS						   *
********************************************************************************
	
	** OUTLINE:		PART 1: Share of variables with all missing observations per section
					PART 2: Identify variables that only have missing variables
					PART 3: Check variables that should have no missing values
					PART 4: Other values to recategorize
					PART 5: Identify outliers
									
	** WRITEN BY:   Luiza Andrade [lcardosodeandrad@worldbank.org]

	** Last time modified: Oct 2017


********************************************************************************
*	PART 1: Share of variables with all missing observations per section
*******************************************************************************/

	if $survey_section {
		preserve
		
			keep $questionVars
			ds, has(type numeric)
			keep `r(varlist)'
			
			tempfile questionVars
			save	 `questionVars'
			
			local nobs = _N
			
			xpose, clear varname promote
		
			gen survey_section = ""
			foreach section of global sectionsList {
				local nChar = length("$`section'")
				replace survey_section = "`section'" if substr(_varname,1,`nChar') == "$`section'"
			}
		
			egen missings = rowmiss(_all)
			gen all_miss = (missings == `nobs')
			
			collapse (count) missings (sum) all_miss, by(survey_section)
			
			gen share = (all_miss/missings)*100
			
			gr 	bar share, ///
				over(survey_section) ///
				graphregion(color(white)) ///
				title("Percentage of variables with all missing" "observations per section") ///
				ytitle("%")
				
			graph export "$output/Raw files/sections_missing.png", width(5000) replace
			
		restore
	}
	
********************************************************************************
* 		PART 2: Identify variables that only have missing variables
********************************************************************************

	if $survey_missvar {
		preserve
		
			clear
			tempfile exportTable
			gen		 delete_me = 1
			save	 `exportTable'
			
			foreach section of global sectionsList {
				
				di "`section'"
				local allmissVarList = ""
				
				use	 `questionVars', clear
				
				foreach allmissVar of varlist $`section'* {
				
					cap assert mi(`allmissVar')
					if !_rc {
						local allmissVarList "`allmissVarList' `allmissVar'"
					}
				}
					
				local varcount = `: word count `allmissVarList''
				if `varcount' > 0 {
					use	 `exportTable', clear
					
					local nobs = _N
					if `varcount' > `nobs' {
						set obs `: word count `allmissVarList''
					}
					
					gen `section' = ""
					
					forvalues varNo = 1/`: word count `allmissVarList'' {		
						replace `section' = "`:word `varNo' of `allmissVarList''" in `varNo'
					}
					
					tempfile  exportTable
					save	 `exportTable', replace
				}
			}
			
			use  `exportTable', clear
			drop delete_me
			
			dataout, save("$output/Raw files/delete_me1") tex mid(1) replace
			
			filefilter 	"$output/Raw files/delete_me1.tex" "$output/Raw files/delete_me2.tex", 	///
						from("_") to("\BS_") ///
						replace			
			filefilter 	"$output/Raw files/delete_me2.tex" "$output/Raw files/delete_me1.tex", 	///
						from("\BS\BS_") to("\BS_") ///
						replace
			filefilter 	"$output/Raw files/delete_me1.tex" "$output/Raw files/allmiss.tex", 	///
						from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
						replace
			erase		"$output/Raw files/delete_me1.tex"
			erase		"$output/Raw files/delete_me2.tex"
			
		restore 
	}	

	
********************************************************************************
* 		PART 3: Check variables that should have no missing values
*******************************************************************************/

	if $survey_nomiss {
		preserve
			
			clear
			
			gen missing_var = ""
			
			tempfile nomiss
			save	 `nomiss'
		
		restore
			
		foreach nomissVar of global nomissVarList {
		
			cap assert mi(`nomissVar')
			if _rc {
			
				preserve 
				
					keep if `nomissVar' == .
					keep 	$enumeratorVar $dateVar $hhVar
					gen 	missing_var = "`nomissVar'"
					
					append 	using `nomiss'
					save 	`nomiss', replace
					
				restore
					
			}	
		}
		
		preserve
			
			use  `nomiss', clear
			sort  missing_var $enumeratorVar
			order missing_var $enumeratorVar $dateVar $hhVar
			
			dataout, save("$output/Raw files/delete_me") tex mid(1) replace
			filefilter 	"$output/Raw files/delete_me.tex" "$output/Raw files/nomiss.tex", 	///
						from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
						replace
		restore
	}
	
********************************************************************************
* 						PART 4: Other values to recategorize
********************************************************************************
	
	if $survey_other {
		foreach otherVar of local otherVarList {
			
			replace `otherVar' = "" if `otherVar' == "."
			
			cap assert mi(`otherVar')
			if _rc {
		
				local varLabel : var label `otherVar'
			
				eststo clear
				estpost tab `otherVar'
				esttab 	using "$output/Raw files/other_`otherVar'.tex", /// 
						cells   ("b(label(Frequency)) pct(fmt(%9.2f)label(Share))")  ///
						replace varlabels(`e(labels)') ///
						title(`varLabel') ///
						nonumbers nomtitles
						
			}
		}
	}
	
********************************************************************************
* 							PART 5: Identify outliers
********************************************************************************

	if $survey_outliers {
		foreach outliersVar of local outliersVarList {
		
			sum `outliersVar', detail
		
			hist 	`outliersVar', ///
					freq kdensity ///
					color(gs12) ///
					xline(`r(p99)', lcolor(red) lwidth(vthin)) ///
					xline(`r(p95)', lcolor(cranberry) lwidth(vthin) lpattern(shortdash)) ///
					note(Note: `r(obs)' observations.)
					
			graph export "$output/Raw files/outliers_`outliersVar'.png", width(5000) replace
					
		}
	}
