capture program drop get_aggregates
program define get_aggregates 
syntax varlist , yv(varlist) [group(varlist)]  [gv(string)] [mv(string)] [fname(string)] [tonly] [addonly]
	/*
	* yv - year variable
	* group - group variable for all variable 
	* gv	-	group variable as prefix 
				This is where each variable has a different grouping
				variable, the gv string is a prefix for each variable in varlist 
				idea for this field is that we have 
					data_k_fix
					agg_k_fix 
						where agg is from the aggregate data and data is from the CIT data for example
						this would need to be included in the group and non-group sections so that we get for field 
						x_deprec:
																	[YEAR]
						Depreciation 	[Industry]					[value]
						Aggregate		[Same Industry as above]	[value from StatsSA]

						does that make sense?
						
						
				* mv number of categories in the gv
	* FK to Dane: automate mv number
	* FK to Dane: Recode the group part so that each group gives its own table?

	* FK to Dane: clean up 			
	* FK to Dane: Include an autoflip option so that when activated it a
				 automatically flips the rows and the columns if there are more columns than rows. 
				 

	*/
	tokenize `varlist' 
	local j = 1
	while "``j''"!="" {
		local j = `j'+1
	}
	local vcounter = `j'
	local ylabel: var label `yv'
	if "`group'"!="" {
		levelsof `group' , local(gr)
		local gindex: var label `group'
		local glabel: val label `group' 
}
	
	
	levelsof `yv', local(year)
	local j = 0 
	foreach val in  `year' { 
		local j = `j'+1
	}
	local ycounter = `j'
	sort `yv' `group' 

		local shape = "{l"
		local gshape = "{ll"
		local vallist = "" 
		local gvallist = ""
		foreach var in `year' {
			local shape = "`shape'c"
			local vallist = "`vallist' & `var'"
			local gshape = "`gshape'c"					
		}


		capture log close
		if "`addonly'"=="" {
			if "`group'"=="" {
				qui log using `fname'.txt, t replace 
				di "\begin{tabular}`shape'}"
				di "Variable `vallist' \\"
				di "\hline"
				qui log close
			}
			else { 
				qui log using `fname'.txt, t replace 
				di "\begin{tabular}`gshape'}"
				di "Variable & `gindex'  `vallist' \\"
				di "\hline"
				qui log close
			}
		}
		sort `yv' `group' 
		local i = 1 
		while "``i''"!="" {
		
			local varname`i': var label ``i''
			if "`group'"=="" {
				by `yv' : egen tot_``i'' = total(``i'')	
				
				foreach y in `year' { 
						qui sum ``i'' if `yv'==`y'  
						local m_``i''_`y' = r(mean)
						local sd_``i''_`y' = r(sd)	
						foreach var in m sd { 
							local vs = round(``var'_``i''_`y'')
							local stlen = strlen("`vs'")
							local `var'_``i''_`y':  di %`=`stlen'+12'.2fc ``var'_``i''_`y''			
							local `var'line_``i'' = "``var'line_``i''' & ``var'_``i''_`y''"
						}
						qui sum tot_``i'' if `yv'==`y'  
						local tot_``i''_`y' = r(mean)
						local vs = round(`tot_``i''_`y'')
						local stlen = strlen("`vs'")				
						local tot_``i''_`y':  di %`=`stlen'+2'.0fc	`tot_``i''_`y'' 
						local totline_``i'' = "`totline_``i''' & `tot_``i''_`y''"
				}
				
				qui log using `fname'.txt, t append 
				di "`varname`i'' `totline_``i''' \\"
				if "`tonly'"==""{
					di "Mean `mline_``i''' \\"
					di "SD `sdline_``i''' \\"
				}
				qui log close
			}

			
			if "`group'"!="" {
				by `yv' `group': egen gtot_``i'' = total(``i'')
				local sc = 1
				foreach g in `gr' {
					if `sc'==1  { 
						local gab:  label `glabel' `g'
						local g`var'line_``i''_`sc' = "`varname`i'' & `gab'"					
					}
					else {
						local gab:  label `glabel' `g'
						local g`var'line_``i''_`sc' = " & `gab'"					
					}
					foreach y in `year' { 
						qui sum gtot_``i'' if `yv'==`y'   & `group'==`g'  					
						local tot_``i''_`y'_`sc' = r(mean)
						local vs = round(`tot_``i''_`y'_`sc'')
						local stlen = strlen("`vs'")				
						local tot_``i''_`y'_`sc':  di %`=`stlen'+2'.0fc	`tot_``i''_`y'_`sc'' 
						local g`var'line_``i''_`sc' = "`g`var'line_``i''_`sc'' & `tot_``i''_`y'_`sc''"					
												
						/* qui sum ``i'' if `yv'==`y'  & `group'==`g' 
						local m_``i''_`y' = r(mean)
						local sd_``i''_`y' = r(sd)			
						foreach var in m sd { 
							local vs = round(``var'_``i''_`y'')
							local stlen = strlen("`vs'")
							capture local `var'_``i''_`y':  di %`=`stlen'+1'.2fc ``var'_``i''_`y''			
							capture  local g`var'line_``i'' = "`g`var'line_``i''' & ``var'_``i''_`y''"
							}
						local tot_``i''_`y' = r(mean)
						*/
						
					}
				qui log using `fname'.txt, t append 
				di 	"`g`var'line_``i''_`sc'' \\"
				qui log close	
				local sc = `sc'+1
				}
			}
			
			if "`gv'"!="" { 
				bys `yv' `gv'_``i'': egen gtot_``i'' = total(``i'')
				levelsof `gv'_``i'', local(gvl)
				foreach y in `year' { 
					foreach g in `gvl' { 
						qui sum ``i'' if `yv'==`y'  & `gv'_``i''==`g' 
						local m_``i''_`y' = r(mean)
						local sd_``i''_`y' = r(sd)			
						foreach var in m sd { 
							local vs = round(``var'_``i''_`y'')
							local stlen = strlen("`vs'")
							capture local `var'_``i''_`y':  di %`=`stlen'+1'.2fc ``var'_``i''_`y''			
							capture  local g`var'line_``i'' = "`g`var'line_``i''' & ``var'_``i''_`y''"
			
						}
					qui sum gtot_``i'' if `yv'==`y'   & `gv'_``i''==`g' 
					local tot_``i''_`y' = r(mean)
					local vs = round(`tot_``i''_`y'')
					local stlen = strlen("`vs'")				
					local tot_``i''_`y':  di %`=`stlen'+2'.0fc	`tot_``i''_`y'' 
					local gtotline_``i'' = "`gtotline_``i''' & `tot_``i''_`y''"	
					}
				}
			qui log using `fname'.txt, t append 
			di "`varname`i'' `gtotline_``i''' \\ "
			if "`tonly'"==""{
				di "Mean `gmline_``i''' \\ "
				di "SD `gsdline_``i''' \\ "
			}
			qui log close
			}
			capture drop gtot_``i''
			capture drop tot_`i'	
			local i = `i'+1 
	
		}
		capture ds tot*
		foreach var in `r(varlist)' { 
			capture drop `var'
		}
		capture ds  gtot*
		foreach var in `r(varlist)' { 
			capture drop `var'
		}
forv i = 1/1 {
	qui log using `fname'.txt, t append 
	di "\hline" 
	di "\end{tabular}"
	qui log close
}	

	filefilter `fname'.txt a`fname'.txt , from("\n> ") to("") replace	
	filefilter a`fname'.txt `fname'.txt , from("\r") to("") replace	

	erase a`fname'.txt
		
end
