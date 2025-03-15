capture program drop fredensity 
	/* note that Bvars should be a list of binary variables tested one at a time */ 
	/* note that OBvars should be a list of ordered binary variables tested in order */ 
	/* note that Cvars should any categorical variables, note that this variable will be grouped and then
		Looped through */ 
	
program define fredensity 
	syntax varlist [if] , [fname(string)] [lims(string)] [BVars(varlist)] [CVars(varlist)] [OBvars(varlist)] [title(string)]
		preserve 
		marksample touse 
		keep if `touse'
		keep `varlist' `cvars' `bvars' `obvars' 
		gen mainvar = `varlist'
		local main_lab: var label `varlist'
		if "`title'"!="" {
			local main_lab = "`title'"
		}
		keep if mainvar!=.
		local stop = 0 
		if "`bvars'"!="" & "`cvars'"!="" { 
			di "bvars and cvars cannot be specified simultaniously" 
			local stop  = 1
		} 
		if "`bvars'"!="" & "`obvars'"!="" { 
			di "bvars and obvars cannot be specified simultaniously" 
			local stop = 1 
		}
		if "`cvars'"!="" & "`obvars'"!="" { 
			di "cvars and obvars cannot be specified simultaniously" 
			local stop = 1 
		}
		if `stop'==1 {
			STOP
		}
		if "`cvars'"=="" & "`bvars'"=="" & "`obvars'"=="" { 
			qui sum mainvar
			local strlen = strlen("`r(N)'")
			local obs_1:  di %`=`strlen'+1'.0fc `r(N)' 

			local a_1: var label mainvar 
			label var mainvar "`a' [N: `obs_1']"
			local leg_1 "label(1 "`a_1' [N: `obs_1']")"
			local legend_list = `"`leg_1'"'
		}
		
		if "`bvars'"!=""{
			foreach var in `bvars' {
				local add_list = ""
				local lcounter = 1 
				forv i = 0/1 { 
					gen mainvar_`i' = mainvar if `var'==`i'
					qui sum mainvar_`i'
					local strlen = strlen("`r(N)'")
					local obs_`lcounter':  di %`=`strlen'+1'.0fc `r(N)' 
					
					if "`lims'"!="" {
						qui sum mainvar_`i', d
						replace mainvar_`i' = `r(p`lims')' if mainvar_`i'<`r(p`lims')'
						replace mainvar_`i' = `r(p`=100-`lims'')' if mainvar_`i'>`r(p`=100-`lims'')' & mainvar_`i'!=.					
					}
						
				local a_`lcounter': val label `var' 
				local b_`lcounter': label `a_`lcounter'' `i'
				label var mainvar_`i' "`a' [N: `obs_`lcounter'']"
				local leg_`lcounter' "label(`lcounter' "`b_`lcounter'' [N: `obs_`lcounter'']")"
				local add_list = "`add_list' (kdensity mainvar_`i')"
				local legend_list =`"`legend_list' `leg_`lcounter''"'
				local lcounter = `lcounter'+1								
				}
			twoway `add_list',  legend(`legend_list') scheme(mine) xtitle(`main_lab')
			if "`fname'"!="" {
				graph export `fname'_`var'.pdf, as(pdf) replace 
			}
		}
	}	
	if "`cvars'"!=""{
			foreach var in `cvars' {
				local add_list = ""
				local lcounter = 1
				levelsof `var', local(lvl)
				foreach i of local lvl { 
					gen mainvar_`i' = mainvar if `var'==`i'
					qui sum mainvar_`i'
					local strlen = strlen("`r(N)'")
					local obs_`lcounter':  di %`=`strlen'+1'.0fc `r(N)' 
					if "`lims'"!="" {
						qui sum mainvar_`i', d
						replace mainvar_`i' = `r(p`lims')' if mainvar_`i'<`r(p`lims')'
						replace mainvar_`i' = `r(p`=100-`lims'')' if mainvar_`i'>`r(p`=100-`lims'')' & mainvar_`i'!=.					
					}				
						
				local a_`lcounter': val label `var' 
				local b_`lcounter': label `a_`lcounter'' `i'
				label var mainvar_`i' "`a' [N: `obs_`lcounter'']"
				local leg_`lcounter' "label(`lcounter' "`b_`lcounter'' [N: `obs_`lcounter'']")"
				local add_list = "`add_list' (kdensity mainvar_`i')"
				local legend_list =`"`legend_list' `leg_`lcounter''"'
				local lcounter = `lcounter'+1								
				}
			twoway `add_list',  legend(`legend_list') scheme(mine) xtitle(`main_lab')
			if "`fname'"!="" {
				graph export `fname'_`var'.pdf, as(pdf) replace 
			}
		}
	}	
	
	restore
end 


