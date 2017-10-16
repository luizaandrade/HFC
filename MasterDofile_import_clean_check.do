/*******************************************************************************
				Rwanda Rural Feeder Road IE EU Follow-up Sept. 2017			   

	PURPOSE		: 	High frequency data check during the data collection.
	
	INPUT		:
				
	OUTPUT		:

	Note		: The HFC dofile from the last survey is datacheck_fu_v2.do

	OUTLINE		:
	WRITEN BY	:	Sakina Shibuya
	DATE		:
	 	  																			
*******************************************************************************/

*********************************************************************************
* 0.	Settings, Globals & Switches											*
*********************************************************************************


	**** Settings
	ieboilstart , version(12.1)
	`r(version)'

	set seed 1320134201



	clear 
	clear matrix
	clear mata

	*-------------------
	* User specification
	*-------------------
	if "`c(username)'" == "Leonardo"	{										// Leonardo Viotti (Personal computer)
		global dropbox "Users/Leonardo/Documents/Pasta/Dropbox/Work/WB"
		global temp	   "C:/temp"
	}
	
	if c(username) == "wb519128" {		
		global dropbox "C:\Users\WB519128\Dropbox\Work\WB" // Enter your UPI or user name
	}

	if c(username) == "Sakina" {		
		global dropbox "C:/Users/Sakina/Dropbox/DIME_work"
	}

	*--------------
	* Set filepaths
	*--------------
	global project 			"$dropbox\Rwanda Feeder Roads"
	global data				"$project\data"
	global fu2_eu			"$data\surveys\HH survey\EU follow up 2 sept 2017"
	global fu2_eu_raw		"$fu2_eu\data\raw"
	global fu2_logbooks		"$fu2_eu\logbooks"
	global fu2_eu_do		"$data\dofiles\hh_survey\EU follow up 2 sept 2017"
	global fu2_eu_output	"$fu2_eu\output"
	global fu2_eu_preload	"$fu2_eu\Preloads"
	
	
*********************************************************************************
* 1.	Section switches															*
*********************************************************************************
	global import_clean			0 // Import the raw csv and clean
	global high_freq_check		0 // Run the high frequency checks
	global select_bc_hh			0 // Randomly select HHs for backchecking
	
	*-----------------------------
	* Raw dataset file name global
	*-----------------------------
	global fresh_data	"$fu2_eu_raw\RFR_FU2_EU_v1.1_WIDE.csv" 
	// Change the file name once the actual data collection starts. This dataset gets imported in import_clean.

	
*********************************************************************************
* 2.	Sections																*
*********************************************************************************	

	*------------------------------
	* Import the raw data and clean
	*------------------------------
	if $import_clean {
		do "$fu2_eu_do\import_clean.do"
	}
	
	*----------------------------------
	* Run the high frequency data check
	*----------------------------------
	if $high_freq_check {
		do "$fu2_eu_do\high_freq_data_check.do"
	}

	*-------------------------------------
	* Randomly select HHs for backchecking
	*-------------------------------------
	if $select_bc_hh {
		do "$fu2_eu_do\select_bc_hh.do"
	}
