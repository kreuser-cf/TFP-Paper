		cap program drop prod_bat_par
		program define  prod_bat_par
		syntax  [, instances(integer 8) ///
                   indvar(string) ///
                   outputvar(string) ///
                   salesvar(string) /// 
                   costvar(string) ///                   
                   capvar(string) ///
                   empvar(string) ///
                   id(string) ///
                   year(string) ///
                   sadr(string) ///
                   prefix(string) ///
                   data(string) ///
                   internalprogadrs(string) ///
                   intvar(string) ///
                   predkeepadr(string) /// 
                   omegapoly(string) ///
                   internalsum(string) ///
			]
			
			
		* 1. Housekeeping
        
        cap mkdir "`sadr'"
        cap mkdir "`predkeepadr'"

        cd "`sadr'"
        * 1.1. Get indvars
        use `indvar' using "`data'" , clear
        di "Creating indvar"
        * 1.1.1. Order industries from large to small
        bys `indvar': gen n = _n 
        bys `indvar': gen N = _N 
        keep if n==1 
        gen min_N = -N
        count 
        local ct = `r(N)' 
        
        local indus = "" 
        local firms = ""
        * 1.1.2. Get some numbers to confirm
        forv i = 1/`ct' { 
            local a = `indvar' in `i'
            local b = N in `i'
            local indus = "`indus' `a'"
            local firms = "`firms' `b'"
        }

        local ct = `ct'+1
        
        /*levelsof `indvar', local(indus)
        local ct = 0 
        foreach v of local indus { 
            local ct = `ct'+1

        }
        */
        * 1.2. Get number of operations per instance 
		* 1.2.1. Get ops per instance 
        local npi = int(`ct'/`instances')	  

     	* 1.2.2 Create instance main folder
		forv i = 1/`instances' { 
			local subfolder_`i' = ""
		}
        * 1.2.3. Assign Industries to instances
        * 1.2.3.1. Initilise
        local vr = 1
		local inst = 1 
		forv i = 1/`instances' { 
			local catset_`i' = ""
            local firmset_`i' = ""
		}
        * 1.2.3.2. Now start assigning, first part assigns the biggest industries first
		while `=`inst'-1'<`ct' { 
			local looplev = 1 
			while `looplev'==1 {
				forv i = 1/`instances' { 
					forv j = 1/1 { 
						local addme : word `inst' of `indus'
                        local firme : word `inst' of `firms'
						local catset_`i' = "`catset_`i'' `addme'"
                        local firmset_`i' = "`firmset_`i'' `firme'"
						local inst = `inst'+1

					}	
				}
				local looplev = 2
			}
            * 1.2.3.3. Now assign remaining industries to instances in snake fashion
			else { 
				forv i = `instances'(-1)1 { 
					local addme : word `inst' of `indus'
                    local firme : word `inst' of `firms'                    
					local catset_`i' = "`catset_`i'' `addme'"
                    local firmset_`i' = "`firmset_`i'' `firme'"
					local inst = `inst'+1
				}
				forv i = 1/`instances' { 
					local addme : word `inst' of `indus'
                    local firme : word `inst' of `firms'                    
					local catset_`i' = "`catset_`i'' `addme'"
                    local firmset_`i' = "`firmset_`i'' `firme'"
					local inst = `inst'+1
				}
                
			}		
		}
        /*
        clear 
        set obs 1000
      	forv i = 1/`instances' { 
            di "`i'"
            gen cat_`i' = "" 
            gen N_`i' = . 
            local counter = 1 
            foreach vs of local catset_`i' { 
                replace cat_`i' = "`vs'" in `counter' 
                local counter = `counter'+1  
            }
            local counter = 1 
            foreach catset of local firmset_`i' { 
                replace N_`i' = `catset' in `counter' 
                local counter = `counter'+1  
            }
        }
        */ 
		
        forv inst = 1/`instances' { 
            di "`catset_`inst''"
			if ($pll_instance == `inst' ) {
				clear
                cap log close 
                forv errlog=1/1 {
                    qui log using "`sadr'\\error_ests_`inst'.txt", replace t
                    di "Industry, obs, sales, cap, lab, cost, iv, ivreg, error_code, reg_type, lim" 
                    qui log close 
                }                
                di "inside instance `inst'"
				di "`catset_`inst''"
				foreach cat in `catset_`inst'' {
                    cap log close                 
                    log using "`sadr'\\log_`cat'" , replace
                    di "Running internal program"
                    qui do "`internalprogadrs'" 
                    qui do "`internalsum'"
                    di "Internalprogram done"
                    * all variables already have to be real 
                    use `id' `year' `outputvar' `salesvar' `empvar' `costvar' `intvar' `capvar' `indvar' if `indvar'=="`cat'" using "`data'", clear 
                    di "Data Opened for `cat'" 
                    gen y = ln(`salesvar')
                    gen m = ln(`costvar') 
                    gen k = ln(`capvar')    
                    gen l = ln(`empvar')
                    gen o = ln(`outputvar')
                    gen i = ln(`intvar') 


                    egen idused = group(`id')
                    xtset idused `year'
                    * i should not to be included here
					internal_sum_stats , outputvar(o) salesvar(y) capitalvar(k) costvar(m) empvar(l) intvar(i) ///
                    year(`year') id(`id') minobs(10) ///
                    sadr("`sadr'") ///
                    sname(sumstats_`capvar'_`empvar'_`ivar'_`cat') ///
                    indvar(`indvar') 
					
                    keep if y!=. & k!=. & l!=. & m!=. 


                    preserve 
                        cap log close
                        log using "`sadr'\\log_`cat'" , append                                 

                        di "__________________________________________________________________________"
                        di " PROD BATTERY LIMITS II "
                        di "__________________________________________________________________________"                    
                        sum `year' 
                        local bigobs = "`r(N)'"
                        if `bigobs'>100 {
                            tokenize y k l  
                            xtset idused `year'
                            gen tagmeout = 0 
                            forv i = 1/3 { 
                                forv j = `=`i'+1'/3 {
                                    if `i'!=`j' { 
                                        cap drop rat_``i''_``j'' 
                                        gen rat_``i''_``j'' = ``i''/``j''
                                        forv yr = 2009/2017 {
                                            sum rat_``i''_``j'' if `year'==`yr', d 
                                            if `r(N)'>0 { 
                                                replace tagmeout = 1 if rat_``i''_``j''<`r(p1)' & `year'==`yr'
                                                replace tagmeout = 1 if rat_``i''_``j''>`r(p99)' & rat_``i''_``j''!=. & `year'==`yr'
                                            }
                                        }
                                    }
                                }
                            }
                            tabout `year' tagmeout using  "`sadr'\\noiv_`salesvar'_`capvar'_`empvar'_`costvar'_`intvar'_`cat'_blim.txt", replace
                            by idused: egen tmo = max(tagmeout)
                            tabout `year' tmo using  "`sadr'\\noiv_`salesvar'_`capvar'_`empvar'_`costvar'_`intvar'_`cat'_blim_tmo.txt", replace
                            keep if tmo==0
                            internal_sum_stats , outputvar(o) salesvar(y) capitalvar(k) costvar(m) empvar(l) intvar(i) ///
                                                        year(`year') id(`id') minobs(10) ///
                                                        sadr("`sadr'") ///
                                                        sname(sumstats_`capvar'_`empvar'_`ivar'_`cat'_blim) ///
                                                        indvar(`indvar')                             
                            local stats_output=""
                            sum `year'
                            local littleobs = `r(N)'
                            if `r(N)'>100 {
                                cap noisily prod_battery, opoly(`omegapoly') phipoly(3)   yvar(y) kvar(k) lvar(l) ///
                                            proxyvar(m)  ///
                                            predkeepadr("`predkeepadr'\\`cat'") ///
                                            phikeepname("noiv_phi_blim_`cat'") ///
                                            prodestkeepname("noiv_prodest_blim_`cat'") ///
                                            boots(1000) idvar(`id')
                                if _rc==0 { 
                                    mat noiv_basic_`omegapoly'pol_blim = e(estmat)
                                    local noiv_basic_`omegapoly'pol_blim_a: rownames e(estmat)
                                    local stats_output = "`stats_output' noiv_basic_`omegapoly'pol_blim"
                                    get_productivity ,  phidat("`predkeepadr'\\`cat'\\noiv_phi_blim_`cat'") ///
                                                        prodestadr("`predkeepadr'\\`cat'")  ///
                                                        prodestloop("`e(prodest_tfp_list)'")  ///
                                                        idvar(`id') year(`year') ///
                                                        sadname("`predkeepadr'\\noiv_productivity_blim_`cat'.dta") ///
                                                        prodestkeepname("noiv_prodest_blim_`cat'") 
                                }
                                else { 
                                    cap log close

                                    local codetext = _rc
                                    qui log using "`sadr'\\error_ests_`inst'.txt", append t
                                    di "`cat', `littleobs', `salesvar', `capvar', `empvar', `costvar', `intvar', noiv, `codetext', standard, blim"     
                                    qui log close                            
                                    log using "`sadr'\\log_`cat'" , append                                 

                                }
                                
                                /*
                                di "__________________________________________________________________________"
                                di " PROD BATTERY LIMITS PRECISE"
                                di "__________________________________________________________________________"                    
                                di "stats_out nol: `stats_out'"

                                cap noisily prod_battery, opoly(`omegapoly') phipoly(3)   yvar(y) kvar(k) lvar(l) ///
                                            proxyvar(m)  ///
                                            predkeepadr("`predkeepadr'\\`cat'") ///
                                            phikeepname("noiv_phi_blim_precise_`cat'") ///
                                            prodestkeepname("noiv_prodest_blim_precise_`cat'") ///
                                            boots(100) idvar(`id') ///
                                            precise
                                if _rc==0 { 
                                    mat noiv_basic_`omegapoly'pol_blim_precise = e(estmat)
                                    local noiv_basic_`omegapoly'pol_blim_precise_a: rownames e(estmat)
                                    local stats_output = "`stats_output' noiv_basic_`omegapoly'pol_blim_precise"
                                    get_productivity ,  phidat("`predkeepadr'\\`cat'\\noiv_phi_blim_precise_`cat'") ///
                                                        prodestadr("`predkeepadr'\\`cat'")  ///
                                                        prodestloop("`e(prodest_tfp_list)'")  ///
                                                        idvar(`id') year(`year') ///
                                                        sadname("`predkeepadr'\\noiv_productivity_blim_precise_`cat'.dta") ///
                                                        prodestkeepname("noiv_prodest_blim_precise_`cat'") 
                                }
                                else { 
                                    local codetext = _rc
                                    qui log using "`sadr'\\error_ests_`inst'.txt", append t
                                    di "`cat', `littleobs', `salesvar', `capvar', `empvar', `costvar', `intvar', noiv, `codetext', precise, blim"     
                                    qui log close                            
                                }
                                */
                                foreach messy in `stats_output' { 
                                    clear 
                                    svmat `messy' , n(col)
                                    gen est ="" 
                                    local c = _N 
                                    local c= 1 
                                    foreach var of local `messy'_a { 
                                        replace est = "`var'" in `c'
                                        local c= `c'+1
                                    }
                                    gen ind = "`cat'"
                                    gen sales = "`salesvar'"
                                    gen capital = "`capvar'"
                                    gen emp = "`empvar'"
                                    gen costvar = "`costvar'"
                                    cap gen intvar = "`intvar'"
                                    gen est_type = "`messy'"
                                    save "`sadr'\\`prefix'_`messy'_`salesvar'_`capvar'_`empvar'_`costvar'_`intvar'_`cat'.dta", replace
                                }
                            }
                            else { 
                                cap log close 
                                qui log using "`sadr'\\error_ests_`inst'.txt", append t
                                di "`cat', `littleobs', `salesvar', `capvar', `empvar', `costvar', `intvar', noiv,obs_lim, standard, blim" 
                                di "`cat', `littleobs', `salesvar', `capvar', `empvar', `costvar', `intvar', noiv, obs_lim, precise, blim" 
                                qui log close 
                            }                                                    
                        }
                        else { 
                            cap log close 
                            qui log using "`sadr'\\error_ests_`inst'.txt", append t
                            di "`cat', `bigobs', `salesvar', `capvar', `empvar', `costvar', `intvar', noiv,obs_lim, standard, blim" 
                            di "`cat', `bigobs', `salesvar', `capvar', `empvar', `costvar', `intvar', noiv, obs_lim, precise, blim" 
                            qui log close 
                        }                        

                    restore 
                 
                }                   
			}
		}
    
	end


    * make sure above var is string
    parallel setclusters 6, force
    save "D:\\Researchers\\Workbenches\\epadmin\\brink_dane\\Productivity\\data\\manuf_qfs_v4.dta", replace 
    foreach letter in A  { 
        foreach intvar in  real_int_lag   {
            foreach empvar in kerr_w_b kerr_dw_b {
                foreach indvar in isic4_str comp_prof_sic5_3d_s {
                    foreach cvar in pi_iv_fixed_pd_10  pi_iv_k_ppe_pd_10 pi_iv_fixed_p_i_l k_fixed pi_iv_k_ppe_p_i_l     real_kppe {  
                        foreach poly in 3  {
                            local main_adr = "D:\\Researchers\\Workbenches\\epadmin\\brink_dane\\Productivity\\"
                            local foldername = "output_p`poly'_`indvar'_d19"
                            cap mkdir "`main_adr'"
                            cap mkdir "`main_adr'\\`foldername'\\"
                            cap mkdir "`main_adr'\\`foldername'\\`cvar'\\"
                            cap mkdir "`main_adr'\\`foldername'\\`cvar'\\`empvar'"
                            cap mkdir "`main_adr'\\`foldername'\\`cvar'\\`empvar'\\va_`letter'"
                            cap mkdir "`main_adr'\\`foldername'\\`cvar'\\`empvar'\\va_`letter'\\`intvar'"
                            local sad = "`main_adr'\\`foldername'\\`cvar'\\`empvar'\\va_`letter'\\`intvar'"
                            cap mkdir "`main_adr'\\`foldername'_preds\\"
                            cap mkdir "`main_adr'\\`foldername'_preds\\`cvar'\\"
                            cap mkdir "`main_adr'\\`foldername'_preds\\`cvar'\\`empvar'"
                            cap mkdir "`main_adr'\\`foldername'_preds\\`cvar'\\`empvar'\\va_`letter'"                
                            cap mkdir "`main_adr'\\`foldername'_preds\\`cvar'\\`empvar'\\va_`letter'\\`intvar'"       
                            local predadr = "`main_adr'\\`foldername'_preds\\`cvar'\\`empvar'\\va_`letter'\\`intvar'"                                      
                            * This address will store the log files and addresses
                            cap mkdir "`sad'\\logfiles\\"
                            cd  "`sad'\\logfiles\\"
                            parallel, prog(prod_bat_par): prod_bat_par, instances(6) ///
                                    indvar(`indvar') ///
                                    outputvar(real_sales) ///
                                    salesvar(va_`letter') /// 
                                    costvar(real_gcos_`letter') ///
                                    capvar(`cvar') ///
                                    empvar(`empvar') ///
                                    id(taxrefno) ///
                                    year(taxyear) ///
                                    sadr("`sad'") ///
                                    prefix(manuf) ///
                                    data("D:\\Researchers\\Workbenches\\epadmin\\brink_dane\\Productivity\\data\\manuf_qfs_v4.dta") ///
                                    internalprogadrs("D:\\Researchers\\Workbenches\\epadmin\\brink_dane\\Productivity\\do-files\\prod_bat_only_19.do") ///
                                    internalsum("D:\\Researchers\\Workbenches\\epadmin\\brink_dane\\Productivity\\do-files\\internal_sum.do") ///
                                    intvar(`intvar')  ///
                                    omegapoly(`poly') ///
                                    predkeepadr("`predadr'") 
                        }  
                    }
                }
            }
        }
    } 
