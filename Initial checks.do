/*******************************************************************************
*								MOZ LANDSCAPES 								   *
*   					  SURVEY HIGH FREQUENCY CHECKS						   *
*   							   2017										   *
********************************************************************************
	
	** OUTLINE:		1. Check for duplicates
					2. Check for consent
				->	3. Check progress
					3. Survey checks
				->		check skip patterns and survey logic 
						variables that should have no missing values
						variables that contain only missing
				->		variables constraints
						'other values': recategorize
						outliers						
					4. Per enumerator
						number of surveys sent
						IDs of surveys sent
						duration fields
				->		average skips
						share of missing (don't know/refusal)
						Check the percentage giving each answer for key filter questions by enumerator
						Check the percentage of survey refusals by enumerator
						Check the duration of consent by enumerator			
				->	5. Back checks
						1. Select back checks sample
						2. Run bcstats
					
	** CREATES: 	
					
	** WRITEN BY:   

	** Last time modified: July 2017
	

*******************************************************************************/




********************************************************************************
* 							Check for duplicates
********************************************************************************

	foreach team of local teamsList {

		ieduplicates 	`hhVar' if `teamVar' == `team', ///
						folder("$HFC/Final documents") ///
						uniquevars(`dateVar' `submissionVar' `obsVar') ///
						keepvars(`idnoteVar') ///
						suffix(_team`team')
	
	}	
	
	
********************************************************************************
* 							Check for consent
********************************************************************************	

	foreach team of local teamsList {

		count if `teamVar' == `team' & `consentVar' != 1
		if r(N) != 0 {
		
			noi display as error "{phang}Team `team' has `r(N)' surveys with no consent.{p_end}"
		
			preserve 
			
				keep 	`hhVar' `consentVar' `dateVar' `submissionVar' `obsVar' `enumeratorVar' if `teamVar' == `team'
				order 	`enumeratorVar' `dateVar' `submissionVar' `hhVar' `consentVar' `obsVar'
				sort 	`enumeratorVar' `dateVar'
				
				dataout, 	save("$HFC/Raw files/delete_me") tex mid(1) replace
				filefilter 	"$HFC/Raw files/delete_me.tex" "$HFC/Raw files/team`team'_noconsent.tex", 	///
							from("documentclass[]{article}") to("documentclass[border=1em]{standalone}") ///
							replace
			
			restore	
		}	
	}	

********************************************************************************
* 							Check if survey was completed
********************************************************************************	

	
	
	
********************************************************************************
* 							Check progress
********************************************************************************	

	* Number of surveys per day/over entire period vs goal
	* Any other balance vars? (number of obs by gender, district, etc
