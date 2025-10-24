capture program drop smooth_regs 
program define smooth_regs 
syntax varlist , fname(string) maxdist(integer) [altform(varlist) altformcond(string)] xt(varlist) [nolog]

local counter = 0 
gl logfilename = "`fname'.txt"

xtset `xt'
tokenize `xt'
local idv = "`1'"
local yv = "`2'"

foreach var in `varlist'  {
	local varlabel: var label `var'
	if "`varlabel'"=="" {
			local varlabel = "`var'"
	}
		
	if "`altform'"=="" {
		capture drop imp_`var'
		gen imp_`var' = . 
		capture drop imp_`var'_code 
		gen imp_`var'_code = . 
		foreach l in a { 
			capture drop taglim_`var'_`l'
			gen taglim_`var'_`l' = 0	
		}
		

		local tag_a = 0 
		local tag_b = 0	
		capture drop prev_var 
		capture drop next_var 
		capture drop prev_yr
		capture drop next_yr
		gen prev_var = . 
		gen next_var = .
		gen next_yr = . 
		gen prev_yr = .
		forv i = 1/`maxdist' { 
			replace prev_var = l`i'.`var' if l`i'.`var'!=. & l`i'.`var'!=0 & prev_var==.
			replace next_var = f`i'.`var' if f`i'.`var'!=. &  f`i'.`var'!=0 & next_var==.
			replace prev_yr = l`i'.`yv' if l`i'.`var'!=. & l`i'.`var'!=0 & prev_yr==.
			replace next_yr = f`i'.`yv' if f`i'.`var'!=. &  f`i'.`var'!=0  & next_yr==.
		}	
		
		capture drop pers
		gen pers = 0 
		replace pers = 1 if next_yr!=. & prev_yr!=. 
		replace pers = 2 if next_yr==. & prev_yr!=. 
		replace pers = 3 if next_yr!=. & prev_yr==. 
		capture drop weight_prev
		capture drop weight_next
		capture drop weight_tot

		gen weight_prev = . 
		gen weight_next = . 
		replace weight_prev = abs(`yv'-prev_yr) 
		replace weight_next = abs(`yv'-next_yr) 
		egen weight_tot = rowtotal(weight_prev weight_next)
		capture drop imp_var
		gen double imp_var = prev_var if pers==2 
		replace imp_`var'_code = 2 if prev_var!=. & pers==2  	
		replace imp_var= next_var if pers==3 
		replace imp_`var'_code = 3 if next_var!=. & pers==3	
		replace imp_var = ((weight_next)/weight_tot)*prev_var+((weight_prev)/weight_tot)*next_var if pers==1
		replace imp_`var'_code = 1 if imp_var!=. & pers==1 
		replace imp_var = . if imp_var==0 | imp_var<=0
		replace imp_var = . if f.imp_var==. & l.imp_var==. 
		replace imp_var = . if  f.weight_next>`maxdist' & f.weight_next!=. & weight_prev!=. 
		replace imp_var = . if  weight_next>`maxdist'  & weight_next!=. & weight_prev==`maxdist' 
		replace imp_var = . if  l.weight_prev>`maxdist' & l.weight_prev!=. & weight_next!=. 
		replace imp_var = . if  weight_prev>`maxdist'  & weight_prev!=. & weight_next==`maxdist' 	
		replace imp_`var' = imp_var 
		
		/* note that we run into a scaling issue in stata here so we */
		capture drop temprvar 
		gen double temprvar = `var'/1000
		capture drop tempivar 
		gen double tempivar = imp_var/1000
		local persicond = "if pers==1"

	}
	else {
		local tag_a = 0 
		capture drop temprvar 
		gen double temprvar = `altform'/100
		capture drop tempivar
		gen double tempivar = `var'/100
		local persicond = ""
		foreach l in a { 
			capture drop taglim_`var'_`l'
			gen taglim_`var'_`l' = 0	
		}		
		if "`altformcond'"!=""{ 
			local persicond = "if `altformcond'"
		}
	
	}
	 reg temprvar tempivar `persicond' 

		if _rc==0 {
			local n_a = e(N)
			local ar2_a = round(e(r2_a),.001)
			local b_a = round(_b[tempivar],.001)
			local t_a = _b[tempivar]/_se[tempivar]
			local se_a = round(_se[tempivar],.001)
			local pval_a =  round(2*ttail(e(df_r),abs(`t_a')),.001)
			local cons_a = round(_b[_cons],.001)
			local secons_a = round(_se[_cons],.001)
			local tcons_a = _b[_cons]/_se[_cons]
			local pvalcons_a =  round(2*ttail(e(df_r),abs(`tcons_a')),.001)
			if `ar2_a'>0 { 
				local subv_`var'_a = ""
				if `pvalcons_a'>=.1 {
					local subv_`var'_a = "^{\dagger}"
					replace taglim_`var'_a = 2  
					
				}
				
				test _b[tempivar] = 1 
				if `r(p)'>=.1 { 
					local subv_`var'_a = "^{\dagger\dagger}"
					replace taglim_`var'_a = 1  

				}

				if `r(p)'>=.1 & `pvalcons_a'>=.1 { 
					local subv_`var'_a = "^{\dagger\dagger\dagger}" 
					replace taglim_`var'_a = 3  

				}
			}
			foreach pval in pval_a pvalcons_a {
				local star_`pval' = ""
				if ``pval''<.1 {
						local star_`pval' = "^{\ast}"
					}
					if ``pval''<.05 {
						local star_`pval' = "^{\ast\ast}"
					}
					if ``pval''<.01 {
						local star_`pval' = "^{\ast\ast\ast}"
					}
			}
			local tag_a = 1

		
		}
	
		foreach let in a {
			foreach l in r2 ar2 b t se pval cons secons tcons pvalcons { 
				if `tag_`let''==1 { 
					local vv = regexm("``l'_`let''","\.")
					if `vv'==1 { 
						local strpos = strpos("``l'_`let''",".")+3
						local `l'_`let' = substr("``l'_`let''",1,`strpos')
					}

				}
			}
		}
		
	local line_1 ="" 
		local line_2 = ""
		foreach let in a {
			if `tag_`let''==1 {
				local line_1 = "`line_1' & \$ `b_`let''`star_pval_`let'' \$ & \$   `cons_`let''`star_pvalcons_`let'' \$ & \$ `ar2_`let''`subv_`var'_`let'' \$ "
				local line_2 = "`line_2' & \raisebox{-\vspopt}{\smaller[\subsize]{\$ (`se_`let'') \$ } }& \raisebox{-\vspopt}{\smaller[\subsize]{\$(`secons_`let'') \$ }} &  `n_`let''" 
			}
	
		}
	local a = substr("`var'",3,.)
	if `counter'==0 & "`nolog'"=="" {
		capture log close 
		qui log using "$logfilename" , t replace 
		di " \begin{tabular}{lccc} "
		di "Variable & Beta & Cons & Stats \\ "
		di " \hline "
		qui log close
		local counter = 1 
	
	}
	if `tag_a'==1  & "`nolog'"==""  {
		qui log using "$logfilename"  , t append 
		di "`varlabel'  `line_1' \\"
		di "`line_2' \\"
		qui log close
	}
}
forv i = 1/1 { 
	if  "`nolog'"=="" { 
	qui log using "$logfilename"  , t append 
	di "\hline"
	di "\end{tabular}"
	qui log close 
	}
}
forv i = 1/1 { 
	if  "`nolog'"=="" { 

	qui log using notes$logfilename , t replace
	di "\begin{tablenotes}"
	di "\item Source: Author's own calculations based on CIT-IRP5 data. \\"
	di "This table shows the results of a regression \$ Y_t =  \beta_0 + \beta_1 Y^s_t \$"
	di "where \$ Y^s_t \$ is the smoothed variable construced using equation" 
	di "\ref{eq:smoother}."
	di "The second column reflects $ \beta_1$ while the third gives \$ \beta_0 \$." 
	di "The fourth column shows the summary statistics for the same regression with the first row indicating the adjusted \$ R^2\$"
	di "and the second row indicating the number of observations."
	di "To ensure convergence, all variables are divided by $1000$."
	di "All variables are deflated using the value added deflator"
	di "\$ \ast \$  \$ p<.1 \$  \$ \ast\ast \$  \$ p<.05 \$  \$ \ast\ast\ast \$  \$ p<.01 \$ \\"
	di "\$ \dagger \$ indicates that the constant is not statistically significantly different from zero at the 10\% level."
	di "\$ \dagger\dagger \$ indicates that the coeficient is not statistically significantly different from unity at the 10\% level." 
	di "\$ \dagger\dagger\dagger \$ indicates that both previous conditions hold."	
  di "\end{tablenotes}"
	qui log close
	}
}
if  "`nolog'"=="" { 

	filefilter $logfilename a$logfilename , from("> ") to("") replace	
	filefilter a$logfilename $logfilename , from("\r\n") to("") replace
	erase a$logfilename
}

end