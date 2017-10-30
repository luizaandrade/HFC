/*******************************************************************************
*   					  SURVEY HIGH FREQUENCY CHECKS						   *
********************************************************************************
	
	** OUTLINE:		PART 1: Check for duplicates
					PART 2: Check for consent
					PART 3: Check progress (number of completed surveys per interest group)
									
	** WRITEN BY:   Luiza Andrade [lcardosodeandrad@worldbank.org]

	** Last time modified: Oct 2017


********************************************************************************
* 						PART 1: Check for duplicates
*******************************************************************************/

	if $duplicates {
	
		foreach team of global teamsList {
		
			preserve 
			
				keep if $teamVar == `team'
				
				ieduplicates 	$hhVar, ///
								folder("$HFC/Final documents") ///
								uniquevars($dateVar $startVar $endVar) ///
								keepvars($keyVar) ///
								suffix(_team`team')
			restore
		}	
	}
	
********************************************************************************
* 						  2. Check for consent
********************************************************************************	

	if $consent {
		foreach team of global teamsList {

			qui count if $teamVar == `team' & $consentVar != 1 & $completeVar == 1
			if r(N) != 0 {
			
				noi display as error "{phang}Team `team' has `r(N)' surveys with no consent.{p_end}"
			
				preserve 
				
					keep if $teamVar == `team' & $consentVar != 1 & $completeVar == 1
					keep 	$hhVar $consentVar $dateVar $startVar $keyVar $enumeratorVar 
					sort 	$enumeratorVar $dateVar
					
					tostring 	$hhVar, replace
					
					foreach varAux of varlist $consentVar $enumeratorVar {
						rename 		`varAux' delete_me
						decode 		delete_me, gen(`varAux')
						drop		delete_me
					}
					
					rename	 $dateVar delete_me
					generate $dateVar = string(delete_me, "%tC")
					drop	 delete_me	
					
					order 	$enumeratorVar $dateVar $starttime $hhVar $consentVar $keyVar			
					
					dataout, 	save("$HFC/Raw files/delete_me") tex mid(1) replace noauto
					
					filefilter 	"$HFC/Raw files/delete_me.tex" "$HFC/Raw files/team`team'_noconsent.tex", 	///
								from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
								replace
					
					erase		"$HFC/Raw files/delete_me.tex"
				
				restore	
			}	
		}	
	}	
	
********************************************************************************
* 							3. Check progress
********************************************************************************	

	if $progress {
		foreach varAux in $progressVars {
		
			preserve
				
				* Count number of surveys completed
				collapse 	(sum) count = $completeVar ///
							(mean) `varAux'_goal ///
							if `varAux' != ., ///
							by(`varAux')
				
				qui sum `varAux'_goal
				local maxValue = r(max)
				local interval = floor(`maxValue'/5)
				
				sort `varAux'
				gen order = _n
				gen order1 = order -.4
				gen order2 = order +.4
				decode `varAux', gen(label)
				labmask order, val(label)
				
				centile count, centile($lowerPctile $upperPctile)			
				gen 	flag_bottom = 1 if count < `r(c_1)'
				
				twoway 	(bar count order if flag_bottom == 1, color(red) horizontal barwidth(.8)) ///
						(bar count order if count, color(stone) horizontal barwidth(.8)) ///
						(bar count order if count == `varAux'_goal, color("102 194 164") horizontal barwidth(.8)) ///
						(pcarrow order1 `varAux'_goal order2 `varAux'_goal, lcolor("0 88 66") lpattern(dash) msize(zero) mcolor("0 88 66")), ///
						ylabel(1/`r(N)',valuelabel angle(0) labsize(vsmall)) ///
						xlabel(0(`interval')`maxValue') ///
						ytitle("") xtitle("") legend(off) ///
						graphregion(color(white))
							
					* Export graph
					graph export "$HFC/Raw files/obs_per_`varAux'.png", width(5000) replace
					
			restore 
		}
	}
