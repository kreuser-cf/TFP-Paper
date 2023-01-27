* This do-file creates manufacturing data for TFP estimates

clear 
set more off
cap program drop internal_sum_stats 
	program define internal_sum_stats 
	syntax , outputvar(string) salesvar(string) capitalvar(string) costvar(string) empvar(string) ///
             intvar(string) id(string) year(string) indvar(string)  sadr(string) sname(string) minobs(integer)
		preserve 
		tokenize `outputvar'  `costvar' `salesvar' `capitalvar' `empvar' `intvar'
        egen idvar = group(`id')
        xtset idvar `year'
        gen one = 1
        local gcond = "one==1"
        local sum_list = "(sum)" 
		local mean_list = "(mean)"
		local sd_list = "(sd)"
        local check_list = ""
        forv i = 1/6 {
            gen ``i''_lag = ``i'' if ``i''_lag!=. 
            local cond_`i' = "``i''>0 & ``i''!=."
            gen has_``i'' = 1 if `cond_`i''
            gen has_``i''_lag = has_``i'' if l.has_``i''==1             
            local gcond = "`gcond' & `cond_`i''"
            gen has_`i' = 1 if `gcond'
            gen has_`i' = has_`i' if l.has_`i'==1 
            local check_list = "`check_list' ``i''"
            local sum_list = "`sum_list' sum_``i''=``i'' sum_has_``i''=has_``i'' sum_has_`i'=has_`i' sum_``i''_lag=``i''_lag sum_has_``i''_lag=has_``i''_lag sum_has_`i'_lag=has_`i'_lag"
			local mean_list = "`mean_list' mean_``i''=``i'' mean_``i''_lag=``i''_lag"
			local sd_list = "`sd_list' sd_``i''=``i'' sd_``i''_lag=``i''_lag"
		}
        forv i = 1/6 {
            forv j = 1/6 {
                gen ``i''_`j' = ``i'' if has_`j'==1 & ``i''!=.
                gen ``i''_`j'_lag = ``i'' if has_`j'_lag==1 & ``i''_lag!=.
                gen has_``i''_`j'_f = 1 if ``i''_`j'>=0 & ``i''_`j'!=. 
                gen has_``i''_`j'_f_lag = has_``i''_`j'_f if l.``i''_`j'>=0 & l.``i''_`j'!=. 

                local check_list = "`check_list' ``i''_`j' ``i''_`j'_lag "
                local sum_list = "`sum_list' sum_``i''_`j'=``i''_`j' sum_has_``i''_`j'_f=has_``i''_`j'_f sum_``i''_`j'_lag=``i''_`j'_lag sum_has_``i''_`j'_f_lag=has_``i''_`j'_f_lag"
				local mean_list = "`mean_list' mean_``i''_`j'=``i''_`j' mean_``i''_`j'_lag=``i''_`j'_lag"
				local sd_list = "`sd_list' sd_``i''_`j'=``i''_`j' sd_``i''_`j'_lag=``i''_`j'_lag"
					
            }
        }
        collapse (sum) one `sum_list'  `mean_list' `sd_list' , by(`indvar' `year' )		
		foreach var in `check_list' { 
            replace  sum_`var' = -10 if sum_has_`var'<`minobs'
            replace  sum_has_`var' = -10 if sum_has_`var'<`minobs'
        }
        save "`sadr'\\`sname'_by_ind", replace  
		restore 
		preserve 
		tokenize `outputvar'  `costvar' `salesvar' `capitalvar' `empvar' `intvar'
        gen one = 1
        local gcond = "one==1"
        local sum_list = "(sum)" 
		local mean_list = "(mean)"
		local sd_list = "(sd)"
        local check_list = ""
        forv i = 1/6 {
            gen ``i''_lag = ``i'' if ``i''_lag!=. 
            local cond_`i' = "``i''>0 & ``i''!=."
            gen has_``i'' = 1 if `cond_`i''
            gen has_``i''_lag = has_``i'' if l.has_``i''==1             
            local gcond = "`gcond' & `cond_`i''"
            gen has_`i' = 1 if `gcond'
            gen has_`i' = has_`i' if l.has_`i'==1 
            local check_list = "`check_list' ``i''"
            local sum_list = "`sum_list' sum_``i''=``i'' sum_has_``i''=has_``i'' sum_has_`i'=has_`i' sum_``i''_lag=``i''_lag sum_has_``i''_lag=has_``i''_lag sum_has_`i'_lag=has_`i'_lag"
			local mean_list = "`mean_list' mean_``i''=``i'' mean_``i''_lag=``i''_lag"
			local sd_list = "`sd_list' sd_``i''=``i'' sd_``i''_lag=``i''_lag"
		}
        forv i = 1/6 {
            forv j = 1/6 {
                gen ``i''_`j' = ``i'' if has_`j'==1 & ``i''!=.
                gen ``i''_`j'_lag = ``i'' if has_`j'_lag==1 & ``i''_lag!=.
                gen has_``i''_`j'_f = 1 if ``i''_`j'>=0 & ``i''_`j'!=. 
                gen has_``i''_`j'_f_lag = has_``i''_`j'_f if l.``i''_`j'>=0 & l.``i''_`j'!=. 

                local check_list = "`check_list' ``i''_`j' ``i''_`j'_lag "
                local sum_list = "`sum_list' sum_``i''_`j'=``i''_`j' sum_has_``i''_`j'_f=has_``i''_`j'_f sum_``i''_`j'_lag=``i''_`j'_lag sum_has_``i''_`j'_f_lag=has_``i''_`j'_f_lag"
				local mean_list = "`mean_list' mean_``i''_`j'=``i''_`j' mean_``i''_`j'_lag=``i''_`j'_lag"
				local sd_list = "`sd_list' sd_``i''_`j'=``i''_`j' sd_``i''_`j'_lag=``i''_`j'_lag"
					
            }
        }
		collapse (sum) one `sum_list'  `mean_list' `sd_list'  , by(`year' )
		foreach var in `check_list' { 
            replace  sum_`var' = -10 if sum_has_`var'<`minobs'
            replace  sum_has_`var' = -10 if sum_has_`var'<`minobs'
        }
        forv i = 1/6 { 
            replace sum_has_`i' = -10 if sum_has_`i'<`minobs'
        
        }
        replace one = -10 if one<`minobs'
        save "`sadr'\\`sname'", replace 
		restore
	end
cap log using "D:\Researchers\Workbenches\epadmin\brink_dane\Productivity\data\log.scml", replace

local id = "taxrefno"
local year = "taxyear"
local ind3d = "comp_prof_sic5_3d"
local ind2 = "base_isic4"
local saveadr = "D:\Researchers\Workbenches\epadmin\brink_dane\Productivity\sumstats\"
cap mkdir "`saveadr'"

use "D:\Researchers\Workbenches\epadmin\brink_dane\Perpetual_Inventory\data\citirp5_qfs_v4.dta", clear
* Create Industry Var
cap drop idused
egen idused = group(`id')
merge m:1 comp_prof_sic5_3d using "D:\Researchers\Workbenches\epadmin\brink_dane\Productivity\data\3digit_isic4", gen(ind_merge_basic) 
rename comp_prof_sic5_3d old_comp_prof_sic5_3d
rename isic4 `ind2'

gen temp_ind = old_`ind3d' if old_`ind3d'>=300 & old_`ind3d'<400 & old_`ind3d'!=.
by `id': egen cps_3d = mode(temp_ind)
gen tag_cps3d_year = `year' if temp_ind!=. 
by `id': egen last_3d_year = max(tag_cps3d_year)
gen last_3d = temp_ind if last_3d_year==`year' 
by `id': egen last3d = mode(last_3d) 
replace cps_3d = last3d if cps_3d==. 

by taxrefno: egen cps_3d = mode(temp_cps_3d)
gen tag_cps3d_year = taxyear if temp_cps_3d!=. 
by taxrefno: egen last_3d_year = max(tag_cps3d_year)
gen last_3d = temp_cps_3d if last_3d_year==`year' 
by taxrefno: egen last3d = mode(last_3d) 
replace cps_3d = last3d if cps_3d==. 
rename cps_3d comp_prof_sic5_3d 
merge m:1 comp_prof_sic5_3d using "D:\Researchers\Workbenches\epadmin\brink_dane\Productivity\data\3digit_isic4", gen(ind_merge_full) 

* Create Manuf Indicator
gen manuf_ind = 0
replace manuf_ind = 1 if temp_ind!=.
by `id': egen sum_manuf = total(manuf_ind)
gen seen = 0
replace seen = 1 if old_`ind3d'!=. 
by `id': egen tot_seen = total(seen)
gen manuf_coverage = sum_manuf/tot_seen
gen insamp  = 1 
xtset idused `year'
gen ind2_changed = 1*(l.`ind2'!=`ind2')
gen ind3_changed = 1*(l.old_`ind3d'!=old_`ind3d') 
gen isic4_changed = 1*(l.isic4!=isic4) 
gen ind3u_changed = 1*(l.`ind3d'!=`ind3d') 
levelsof isic4, local(ind)
levelsof `year' , local(yr)
local rows  = 0 
	foreach indus of local ind { 
		foreach yy of local yr {
		local ++rows
	}
}
    mata: manuftab = J(`rows',18,.)
	local row = 1 
	foreach indus of local ind { 
		foreach yy of local yr { 
			mata: manuftab[`row',1] = `indus'
			mata: manuftab[`row',2] = `yy'
			qui sum manuf_coverage if isic4==`indus' & `year'==`yy' 
			mata: manuftab[`row',3] = `r(N)'
			if `r(N)'>0 { 
				mata: manuftab[`row',4] = `r(mean)'
			}
			qui sum manuf_coverage if isic4==`indus' & `year'==`yy' & manuf_coverage==1 
			mata: manuftab[`row',5] = `r(N)'
			qui sum manuf_coverage if isic4==`indus' & `year'==`yy' & manuf_coverage==0 
			mata: manuftab[`row',6] = `r(N)'
			qui sum manuf_coverage if isic4==`indus' & `year'==`yy' & manuf_coverage>0 & manuf_coverage<1  
			mata: manuftab[`row',7] = `r(N)'
			if `r(N)'>0 {
				mata: manuftab[`row',8] = `r(mean)'
			}
			qui sum manuf_coverage if isic4==`indus' & `year'==`yy'  & insamp==1 
			mata: manuftab[`row',9] = `r(N)'
			if `r(N)'>0 {
				mata: manuftab[`row',10] = `r(mean)'
			}
			qui sum ind2_changed  if isic4==`indus' & `year'==`yy'   
			mata: manuftab[`row',11] = `r(N)'
			if `r(N)'>0 {
				mata: manuftab[`row',12] = `r(mean)'
			}
			qui sum ind3_changed  if isic4==`indus' & `year'==`yy'   
			mata: manuftab[`row',13] = `r(N)'
			if `r(N)'>0 {
				mata: manuftab[`row',14] = `r(mean)'
			}	
			qui sum isic4_changed  if isic4==`indus' & `year'==`yy'   
			mata: manuftab[`row',15] = `r(N)'
			if `r(N)'>0 {
				mata: manuftab[`row',16] = `r(mean)'
			}
			qui sum ind3u_changed  if isic4==`indus' & `year'==`yy'   
			mata: manuftab[`row',17] = `r(N)'
			if `r(N)'>0 {
				mata: manuftab[`row',18] = `r(mean)'
			}	            				
			local ++row		
		}
	}
	mata: st_matrix("manuf",manuftab)
	mat colnames manuf = ind year N_indus mean_indus N_indus_1 N_indus_0 N_indus_b mean_indus_b N_indus_samp mean_indus_samp N_ind2_changed mean_ind2_changed N_ind3_changed mean_ind3_changed N_isic4_changed mean_isic4_changed  N_ind3u_changed mean_ind3u_changed 
    preserve 
    	svmat manuf , n(col)
        save "`saveadr'\\industries", replace 
    restore

* This is done upstairs 
    keep if isic4!=. 
    keep if manuf_coverage>.5

    qui log close 
    log using "D:\Researchers\Workbenches\epadmin\brink_dane\sumstats_send_fred_new" , replace 
    egen id = group(taxrefno)
    xtset id taxyear

    * 2.3 Real variables	
    gen real_kppe = (k_ppe/defl_grosscapform)*100
    tab taxyear , sum(k_ppe) 
    tab taxyear , sum(real_kppe) 
	
        
    * 2.3.1. fix faother where relevant
    gen real_faother = (k_faother/defl_grosscapform)*100
    replace real_faother = 0 if real_faother==.
    tab taxyear , sum(k_faother) 
    tab taxyear , sum(real_faother) 

    gen real_sales = (g_sales/defl_grossvaladd)*100 

    tab taxyear , sum(g_sales) 
    tab taxyear , sum(real_sales) 


    
    * 2.3.2.2 gcos without 
    gen real_gcos_A = (g_cos/defl_grossvaladd)*100												
    tab taxyear , sum(g_cos) 
    tab taxyear , sum(real_gcos_A) 

        
    * 2.3.2.3. Gcos1 includes stock adjustments
    gen real_gcos_B = (g_cos1/defl_grossvaladd)*100		
    tab taxyear , sum(g_cos1) 
    tab taxyear , sum(real_gcos_B) 
        
    * 2.3.2.4. gcos2 is cost of sales (only purchases)
    gen real_gcos_C = (g_cos2/defl_grossvaladd)*100			
    tab taxyear , sum(g_cos2) 
    tab taxyear , sum(real_gcos_C)	
        
    * 2.5. Value Added  
    foreach letter in A { 
        gen va_`letter' = real_sales - real_gcos_`letter' if real_sales>0 & real_sales!=. & real_gcos_`letter'>0 & real_gcos_`letter'!=. 
        tab taxyear, sum(va_`letter')
    }
		
    * 2.3.5. gcos is cost of sales
    gen real_dep = 	(x_deprec/defl_grosscapform)*100
    replace real_dep = 0 if real_dep==. 
    tab taxyear, sum(x_deprec)
    tab taxyear, sum(real_dep)
	
    * 2.3.7. Interest 
    gen real_int = 	(x_int/defl_grossvaladd)*100 
    replace real_int = 0  if real_int==.
    gen real_int_lag = l.real_int
    gen real_int_1 = 1 if real_int==0 
    gen real_int_1_lag = 1 if real_int_lag==0 

    tab taxyear , sum(x_int)
    tab taxyear , sum(real_int)	
        
    foreach var in real_kppe real_faother real_gcos_A real_gcos_B real_gcos_C real_dep real_sales real_int {
        replace `var' = . if `var'<0
    }

    egen k_fixed = rowtotal(real_kppe real_faother),m 
* 2.6 Capital Stock 
	* This is not consistent with the Pi method no?
		*gen k_fixed = real_kppe + real_faother 				  if real_kppe!=. & real_kppe>0 & real_faother!=. 
cap drop _merge
merge 1:1 taxrefno taxyear using "D:\Researchers\Workbenches\epadmin\brink_dane\Perpetual_Inventory\data\perp_inv_done.dta", keepusing(pi_*)
keep if _merge==3
drop _merge

rename irp5_kerr_weight_b kerr_w_b
rename irp5_kerr_daysweight_b kerr_dw_b
save "D:\Researchers\Workbenches\epadmin\brink_dane\Productivity\data\manuf_qfs_v4.dta", replace
/* RUN prod_bat_par form here */

gen o = ln(real_sales)
gen y = ln(va_A)
gen m = ln(real_gcos_A)
* following capital vars 
	* k_ppe 
	* pi_iv_k_ppe_p_i_l
gen i = .
gen k = .
gen l= . 
xtset id taxyear  
* p
foreach capvar in pi_iv_fixed_pd_10 pi_iv_k_ppe_pd_10 real_kppe k_fixed pi_iv_k_ppe_p_i_l pi_iv_fixed_p_i_l   {  
	cap drop k 
	gen k = ln(`capvar') 
	foreach empvar in kerr_w_b kerr_dw_b {  
		cap drop l 
		gen l  = ln(`empvar')
		foreach ivar in real_int { 
			cap drop i 
			gen i = ln(`ivar')
			* note I switched outputvar and salesvar in orignal code, keeping it like this for consistency
 			internal_sum_stats , outputvar(o) salesvar(y) capitalvar(k) costvar(m) empvar(l) intvar(i) ///
			 					year(taxyear) minobs(10) ///
                                 sadr("`saveadr'") ///
								sname(sumstats_`capvar'_`empvar'_`ivar') ///
								indvar(isic4)
		}
	}
}


keep if taxyear>=2009 & taxyear<=2017
