capture program drop imp_reg
program define imp_reg 
syntax varlist , prefix(string) fname(string) source(string) [DFactor(string)]  

local counter = 0 
gl logfilename = "`fname'.txt"
local stubcounter = 0 
foreach var in `varlist'  {
	local stubcounter = `stubcounter'+1 
}
local widetab = 0
if "`dfactor'"=="" {
	local dfactor = 1
}

if `dfactor'!=1 {
	local divline = "All variables are divided by \$`dfactor'\$ in the level regressions to ensure convergence."
	
}
if `stubcounter'>20 {
	local widetab = 1 
}

foreach var in `varlist'  {
	local varlabel: var label `var'
	if "`varlabel'"=="" {
			local varlabel = "`var'"
	}
	
	
	capture drop temprvar 
	gen double temprvar = `var'/`dfactor'
	capture drop tempivar 
	gen double tempivar = `prefix'_`var'/`dfactor'
		
	reg temprvar tempivar 

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
					
				}
				
				test _b[tempivar] = 1 
				if `r(p)'>=.1 { 
					local subv_`var'_a = "^{\dagger\dagger}"

				}

				if `r(p)'>=.1 & `pvalcons_a'>=.1 { 
					local subv_`var'_a = "^{\dagger\dagger\dagger}" 

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
		
		if `widetab'==0 {
			local line_1 ="" 
			local line_2 = ""
			foreach let in a {
				if `tag_`let''==1 {
					local line_1 = "`line_1' & \$ `b_`let''`star_pval_`let'' \$ & \$   `cons_`let''`star_pvalcons_`let'' \$ & \$ `ar2_`let''`subv_`var'_`let'' \$ "
					local line_2 = "`line_2' & \raisebox{-\vspopt}{\smaller[\subsize]{\$ (`se_`let'') \$ } }& \raisebox{-\vspopt}{\smaller[\subsize]{\$(`secons_`let'') \$ }} &  \raisebox{-\vspopt}{\$`n_`let'' \$ }" 
				}
		
			}
			local a = substr("`var'",3,.)
			if `counter'==0 {
				capture log close 
				qui log using "$logfilename" , t replace 
				di "\begin{tabular}{lccc}"
				di "Variable & Beta & Cons & Stats \\"
				di "\hline"
				qui log close
				local counter = 1 
			
			}
			if `tag_a'==1  {
				qui log using "$logfilename"  , t append 
				di "`varlabel'  `line_1' \\"
				di "`line_2' \\"
				qui log close
			}
		}
		else { 
			local line_1 ="" 
			*local line_2 = ""
			foreach let in a {
				if `tag_`let''==1 {
					local line_1 = "`line_1' & \$ `b_`let''`star_pval_`let'' \$ & \$ (`se_`let'') \$ & \$   `cons_`let''`star_pvalcons_`let'' \$ & \$(`secons_`let'') \$ & \$ `ar2_`let''`subv_`var'_`let'' \$  & \$`n_`let'' \$ " 
				}
		
			}
			local a = substr("`var'",3,.)
			if `counter'==0 {
				capture log close 
				qui log using "$logfilename" , t replace 
				di "\begin{tabular}{lcccccc}"
				di "Variable & Beta & Beta SE & Cons & Cons SE & Adj. \$R^2\$ & Obs.  \\"
				di "\hline"
				qui log close
				local counter = 1 
			
			}
			if `tag_a'==1  {
				qui log using "$logfilename"  , t append 
				di "`varlabel'  `line_1' \\"
				qui log close
			}
		}
		
	capture drop temprvar 
	capture drop tempivar
	capture drop weight_tot
	capture drop weight_prev
	capture drop weight_next
	capture drop imp_var 
	capture drop prev_var
	capture drop imp_var 
	capture drop taglim_`var'_a
	capture drop prev_yr
	capture drop next_yr
	capture drop next_var 
	capture drop pers
}
forv i = 1/1 { 
	if  "`nolog'"=="" { 
	qui log using notes$logfilename , t replace
	di "\begin{tablenotes}"
	di "\item Source: `source' \\ "
	di "This table shows the results of a regression "
	di "\$ Y_t =  \beta_0 + \beta_1 Y^p_t \$"
	di "where "
	di "\$ Y^p_t \$ "
	di "is the smoothed variable constructed by applying the ratio imputed according to  "
	di "\$ Y^s_t = Y_{t-n} \times \bigg( \frac{{} p }{p+n} \bigg) + Y_{t+p}\times \bigg(\frac{n}{n+p}\bigg) \$" 
	di " if  "
	di "\$ p,n \leq d \land \{ p\leq d-1 \lor n\leq d-1 \} \$." 
	di " to construct either side of the missing variable.".
	di "periods moved ahead or before period \$ t \$ until reaching a non-missing "
	di "non-zero value for  \$ Y_t\$. The maxmimum distance moved, \$ d \$, is "
	di "set to `maxdist'. \\" 
	di "The second column reflects \$ \beta_1 \$ while the third gives \$ \beta_0 \$." 
	di "The fourth column shows the summary statistics for the same regression "
	di "with the first row indicating the adjusted \$ R^2\$"
	di "and the second row indicating the number of observations."
	di "`divline'"
	di "\$ \ast \$  \$ p<.1 \$  \$ \ast\ast \$  \$ p<.05 \$  \$ \ast\ast\ast \$  \$ p<.01 \$ \\"
	di "\$ \dagger \$ indicates that the constant is not statistically "
	di " significantly different from zero at the 10\% level."
	di "\$ \dagger\dagger \$ indicates that the coeficient is not statistically significantly different from unity at the 10\% level." 
	di "\$ \dagger\dagger\dagger \$ indicates that both previous conditions hold."	
  di "\end{tablenotes}"
	qui log close
	}
}

forv i = 1/1 { 
	qui log using "$logfilename"  , t append 
	di "\hline"
	di "\end{tabular}"
	qui log close 
}
if  "`nolog'"=="" { 
	filefilter $logfilename a$logfilename , from("\n> ") to("") replace	
	filefilter notes$logfilename anotes$logfilename , from("\n> ") to("") replace	

	filefilter a$logfilename $logfilename , from("\r") to("") replace
	filefilter anotes$logfilename notes$logfilename , from("\r") to("") replace

	erase a$logfilename
	erase anotes$logfilename

	}

end
