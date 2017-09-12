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

	version 		13.1
	set maxvar 		32767
	set more 		off, perm
	pause 			on
	set varabbrev 	off
	
	ssc install bcstats, replace
	ssc install ietoolkit, replace

	
/*******************************************************************************
						PART 0: Set options
*******************************************************************************/

	use XXXXX, clear

	* Set file path
	global HFC 
	
	* Identify unique ID
	local hhVar
	
	* Define date variable
	local dateVar	date
	
	* Identify submission time variable
	local submissionVar
	
	* Identify unique observation ID (key)
	local obsVar
	local idnoteVar
	
	* Identify team	
	gen 	team = .
	replace team = 1 if enumerator <= 8
	replace team = 2 if enumerator > 8 & enumerator <= 16
	replace team = 3 if enumerator > 16 & enumerator <= 24

	local teamVar 	
	local enumeratorVar
	local teamLeaderVar
	
	split 	enumeratorname, generate(enum)

	* Identify percentiles
	local lowerPctile
	local upperPctile
	
	* Define duration variables to be checked: REMEMBER TO INCLUDE CONSENT HERE
	local durationList	duration													// Remember to add labels to these variables
	
	* Define missing codes and "mandatory" variables
	local checkMissVars	
	local dkCodes	
	local refCodes	
	
	* Define consent variable
	local consentVar
	
	* Define variables to be check the percentage giving each answer
	local checkVarList
	
	* Define type 1,2 and 3 variables
	local type1VarList
	local type2VarList
	local type3VarList
	
	* Variables that should never be missing
	local nomissVarList
	
	* Variables to check for outliers
	local outliersVarList
	
	* Variables identifying `other' values
	local otherVarList
	
	* Define skip variables
	local skipVarList
	
********************************************************************************
* 							Calculate inputs
********************************************************************************
	
	levels of `teamVar', local(teamsList)
	
	* Identify last submission date
	qui sum `submissionVar'
	local lastDay = r(max)
	
