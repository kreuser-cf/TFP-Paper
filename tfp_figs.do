cap program drop tfp_figs 
	program define tfp_figs
	syntax , outputvar(string) salesvar(string) costvar(string) empvar(string) capvar(string) ///
			 omegapoly(string) ivar(string) predadr(string) indvar(string) sadr(string) ///
			 estadr(string) id(string) year(string) dataadr(string) ///
			 [addvars(string)] dofileadr(string)
            local dr  = "`predadr'"
			cd "`predadr'"
			cap mkdir "`sadr'\\"
			qui do "`dofileadr'\\fredenisty.do"
            cap log close
			log using "`sadr'\\tfp_figs", replace 
			foreach set in noiv { 
				foreach lim in blim  {
					clear  					
					local files : dir "`dr'" files "`set'*productivity*`lim'*.dta" 
                
					foreach file in `files' {
						di "`file'"
                        if regexm("`file'","precise")==0  {
							append using `file'
							cap gen source = "`file'" 
							cap replace source = "`file'" if source==""
						}
					}
					save "`estadr'\\prod_final_`set'_`lim'.dta", replace      
                    di "Merging in CITIRP5 Data"
					merge 1:1 `id' `year' using "`dataadr'", gen(prod_dat) keepusing(`indvar' `ivar' `outputvar' `salesvar' `costvar' `empvar' `capvar' `addvars')
					egen idused = group(`id')
					xtset idused `year'
					by idused: egen has_prod_dat = max(prod_dat)
					keep if has_prod_dat==3 
                    * KEeping Years
					keep if `year'>2009 & `year'<2018
					cap drop empl_type
                    gen empl_type  = 0 
                    replace empl_type = 1 if `empvar'<5 & `empvar'>0
					replace empl_type = 2 if `empvar'<10 & `empvar'>=5
					replace empl_type = 3 if `empvar'<20 & `empvar'>=10
					replace empl_type = 4 if `empvar'<50 & `empvar'>=20
					replace empl_type = 5 if `empvar'<100 & `empvar'>=50
					replace empl_type = 6 if `empvar'<250 & `empvar'>=100
					replace empl_type = 7 if `empvar'<1000 & `empvar'>=250
					replace empl_type = 8 if `empvar'>=1000 & `empvar'!=. 
					label def empl_type 1 "(0,5)" 2 "[5,10)" 3 "[10,20)" 4  "[20,50)" 5  "[50,100)" 6  "[100,250)"  7 "[250,1000)" 8 "[1000,max]"
					label val empl_type empl_type 
					label var empl_type "Firm Size"
					local tfp_prodest_acf  = "{Y} PRODEST"
					local phi_prodest_acf  = "{&Phi} PRODEST"
					local tfp_prodest_full  = "Y PRODEST"
					local phi_prodest_full  = "{&Phi} PRODEST"					
					local oy_ols_samp = "Y OLS"
					local op_ols_samp = "{&Phi} OLS"
					local oy_GMM = "Y Wooldridge (KN)"
					local oy_basic_bs  = "Y OLS Init."
					local oy_basic_pe_bs  = "Y OLS Init. SS"
					local oy_basica_bs = "Y ACF (p)"
					local oy_basic2a_bs = "Y ACF (p)"
					local oy_grid_bs  = "Y Grid"
					local op_basic_bs  = "{&Phi} ACF"

					local op_basic_pe_bs  = "{&Phi} ACF SS"
					local op_basica_bs = "{&Phi} ACF (p)"
					local op_basic2a_bs = "{&Phi} ACF (p)"
					local op_grid_bs  = "{&Phi} Grid"		
					local ind_10 = "10 Food"
					local ind_11 = "11 Beverages"
					local ind_12 = "12 Tobacco" 
					local ind_13 = "13 Textiles"
					local ind_14 = "14 Apparel"
					local ind_15 = "15 Leather and Footwear"
					local ind_16 = "16 Wood" 
					local ind_17 = "17 Paper" 
					local ind_18 = "18 Printing" 
					local ind_19 = "19 Petroleum" 
					local ind_20 = "20 Chemicals and Pharma"
					local ind_22 = "22 Rubber and Plastics"
					local ind_23 = "23 Non-Metallic Minerals" 
					local ind_24 = "24 Basic Metals" 
					local ind_25 = "25 Fabricated Metals" 
					local ind_26 = "26 Computer and Electronic" 
					local ind_27 = "27 Electrical" 
					local ind_28 = "28 Machinery Equipment N.E.C"
					local ind_29 = "29 Motor Vehicles" 
					local ind_30  = "30 Other Transport" 
					local ind_31 = "31 Furniture" 
					local ind_32 = "32 Other"					
					forv jjj = 2005/2021 { 
						label def yr `jjj' "`jjj'", modify
					}
					label val `year' yr
					rename tfp_prodest_full tfp_pdf 
                    rename tfp_prodest_acf tfp_pda 
                    rename oy_basic_pe_bs oy_bpe_bs 
                    rename op_basic_pe_bs op_bpe_bs 

					foreach tfpvar in op_basica_bs oy_basica_bs op_basic2a_bs   oy_basic2a_bs   tfp_pdf tfp_pda   ///
										oy_GMM ///
										oy_basic_bs oy_bpe_bs  ///
										op_basic_bs op_bpe_bs   {
						di "Working on `tfpvar'"
                        cap drop one 							
						qui gen one = 0 
						qui replace one = 1 if `tfpvar'!=. 
						cap drop __`outputvar'
						cap drop __`salesvar'
						qui gen __`outputvar' = `outputvar' if one==1 
						qui gen __`salesvar' = `salesvar' if one==1 
						cap drop mean_`tfpvar'
						cap drop dm_`tfpvar'
						cap drop mean_`tfpvar'_wi 
						cap drop dm_`tfpvar'_wi
						bys `indvar' `year': egen mean_`tfpvar' = mean(`tfpvar')   
						qui gen dm_`tfpvar' = `tfpvar'-mean_`tfpvar'
						by `indvar' : egen mean_`tfpvar'_wi = mean(`tfpvar')   						
						qui gen dm_`tfpvar'_wi = `tfpvar'-mean_`tfpvar'_wi 

						label var dm_`tfpvar' "``tfpvar''" 
						label var dm_`tfpvar'_wi "``tfpvar'' Industry" 
						cd "`sadr'"
						cap noisily fredensity dm_`tfpvar' , fname(dm_`tfpvar'_`set'_`lim'_`indvar'_`capvar'_`empvar'_`salesvar'_`ivar') cvars(empl_type) lims(1) title("Demeaned ``tfpvar'' by Firm Size")
						di "Tagging Stuff"
                        levelsof `year', local(yyy)
						levelsof `indvar', local(indus) 
						foreach pct in 95 99 999 {
                            cap drop tag_sales_`pct'
                            cap drop tag_va_`pct' 
							qui  gen tag_sales_`pct' = 0
							qui gen tag_va_`pct' = 0  
						}
						foreach vvv in `outputvar' `empvar' `capvar' { 
							cap drop __l`vvv' 
							gen __l`vvv' = ln(`vvv') if one==1 
						}
						cap drop tagrest 
						gen tagrest = 0 if one==1 
						di "Censoring Data"
                        foreach vv1 in `outputvar' `empvar' `capvar' { 
							foreach vv2 in  `empvar' `capvar' { 
								if "`vv1'"!="`vv2'" {
									cap drop r`vv1'`vv2' 
									qui gen r`vv1'`vv2' = __l`vv1'/__l`vv2' 
									foreach ind of local indus { 
										qui sum r`vv1'`vv2' if `indvar'=="`ind'" & one==1,d  
										if `r(N)'>0 {
											replace tagrest = 1 if r`vv1'`vv2'<`r(p1)' & one ==1  & `indvar'=="`ind'" 
											replace tagrest = 1 if r`vv1'`vv2'>`r(p99)' & r`vv1'`vv2'!=. & one ==1  & `indvar'=="`ind'" 
										}
									}
								}
							}
						}
						cap drop has_tag
						di "Tagging Data"

						bys `id': egen has_tag = max(tagrest)
						cap drop tag_sales_lim
						cap drop tag_va_lim 
						qui gen tag_sales_lim = 0 if has_tag==0 
						qui gen tag_va_lim = 0 if has_tag==0 
						cap drop tag_va_tlim
						cap drop tag_sales_tlim 
						foreach jj in 95 99 999 { 
							cap drop tag_va_t`jj' 
							cap drop tag_sales_t`jj' 
							gen tag_va_t`jj' = 0 
							gen tag_sales_t`jj' = 0 

						}
                        di "Tagging per year industry"
						foreach ind of local indus { 
							foreach yr of local yyy {
								qui sum `tfpvar' if `indvar'=="`ind'" & `year'==`year', d 
								if `r(N)'>0 { 
									qui replace tag_va_t95 = 1  if `tfpvar'>`r(p95)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_va_t95 = 1 if `tfpvar'<`r(p5)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_va_t99 = 1  if `tfpvar'>`r(p99)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_va_t99 = 1 if `tfpvar'<`r(p1)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_sales_t95 = 1  if `tfpvar'>`r(p95)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_sales_t95 = 1 if `tfpvar'<`r(p5)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_sales_t99 = 1  if `tfpvar'>`r(p99)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_sales_t99 = 1 if `tfpvar'<`r(p1)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_va_t999 = 1 if `tfpvar'<`r(p1)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									qui replace tag_sales_t999 = 1 if `tfpvar'<`r(p1)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									if `r(N)'> 1000 { 									
										qui sum `tfpvar' if `indvar'=="`ind'" & `year'==`year' & `tfpvar'>=`r(p99)', d
										qui replace tag_va_t999 = 1  if `tfpvar'>`r(p90)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
										qui replace tag_sales_t999 = 1 if `tfpvar'>`r(p90)' & `indvar'=="`ind'" & `year'==`yr' & `tfpvar'!=.
									}

								}

							}	
						}
                        di "More Tags"

						foreach jjj in 95 99 999 {
							foreach sh in va sales { 
								cap drop tag_`sh'_tl`jjj'
								bys `indvar': egen tag_`sh'_tl`jjj' = max(tag_`sh'_t`jjj')
							}

						}



						foreach ind of local indus { 
							*cap noisily fredensity dm_`tfpvar'_wi if `indvar'=="`ind'", fname(dm_`tfpvar'_wi_`ind'_`set'_`lim'_`indvar'_`capvar'_`empvar'_`salesvar'_`ivar') cvars(`year') lims(1)   title("Demeaned ``tfpvar'' by Year for `ind_`ind''")
							*cap noisily fredensity dm_`tfpvar'_wi if `indvar'=="`ind'", fname(dm_`tfpvar'_emp_`ind'_`set'_`lim'_`indvar'_`capvar'_`empvar'_`salesvar'_`ivar') cvars(empl_type) lims(1)  title("Demeaned ``tfpvar'' by Firm Size for `ind_`ind''")
							
							
							di "by industry `ind'"
							
							cap noisily sum __`outputvar' if `indvar'=="`ind'" &  one==1
                            if _rc==0 {
                                foreach yr of local yyy { 
                                    qui sum __`outputvar' if `indvar'=="`ind'" & `year'==`yr' & one==1, d
                                    if `r(N)'>0 {
                                        foreach pct in 95 99 {  
                                            local oside = 100-`pct'
                                            replace tag_sales_`pct' = 1 if __`outputvar'>`r(p`pct')' & __`outputvar'!=.  & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                            replace tag_sales_`pct' = 1 if __`outputvar'<`r(p`oside')' & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                        }
                                        replace tag_sales_999 = 1 if __`outputvar'<`r(p1)' & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                        if `r(N)'>1000 {
                                            qui sum __`outputvar' if `indvar'=="`ind'" & `year'==`yr' & __`outputvar'>`r(p99)'  & one==1, d
                                            replace tag_sales_999 = 1 if __`outputvar'>`r(p90)' &  `indvar'=="`ind'"  & __`outputvar'!=.  & `year'==`yr'  & one==1
                                        }
                                        else { 
                                            qui sum __`outputvar' if `indvar'=="`ind'" & `year'==`yr' & __`outputvar'>=`r(p99)'  & one==1, d
                                            replace tag_sales_999 = 1 if __`outputvar'>=`r(p99)' &  `indvar'=="`ind'" & __`outputvar'!=.  & `year'==`yr'  & one==1
                                        }
                                    }

                                    qui sum __`salesvar' if `indvar'=="`ind'" & `year'==`yr' & one==1 , d
                                    if `r(N)'>0 {
                                        foreach pct in 95 99 {  
                                            local oside = 100-`pct'
                                            replace tag_va_`pct' = 1 if __`salesvar'>`r(p`pct')' & __`salesvar'!=.  & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                            replace tag_va_`pct' = 1 if __`salesvar'<`r(p`oside')' & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                        }
                                        replace tag_va_999 = 1 if __`salesvar'<`r(p1)' & `year'==`yr' & one==1 &  `indvar'=="`ind'"
                                        if `r(N)'>1000 {
                                            qui sum __`salesvar' if `indvar'=="`ind'" & `year'==`yr' & __`salesvar'>`r(p99)'  & one==1 &  `indvar'=="`ind'" , d
                                            replace tag_va_999 = 1 if __`salesvar'>`r(p90)' & __`salesvar'!=.  & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                        }
                                        else { 
                                            qui sum __`salesvar' if `indvar'=="`ind'" & `year'==`yr' & __`salesvar'>=`r(p99)'  & one==1 &  `indvar'=="`ind'" , d
                                            replace tag_va_999 = 1 if __`salesvar'>=`r(p99)' & __`salesvar'!=.  & `year'==`yr'  & one==1 &  `indvar'=="`ind'"
                                        }
									
									}
                                }
							}							
						}

						foreach pct in 95 99 999 lim t95 t99 t999  /// 
										tl95 tl99 tl999 {
							tab tag_sales_`pct' tag_va_`pct' 
							foreach sh in sales va {
								cap drop one 							
								gen one = 0 
								replace one = 1 if `tfpvar'!=.  & tag_`sh'_`pct'==0
								cap drop ntfpvar 
								gen ntfpvar = `tfpvar' if `tfpvar'!=.  & tag_`sh'_`pct'==0
								cap drop __`outputvar'
								cap drop __`salesvar'
								gen __`outputvar' = `outputvar' if one==1 & tag_`sh'_`pct'==0
								gen __`salesvar' = `salesvar' if one==1 & tag_`sh'_`pct'==0
								cap drop tot_N
								bys `indvar' `year': egen tot_N = total(one)
								cap drop omega
								gen omega = exp(ntfpvar)
								cap drop mean_omega
								bys `indvar' `year': egen mean_omega = mean(omega)

								cap drop tot_sales	
								bys `indvar' `year': egen tot_sales = total(__`outputvar')

								cap drop tot_va	
								bys `indvar' `year': egen tot_va = total(__`salesvar')
								cap drop share_sales 
								gen share_sales = __`outputvar'/tot_sales   
								cap drop share_va 
								gen share_va = __`salesvar'/tot_va  						
								cap drop mean_share_`sh' 
								bys `indvar' `year': egen mean_share_`sh' = mean(share_`sh')   
                                cap drop max_share_`sh' 
                                cap drop min_share_`sh'
								bys `indvar' `year': egen max_share_`sh' = max(share_`sh')   
								bys `indvar' `year': egen min_share_`sh' = min(share_`sh')   

								cap drop share_omega_`sh' 
								gen share_omega_`sh' = share_`sh'*omega 
								cap drop p_t_`sh'
								bys `indvar' `year': egen p_t_`sh' = total(share_omega_`sh')	

								cap drop p_ta_`sh'
								gen p_ta_`sh' = p_t_`sh' if `year'==2010
								cap drop index_p_ta_`sh'
								by `indvar' : egen index_p_ta_`sh' = max(p_ta_`sh')
								cap drop pv_`sh' 
								gen pv_`sh' = p_t_`sh'/index_p_ta_`sh'	
								gen pv_a_`sh' = mean_omega/index_p_ta_`sh'
								cap drop pv_d_`sh'
								gen pv_d_`sh' =pv_`sh'-pv_a_`sh'
								rename pv_`sh' `tfpvar'_pv_`sh'_`pct'
								rename pv_a_`sh' `tfpvar'_pv_a_`sh'_`pct'
								rename pv_d_`sh' `tfpvar'_pv_d_`sh'_`pct'
                                rename tot_N N_`tfpvar'_`sh'_`pct'
                                rename tot_`sh' `tfpvar'_tot_`sh'_`pct'
                                rename mean_share_`sh' `tfpvar'_as_`sh'_`pct'
                                rename min_share_`sh' `tfpvar'_mns_`sh'_`pct'
                                rename max_share_`sh' `tfpvar'_mxs_`sh'_`pct'

								label var `tfpvar'_pv_`sh'_`pct' "``tfpvar'' `sh' `pct'"
							}
						}
					}
				cap drop counter 
				bys `indvar' `year': gen counter = _n
				edit `indvar' `year' *_p* N_* if counter==1
				keep if counter==1 
				keep  `indvar' `year' *_pv* N_* *_tot_* *_as_* *_mns_* *_mxs_*
				keep if `year'>=2010
				keep if `year'<=2017
				save "`sadr'\\prodindex_withlims_`set'_`lim'_`indvar'_`capvar'_`empvar'_`salesvar'_`ivar'.dta", replace 											
				}		
			}
        cap log close
	
	end 