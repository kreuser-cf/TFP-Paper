cap program drop perp_inv 
program define perp_inv 
	syntax , data(string)  ///
			 capdeflator(string) /// 
			 capitalvar(string) ///
			 year(string) ///
			 id(string) /// 
			 depvar(string) ///
			 [dephardcode(string) ///
			 importcond(string) condvars(string)] ///
			 sadr(string) ///
			 logadr(string) ///
			 logprefix(string) ///
			 tabprefix(string) ///
			 [addvars(string)] ///
             [doadr(string)] ///
             sname(string) ///
             fixedassets(string)  
             
	
	* 0. Check code works 
	if "`importcond'"!=""{ 
		if "`condvars'"=="" { 
			di as err "Specify condvars if you have import conditions"
			exit 
		}
	}




    do "`doadr'\\get_aggregates.do"
    do "`doadr'\\smooth_regs_upd.do"
    do "`doadr'\\smooth_ratio_upd.do"
    do "`doadr'\\imp_reg.do"
    do "`doadr'\\fredenisty.do"

	cap mkdir `logadr'
	* 1. Housekeeping 
	use `id' `year' `capitalvar' `depvar' `capdeflator' `condvars' `addvars' `fixedassets' `importcond'  using `data', clear 
	egen idused = group(`id') 
	xtset idused `year'
	gen __dep_p = `depvar' if `depvar'>0
    
    if "`fixedassets'"!="" {
		local falist = "" 
        foreach var in `fixedassets' { 
			gen __`var'_p = `var' if `var'>0
			local falist = "`falist' __`var'_p"
		}
        egen fixed = rowtotal(`falist'), m 
		replace fixed = . if fixed<0 
		local capitalvar = "`capitalvar' fixed"
    }
     
	
	* 2. Capital variable if positive 
	foreach var in `capitalvar'  { 
		gen `var'_p = `var' if `var'>0 
		* 2.1. Gen if has depreciation 
        cap drop tag_dep
		gen tag_dep = 0 if `var'_p!=. 
		replace tag_dep =1 if __dep_p!=. & __dep_p>0 

        gen `var'_wd = `var'_p if tag_dep==1 
        gen `var'_pd = `var'_p + __dep_p if __dep_p!=.  
        replace `var'_pd = `var'_p if __dep_p==. 
        
	* capital stock if positive plus depreciation
		local basic_dr_list = "" 
        foreach depstatus in p { 
			gen dr_`var'_`depstatus'_b_a = __dep_p/l.`var'_`depstatus' 
			gen dr_`var'_`depstatus'_b_l = __dep_p/l.`var'_`depstatus'  if  __dep_p<l.`var'_`depstatus'
			gen dr_`var'_`depstatus'_i_a = dr_`var'_`depstatus'_b_a
			replace dr_`var'_`depstatus'_i_a = f.dr_`var'_`depstatus'_b_a if dr_`var'_`depstatus'_b_a==. 
			gen dr_`var'_`depstatus'_i_l =  dr_`var'_`depstatus'_b_l 
			replace dr_`var'_`depstatus'_i_l = f.dr_`var'_`depstatus'_b_l  if dr_`var'_`depstatus'_b_l ==. 
			local basic_dr_list = "`basic_dr_list' dr_`var'_`depstatus'_b_a dr_`var'_`depstatus'_b_l dr_`var'_`depstatus'_i_a dr_`var'_`depstatus'_i_l"
		}

	    local kap_var_list = "`var' `var'_p `var'_pd  "
        cd "`logadr'"
        smooth_regs `kap_var_list' , xt(idused `year') fname(`tabprefix'_level_`var') maxdist(2) 	///
                                    source("Author's own calculations based on CIT-IRP5 Data. All values are deflated using gross capital formation.") ///
                                    df(1000)

        foreach j in `kap_var_list' { 
            capture drop iv_`j'
            gen iv_`j' = `j'
            capture drop iv_`j'_code 
            gen iv_`j'_code = 1 if iv_`j'!=. 
            replace iv_`j' = imp_`j' if iv_`j'==. & imp_`j'>0 
            replace iv_`j'_code = 2 if iv_`j'!=. & iv_`j'_code==. 		
            capture drop imp_`j'
        }


        
        smooth_ratio `basic_dr_list' ,  xt(idused `year') fname(`tabprefix'_rate_`var') maxdist(2) 		source("Author's own calculations based on CIT-IRP5 Data. All values are deflated using gross capital formation.") 
        foreach j in `basic_dr_list' { 
            capture drop iv_`j'
            gen iv_`j' = `j'
            capture drop iv_`j'_code 
            gen iv_`j'_code = 1 if iv_`j'!=. 		
            replace iv_`j' = iratio_`j' if iv_`j'==. & iratio_`j'>0 & iratio_`j'<1
            replace iv_`j'_code = 2 if iv_`j'!=. & iv_`j'_code==. 			
	    }
        local p_b_a = "Basic All"
        local p_b_l = "Basic Lim."
        local p_i_a = "F. Imp. All"
        local p_i_l = "F. Imp. Lim."
        local vlist = "" 
		local vlistlim = ""
        foreach j in p_b_a p_b_l p_i_a p_i_l { 
            label var dr_`var'_`j' "``j''"
            label var iv_dr_`var'_`j'  "Imputed ``j''"
            local vlist ="`vlist' dr_`var'_`j' iv_dr_`var'_`j'"
			local vlistlim = "`vlistlim' lim_dr_`var'_`j' lim_iv_dr_`var'_`j'"
			
			gen lim_dr_`var'_`j' = dr_`var'_`j' if dr_`var'_`j'<1.5
			gen lim_iv_dr_`var'_`j' = iv_dr_`var'_`j' if iv_dr_`var'_`j'<1.5
			
			label var lim_dr_`var'_`j' "Lim. ``j'' "
			label var lim_iv_dr_`var'_`j' "Lim. Imp. ``j''"
		}
        fredensity_mv  `vlist' , fname(`tabprefix'_drs_`var') lims(1) addmean addmed
		fredensity_mv  `vlistlim' , fname(lim_`tabprefix'_drs_`var') lims(1) addmean addmed



        * The only hard deprec we use is on _pd 
        foreach dr in b i { 
            foreach st in a l  {
                foreach depstatus in p { 
                capture drop iv_dep_`var'_`depstatus'_`dr'_`st'	
                capture drop iv_dep_`var'_`depstatus'_`dr'_`st'_code 
                gen iv_dep_`var'_`depstatus'_`dr'_`st' = __dep_p if __dep_p>0 
                gen iv_dep_`var'_`depstatus'_`dr'_`st'_code	 = 1 if iv_dep_`var'_`depstatus'_`dr'_`st'!=. 
                replace iv_dep_`var'_`depstatus'_`dr'_`st' =  iv_dr_`var'_`depstatus'_`dr'_`st'*l.iv_`var'_`depstatus' if  iv_dep_`var'_`depstatus'_`dr'_`st'==.			
                replace iv_dep_`var'_`depstatus'_`dr'_`st'_code	 = 2 if iv_dep_`var'_`depstatus'_`dr'_`st'!=. & iv_dep_`var'_`depstatus'_`dr'_`st'_code==.	

                gen iv_`var'_`depstatus'_`dr'_`st' = iv_`var'_`depstatus'
                capture drop iv_`var'_`depstatus'_`dr'_`st'_code
                gen iv_`var'_`depstatus'_`dr'_`st'_code = iv_`var'_`depstatus'_code 			                
                replace iv_`var'_`depstatus'_`dr'_`st' = iv_dep_`var'_`depstatus'_`dr'_`st'/iv_dr_`var'_`depstatus'_`dr'_`st' if iv_`var'_`depstatus'_`dr'_`st'==.
                replace iv_`var'_`depstatus'_`dr'_`st'_code = 3 if iv_`var'_`depstatus'_`dr'_`st'_code==. & iv_`var'_`depstatus'_`dr'_`st'!=.
                }
            }
        }
 
        foreach depstatus in p   { 
            foreach dr in b i  { 
                foreach st in a l  {
                    capture drop investment 
                    gen investment = (`var'_`depstatus'-l.`var'_`depstatus'+__dep_p)/`capdeflator'		
                    capture drop syearv
                    gen syearv = `year' if `var'_`depstatus'!=. & `var'_`depstatus'>0  
                    capture drop min_syearv
                    by idused: egen min_syearv = min(syearv)				
                    capture drop pi_`var'_`depstatus'_`dr'_`st' 
                    gen double pi_`var'_`depstatus'_`dr'_`st' = `var'_`depstatus'/`capdeflator' if `year'==min_syearv
                    replace pi_`var'_`depstatus'_`dr'_`st' = l.pi_`var'_`depstatus'_`dr'_`st'*(1-dr_`var'_`depstatus'_`dr'_`st') + investment if `year'>min_syearv 
                }
            }	
        }

        foreach dr in 10 15 20 { 
            cap drop dep_`dr'
            gen dep_`dr' = (`dr'/100)*l.`var'_pd 
            capture drop investment 
            gen investment = (`var'_pd-l.`var'_pd+dep_`dr')/`capdeflator'		
            capture drop syearv
            gen syearv = `year' if `var'_pd!=. 
            capture drop min_syearv
            by idused: egen min_syearv = min(syearv)				
            capture drop pi_`var'_pd_`dr' 
            gen double pi_`var'_pd_`dr ' = `var'_pd/`capdeflator' if `year'==min_syearv
            replace pi_`var'_pd_`dr' = l.pi_`var'_pd_`dr'*(1-(`dr'/100)) + investment if `year'>min_syearv 
        }
        local p_b_a = "Basic All"
        local p_b_l = "Basic Lim."
        local p_i_a = "F. Imp. All"
        local p_i_l = "F. Imp. Lim."
        local pd_10 = "10% Dep."
        local pd_15 = "15% Dep."
        local pd_20 = "20% Dep."
        local vlist = "" 
        foreach dcol in p_b_a p_b_l p_i_a p_i_l pd_10 pd_15 pd_20 { 
            gen lpi_`var'_`dcol' = ln(pi_`var'_`dcol')
            label var lpi_`var'_`dcol' "``dcol''"
            local vlist = "`vlist' lpi_`var'_`dcol'"            
        }
        gen l`var'_p = ln(`var'_p) 
        label var l`var'_p "Log `var'"
        gen l`var'_wd = ln(`var'_wd)
        label var l`var'_wd "Log `var' with Dep"
        fredensity_mv l`var'_p  l`var'_wd `vlist' , fname(`tabprefix'_pi_`var') lims(1)

    	foreach depstatus in p  { 
            foreach dr in b i { 
                foreach st in a l  {
                    capture drop investment 
                    gen investment = (iv_`var'_`depstatus'_`dr'_`st'-l.iv_`var'_`depstatus'_`dr'_`st'+iv_dep_`var'_`depstatus'_`dr'_`st')/`capdeflator'
                    capture drop syearv
                    gen syearv = `year' if iv_`var'_`depstatus'_`dr'_`st'!=. 
                    capture drop min_syearv
                    by idused: egen min_syearv = min(syearv)				
                    capture drop pi_iv_`var'_`depstatus'_`dr'_`st' 
                    gen double pi_iv_`var'_`depstatus'_`dr'_`st' = iv_`var'_`depstatus'_`dr'_`st'/`capdeflator' if `year'==min_syearv
                    replace pi_iv_`var'_`depstatus'_`dr'_`st' = l.iv_`var'_`depstatus'_`dr'_`st'*(1-iv_dr_`var'_`depstatus'_`dr'_`st') + investment if `year'>min_syearv 
			    }
		    }	
	    }


        foreach dr in 10 15 20 { 
            cap drop dep_`dr'
            gen dep_`dr' = (`dr'/100)*l.iv_`var'_pd 
            capture drop investment 
            gen investment = (iv_`var'_pd-l.iv_`var'_pd+dep_`dr')/`capdeflator'		
            capture drop syearv
            gen syearv = `year' if iv_`var'_pd!=. 
            capture drop min_syearv
            by idused: egen min_syearv = min(syearv)				
            capture drop pi_iv_`var'_pd_`dr' 
            gen double pi_iv_`var'_pd_`dr ' = iv_`var'_pd/`capdeflator' if `year'==min_syearv
            replace pi_iv_`var'_pd_`dr' = l.pi_iv_`var'_pd_`dr'*(1-(`dr'/100)) + investment if `year'>min_syearv 
        }
        gen liv_`var'_p = ln(iv_`var'_p) 
        label var liv_`var'_p "Imp. Log `var'"
        local vlist = ""
        foreach dcol in p_b_a p_b_l p_i_a p_i_l pd_10 pd_15 pd_20 { 
            gen lpi_iv_`var'_`dcol' = ln(pi_iv_`var'_`dcol')
            label var lpi_iv_`var'_`dcol' "``dcol''"
            local vlist = "`vlist' lpi_iv_`var'_`dcol'"            
        }

        fredensity_mv l`var'_p liv_`var'_p   `vlist' , fname(`tabprefix'_pi_iv_`var') lims(1) 
    

        cap drop lpi* 
        cap drop liv*
        


    }
    cd "`sadr'"
    save `sname', replace 
        
	end 
