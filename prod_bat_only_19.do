
cap program drop gmm_grid_bs
program  define gmm_grid_bs, eclass 
	syntax varlist [, polyset(integer 1) bl_init(real .5) bk_init(real .5) PRECise]  
        tokenize `varlist' 
        local wc = wordcount("`varlist'")

        if "`polyset'"=="" | "`polyset'"=="1" {
			local OMEGA_LAG_MATRIX = "(CONST,OMEGA_lag)"
			mata: g_b = (1,1)
		}
		else { 
			local OMEGA_LAG_MATRIX = "(CONST,OMEGA_lag"
			local g_b = "(1,1"
			forv i =  2/`polyset' { 
				local OMEGA_LAG_MATRIX = "`OMEGA_LAG_MATRIX',OMEGA_lag`i'"
				local g_b = "`g_b',1"
			}
				local OMEGA_LAG_MATRIX = "`OMEGA_LAG_MATRIX')"
				local g_b = "`g_b')"
				mata: g_b = `g_b'
				
			di "`OMEGA_LAG_MATRIX'"
		}
	
			* 2.7.1. Prepare coefs no IV
        if `wc'==3 {
			* 2.7.1. Prepar+e coefs no IV
			mata: PHI=st_data(.,("`1'"))
			mata: PHI_LAG=st_data(.,("`1'_lag"))
			mata: X=st_data(.,("`2'","`3'"))
			mata: X_lag=st_data(.,("`2'_lag","`3'_lag"))
			mata: Z=st_data(.,("`2'_lag","`3'"))
			mata: W=invsym(Z'Z)/rows(Z)
			if "`precise'"!="" { 
				mata: Z=st_data(.,("`2'","`2'_lag","`3'"))
				mata: W=invsym(Z'Z)/rows(Z)			
			}
        } 


			mata: S=optimize_init()
			mata: optimize_init_evaluator(S, &GMM_EST_`polyset'())
			mata: optimize_init_evaluatortype(S,"d0")
			mata: optimize_init_technique(S, "nm")
			mata: optimize_init_which(S,"min")
			mata: optimize_init_params(S,(`bl_init',`bk_init'))
			mata: optimize_init_argument(S, 1, PHI)
			mata: optimize_init_argument(S, 2, PHI_LAG)
			mata: optimize_init_argument(S, 3, Z)
			mata: optimize_init_argument(S, 4, X)
			mata: optimize_init_argument(S, 5, X_lag)
			mata: optimize_init_argument(S, 6, W)
			mata: optimize_init_argument(S, 7, g_b)
			* This is for bootrap to look around minima:
			* 2.7.3. Start with big steps and take smaller steps
			mata: optimize_init_nmsimplexdeltas(S, .00001)
			qui mata: p=optimize(S)		
			qui mata: optimize_init_params(S,p)			
			qui mata: p=optimize(S)
			
					
			mata: st_matrix("beta_acf_va",p)
			mata: st_matrix("g_b",g_b)
			
			mata: result = optimize_result_value(S) 
			mata: obs = rows(PHI)
			mata: st_matrix("result",(result,obs))
			local bl_est = beta_acf_va[1,1]
			local bk_est = beta_acf_va[1,2]
			forv i = 1/`=`polyset'+1' { 
				local gb`i'= g_b[`i',1]
			}
			local min_crit = result[1,1]
			local obs  = result[1,2]
			ereturn local beta_l = `bl_est'
			ereturn local beta_k = `bk_est'
			ereturn local critval = `min_crit'
			ereturn local obs= `obs'
			local gbname = ""
            forv i = 1/`=`polyset'+1' { 
				ereturn local g_b`i'= `gb`i''
                local gbname = "`gbname' gb_`i'"
			}	
            
            mata: st_matrix("output",(`bl_est', `bk_est',g_b',result[1,1]))
            mat colnames output = beta_l beta_k `gbname' crit
            ereturn post output	
    end		
cap program drop reset_mata
    program define reset_mata 
    syntax varlist [, precise]
    xtset `1' `2' 
    mata: PHI=st_data(.,("__PHI"))
    mata: PHI_LAG=st_data(.,("__PHI_lag"))
    mata: X=st_data(.,("__LAB","__CAP"))
    mata: X_lag=st_data(.,("__LAB_lag","__CAP_lag"))
    mata: Z=st_data(.,("__LAB_lag","__CAP"))
    mata: W=invsym(Z'Z)/rows(Z)	   
    if "`precise'"!="" {
        mata: Z=st_data(.,("__LAB","__LAB_lag","__CAP"))
    }
    end    	
cap program drop gmm_grid_bsa
program  define gmm_grid_bsa, eclass 
	syntax varlist [, polyset(integer 1) bl_init(real .5) bk_init(real .5) PRECise ///
					  gb1_init(real 0.1) ///
					  gb2_init(real 0.1) ///
					  gb3_init(real 0.1) ///
					  gb4_init(real 0.1) ///
					  gb5_init(real 0.1) ///
					  gb6_init(real 0.1) ///
					]  
        tokenize `varlist' 
        local wc = wordcount("`varlist'")

        if "`polyset'"=="" | "`polyset'"=="1" {
			local OMEGA_LAG_MATRIX = "(CONST,OMEGA_lag)"
			mata: g_b = (1,1)
		}
		else { 
			local OMEGA_LAG_MATRIX = "(CONST,OMEGA_lag"
			local g_b = "(1,1"
			forv i =  2/`polyset' { 
				local OMEGA_LAG_MATRIX = "`OMEGA_LAG_MATRIX',OMEGA_lag`i'"
				local g_b = "`g_b',1"
			}
				local OMEGA_LAG_MATRIX = "`OMEGA_LAG_MATRIX')"
				local g_b = "`g_b')"
				mata: g_b = `g_b'
				
			di "`OMEGA_LAG_MATRIX'"
		}
			* 2.7.1. Prepare coefs no IV
        if `wc'==3 {
			* 2.7.1. Prepar+e coefs no IV
			mata: PHI=st_data(.,("`1'"))
			mata: PHI_LAG=st_data(.,("`1'_lag"))
			mata: X=st_data(.,("`2'","`3'"))
			mata: X_lag=st_data(.,("`2'_lag","`3'_lag"))
			mata: Z=st_data(.,("`2'_lag","`3'"))
			mata: W=invsym(Z'Z)/rows(Z)
			if "`precise'"!="" { 
				mata: Z=st_data(.,("`2'","`2'_lag","`3'"))
				mata: W=invsym(Z'Z)/rows(Z)			
			}
        } 
 
		local init_list = "`bl_init', `bk_init', `gb1_init', `gb2_init'"
		if `polyset'>1 {
			forv i =3/`=`polyset'+1' { 
				local init_list = "`init_list', `gb`i'_init'"
			}
		}
			di "`init_list'"
			mata: S=optimize_init()
			mata: optimize_init_evaluator(S, &GMM_EST_`polyset'a())
			mata: optimize_init_evaluatortype(S,"d0")
			mata: optimize_init_technique(S, "nm")
			mata: optimize_init_which(S,"min")
			mata: optimize_init_params(S,(`init_list'))
			mata: optimize_init_argument(S, 1, PHI)
			mata: optimize_init_argument(S, 2, PHI_LAG)
			mata: optimize_init_argument(S, 3, Z)
			mata: optimize_init_argument(S, 4, X)
			mata: optimize_init_argument(S, 5, X_lag)
			mata: optimize_init_argument(S, 6, W)
			* This is for bootrap to look around minima:
			* 2.7.3. Start with big steps and take smaller steps
			mata: optimize_init_nmsimplexdeltas(S, .01)
			qui mata: p=optimize(S)		
			qui mata: optimize_init_params(S,p)			
			qui mata: p=optimize(S)
			mata: st_matrix("beta_acf_va",p)
			mat list beta_acf_va
			mata: result = optimize_result_value(S) 
			mata: obs = rows(PHI)
			mata: st_matrix("result",(result,obs))
			local bl_est = beta_acf_va[1,1]
			local bk_est = beta_acf_va[1,2]
			forv i = 1/`=`polyset'+1' { 
				di "GB `i'"
				local gb`i'= beta_acf_va[1,`=`i'+2']
				di `gb`i''
			}
			local gbcoefs = "`gb1', `gb2'"
			if `polyset'>1 {
				forv i =3/`=`polyset'+1' { 
					local gbcoefs = "`gbcoefs', `gb`i''"
				}
			}			
			*di "`gbcoefs'"
			local min_crit = result[1,1]
			local obs  = result[1,2]
			*di "MIN DONE"
			ereturn local beta_l = `bl_est'
			ereturn local beta_k = `bk_est'
			ereturn local critval = `min_crit'
			ereturn local obs= `obs'
			local gbname = ""
            forv i = 1/`=`polyset'+1' { 
				ereturn local g_b`i'= `gb`i''
                local gbname = "`gbname' gb_`i'"
			}	
            *di "`gbname'"
            mata: st_matrix("output",(`bl_est', `bk_est', `gbcoefs', `min_crit'))
            mat colnames output = beta_l beta_k `gbname' crit
            ereturn post output	
    end			
cap program drop gmm_basic 
program  define gmm_basic, eclass 
	args polyset bl_init bk_init
			mata: S=optimize_init()
			mata: optimize_init_evaluator(S, &GMM_EST_`polyset'())
			mata: optimize_init_evaluatortype(S,"d0")
			mata: optimize_init_technique(S, "nm")
			mata: optimize_init_which(S,"min")
			mata: optimize_init_params(S,(`bl_init',`bk_init'))
			mata: optimize_init_argument(S, 1, PHI)
			mata: optimize_init_argument(S, 2, PHI_LAG)
			mata: optimize_init_argument(S, 3, Z)
			mata: optimize_init_argument(S, 4, X)
			mata: optimize_init_argument(S, 5, X_lag)
			mata: optimize_init_argument(S, 6, W)
			mata: optimize_init_argument(S, 7, g_b)
			* resetting tolerance to default

			* 2.7.3. Start with big steps and take smaller steps
			foreach stepsize in  .25 .1 .05 .01 .001 .001 .0001 { 
				mata: optimize_init_nmsimplexdeltas(S, `stepsize')
				qui mata: p=optimize(S)		
				qui mata: optimize_init_params(S,p)
				* add a bit of noise a
				qui mata: p=optimize(S)
				if `stepsize'>.1 { 
					qui mata: optimize_init_params(S,(p[1]+rnormal(1,1,0,`=`stepsize'*.1'),p[2]+rnormal(1,1,0,`=`stepsize'*.1')))
					qui mata: p=optimize(S)
				}
				else { 
					qui mata: optimize_init_params(S,p)
					qui mata: p=optimize(S)
				}
				qui mata: optimize_init_params(S,p)
				qui mata: p=optimize(S)
				
			}
					
			mata: st_matrix("beta_acf_va",p)
			mata: st_matrix("g_b",g_b)
			
			mata: result = optimize_result_value(S) 
			mata: obs = rows(PHI)
			mata: st_matrix("result",(result,obs))
			local bl_est = beta_acf_va[1,1]
			local bk_est = beta_acf_va[1,2]
			forv i = 1/`=`polyset'+1' { 
				local gb`i'= g_b[`i',1]
			}
			local min_crit = result[1,1]
			local obs  = result[1,2]
			ereturn local beta_l = `bl_est'
			ereturn local beta_k = `bk_est'
			ereturn local critval = `min_crit'
			ereturn local obs= `obs'
			forv i = 1/`=`polyset'+1' { 
				ereturn local g_b`i'= `gb`i''
			}		
	end		


cap program drop gmm_basica 
program  define gmm_basica, eclass 
	args polyset bl_init bk_init gb0_init gb1_init 
			local gbinits = "`gb0_init', `gb1_init'"
			if `polyset'>1 {
				forv i = 2/`polyset' { 
					local gbinits = "`gbinits', 0"
				}
			}

			mata: S=optimize_init()
			mata: optimize_init_evaluator(S, &GMM_EST_`polyset'a())
			mata: optimize_init_evaluatortype(S,"d0")
			mata: optimize_init_technique(S, "nm")
			mata: optimize_init_which(S,"min")
			mata: optimize_init_params(S,(`bl_init',`bk_init', `gbinits'))
			mata: optimize_init_argument(S, 1, PHI)
			mata: optimize_init_argument(S, 2, PHI_LAG)
			mata: optimize_init_argument(S, 3, Z)
			mata: optimize_init_argument(S, 4, X)
			mata: optimize_init_argument(S, 5, X_lag)
			mata: optimize_init_argument(S, 6, W)
			* resetting tolerance to default

			* 2.7.3. Start with big steps and take smaller steps
			/*foreach stepsize in   .1 .05 .01 .001 .001 .0001 { 
				qui mata: optimize_init_nmsimplexdeltas(S, `stepsize')
				qui mata: p=optimize(S)		
				qui mata: optimize_init_params(S,p)
				qui mata: p 
                */
	        foreach stepsize in .1 .05 .01 .001 .001 .0001 { 
				qui mata: optimize_init_nmsimplexdeltas(S, `stepsize')
				qui mata: p=optimize(S)		
                qui mata: optimize_init_params(S,p)

				* add a bit of noise to ensure we don't get stuck
				qui mata: p=optimize(S)
				if `stepsize'>.1 { 
                    di "noise"
                    forv noise = 1/6 { 
                        local noise_`noise' = rnormal(0,`stepsize'*.01)
                        if `noise'>2 {
                            local noise_`noise' = rnormal(0,`stepsize'*.01)
                        }
                    }
                    
                    forv i =1/6 {
                        qui mata: p[`i'] = p[`i']+`noise_`i''
                    } 
					qui mata: optimize_init_params(S,p)
					qui mata: p=optimize(S)
				}
				else { 
					qui mata: optimize_init_params(S,p)
					qui mata: p=optimize(S)
				}
            }

			qui mata: optimize_init_params(S,p)
			qui mata: p=optimize(S)	    
			qui mata: optimize_init_params(S,p)
			qui mata: p=optimize(S)	    

			mata: st_matrix("beta_acf_va",p)			
			mata: result = optimize_result_value(S) 
			mata: obs = rows(PHI)
			mata: st_matrix("result",(result,obs))
			local bl_est = beta_acf_va[1,1]
			local bk_est = beta_acf_va[1,2]
			forv i = 1/`=`polyset'+1' { 
				local gb`i'= beta_acf_va[1,`=`i'+2']
			}
			local min_crit = result[1,1]
			local obs  = result[1,2]
			ereturn local beta_l = `bl_est'
			ereturn local beta_k = `bk_est'
			ereturn local critval = `min_crit'
			ereturn local obs= `obs'
			forv i = 1/`=`polyset'+1' { 
				ereturn local g_b`i'= `gb`i''
			}		
	end		



