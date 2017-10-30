/*******************************************************************************
*								MOZ LANDSCAPES 								   *
*   					  SURVEY HIGH FREQUENCY CHECKS						   *
*   							   2017										   *
********************************************************************************
	
	
			1.	INITIAL CHECKS
				
				1.1 Check for duplicates
				1.2 Check for consent
				1.3 Check progress (number of completed surveys per interest group)
	
			2.	ENUMERATORS CHECKS
				
				2.1 List uploaded surveys by enumerator on last survey day		
				2.2 Total number of households surveyed by enumerator
				2.3 Total number of surveys completed by enumerator
				2.4 Average survey duration by enumerator
				2.5 Share of don't knows and refusals
				-> 2.6 Check the percentage giving each answer for key filter questions 
				-> 2.7 Average skips
				-> 2.8 Check the duration of consent by enumerator		
					
			3.	ENUMERATORS CHECKS
				
				3.1 Check skip patterns
				3.2 Identify variables that only contain missing values
				3.3 Check variables that should never be missing
				3.4 Check other values to recategorize
				3.5 Check key variables for outliers
				-> 3.6 Check variables constraints
				-> 3.7 Check survey logic 
			
			4. BACK CHECKS
				
				-> 4.1 Select back checks sample
				-> 4.2 Run bcstats
	

	
********************************************************************************
* 							Set initial configurations
*******************************************************************************/

	*ssc install bcstats, replace
	*ssc install ietoolkit, replace
	*ssc install labmask, replace
	
	ieboilstart, version(14.0)
	`r(version)'
	


********************************************************************************
* 								Set folder paths
******************************************************************************** 	
	
	* Set file path
	if "`c(username)'" == "wb501238" {
		global HFC 		"C:\Users\WB501238\Dropbox\RFR HFC Luiza"
	}	
	
	global logbook	"$HFC/Logbook.16th Oct 2017.xlsx"
	global output	"$HFC/Output"
	global dofiles	"$HFC/Do-files"

	
********************************************************************************
*								PART 0: Set options
********************************************************************************

*-------------------------------------------------------------------------------
*							INITIAL CHECKS
*-------------------------------------------------------------------------------
	
	* Identify duplicated surveys. Creates one excel with duplicates reports per
	* team of enumerators. To make it one single report, edit PART 1 of Initial 
	* checks.do
	global	duplicates		1	
		
	* Check for survey consent. Throws a warning and lists any households that
	* were interviewed without consent
	global 	consent			1
		
	* Count number of surveys completed per key variables
	global 	progress		1

	* Check server and logbook entries
	local 	logbook			0
	
*-------------------------------------------------------------------------------
*							ENUMERATORS CHECKS
*-------------------------------------------------------------------------------
	
	* Export a list of all households submitted by each enumerator. Default is to
	* export to latex. To change to excel, edit PART 1 of Enumerator checks.do
	global	enum_ids		1	
		
	* Count number of households approached and surveyed per enumerator
	global 	enum_count		1
		
	* Count number of surveys completed per enumerator
	global 	enum_finish		1
		
	* Check duration of key sections per enumerator
	global 	enum_duration	1
		
	* Check share of don't knows and refusals to answer per enumerator
	global	enum_ref		1

*-------------------------------------------------------------------------------
*							SURVEY CHECKS
*-------------------------------------------------------------------------------

	* Calculate share of variables with all missing observations per section
	global survey_section	1
	
	* Identify variables that only have missing variables
	global survey_missvar	1
	
	* Check variables that should never be missing
	global survey_nomiss	0
	
	* Check other values to recategorize
	global survey_other		0
	
	* Identify outliers in key questions
	global survey_outliers	0
	
********************************************************************************
*								PART 0: Set options
********************************************************************************

*-------------------------------------------------------------------------------
*							BASIC CHECKS
*-------------------------------------------------------------------------------

	* Identify unique ID
	global hhVar 	hhid	// household ID
	
	* Define date variable
	global dateVar			submissiondate			// Date of survey submission
	global startVar			starttime				// Date when survey started
	global endVar			endtime					// Date when survey ended
	global keyVar			key						// Server ID (key)
	
	* Identify percentiles to be flagged
	global lowerPctile 		20						// Lower tail: choose 0 to not flag any lower tails
	global upperPctile		80						// Upper tail: choose 100 to not flag any upper tails
	
	
*-------------------------------------------------------------------------------
*							ENUMERATOR CHECKS
*-------------------------------------------------------------------------------

	global teamVar 			id_04 					// ID for team of enumerators. Must be a labeled factor variable
	global enumeratorVar	id_03					// ID for enumerators. Must be a lebeled factor variable
	
	global consentVar		consent					// Variable that indicates if HH consented to being surveyed
	global consentYesVar	consent_yes				// Equals one if household consented to survey
	global completeVar		complete				// Equals on if survey was completed
	
	global durationList		duration				// List the names of all duration variables to be checked
	
	global dkCode			-88						// Code for "don't know"
	global refCode			-66						// Code for "refuse to answer"
		
*-------------------------------------------------------------------------------
*							PROGRESS CHECKS
*-------------------------------------------------------------------------------

	global progressVars		"village_id district_id"	// List the names of all categories across which you want to check survey progress, e.g., village, district, gender. Listed variables must be labeled factors
	
	* Observation goals
	gen village_id_goal = 15

	gen district_id_goal = .	
	replace district_id_goal = 240 if pl_id_09 == "BUGESERA"
	replace district_id_goal = 238 if pl_id_09 == "HUYE"
	replace district_id_goal = 80  if pl_id_09 == "MUHANGA"
	replace district_id_goal = 279 if pl_id_09 == "NGOMA"
	replace district_id_goal = 274 if pl_id_09 == "NGORORERO"
	replace district_id_goal = 240 if pl_id_09 == "RULINDO"
	replace district_id_goal = 680 if pl_id_09 == "RUBAVU"

	
*-------------------------------------------------------------------------------
*							SURVEY CHECKS
*-------------------------------------------------------------------------------

	global hhRoster1		ros_
	global hhRoster2		b_
	global plotRoster		c_
	global cropRoster		d_
	global incomeSec		e_
	global questionVars		"${hhRoster1}* ${hhRoster2}* ${plotRoster}* ${cropRoster}* ${incomeSec}*"
	global sectionsList		hhRoster1 hhRoster2 plotRoster cropRoster incomeSec
	
	global nomissVarList	// List variables that should never be missing

	global otherVarList		// List of 'other' variables
	
	global outliersVarList	// Lit of variables to check for outliers
	
********************************************************************************
* 							Calculate inputs
********************************************************************************
	
	levelsof ${teamVar}, local(teamsList)
	global teamsList = "`teamsList'"
	
	* Identify last submission date
	qui sum $dateVar
	global lastDay = dofc(r(max))
	

********************************************************************************
*				Check that all necessary globals are defined
********************************************************************************


********************************************************************************
*		If you have a do file adapting your data to the required formats,
* 		run it here
********************************************************************************
	
********************************************************************************
*								Run checks
********************************************************************************

	if	$duplicates + $consent + $progress >= 1 {
		do "$dofiles/Survey checks.do"
	}
	
	if `logbook' {
		do "$dofiles/Server_vs_logbook.do"
	}
	
	if 	$enum_ids + $enum_count + $enum_finish + $enum_ref + $enum_duration >= 1 {
		do "$dofiles/Enumerator checks.do"
	}
	
	if 	$survey_section + $survey_missvar + $surver_nomiss + ///
		$survey_other + $survey_outliers {
		do "$dofiles/Survey checks.do"
	}
