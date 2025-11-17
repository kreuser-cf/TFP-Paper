cap program drop perp_inv 
program define perp_inv 
	syntax , data(string)  ///
			 capdeflator(string) /// 
			 capitalvar(string) ///
			 year(string) ///
			 id(string) /// 
			 depvar(string) ///
			 sadr(string) ///
			 logadr(string) ///
			 tabadr(string) ///
			 figadr(string) ///
			 logprefix(string) ///
			 tabprefix(string) ///
			 doadr(string) ///
			 [addvars(string)] ///
             sname(string) ///
             [fixedassets(string) ///
			 importcond(string) condvars(string)]  
	/* 
		* data the data source
		* capdeflator: the capital deflator 
		* capital var: list of capital variables of interest
		* fixedassets: list of variables that should be summed together for a new capital variable called fixed
		* depvar: dependant variable 
		* adr; addresess and locations
	*/
	
	/* 
	
	Suffix meanings 
	
	
	_p: Var is positive with non-missing non-zero value. 
	_pd: var plus depreciation; the idea here is to calculate beginning of period capital stock and not end of period capital stock 
	_wd: var is in an unit of analusos that has non-zero non missing depreciation
	_b_*: Basic - no imputations 

	_a: unrestricted sample (conidtional on other suffixes)
	_l: restricted sample, generally that depreciation of the firm reported in this period must be less than closing value in previous period
	
	
	PREFIX MEANINGS
	dr_ : depreciation rate calculated based on x_deprec over the relevant noted capvar
	iv_ : imputation indicator; indicates whetehr the value was imputed from the smooth_regs data 
    iv2_: depreciation rate that is built from a level and not rate; special case
	
	
	*/
	qui log query
	local pi_remember_log_file_name = "`r(filename)'"
	local remember_address = c(pwd)
	* 0. Check code works 
	if "`importcond'"!="" { 
		if "`condvars'"=="" { 
			di as err "Specify condvars if you have import conditions"
			exit 
		}
	}
	
	
   * do "`doadr'/get_aggregates.do"
    do "`doadr'/smooth_regs.do"
    * Smooth ratio is no longer used
	* do "`doadr'/smooth_ratio_upd.do"
    * do "`doadr'/imp_reg.do"
    do "`doadr'/fredensity.do"

	cap mkdir "`tabadr'"
	cd "`tabadr'"

	di "1. Housekeeping"
	use `id' `year' `capitalvar' `depvar' `capdeflator' `condvars' `addvars' `fixedassets' `importcond'  using "`data'", clear
	
	egen idused = group(`id') 
	xtset idused `year'
	gen __dep_p = `depvar' if `depvar'>0
	gen `depvar'_p = __dep_p 
	
	smooth_regs `depvar'_p, xt(idused `year') fname(`tabprefix'_level_`var') maxdist(2) 	///
                 source("Author's own calculations based on CIT-IRP5 Data. The industry gross fixed capital formation deflator is used. ") tabadr("`tabadr'")
								  
	foreach j in `depvar'_p { 
		capture drop iv_`j'
		* Create IV_ which takes on the original value 
		gen iv_`j' = `j'
		capture drop iv_`j'_code 
		* State that variable is not imputed using code 1
		gen iv_`j'_code = 0 if iv_`j'!=. 
		* Replace IV with the imputed value if imputed value is greater than 0
		replace iv_`j' = imp_`j' if iv_`j'==. & imp_`j'>0 
		* Replace IV code with the imputation code used 
		replace iv_`j'_code = imp_`j'_code if iv_`j'!=. & iv_`j'_code==. 		
		capture drop imp_`j'
		capture drop imp_`j'_code
	}

								  
	sum `capdeflator' 
	* This line is an insurance line in case 
	if `r(max)'>30 {
		di "Warning capital deflator has value above 30; assuming it intended to be a indexed deflator, dividing by 100"
		replace `capdeflator' = `capdeflator'/100 
	}
	
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
     
	gen rawdeprate = `depvar'
	
	di "2. Capital variable if positive"
	* cap drop rawdeprate 
		
	foreach var in `capitalvar'  { 
		
		* 2.1. Generate Capital if positive (negative capital stock does not make sense)
		gen `var'_p = `var' if `var'>0 
		* 2.2. Gen conditional if has positive depreciation 
        cap drop tag_dep
		gen tag_dep = 0 if `var'_p!=. 
		replace tag_dep =1 if __dep_p!=. & __dep_p>0 
		* 2.3. Generate wd 
        gen `var'_wd = `var'_p if tag_dep==1 
        gen `var'_pd = `var'_p + __dep_p if __dep_p!=.  
        replace `var'_pd = `var'_p if __dep_p==. 
        local lab_p = "Pos"
        local lab_pd = "Pos+Depr"
		if "`var'"!="fixed" {
			local lab_`var': var label `var'
		} 
		else { 
			local lab_`var' = "Fixed"
		}
		
		local kap_var_list = "`var'_p  `var'_pd "
		
		di "2.4: Apply smoothing function and check fit:"
			* The function smoothes the capital stock at a firm for 2 consequtive missing periods only in a straight line. 
			* It will upweight the closer one. If the order is 300 x y 600; y = 2/3*600 + 1/3*300 = 400+100=500; and x= 1/3*600+2/3*300 = 200+200=400. 
			* This approach can be expanded to more years; but for now the distance is kept to 2 periods 
		smooth_regs `kap_var_list' , xt(idused `year') fname(`tabprefix'_level_`var') maxdist(2) 	///
                                  source("Author's own calculations based on CIT-IRP5 Data. The industry gross fixed capital formation deflator is used. ") tabadr("`tabadr'")
		* 2.4.1. Update the imputed variable code to indicate that the relevant imputed variable has been updated. 
        foreach j in `kap_var_list' { 
            capture drop iiv_`j'
			* Create IV_ which takes on the original value 
            gen iiv_`j' = `j'
            capture drop iiv_`j'_code 
			* State that variable is not imputed using code 1
            gen iiv_`j'_code = 0 if iiv_`j'!=. 
			* Replace IV with the imputed value if imputed value is greater than 0
            replace iiv_`j' = imp_`j' if iiv_`j'==. & imp_`j'>0 
			* Replace IV code with the imputation code used 
            replace iiv_`j'_code = imp_`j'_code if iiv_`j'!=. & iiv_`j'_code==. 		
			
			capture drop iv_`j'
			gen iv_`j' = `j'
			capture drop iv_`j'_code 
			gen iv_`j'_code = 0 if iv_`j'!=. 
			replace iv_`j' = imp_`j' if iv_`j'==. & imp_`j'>0 
			replace iv_`j'_code = imp_`j'_code if iv_`j'!=. & iv_`j'_code==. 		


			replace iv_`j' = . if iv_`j'_code == 2 | iv_`j'_code == 3
			
					
			
        }
		

		* 2.5. Generate depreciation rates 
			* Depreciation rates in this period are generated based on the closing values of the previous period
			* It is assumed that K_{t} = (1-delta_{t})K_{t-1}+I_{t}: 
			*	K_{t}=K_{t-1}-delta_t K_{t-1} + I_t
			* so that delta_t K_{t-1} = Depreciation_{t}
			* Meaning that delta_t = depreciation_t/K_{t-1}

		* These depreciation rates only use non-imputed values
		local basic_dr_list = "" 
        foreach kapstatus in p pd { 
			gen dr_`var'_`kapstatus'_b_a = __dep_p/l.`var'_`kapstatus' 
			* Limit value sets the depreciation applied to be between 0 and 1
			gen dr_`var'_`kapstatus'_b_l = dr_`var'_`kapstatus'_b_a   if  dr_`var'_`kapstatus'_b_a>=0 & dr_`var'_`kapstatus'_b_a<=1

			local basic_dr_list = "`basic_dr_list' dr_`var'_`kapstatus'_b_a dr_`var'_`kapstatus'_b_l"
		}
	
		* Smooth ratios
		smooth_regs  `basic_dr_list' ,  xt(idused `year') fname(`tabprefix'_rate_`var') maxdist(2) 		source("Author's own calculations based on CIT-IRP5 Data. All values are deflated using gross capital formation.") tabadr("`tabadr'")  isratio
        foreach j in `basic_dr_list' { 
			capture drop iv_`j'
			* Create IV_ which takes on the original value 
            gen iv_`j' = `j'
            capture drop iv_`j'_code 
			* State that variable is not imputed using code 1
            gen iv_`j'_code = 0 if iv_`j'!=. 
			* Replace IV with the imputed value if imputed value is greater than 0
            replace iv_`j' = isratio_`j' if iv_`j'==. & isratio_`j'>=0
			* Replace IV code with the imputation code used 
            replace iv_`j'_code = isratio_`j'_code if iv_`j'!=. & iv_`j'_code==. 
            capture drop isratio_`j'
			capture drop isratio_`j'_code
	    }

        * 2.6. generate double imputed depreciation rates implied by imputation of both depreciation and capital var (for comparison)
		* use iiv for initialisation
		gen iv2_dr_`var'_p_b_a = iv_`depvar'_p/l.iiv_`var'_p
		gen iv2_dr_`var'_pd_b_a = iv_`depvar'_p/l.iiv_`var'_pd 
		foreach vsl in p_b pd_b { 
			gen iv2_dr_`var'_`vsl'_l = iv2_dr_`var'_`vsl'_a if iv2_dr_`var'_`vsl'_a>=0 & iv2_dr_`var'_`vsl'_a<=1
		}
	
		*2.7. Provide densities of imputations 
