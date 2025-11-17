capture program drop fredensity 
	/* note that Bvars should be a list of binary variables tested one at a time */ 
	/* note that OBvars should be a list of ordered binary variables tested in order */ 
	/* note that Cvars should any categorical variables, note that this variable will be grouped and then
		Looped through it must have value labels*/ 
	
program define fredensity 
	syntax varlist [if] , [fname(string)] [lims(string)] [BVars(varlist)] [CVars(varlist)] [OBvars(varlist)] [title(string)] figadr(string)
		local remember_address = c(pwd)
		cd "`figadr'"
		preserve 
		marksample touse 
		keep if `touse'
		keep `varlist' `cvars' `bvars' `obvars' 
		gen ___mainvar = `varlist'
		local main_lab: var label `varlist'
		if "`title'"!="" {
			local main_lab = "`title'"
		}
		keep if ___mainvar!=.
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
			qui sum ___mainvar
			local strlen = strlen("`r(N)'")
			local obs_1:  di %`=`strlen'+1'.0fc `r(N)' 

			local a_1: var label ___mainvar 
			label var ___mainvar "`a' [N: `obs_1']"
			local leg_1 "label(1 "`a_1' [N: `obs_1']")"
			local legend_list = `"`leg_1'"'
		}
		
		if "`bvars'"!=""{
			foreach var in `bvars' {
				local add_list = ""
				local lcounter = 1 
				forv i = 0/1 { 
					gen ___mainvar_`i' = ___mainvar if `var'==`i'
					qui sum ___mainvar_`i'
					local strlen = strlen("`r(N)'")
					local obs_`lcounter':  di %`=`strlen'+1'.0fc `r(N)' 
					
					if "`lims'"!="" {
						qui sum ___mainvar_`i', d
						replace ___mainvar_`i' = `r(p`lims')' if ___mainvar_`i'<`r(p`lims')'
						replace ___mainvar_`i' = `r(p`=100-`lims'')' if ___mainvar_`i'>`r(p`=100-`lims'')' & ___mainvar_`i'!=.					
					}
						
				local a_`lcounter': val label `var' 
				local b_`lcounter': label `a_`lcounter'' `i'
				label var ___mainvar_`i' "`a' [N: `obs_`lcounter'']"
				local leg_`lcounter' "label(`lcounter' "`b_`lcounter'' [N: `obs_`lcounter'']")"
				local add_list = "`add_list' (kdensity ___mainvar_`i')"
				local legend_list =`"`legend_list' `leg_`lcounter''"'
				local lcounter = `lcounter'+1								
				}
			twoway `add_list',  legend(`legend_list') scheme(friendly) xtitle(`main_lab')
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
					gen ___mainvar_`i' = ___mainvar if `var'==`i'
					qui sum ___mainvar_`i'
					local strlen = strlen("`r(N)'")
					local obs_`lcounter':  di %`=`strlen'+1'.0fc `r(N)' 
					if "`lims'"!="" {
						qui sum ___mainvar_`i', d
						replace ___mainvar_`i' = `r(p`lims')' if ___mainvar_`i'<`r(p`lims')'
						replace ___mainvar_`i' = `r(p`=100-`lims'')' if ___mainvar_`i'>`r(p`=100-`lims'')' & ___mainvar_`i'!=.					
					}				
						
				local a_`lcounter': val label `var' 
				local b_`lcounter': label `a_`lcounter'' `i'
				label var ___mainvar_`i' "`a' [N: `obs_`lcounter'']"
				local leg_`lcounter' "label(`lcounter' "`b_`lcounter'' [N: `obs_`lcounter'']")"
				local add_list = "`add_list' (kdensity ___mainvar_`i')"
				local legend_list =`"`legend_list' `leg_`lcounter''"'
				local lcounter = `lcounter'+1								
				}
			twoway `add_list',  legend(`legend_list') scheme(friendly) xtitle(`main_lab')
			if "`fname'"!="" {
				graph export `fname'_`var'.pdf, as(pdf) replace 
			}
		}
	}	
	restore
	cd "`remember_address'"
end 

capture program drop fredensity_mv 
program define fredensity_mv 
	syntax varlist [if] , [fname(string)] [lims(string)] [BVars(varlist)] [CVars(varlist)] [OBvars(varlist)] [title(string)] [addmean] [addmed] figadr(string)
		local remember_address = c(pwd)
		cd "`figadr'"
		tokenize `varlist' 
		local wc = wordcount("`varlist'")
		di "`wc'"

		local legend_list = "" 
		local kdensity_list = "" 
		forv i = 1/`wc' { 
			local main_lab_`i': var label ``i''
            sum ``i'' , d
            local strlen_`i' = strlen("`r(N)'")

			if "`lims'"!="" {            
                * take 1,99% level 
                local min_``i'' = r(p`lims')
                local max_``i'' = r(p`=100-`lims'')
                sum ``i'' if ``i''>=`min_``i''' & ``i''<=`max_``i''', d
                local strlen_`i' = strlen("`r(N)'")
                local cond_`i' = "if ``i''>=`min_``i''' & ``i''<=`max_``i'''"			
            }
			local obs_`i':  di %`=`strlen_`i''+1'.0fc `r(N)' 
            local meanie = `r(mean)'
            local medie = `r(p50)'
            if `r(mean)'<10 { 
	    		local mean_`i': di %4.3g `meanie'
            }
			else { 
	    		local mean_`i': di %7.4g `meanie'				
			}
            if `medie'<10 { 
	    		local med_`i': di %4.3g `medie'
            }
            else {
	    		local med_`i': di %7.4g `medie'
				
				
			}
			cap drop __temp_`i'
			gen __temp_`i' = ``i''
            label var __temp_`i' "`main_lab_`i'' [N: `obs_`i'']"
			local leg_`i' "label(`i' "`main_lab_`i'' [N: `obs_`i'']")"
			if "`addmean'"!="" { 
    			local leg_`i' "label(`i' "`main_lab_`i''(`mean_`i'') [`obs_`i''] ")"
            }
            if "`addmed'"!="" { 
    			local leg_`i' "label(`i' "`main_lab_`i'' (`mean_`i'') |`med_`i''| [`obs_`i''] ")"
            }
            local legend_list   `legend_list' `leg_`i''
			local kdensity_list = "`kdensity_list' (kdensity __temp_`i' `cond_`i'')" 
		}

		twoway `kdensity_list',  legend(`legend_list' size(vsmall)) scheme(friendly)  xtitle("")
		if "`fname'"!="" {
			graph export `fname'.pdf, as(pdf) replace 
		}
		
		forv i = 1/`wc' { 
			cap drop __temp_`i'

		}
		cd "`remember_address'"
end 

/*
clear 
set obs 1000
gen y = runiform()
gen x = rnormal() + y
gen z = rnormal()
gen cat = 1 if y<.2 
replace cat = 2 if y>=.2 & y<.4 
replace cat = 3 if y>=.4 & y<.6 
replace cat = 4 if y>=.6 & y<.8
replace cat = 5 if y>=.8 & y<=1
 * make sure that cats have value labels 
 forv i = 1/5 { 
	label define cat `i' "Category `i'", modify 
	}
	label val cat cat 
	label var cat "Category"
* This would be the basic version	
fredensity x, fname(test) cvars(cat) 
* if you want to include conditions for 1 percentile control of the main variable 
fredensity x, fname(limit1) cvars(cat) lims(1)
* this would be if you want to use some other ratio
fredensity x if z>1, fname(zcond) cvars(cat) 

*/