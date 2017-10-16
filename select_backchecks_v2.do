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
		
	use "$fu2_eu_raw/RFR_FU2_EU_v1.6.dta", clear
	
	
	**** Minor fixes
	
	destring id_05 id_05_reenter, replace


*-------------------------------------------------------------------------------
* 1. Week variable
*-------------------------------------------------------------------------------
/*	
	
	g svystart=date("10/09/2017","MDY")										//the first seems to be started 8/29 but should be 9/10
	format svystart %td
	
	

		egen week_count_new=count(n), by(week)
		compare week_count week_count_new
		replace week_count=week_count_new if week_count==.
	
		g week=ceil((submissiondate-svystart)/7)
		assert week!=.
		su week
	
	gen fobar year(dofc(submissiondate))
	
	
	* DROP LOGBOOK ONLY
	* Define week variable
	* Keep only the ones from the right week
	* Select 10% of HH randomly and replicably
	* Save an excel sheet saying if they were selected before EVEN IF THEY WERE NOT INTERVIEWED?
*/
	
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
	
	**** Replace HH if it changed
	gen pl_resp = pl_id_11
	replace pl_resp = id_11_corrected if id_11_confirm == 0
	
	**** Gen the number of plots owned
	
	gen  pl_plots = c_14_00
	
*-------------------------------------------------------------------------------
* 3. Exporting back check table
*-------------------------------------------------------------------------------	
	
	keep if backcheck == 1

	
	keep id_06 id_07 id_08 id_09 headid samplehh pl_resp pl_plots 
	
	//export delimited using "$fu2_eu_preload/preload_data_HH_bc.csv", replace

	
	/*
	
	//keep headid	id_06	id_07	id_08	id_09	id_11	id_12	id_13	/*id_14*/	samplehh	id_11_confirm	id_11_change	id_11_move	id_11_new	id_11_note	id_11_note2	firstlast_1	firstlast_2	firstlast_3	firstlast_4	firstlast_5	firstlast_6	firstlast_7	firstlast_8	firstlast_9	firstlast_10	firstlast_11	firstlast_12	firstlast_13	firstlast_14	firstlast_15	age_1	age_2	age_3	age_4	age_5	age_6	age_7	age_8	age_9	age_10	age_11	age_12	age_13	age_14	age_15	ovr18_1	ovr18_2	ovr18_3	ovr18_4	ovr18_5	ovr18_6	ovr18_7	ovr18_8	ovr18_9	ovr18_10	ovr18_11	ovr18_12	ovr18_13	ovr18_14	ovr18_15	sex_1	sex_2	sex_3	sex_4	sex_5	sex_6	sex_7	sex_8	sex_9	sex_10	sex_11	sex_12	sex_13	sex_14	sex_15	id_1	id_2	id_3	id_4	id_5	id_6	id_7	id_8	id_9	id_10	ovr18_orig_1	ovr18_orig_2	ovr18_orig_3	ovr18_orig_4	ovr18_orig_5	ovr18_orig_6	ovr18_orig_7	ovr18_orig_8	ovr18_orig_9	ovr18_orig_10	ovr18_orig_11	ovr18_orig_12	ovr18_orig_13	ovr18_orig_14	ovr18_orig_15	hhsize	NID	
	//villagecode 
		
	****	Cosmetics															
	label variable id_06 "Village"
	label variable id_07 "Cell"
	label variable id_08 "Sector"
	label variable id_09 "District"
	label variable id_11 "HH Head"
	label variable id_12 "HH head NID"
	label variable id_13 "HH head spouse"
	label variable id_14 "HH head spouse NID"
	label variable map1 "Map id 1st half"
	label variable map2	"Map id 2nd half"
	
	forvalues memb = 1/15 {
		label variable firstlast_`memb' "HH member `memb' name"
		label variable age_`memb' 		"HH member `memb' age"
		label variable ovr18_`memb' 	"Is HH member `memb' over 18"
		label variable sex_`memb' 		"HH member `memb' gender"
	}
	
	
	** Order columns
	order VillageCode headid id_06 id_07 id_08 id_09 id_11 id_12 id_13 id_14 id_15 samplehh landmapid map_check	
			
		**** Keep only the HH selected for replacement
		//keep if backcheck == 1
		
		* save preload for the back check
		* save excel sheet with a list of all HH ever seleceted to be 
		
		save `ubudehe_replacement', replace
	*/
