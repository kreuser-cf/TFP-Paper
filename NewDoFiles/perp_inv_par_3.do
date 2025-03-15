cap program drop perp_inv_par 
		program define  perp_inv_par 
		syntax , data(string)  ///
                capdeflator(string) /// 
                capitalvar(string) ///
                year(string) ///
                id(string) /// 
                depvar(string) ///
                sadr(string) ///
                [doadr(string)] ///
                fixedassets(string) ///
                indvar(string) ///
                instances(string) ///
                prefix(string) ///
				perpinvname(string)
                
		* addr is the directory address in which first level can be found 
		* firstlevel is a list of folders with same structure in addr
		* second level is same
		* adrfrom 
			* address to open excel files from
		* adrto
			* adress to close from 
		cap mkdir `sadr'
		* 1. Housekeeping
		* 1.1 Open data with only industry var 
        use `indvar' using `data' , clear
        bys `indvar': gen n = _n 
        keep if n==1 
        levelsof `indvar', local(indus)
        local ct = 0 
        foreach v in `indus' { 
            local ct = `ct'+1

        }

        * 1.2. Get number of operations per instance 
		* 1.2.1. Get ops per instance 
        local npi = int(`ct'/`instances')	  

     	* 1.2.2 Create instance main folder
		forv i = 1/`instances' { 
			local subfolder_`i' = ""
		}
		* 1.2.3. Create ordered list of operations, 

		/*foreach l1 of local indus { 
			 local set_`counter' "`l1'"
			 local counter_list = "`counter_list' set_`counter'"
			 local counter = `counter'+1
		}
        local counter = `counter'-1
        */
		* 1.2.4. Assign Counters to list 
		local vr = 1
		local inst = 1 
		forv i = 1/`instances' { 
			local catset_`i' = ""
		}
		while `=`inst'-1'<`ct' { 
			local looplev = 1 
			while `looplev'==1 {
				forv i = 1/`instances' { 
					forv j = 1/`npi' { 
						local addme : word `inst' of `indus'
						local catset_`i' = "`catset_`i'' `addme'"
						local inst = `inst'+1
                        di "`i'"
                        di "`catset_`i''"
					}	
				}
				local looplev = 2
			}
			else { 
				forv i = 1/`instances' { 
					local addme : word `inst' of `indus'
					local catset_`i' = "`catset_`i'' `addme'"
					local inst = `inst'+1
				}
			}		
		}
		forv i = 1/`instances' { 
            di "`catset_`i''"
			if ($pll_instance == `i' ) {
				clear
                di "inside instance `i'"
				di "`catset_`i''"
				foreach cat in `catset_`i'' {
					cap mkdir "`sadr'\\`indvar'_`cat'"			
                    cap mkdir"`sadr'\\`indvar'_`cat'\\log"
                    qui do "`doadr'\\`perpinvname'.do" 
                    di "`cat'"
                    cap noi perp_inv, data(`data') ///
                              importcond(if `indvar'=="`cat'") condvars(`indvar')  ///
                              capdeflator(`capdeflator') year(`year') id(`id') ///
                              depvar(`depvar') ///
                               capitalvar(`capitalvar') addvars(`indvar') ///
                               sadr("`sadr'\\`indvar'_`cat'") ///
                               logprefix(`prefix'_`indvar'_`cat') ///
                               tabprefix(`prefix'_`indvar'_`cat') ///
                               logadr("`sadr'\\`indvar'_`cat'\\log\\") ///
                               doadr("`doadr'") ///
                               sname(`prefix'_`indvar'_`cat') fixedassets(`fixedassets') 
				}
			}
		}
		
		end 	
		/* make sure this is latest version */		
      mata mata mlib index
      parallel setclusters 4, force 
      parallel, prog(perp_inv_par) :  perp_inv_par,   ///
	  			data(D:\Researchers\Workbenches\epadmin\brink_dane\Perpetual_Inventory\data\citirp5_v4.dta)  ///
                capdeflator(invdefl) /// 
                capitalvar(k_ppe) ///
                year(taxyear) ///
                id(taxrefno) /// 
                depvar(x_deprec) ///
                sadr(D:\Researchers\Workbenches\epadmin\brink_dane\Perpetual_Inventory\output) ///
                doadr(D:\Researchers\Workbenches\epadmin\brink_dane\Perpetual_Inventory\do-files\)   ///
                fixedassets(k_ppe k_faother) ///
                indvar(comp_prof_sic5_1d_last_str) ///
                instances(4) ///
                prefix(perp_inv) ///
				perpinvname("perpinv5")