cap program drop gmm_basic_pe 
program  define gmm_basic_pe, eclass 
	args polyset bl_init bk_init
			mata: S=optimize_init()
			mata: optimize_init_evaluator(S, &GMM_EST_`polyset'())
			mata: optimize_init_evaluatortype(S,"d0")
			mata: optimize_init_technique(S, "nm")
			mata: optimize_init_which(S,"min")
			mata: optimize_init_params(S,(`bl_init',`bk_init'))
			mata: optimize_init_argument(S, 1, PHI)
			mata: optimize_init_argument(S, 2, PHI_LAG)
			mata: optimize_init_argument(S, 3, Z)
			mata: optimize_init_argument(S, 4, X)
			mata: optimize_init_argument(S, 5, X_lag)
			mata: optimize_init_argument(S, 6, W)
			mata: optimize_init_argument(S, 7, g_b)
			mata: optimize_init_nmsimplexdeltas(S, `stepsize')
			* resetting tolerance to default

			mata: optimize_init_nmsimplexdeltas(S, .00001)
			qui mata: p=optimize(S)
			qui mata: optimize_init_params(S,p)
			qui mata: p=optimize(S)
			qui mata: optimize_init_params(S,p)
			qui mata: p=optimize(S)
			qui mata: optimize_init_params(S,p)
			qui mata: p=optimize(S)
			* 2.7.3. Start with big steps and take smaller steps

					
			mata: st_matrix("beta_acf_va",p)
			mata: st_matrix("g_b",g_b)
			
			mata: result = optimize_result_value(S) 
			mata: obs = rows(PHI)
			mata: st_matrix("result",(result,obs))
			local bl_est = beta_acf_va[1,1]
			local bk_est = beta_acf_va[1,2]
			forv i = 1/`=`polyset'+1' { 
				local gb`i'= g_b[`i',1]
			}
			local min_crit = result[1,1]
			local obs  = result[1,2]
			ereturn local beta_l = `bl_est'
			ereturn local beta_k = `bk_est'
			ereturn local critval = `min_crit'
			ereturn local obs= `obs'
			forv i = 1/`=`polyset'+1' { 
				ereturn local g_b`i'= `gb`i''
			}		
	end		

cap program drop get_locals 
    program define get_locals, eclass 
    syntax , name(string) polyset(string)
        local gblist = ""
        forv i = 1/`=1+`polyset'' {
            ereturn local gb`i'_`name' = `e(g_b`i')'
            ereturn local gb`i'_se_`name' = -99
            local gblist = "`gblist', `e(g_b`i')'"
        }
        ereturn local obs_`name' = `e(obs)'
        ereturn local bl_`name' = `e(beta_l)'
        ereturn local bk_`name' = `e(beta_k)'
        ereturn local bl_se_`name' = -99
        ereturn local bk_se_`name' = -99
        ereturn local crit_`name' = `e(critval)'
    end