*        local p_i_a = "F. Imp. All"
 *       local p_i_l = "F. Imp. Lim."
*		local type_list = "p_b_a p_b_l p_i_a p_i_l"
        local vlist = ""
        local bigvlist = "" 
		local vlistlim = ""
		local b_a = "No Restr."
		local b_l = "0{&le}{&delta}{&le}1"
       
        foreach kapstatus in p pd { 
             local vlist = ""
            foreach limtype in b_a b_l { 
                label var dr_`var'_`kapstatus'_`limtype' "`lab_`kapstatus'' ``limtype''"
                label var iv_dr_`var'_`kapstatus'_`limtype'  "Imp `lab_`kapstatus'' ``limtype''"
                label var iv2_dr_`var'_`kapstatus'_`limtype'  "Double Imp: depr.{&frasl}kap `lab_`kapstatus'' ``limtype''"

                

                local vlist ="`vlist' dr_`var'_`kapstatus'_`limtype' iv_dr_`var'_`kapstatus'_`limtype' iv2_dr_`var'_`kapstatus'_`limtype'"
                local bigvlist ="`bigvlist' dr_`var'_`kapstatus'_`limtype' iv_dr_`var'_`kapstatus'_`limtype' iv2_dr_`var'_`kapstatus'_`limtype'"
            }
            fredensity_mv  `vlist' , fname(`tabprefix'_drs_`var'_`kapstatus') lims(1) addmean addmed  figadr("`figadr'")
			

        }

		* Update 05 Sept 2025: use both p and pd for hardcode 
    * 2.8 create imputed depreciation and resulting investment series and encode
        local impkap_0 = "Kap No"
        local impkap_1 = "Kap Interior"
        local impkap_2 = "Kap Forward"
        local impkap_3 = "Kap Backward"
        local impdr_0 = "{&delta} No"
        local impdr_1 = "{&delta} Interior"
        local impdr_2 = "{&delta} Forward"
        local impdr_3 = "{&delta} Backward"


       foreach dr in b { 
            foreach st in a l  {
                foreach kapstatus in p pd { 
                capture drop iv_dep_`var'_`kapstatus'_`dr'_`st'	
                capture drop iv_dep_`var'_`kapstatus'_`dr'_`st'_code 
                gen iv_dep_`var'_`kapstatus'_`dr'_`st' = __dep_p if __dep_p>0 
                gen iv_dep_`var'_`kapstatus'_`dr'_`st'_code	 = 0 if iv_dep_`var'_`kapstatus'_`dr'_`st'!=. 
                
                replace iv_dep_`var'_`kapstatus'_`dr'_`st' =  iv_dr_`var'_`kapstatus'_`dr'_`st'*l.iv_`var'_`kapstatus' if  iv_dep_`var'_`kapstatus'_`dr'_`st'==.
				        local ifcondcounterlabel = 1 			
			forv impkap = 0/3 { 
				forv impdr = 0/3 { 
					local depif_`ifcondcounterlabel' = "iv_dr_`var'_`kapstatus'_`dr'_`st'_code==`impdr' &                  l.iv_`var'_`kapstatus'_code==`impkap'"
					local depif_label_`ifcondcounterlabel' = "`impkap_`impkap''; `impdr_`ifcounterlabel''"
					local ++ifcondcounterlabel
				}
			}

                    forv natureofimputation = 1/`=`ifcondcounterlabel'-1' {
                        replace iv_dep_`var'_`kapstatus'_`dr'_`st'_code	 = `natureofimputation' if  iv_dep_`var'_`kapstatus'_`dr'_`st'!=. & iv_dep_`var'_`kapstatus'_`dr'_`st'_code==.	& `depif_`natureofimputation''

                    }
                }
            }
       }

       **************************************
       * 2.9 Calculate Clean Perpetual inventory capital stock with no imputations
        **********************************************************
        * 2.9.1. Using accounting Depreciation
        foreach kapstatus in p pd { 
            foreach dr in b  { 
                foreach st in a l  {
                    capture drop investment 
                    gen investment = (`var'_`kapstatus'-l.`var'_`kapstatus'+__dep_p)/`capdeflator'		
                    * Generate the first year in which the firm has a value for capital stock and set as opening value
                    capture drop syearv
                    gen syearv = `year' if `var'_`kapstatus'!=. & `var'_`kapstatus'>0  
                    capture drop min_syearv
                    by idused: egen min_syearv = min(syearv)	
                    capture drop pi_`var'_`kapstatus'_`dr'_`st' 
                    gen double pi_`var'_`kapstatus'_`dr'_`st' = `var'_`kapstatus'/`capdeflator' if `year'==min_syearv
                    * Construct the perpetual inventory measure for periods after that
                    replace pi_`var'_`kapstatus'_`dr'_`st' = l.pi_`var'_`kapstatus'_`dr'_`st'*(1-dr_`var'_`kapstatus'_`dr'_`st') + investment if `year'>min_syearv 
                }
            }	
        }
        cap drop investment
        * 2.9.2. Hardcoded depreciation
        foreach dr in 10 15 20 { 
			foreach kapstatus in p pd {
				cap drop dep_`kapstatus'_`dr'
				gen dep_`kapstatus'_`dr' = (`dr'/100)*l.`var'_`kapstatus' 
				capture drop investment
				gen investment = (`var'_`kapstatus'-l.`var'_`kapstatus'+dep_`kapstatus'_`dr')/`capdeflator'		
				capture drop syearv
				gen syearv = `year' if `var'_`kapstatus'!=.  & `var'_`kapstatus'>0  
				capture drop min_syearv
				by idused: egen min_syearv = min(syearv)				
				capture drop pi_`var'_`kapstatus'_`dr' 
				gen double pi_`var'_`kapstatus'_`dr ' = `var'_`kapstatus'/`capdeflator' if `year'==min_syearv & `var'_`kapstatus'>0  
				replace pi_`var'_`kapstatus'_`dr' = l.pi_`var'_`kapstatus'_`dr'*(1-(`dr'/100)) + investment if `year'>min_syearv  
			
			}
        }
        cap drop investment
        ***************************************************************
        * 2.10. Depreciation with imputations 
        *****************************************************************
    	foreach kapstatus in p pd  { 
            foreach dr in b { 
                foreach st in a l  {
                    capture drop investment 
                    gen investment = (iv_`var'_`kapstatus'-l.iv_`var'_`kapstatus'+iv_dep_`var'_`kapstatus'_`dr'_`st')/`capdeflator'
                    capture drop syearv
                    gen syearv = `year' if `var'_`kapstatus'!=. & `var'_`kapstatus'>0  
                    capture drop min_syearv
                    by idused: egen min_syearv = min(syearv)							
					gen double pi_iv_`var'_`kapstatus'_`dr'_`st' = `var'_`kapstatus'/`capdeflator' if `year'==min_syearv
                  
                   replace pi_iv_`var'_`kapstatus'_`dr'_`st' = l.pi_iv_`var'_`kapstatus'_`dr'_`st'*(1-iv_dr_`var'_`kapstatus'_`dr'_`st') + investment if `year'>min_syearv     
                    * absolute imputed investment					
                    capture drop investment 
                    gen investment = (iv_`var'_`kapstatus'-l.iv_`var'_`kapstatus'+iv_`depvar'_p)/`capdeflator'
                    capture drop syearv
                    gen syearv = `year' if `var'_`kapstatus'!=.  & `var'_`kapstatus'>0  
                    capture drop min_syearv
                    by idused: egen min_syearv = min(syearv)							
					gen double pi_iv2_`var'_`kapstatus'_`dr'_`st' = `var'_`kapstatus'/`capdeflator' if `year'==min_syearv
                    replace pi_iv2_`var'_`kapstatus'_`dr'_`st' = l.pi_iv2_`var'_`kapstatus'_`dr'_`st'*(1-iv2_dr_`var'_`kapstatus'_`dr'_`st') + investment if `year'>min_syearv
			    }

		    }	
	    }
        cap drop investment
        foreach dr in 10 15 20 {
			foreach kapstatus in p pd {
				cap drop dep_`kapstatus'_`dr'
				gen dep_`kapstatus'_`dr' = (`dr'/100)*l.iv_`var'_`kapstatus'
				capture drop investment
				gen investment  = (iv_`var'_`kapstatus'-l.iv_`var'_`kapstatus'+dep_`kapstatus'_`dr')/`capdeflator'		
				capture drop syearv
				gen syearv = `year' if `var'_`kapstatus'!=. & `var'_`kapstatus'>0  
				capture drop min_syearv
				by idused: egen min_syearv = min(syearv)				
				capture drop pi_iv_`var'_`kapstatus'_`dr' 
				gen double pi_iv_`var'_`kapstatus'_`dr ' = `var'_`kapstatus'/`capdeflator' if `year'==min_syearv
				replace pi_iv_`var'_`kapstatus'_`dr' = l.pi_iv_`var'_`kapstatus'_`dr'*(1-(`dr'/100)) + investment if `year'>min_syearv 
			}
		}

        * 2.11: create absolute depreciation imputation series for comparison 
        * what is created at this stage: 
            * pi_iv_var_kapstatus_dr - 10-15-20
            * pi_var_kapstatus_dr - 10-15-20
            * pi_var_kapstatus_dr_st - dr_st for these are b_a and b_l
            * pi_iv_var_kapstatus_dr_st - same as above
            * pi_iv2_var_kapstatus_dr_st ; 

        local dr_b_a = "No Rest."
        local dr_b_l = "0{&le}{&delta}{&le}1"
        local dr_10 = ".10 assumed"
        local dr_15 = ".15 assumed"
        local dr_20 = ".20 assumed"
        local pref_pi = "Perp Inv."
        local pref_pi_iv = "PIM Imp. {{&delta},K}"
		local pref_pi_iv2 = "PIM Imp. {Depr.,K}"
        local pref_r = "Real"
        local pref_r_iv "Real Imp. "
        local status_p = ""
        local status_pd = "+Depr."
        foreach kapstatus in p pd { 
            gen r_`var'_`kapstatus' = `var'_`kapstatus'/`capdeflator'
            gen r_iv_`var'_`kapstatus' = iv_`var'_`kapstatus'/`capdeflator'
        }

        foreach kapstatus in p pd {    
*            local density_set_`kapstatus' = "" 
			foreach pref in r r_iv { 
				  label var `pref'_`var'_`kapstatus' "`pref_`pref'' `lab_`var'' `status_`kapstatus'' "
                  gen l`pref'_`var'_`kapstatus' = ln(`pref'_`var'_`kapstatus')
                   label var l`pref'_`var'_`kapstatus' "`pref_`pref'' `lab_`var''  `status_`kapstatus''"
 *                   local density_set_`kapstatus' = "`density_set_`kapstatus'' l`pref'_`var'_`kapstatus'"
			
			}
			foreach dr in b_a b_l { 
				gen lpi_iv2_`var'_`kapstatus'_`dr' = ln(pi_iv2_`var'_`kapstatus'_`dr')
				label var pi_iv2_`var'_`kapstatus'_`dr' "`pref_pi_iv2' `lab_`var''  `status_`kapstatus'' `dr_`dr'' " 
				label var lpi_iv2_`var'_`kapstatus'_`dr' "`pref_pi_iv2' `lab_`var''  `status_`kapstatus'' `dr_`dr'' " 
			}
            foreach pref in pi_iv pi { 
                foreach dr in 10 15 20 b_a b_l { 
                        label var `pref'_`var'_`kapstatus'_`dr' "`pref_`pref' `lab_`var'' `status_`kapstatus'' ' {&delta} `dr_`dr'' "
                        gen l`pref'_`var'_`kapstatus'_`dr' = ln(`pref'_`var'_`kapstatus'_`dr')
                        label var l`pref'_`var'_`kapstatus'_`dr' "`pref_`pref' `lab_`var'' `status_`kapstatus'' ' {&delta} `dr_`dr'' "
  *                      local density_set_`kapstatus' = "`density_set_`kapstatus'' l`pref'_`var'_`kapstatus'_`dr' "
                    }
            }


			local set_a = "lr_`var'_`kapstatus' lr_iv_`var'_`kapstatus' lpi_`var'_`kapstatus'_b_a lpi_`var'_`kapstatus'_b_l lpi_iv_`var'_`kapstatus'_b_l lpi_`var'_`kapstatus'_10 lpi_iv_`var'_`kapstatus'_10 lpi_iv2_`var'_`kapstatus'_b_l"
				  fredensity_mv `set_a' , fname(`tabprefix'_pi_iv_`var'_`kapstatus') lims(1)  figadr("`figadr'") addmed
					
		}
		
		  
    }
	
	          

    cd "`sadr'"
    save `sname', replace 
	cd "`remember_address'"
	end 
