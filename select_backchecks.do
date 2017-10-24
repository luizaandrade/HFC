/*******************************************************************************
				Rwanda Rural Feeder Road IE EU Follow-up Sept. 2017			   

	PURPOSE		: 	Selects weekly backcheck HH (10% of that week's sample)
	
	INPUT		:
				
	OUTPUT		:

	WRITEN BY	:	Leonardo Viotti
	DATE		
	 	  																			
*******************************************************************************/

di "This do-file depends on a master to run. Plase, find it at Rwanda Feeder Roads\data\dofiles\hh_survey\EU follow up 2 sept 2017\MasterDofile_import_clean_check.do and run it"

di "Seed and Stata version already set in the Master"


*-------------------------------------------------------------------------------
* 0. Load RAW data
*-------------------------------------------------------------------------------		
		
	
	**** Load data from the first version (1.6) of the from 
	use "$fu2_eu_raw/RFR_FU2_EU_v1.6.dta", clear
	
	**** Add Raw data from form version 1.9
	merge 1:1 id_05 using "$fu2_eu_raw/RFR_FU2_EU_v1.9.dta", gen(duplic_versions)
	
	tab duplic_versions
	
	drop duplic_versions
	
	
	**** Minor fixes
	
	destring id_05 id_05_reenter, replace


*-------------------------------------------------------------------------------
* 0.1. Switches
*-------------------------------------------------------------------------------	
	
	**** Select for wich week to run, 1, 2, 3 or 4
	
	global select_week = 2

*-------------------------------------------------------------------------------
* 1. Week variable
*-------------------------------------------------------------------------------

	**** Formar submission date
	gen 	server_date = dofc( submissiondate )
	format 	server_date %tdnn/dd/CCYY

	
	**** Create week dummies
	gen 	week = 0
	
	replace week=1 if server_date < date("20171015","YMD")
	replace week=2 if server_date < date("20171022","YMD") & server_date >= date("20171015","YMD")
	replace week=3 if server_date < date("20171029","YMD") & server_date >= date("20171022","YMD")
	replace week=4 if server_date < date("20171105","YMD") & server_date >= date("20171029","YMD")	
	
	
	**** Drop observations from other weeks (based on switch)
	if ${select_week} == 1	{
		keep if week==1
	}
	
	if ${select_week} == 2	{
		keep if week==2
	}
	
	if ${select_week} == 3	{
		keep if week==3
	}
	
	if ${select_week} == 4	{
		keep if week==4
	}
	

	
*-------------------------------------------------------------------------------
* 3. Randomly select 10% of that week sample
*-------------------------------------------------------------------------------	
	
	
		**** Randomization
		
		* Sort data in to make sure every HHid gets always the same random number if seed and version are correct
		sort id_05
		
		* Generate random number
		generate random = runiform()
		
		* Create rank by enumarator (id_03)
		bysort id_03 (random): gen randomrank = _n
		
		* Total of HH visited by each enumerator
		bysort id_03: gen total_enhh = _N
		
		
		**** Replacement variable
		gen 	backcheck = 0
		
		replace backcheck = 1 if randomrank <= 1								// Only in the first week
		//replace backcheck = 1 if randomrank <= round(total_enhh*0.1)

*-------------------------------------------------------------------------------
* 3. Cosmetics
*-------------------------------------------------------------------------------		
		
	rename id_05 headid	
	rename pl_id_06 id_06
	rename pl_id_07 id_07
	rename pl_id_08 id_08
	rename pl_id_09 id_09
	
	rename pl_sample samplehh	
	
	
	**** Varaible labels 
	label variable id_06 "Village"
	label variable id_07 "Cell"
	label variable id_08 "Sector"
	label variable id_09 "District"
	label variable id_24 "Cellphone number"
	
	
	**** Replace HH if it changed
	gen pl_resp = pl_id_11
	replace pl_resp = id_11_corrected if id_11_confirm == 0
	
	**** Gen the number of plots owned
	
	gen  pl_plots = c_14_00
	
*-------------------------------------------------------------------------------
* 3. Exporting back check table
*-------------------------------------------------------------------------------	
	
	
	**** Drop all HHs not selected to be backchecked
	keep if backcheck == 1

	
	**** Check if any of the HHs was alreafy selected for Back checks
	* This should not happen because we're already selecting by week,
	* but check just in case
	
	//use
	
	
	
	keep id_06 id_07 id_08 id_09 headid samplehh pl_resp pl_plots id_24 week
	
	
	
	**** Merge with the laste version of the preload to add newer obs and see if duplicates
	preserve
		tempfile last_bc_preload
		
		//import delimited "$fu2_eu_bc/preload_data_HH_bc_week1.csv", clear
		
		tostring id_24, replace // make cellphone number to string
	
		save `last_bc_preload'
	
	restore
	
	destring samplehh, replace
	
	merge 1:1 headid using `last_bc_preload'
	
	**** Minor fix because the first one did not have a week variable
	replace week =1 if week ==.
	
	**** Export
	local save_week = "$select_week"
	
	
	
	export delimited using "$fu2_eu_preload/Back Checks/preload_data_HH_bc_week${select_week}.csv", replace
	export delimited using "$fu2_eu_preload/preload_data_HH_bc.csv", replace

	