capture program drop polyc 
	program define polyc , eclass 
	syntax varlist , Store(string) [level(string)]  [pol3d]  [full]
		local `store' = ""
		tokenize `varlist' 
		local varnum= wordcount("`varlist'")
		if "`level'"=="" { 
			local M = 3 
			local N = 3 		
		}
		else { 
			local M = `level'
			local N = `level'
		}
		if "`pol3d'"=="" { 
			global pol3d =1 
		}
		else { 
			global pol3d = 0 
		}
		if "`full'"!= "" {		
			forv input = 1/3 {
				local ``input''_list = "" 
				forvalues i=1/`M' {
					capture drop ``input''`i'
					if `i'!=1 {
					qui gen ``input''`i'=``input''^(`i')				
					local ``input''_list = "```input''_list' ``input''`i'"
					}
					else { 
						local ``input''_list = "```input''_list' ``input''"	
					}
				*interaction terms
					forvalues j=1/`N' {
						forv input2 = `=`input'+1'/3 { 
							if `input'<3 { 
								capture drop ``input''`i'``input2''`j'
								qui gen ``input''`i'``input2''`j'=(``input''^(`i'))*(``input2''^(`j'))
								local ``input''_list = "```input''_list' ``input''`i'``input2''`j'"
								if $pol3d == 1 {
									forv n = 1/`N' { 
										forv input3 = `=`input2'+1'/3 { 
											capture drop ``input''`i'``input2''`j'``input3''`n'
											qui gen ``input''`i'``input2''`j'``input3''`n'=(``input''^(`i'))*(``input2''^(`j'))*(``input3''^(`n'))
											local ``input''_list = "```input''_list' ``input''`i'``input2''`j'``input3''`n'"
										}
									}
								}
							}
						}
					}
				}
			}
			if $pol3d == 0 { 
				forv poly = 1/`M'  {
					capture drop `1'`poly'`2'`poly'`3'`poly'
					qui gen `1'`poly'`2'`poly'`3'`poly' = (`1'^(`poly'))*(`2'^(`poly'))*(`3'^(`poly'))			
					local `1'_list = "``1'_list' `1'`poly'`2'`poly'`3'`poly'"
				}
			}
			
			forv input = 1/3 {
				local ``input''_list  =  "```input''_list'"
				ereturn local ``input''_list  =  "```input''_list'"
				local `store' = "``store'' ```input''_list'"
			}
		}
		* The prodest approach estimator does it slightly differently 
		else { 
			forv i = 1/`varnum' { 
				local `store' = "``store'' ``i''"
				forv j = `i'/`varnum' { 
					cap drop ``i''``j''
					qui gen ``i''``j'' = ``i''*``j''
					local `store' = "``store'' ``i''``j''"
					if `level'>2 { 
						forv n = `j'/`varnum' { 
							cap drop ``i''``j''``n''
							qui gen ``i''``j''``n'' = ``i''*``j''*``n''
							local `store' = "``store'' ``i''``j''``n''"
							if `level'>3 { 
								forv m = `n'/`varnum' { 
									qui gen ``i''``j''``n''``m'' = ``i''*``j''*``n''*``m''
									local `store' = "``store'' ``i''``j''``n''``m''"
								}
							}
						}
					}		
				}
		
			}

		}
	ereturn local `store' = "``store''"

end
global OMEGA_LAG_MATRIX = ""
mata: mata clear 	
	mata:
	void GMM_EST_1(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,g_b,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		OMEGA=PHI-X*betas'
		OMEGA_lag=PHI_LAG-X_lag*betas'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag)

		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
		
		XI=OMEGA-OMEGA_lag_pol*g_b
		crit=(Z'XI)'*W*(Z'XI)
	}
	end

	mata:
	void GMM_EST_1a(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		betcoef= (betas[1],betas[2])
		gbcoef = (betas[3],betas[4])
		OMEGA=PHI-X*betcoef'
		OMEGA_lag=PHI_LAG-X_lag*betcoef'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag)
		XI=OMEGA-OMEGA_lag_pol*gbcoef'
		crit=(Z'XI)'*W*(Z'XI)
	}
	end	

    mata:
	void GMM_EST_1Z(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,g_b,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		OMEGA=PHI-X*betas'
		OMEGA_lag=PHI_LAG-X_lag*betas'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag)
		
        g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
		
		XI=OMEGA-OMEGA_lag_pol*g_b
		crit=(Z'XI)'*W*(Z'XI)
	}
	end

	mata:
	void GMM_EST_2(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,g_b,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		OMEGA=PHI-X*betas'
		OMEGA_lag=PHI_LAG-X_lag*betas'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag,OMEGA_lag2)
		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
		
		XI=OMEGA-OMEGA_lag_pol*g_b
		crit=(Z'XI)'*W*(Z'XI)
	}
	end	
	mata:
	void GMM_EST_2a(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		betcoef= (betas[1],betas[2])
		gbcoef = (betas[3],betas[4],betas[5])
		OMEGA=PHI-X*betcoef'
		OMEGA_lag=PHI_LAG-X_lag*betcoef'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag,OMEGA_lag2)
		XI=OMEGA-OMEGA_lag_pol*gbcoef'
		crit=(Z'XI)'*W*(Z'XI)
	}
	end		
	mata:
	void GMM_EST_3(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,g_b,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		OMEGA=PHI-X*betas'
		OMEGA_lag=PHI_LAG-X_lag*betas'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag,OMEGA_lag2,OMEGA_lag3)
		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA		
		XI=OMEGA-OMEGA_lag_pol*g_b
		crit=(Z'XI)'*W*(Z'XI)
	}
	end		
	mata:
	void GMM_EST_3a(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		betcoef= (betas[1],betas[2])
		gbcoef = (betas[3],betas[4],betas[5],betas[6])
		OMEGA=PHI-X*betcoef'
		OMEGA_lag=PHI_LAG-X_lag*betcoef'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag,OMEGA_lag2,OMEGA_lag3)
		XI=OMEGA-OMEGA_lag_pol*gbcoef'
		crit=(Z'XI)'*W*(Z'XI)
	}
	end	

	mata:
	void GMM_EST_4(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,g_b,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		OMEGA=PHI-X*betas'
		OMEGA_lag=PHI_LAG-X_lag*betas'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag4 = OMEGA_lag3:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag,OMEGA_lag2,OMEGA_lag3,OMEGA_lag4)
		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA		
		XI=OMEGA-OMEGA_lag_pol*g_b
		crit=(Z'XI)'*W*(Z'XI)
	}
	end		
	mata:
	void GMM_EST_5(todo,betas,PHI,PHI_LAG,Z,X,X_lag,W,g_b,crit,g,H)
	{
		CONST=J(rows(PHI),1,1)
		OMEGA=PHI-X*betas'
		OMEGA_lag=PHI_LAG-X_lag*betas'
		OMEGA_lag2 = OMEGA_lag:*OMEGA_lag
		OMEGA_lag3 = OMEGA_lag2:*OMEGA_lag
		OMEGA_lag4 = OMEGA_lag3:*OMEGA_lag
		OMEGA_lag5 = OMEGA_lag4:*OMEGA_lag
		OMEGA_lag_pol=(CONST,OMEGA_lag,OMEGA_lag2,OMEGA_lag3,OMEGA_lag4,OMEGA_lag5)
		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA		
		XI=OMEGA-OMEGA_lag_pol*g_b
		crit=(Z'XI)'*W*(Z'XI)
	}
	end		

	cap program drop keep_dat 
    program define keep_dat 
		syntax , keeplist(string) sname(string) sadr(string) idvar(string)
    	preserve 
        cap mkdir "`sadr'\\"
        capture local xtvars: sortedby 
        tokenize `xtvars'
		local xt1 = "`1'"
		local xt2 = "`2'"
        keep `idvar' `xt2' `keeplist' 
        save "`sadr'\\`sname'", replace 
        restore 
    end
cap program drop get_productivity 
    program define get_productivity
    syntax , phidat(string) prodestadr(string) prodestloop(string) ///
             idvar(string) year(string) sadname(string) prodestkeepname(string)
    preserve 
        mat me = e(estmat)
        local me_a: rownames e(estmat)    
        mat list me 
        merge 1:1 `idvar' `year' using "`phidat'" , gen(statm)
		foreach dat in `prodestloop' { 
            merge 1:1 `idvar' `year' using "`prodestadr'\\`prodestkeepname'_tfp_`dat'" , gen(`dat')
        } 


        * gen matrix
        tokenize `me_a' 
        local wca = wordcount("`me_a'")
        * Loop over matrix 
        forv ccc = 1/`wca' {
            if regexm("``ccc''","OLS")==1  { 
                gen oy_``ccc'' = y-me[`ccc',4]*l-me[`ccc',6]*k
            }   
            if regexm("``ccc''","GMM")==1 & regexm("``ccc''","IV")==0 { 
                gen oy_``ccc'' = y-me[`ccc',4]*l-me[`ccc',6]*k
            }    
            if regexm("``ccc''","GMM")==1 & regexm("``ccc''","IV")==1 { 
                gen oy_``ccc'' = y-me[`ccc',4]*l-me[`ccc',6]*__CAPhat
            }    
            if (regexm("``ccc''","basic")==1 | regexm("``ccc''","altinit")==1 | regexm("``ccc''","grid")==1) & regexm("``ccc''","IV")==0 { 
                gen oy_``ccc'' = y-me[`ccc',4]*l-me[`ccc',6]*k
                gen op_``ccc'' = __PHI-me[`ccc',4]*l-me[`ccc',6]*k
            }
            if regexm("``ccc''","IV")==1 & regexm("``ccc''","GMM")==0  {
                gen oy_``ccc'' = y-me[`ccc',4]*l-me[`ccc',6]*__CAPhat
                gen op_``ccc'' = __PHI_2s-me[`ccc',4]*l-me[`ccc',6]*__CAPhat
            }         
        }
        sum tfp* oy* op* phi*
        keep `idvar'  `year' phi* tfp* oy* op* y k l m o __PHI
        save "`sadname'", replace 
    restore 
end


 
capture program drop  prod_battery 
program define prod_battery , eclass
	syntax  [,  opoly(int 1) phipoly(int 0) pol3d NBaseline yvar(string) kvar(string) ///
                lvar(string) PROXYvar(string) ivar(string) boots(integer 1) ///
                predkeepadr(string) phikeepname(string) ///
                prodestkeepname(string) idvar(string) /// 
				PRECise]    

	
	preserve

	set seed 123456789
	/* 1.1. Househkeeping */
	* set seed to make sure that same coefficients are obtained
	local baseline = -99
	if "`nbaseline'"=="" {
		local baseline =1 
	} 
	else {
		local baseline = 0 
	}
	local bootstrap_on = 0 
	if "`boots'"!="1" { 
		local bootstrap_on = 1 
		local reps = `boots'
	}
	else {
		local reps = 10
	}
	cap drop __*

	/* 1.1.0.1. These should become options */
		* 2.9.1.2. Initial Step Size
		local size = .05
		* 2.9.1.3. Grids 
		local grids = 4 
		* 2.9.1.4. Scale 
		local scale_min = .7
		local scale_max = 1.15
		local rangec = 10
		local init_min_bl = .15
		local init_max_bl = .9
		local init_min_bk = .1
		local init_max_bk = .85
	
	* 1.1.1. Check if panel 
	capture local xtvars: sortedby 
	if _rc!=0 { 
		di as error "XT not set"
		stop
	}
	else { 
		tokenize `xtvars'
		local xt1 = "`1'"
		local xt2 = "`2'"
	}
	tempvar keepme
	qui gen `keepme' = 1 

	tokenize `varlist'
	
	* 1.1.2. create vars 
	
	local counter = 1 
	local allvarlist = "" 
    gen __OUT = `yvar' 
    gen __LAB = `lvar'
    gen __CAP = `kvar' 
    gen __PROXY = `proxyvar'
    if "`ivar'"!="" { 
        gen __IV = `ivar'
    }
	foreach var in __LAB __CAP { 
		gen `var'_lag = L.`var' 
		replace `keepme' = 0 if `var'==. 
		replace `keepme' = 0 if `var'_lag==. 
	}
    local wc = wordcount("`yvar' `lvar' `kvar' `proxyvar' `ivar'")
    
 

	* 1.1.4. Generate results matrix 
	* crit 1, 
    * obs 1 
	* rts test
    * betas 2*2
    * opoly+1*2
    local cols = 1+1+1+2*2+`=`opoly'+1'*2
	
	
	if `baseline' == 1 { 
			local reslist = "ols ols_samp FE GMM prodest_acf  basic basic_bs   basica basica_bs  basic_pe basic_pe_bs      "	
            local prodest_tfp_list = "prodest_full prodest_acf"
           
		}
		else {
			local reslist = "ols basic basica basic_pe"	
		}	
	
	local rows = wordcount("`reslist'")
	mata: estimate_matrix = J(`rows',`cols',.)
	
	
	
	
	* 1.2 Generate phi poly list
	* 1.2.1. Power List 

	if `phipoly'==0 { 
		local phi_list = "__LAB __CAP __PROXY"
	}
	else { 
		qui polyc __LAB __CAP __PROXY , s(phi_list) level(`phipoly') `pol3d' 
		local phi_list = "`e(phi_list)'"

	}
	reg __OUT `phi_list'
	di "Phi reg coefs" _b[__LAB] "   " _b[__CAP]
	qui predict __PHI , xb 
	local prodpoly = `phipoly' 
	if `prodpoly'<2 { 
		local prodpoly = 2 
	}



	* 1.2.2. Generate phi

	* 1.3 Generate lags 

	qui foreach var in  PHI  { 
		gen __`var'_lag = L.__`var'
		replace `keepme' =0 if __`var'==. 
		replace `keepme' =0 if __`var'_lag==. 		
	}
	qui foreach var in   OUT  { 
		gen __`var'_lag = L.__`var'
		replace `keepme' =0 if __`var'==. 
		*replace `keepme' =0 if __`var'_lag==. 		
	}

	local hatkeeps = ""
	foreach var in `phi_2s' `caphat' { 
		gen __`var'_lag = L.__`var'
		*replace `keepme' =0 if __`var'==. 
		*replace `keepme' =0 if __`var'_lag==. 	
		local hatkeeps = "`hatkeeps' __`var' __`var'_lag "	
	}
	keep_dat , keeplist(__PHI __PHI_lag `hatkeeps') sname("`phikeepname'") sadr("`predkeepadr'") idvar("`idvar'")
	* 1.4. Generate regressors and lags 
	local phi_lag_list = ""

	qui foreach var in `phi_list' {
		cap gen `var'_lag = L.`var'
		local vtype = regexm("`var'","LAB")
		if `vtype'!=1 { 
			local phi_lag_list = "`phi_lag_list' `var'_lag"
		}
		* replace `keepme' =0 if `var'==. 
		* replace `keepme' =0 if `var'_lag==.	
	}

	
	* 2. Estimates 
	* 2.1 OLS
	reg __OUT __LAB __CAP
	local bl_ols = _b[__LAB]
	local bk_ols = _b[__CAP]
	local obs_ols = `e(N)'
	local crit_ols = `e(r2_a)'
    local bl_se_ols = _se[__LAB]
	local bk_se_ols = _se[__CAP]
	local cons_ols = _b[_cons]
    local cons_se_ols = _se[_cons]
	test _b[__LAB]+_b[__CAP]=1
	local rtsp_ols = `r(p)' 
	
    di "OLS, `bl_ols' , `bk_ols'"
	
	if `baseline'==1 {
	* 2.6. Prodest 
		prodest __OUT   , free(__LAB) state(__CAP) proxy(__PROXY) va met(lp) reps(`reps') id(`xt1') t(`xt2')  acf poly(`prodpoly') fsresiduals(phi_prodest_full)
		local bl_prodest_full = _b[__LAB]
		local bk_prodest_full = _b[__CAP]
        local bl_se_prodest_full = _se[__LAB]
		local bk_se_prodest_full = _se[__CAP]
		local obs_prodest_full= `e(N)'
		local crit_prodest_full = -99
        predict tfp_prodest_full, omega 
		test _b[__LAB]+_b[__CAP]=1
		local rtsp_prodest_full = `r(p)' 
        label var tfp_prodest_full "Prodest TFP no limit"
		keep_dat , keeplist(tfp_prodest_full phi_prodest_full) sname("`prodestkeepname'_tfp_prodest_full") sadr("`predkeepadr'") idvar("`idvar'")		
	}
	
	
	
	
	* 2.0 Keep sample  
	keep if `keepme'==1 
	* 2.2. Sample rest
	if `baseline'==1 {
		reg __OUT __LAB __CAP  
		local bl_ols_samp = _b[__LAB]
		local bk_ols_samp = _b[__CAP]
		local bl_se_ols_samp = _se[__LAB]
		local bk_se_ols_samp = _se[__CAP]
		local obs_ols_samp = `e(N)'
		local crit_ols_samp = `e(r2_a)'
		test _b[__LAB]+_b[__CAP]=1
		local rtsp_ols_samp = `r(p)' 
		di "OLS SAMP, `bl_ols_samp' , `bk_ols_samp'"
		if `wc'==5 {
			ivregress 2sls __OUT __LAB (__CAP = __IV)   
			local bl_ols_samp_IV = _b[__LAB]
			local bk_ols_samp_IV = _b[__CAP]
			local bl_se_ols_samp_IV = _se[__LAB]
			local bk_se_ols_samp_IV = _se[__CAP]
			local obs_ols_samp_IV = `e(N)'
			local crit_ols_samp_IV = `e(r2_a)'
			test _b[__LAB]+_b[__CAP]=1
			local rtsp_ols_samp_IV = `r(p)' 			
		}




		* 2.3. FE 
		qui xtreg __OUT __LAB __CAP  , fe 
		local bl_FE = _b[__LAB]
		local bk_FE = _b[__CAP]
		local bl_se_FE = _se[__LAB]
		local bk_se_FE = _se[__CAP]
		local obs_FE = `e(N)'	
		local crit_FE = `e(r2_w)'
		
		* 2.4. GMM Wooldridge  (Kreuser Newman)
		ivreg2 __OUT __CAP (__LAB = __LAB_lag) `phi_lag_list'    , gmm2s first
		local obs_GMM = `e(N)'
		local bl_GMM = _b[__LAB]
		local bk_GMM = _b[__CAP]
		local bl_se_GMM = _se[__LAB]
		local bk_se_GMM = _se[__CAP]
		local crit_GMM = `e(r2_a)'
		test _b[__LAB]+_b[__CAP]=1
		local rtsp_GMM = `r(p)' 	
	
		

		* Get first stage coefs 
		qui reg __LAB __CAP __LAB_lag `phi_lag_list' if e(sample)
		local gb1_GMM = _b[__LAB_lag]
		local gb2_GMM = _b[__CAP]
		local gb3_GMM = _b[__PROXY_lag]
		local gb1_se_GMM = _se[__LAB_lag]
		local gb2_se_GMM = _se[__CAP]
		local gb3_se_GMM = _se[__PROXY_lag]
		
		
		/* 2.5. First difference
		gen __dOUT = d.__OUT
		gen __dCAP = d.__CAP
		gen __dLAB = d.__LAB
		gen __dPROXY = d.__PROXY 
		if `phipoly'==0 { 
			local dphi_list = "__dLAB __dCAP __dPROXY"
		}
		else { 
			qui polyc __dLAB __dCAP __dPROXY , s(dphi_list) level(`phipoly') `pol3d'
			local dphi_list = "`e(dphi_list)'"

		}
		local dphi_lag_list = ""
		qui foreach var in `dphi_list' {
			gen `var'_lag = L.`var'
			local vtype = regexm("`var'","LAB")
			if `vtype'!=1 { 
				local dphi_lag_list = "`dphi_lag_list' `var'_lag"
			}
		
		}
		qui ivreg2 d.__OUT   __dCAP (__dLAB = __dLAB_lag )  `dphi_lag_list' , gmm2s
		local obs_FD = `e(N)'
		local crit_FD = `e(r2_a)'
		local bl_FD = _b[__dLAB]
		local bk_FD = _b[__dCAP]
		local bl_se_FD = _se[__dLAB]
		local bk_se_FD = _se[__dCAP]

        * First stage 
		qui reg __dLAB __dCAP __dLAB_lag `dphi_lag_list' if e(sample)
		local gb1_FD = _b[__dLAB_lag]
		local gb2_FD = _b[__dCAP_lag]
		local gb3_FD = _b[__dPROXY_lag]
		local gb1_se_FD = _se[__dLAB_lag]
		local gb2_se_FD = _se[__dCAP_lag]
		local gb3_se_FD = _se[__dPROXY_lag]
		*/



		* 2.6. Prodest 
	
		prodest __OUT  if `keepme'==1 , free(__LAB) state(__CAP) proxy(__PROXY) va met(lp) reps(`reps') id(`xt1') t(`xt2')  acf poly(`prodpoly')  fsresiduals(phi_prodest_acf)
		local bl_prodest_acf = _b[__LAB]
		local bk_prodest_acf = _b[__CAP]
 		local bl_se_prodest_acf = _se[__LAB]
		local bk_se_prodest_acf = _se[__CAP] 
		local obs_prodest_acf = `e(N)'
		local crit_prodest_acf = -99
        predict tfp_prodest_acf, omega 
        label var tfp_prodest_acf "Prodest TFP acf lim"
		test _b[__LAB]+_b[__CAP]=1
		local rtsp_prodest_acf = `r(p)' 		
		keep_dat , keeplist(tfp_prodest_acf phi_prodest_acf) sname("`prodestkeepname'_tfp_prodest_acf") sadr("`predkeepadr'") idvar("`idvar'")
		cap drop phi_prodest_acf
		cap drop tfp_prodest_acf
      
	
	}
	
	local polyset = `opoly'
	*forv polyset = 	1/3 {
		if "`polyset'"=="" | "`polyset'"=="1" {
			local OMEGA_LAG_MATRIX = "(CONST,OMEGA_lag)"
			mata: g_b = (1,1)
		}
		else { 
			local OMEGA_LAG_MATRIX = "(CONST,OMEGA_lag"
			local g_b = "(1,1"
			forv i =  2/`polyset' { 
				local OMEGA_LAG_MATRIX = "`OMEGA_LAG_MATRIX',OMEGA_lag`i'"
				local g_b = "`g_b',1"
			}
				local OMEGA_LAG_MATRIX = "`OMEGA_LAG_MATRIX')"
				local g_b = "`g_b')"
				mata: g_b = `g_b'
				
			di "`OMEGA_LAG_MATRIX'"
		}
			xtset `xt1' `xt2'
			* 2.7.1. Prepare coefs no IV
			mata: PHI=st_data(.,("__PHI"))
			mata: PHI_LAG=st_data(.,("__PHI_lag"))
			mata: X=st_data(.,("__LAB","__CAP"))
			mata: X_lag=st_data(.,("__LAB_lag","__CAP_lag"))
			mata: Z=st_data(.,("__LAB_lag","__CAP"))
			mata: W=invsym(Z'Z)/rows(Z)			
			if "`precise'"!="" {
				mata: Z=st_data(.,("__LAB","__LAB_lag","__CAP"))
				mata: W=invsym(Z'Z)/rows(Z)
			}
		* 2.8 ACF GMM METHODS
            ********************************************************************************************************************************
            * 2.8.1. BASIC 
            *****************************************************************************************
			gen one =1 
            reset_mata `xt1' `xt2' , `precise'
            gmm_basic `polyset' `bl_ols' `bk_ols'
			local gblist = ""
            forv i = 1/`=1+`polyset'' {
				local gb`i'_basic = `e(g_b`i')'
                local gb`i'_se_basic = -99
				local gblist = "`gblist', `e(g_b`i')'"
			}
			local obs_basic = `e(obs)'
			local bl_basic = `e(beta_l)'
			local bk_basic = `e(beta_k)'
            local bl_se_basic = -99
			local bk_se_basic = -99
			local crit_basic = `e(critval)'
			di "ACF Basic, `e(critval)', `e(obs)', `e(beta_l)', `e(beta_k)' `gblist' "
			
            ***********************************************************
            * 2.8.2. ACF (rho)
            **********************************************************
            cap gen __omcheck = __PHI - `bl_ols'*__LAB - `bk_ols'*__CAP  
			cap gen __omcheck_lag = __PHI_lag - `bl_ols'*__LAB_lag - `bk_ols'*__CAP_lag
			reg __omcheck __omcheck_lag
			local gb0_init = _b[_cons]
			local gb1_init = _b[__omcheck_lag]
			/*if `opoly'>1 {
				local oe_initlist = ""
				forv oe = 2/`opoly' { 
					local gb`oe'_init = 0
					local oe_initlist = "`oe_initlist' `gb`oe'_init'"
				}
			}*/
            reset_mata `xt1' `xt2' , `precise'
			gmm_basica `polyset' `bl_ols' `bk_ols' `gb0_init' `gb1_init'  
			local gblist = ""
			local gbinitlist = "" 
			forv i = 1/`=1+`polyset'' {
				local gb`i'_basica = `e(g_b`i')'
                local gb`i'_se_basica = -99
				local gblist = "`gblist', `e(g_b`i')'"
				local gbinitlist= "`gbinitlist' gb`i'_init(`gb`i'_basica')"
			}
			di "`gbinitlist'"
			local obs_basica = `e(obs)'
			local bl_basica = `e(beta_l)'
			local bk_basica = `e(beta_k)'
            local bl_se_basica = -99
			local bk_se_basica = -99
			local rtsp_basica = - 99
			local crit_basica = `e(critval)'
			di "ACF Basica, `e(critval)', `e(obs)', `e(beta_l)', `e(beta_k)' `gblist' "			
			
            ***********************************************************
            * 2.8.3. ACF PRODEST APPROACH
            **********************************************************
            reset_mata `xt1' `xt2' , `precise'            
			gmm_basic_pe `polyset' `bl_ols' `bk_ols'
			local gblist = ""
			forv i = 1/`=1+`polyset'' {
				local gb`i'_basic_pe = `e(g_b`i')'
                local gb`i'_se_basic_pe = -99
				local gblist = "`gblist', `e(g_b`i')'"
			}
			local obs_basic_pe = `e(obs)'
			local bl_basic_pe = `e(beta_l)'
			local bk_basic_pe = `e(beta_k)'
            local bl_se_basic_pe = -99
			local bk_se_basic_pe = -99
			local crit_basic_pe = `e(critval)'
			di "ACF Basic PE, `e(critval)', `e(obs)', `e(beta_l)', `e(beta_k)' `gblist' "			

          


            ******************************************************************************
            * 2.9 Now Bootstrap
            *****************************************************************************


			gen panelvar = `xt1'

            if `bootstrap_on'==1 {
                * Reset Mata: 
                reset_mata `xt1' `xt2' , `precise'
                cap drop newid
                * clear xt and tsset 
                * 2.9.1. BASIC WITH BASIC INITS 
                tsset, clear
				xtset, clear 
				di "init bootstrap"
                capture noisily bootstrap , reps(`reps') seed(`seed') cluster(`xt1') idcluster(newid): gmm_grid_bs __PHI __LAB __CAP, polyset(`polyset') bl_init(`bl_basic') bk_init(`bk_basic') `precise'
				if _rc==0 {
                    cap drop newid
                    local obs_basic_bs = `e(N)'
                    local crit_basic_bs = _b[crit]
                    local bl_basic_bs = _b[beta_l]
                    local bl_se_basic_bs = _se[beta_l]
                    local bk_basic_bs = _b[beta_k]
                    local bk_se_basic_bs = _se[beta_k]
                    forv i = 1/`=1+`polyset'' {
                        local gb`i'_basic_bs = _b[gb_`i']
                        local gb`i'_se_basic_bs = _se[gb_`i']
                    }
					test _b[beta_l]+_b[beta_k]=1 
					local rtsp_basic_bs = `r(p)'

                }
                else { 
                    cap drop newid
                    local obs_basic_bs = -99
                    local crit_basic_bs = -99
                    local bl_basic_bs = -99
                    local bl_se_basic_bs = -99
                    local bk_basic_bs = -99
                    local bk_se_basic_bs = -99
                    forv i = 1/`=1+`polyset'' {
                        local gb`i'_basic_bs = -99
                        local gb`i'_se_basic_bs = -99
                    }
                }
  
                * 2.9.2. ACF(rho) with inits
                reset_mata `xt1' `xt2' , `precise'
                cap drop newid
				tsset, clear
				xtset, clear                 
				capture noisily bootstrap , reps(`reps') seed(`seed') cluster(`xt1') idcluster(newid): gmm_grid_bsa __PHI __LAB __CAP, polyset(`polyset') bl_init(`bl_basica') bk_init(`bk_basica') `gbinitlist'  `precise' 
				if _rc==0 {
                    cap drop newid
                    local obs_basica_bs = `e(N)'
                    local crit_basica_bs = _b[crit]
                    local bl_basica_bs = _b[beta_l]
                    local bl_se_basica_bs = _se[beta_l]
                    local bk_basica_bs = _b[beta_k]
                    local bk_se_basica_bs = _se[beta_k]
                    forv i = 1/`=1+`polyset'' {
                        local gb`i'_basica_bs = _b[gb_`i']
                        local gb`i'_se_basica_bs = _se[gb_`i']
                    }
					test _b[beta_l]+_b[beta_k]=1 
					local rtsp_basica_bs = `r(p)'					
                }
                else {
                    local obs_basica_bs = -99
                    local crit_basica_bs = -99
                    local bl_basica_bs = -99
                    local bl_se_basica_bs = -99
                    local bk_basica_bs = -99
                    local bk_se_basica_bs = -99
                    forv i = 1/`=1+`polyset'' {
                        local gb`i'_basica_bs = -99
                        local gb`i'_se_basica_bs = -99
                    }
                }
               
                *******
                * 2.9.5 PRODEST approach              
                reset_mata `xt1' `xt2' , `precise'
                cap drop newid
				tsset, clear
				xtset, clear             
                capture noisily bootstrap , reps(`reps') seed(`seed') cluster(`xt1') idcluster(newid): gmm_grid_bs __PHI __LAB __CAP, polyset(`polyset') bl_init(`bl_basic_pe') bk_init(`bk_basic_pe') `precise'
				if _rc==0 {
                    cap drop newid
                    local obs_basic_pe_bs = `e(N)'
                    local crit_basic_pe_bs = _b[crit]
                    local bl_basic_pe_bs = _b[beta_l]
                    local bl_se_basic_pe_bs = _se[beta_l]
                    local bk_basic_pe_bs = _b[beta_k]
                    local bk_se_basic_pe_bs = _se[beta_k]
                    forv i = 1/`=1+`polyset'' {
                        local gb`i'_basic_pe_bs = _b[gb_`i']
                        local gb`i'_se_basic_pe_bs = _se[gb_`i']
                    }
					test _b[beta_l]+_b[beta_k]=1 
					local rtsp_basic_pe_bs = `r(p)'							
                }
                else { 
                    cap drop newid
                    local obs_basic_pe_bs = -99
                    local crit_basic_pe_bs = -99
                    local bl_basic_pe_bs = -99
                    local bl_se_basic_pe_bs = -99
                    local bk_basic_pe_bs = -99
                    local bk_se_basic_pe_bs = -99
                    forv i = 1/`=1+`polyset'' {
                        local gb`i'_basic_pe_bs = -99
                        local gb`i'_se_basic_pe_bs = -99
                    }                   
                }
            
			}                
        
	local gb_set = ""
	forv i = 1/`=1+`polyset'' {
		local gbset = "`gbset' gb`i' gb`i'_se"
	}
    local row = 1 
	foreach rs in `reslist' { 
		local col = 1 
		foreach entry in crit obs rtsp bl bl_se bk bk_se `gbset' { 
			if "``entry'_`rs''"!="" {
				capture noisily mata: estimate_matrix[`row',`col'] = ``entry'_`rs''
			}
			local col = `col'+1		
		}
		local row = `row'+1
	}
	set trace off
	restore
	mata: estimate_matrix
   
	mata: st_matrix("estimate_matrix", estimate_matrix)
	matrix estimate_matrix= estimate_matrix
	mat colnames estimate_matrix = crit obs rtsp bl bl_se bk bk_se `gbset'
	mat rownames estimate_matrix = `reslist'
    ereturn local reslist = "`reslist'"
    ereturn local prodest_tfp_list = "`prodest_tfp_list'"
    

	ereturn matrix estmat = estimate_matrix

	end 
