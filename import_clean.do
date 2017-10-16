* This is part of the master dofile "MasterDofile_import_clean_check.do".

	*---------------------
	* 1. Clean the logbook
	*---------------------
	
	* Import the logbook and put better labels
	import excel using "$fu2_eu\Logbook.xlsx", firstrow clear 
	drop W-AE
	rename (headid interviewcompletedANDsentto droppedfromsampleYes1 Reason1Permanentlymovedaway HHreplaced HHcodelinkedtoreplacement HHcodelinkedtoduplicate backcheck_sample backcheckcompletedANDsentt backcheckresult0Notvisited thirdvisitresult0Responden backcheckcorrectionsmadetosu) ///
		   (id_05 complete dropped reason replaced linked_replacement linked_duplicate bc_sample bc_completed bc_notvisited visit3_fail bc_corrected)
	label var id_05 "HH ID"
	label var id_06 "Village"
	label var id_07 "Cell"
	label var id_08 "Sector"
	label var id_09 "District"
	label var id_11 "HHH name"
	label var id_12 "HHH national ID"
	label var id_13 "Spouse name"
	label var id_14 "Spouse national ID"
		
	* Make sure all HH ID is unique in the logbook
	duplicates tag id_05, gen(duplicate)
	assert duplicate == 0 
	drop duplicate
	
	* Save the logbook as a temp file
	tempfile logbook
	save `logbook'

	*-------------------------------------
	* 2. Import the latest survey raw data
	*-------------------------------------

	import delimited using "$fresh_data", clear case(lower) 
	
	* Merge with the logbook made above
	mmerge id_05 using `logbook'
	
	