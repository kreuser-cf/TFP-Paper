# # -*- coding: utf-8 -*-
# """
# Created on Wed Apr 21 20:03:52 2021

# @author: Friedrich
# """
    


# import numpy as np
# import matplotlib.pyplot as plt

# colors = ["crimson", "purple", "gold"]

# f = lambda m,c: plt.plot([],[],marker=m, color=c, ls="none")[0]

# handles = [f("s", colors[i]) for i in range(3)]
# labels = colors
# legend = plt.legend(handles, labels, loc=3, framealpha=1, frameon=True)

# def export_legend(legend, filename="legend.png", expand=[-5,-5,5,5]):
#     fig  = legend.figure
#     fig.canvas.draw()
#     bbox  = legend.get_window_extent()
#     bbox = bbox.from_extents(*(bbox.extents + np.array(expand)))
#     bbox = bbox.transformed(fig.dpi_scale_trans.inverted())
#     fig.savefig(filename, dpi="figure", bbox_inches=bbox)

# export_legend(legend)
# plt.show()


# # This program creates the figures
def createfigsiv(path,prefix,estimator,altv,suffix,savename,savepath):
    import csv
    import glob
    import os
    import re

    import matplotlib.pyplot as plt
    import numpy as np
    import pandas as pd
    import pylab
    from matplotlib.backends.backend_pdf import PdfPages
    os.chdir(path)
    indlist = [10, 11, 12, 13, 14, 15 , 16 ,17 ,18 , 19, 20, 22, 23 , 24, 25, 26, 27, 28, 29, 30, 31, 32]
    namelist = ['10 Food',
                '11 Beverages',
                '12 Tobacco', 
                '13 Textiles',
                '14 Apparel',
                '15 Leather and Footwear',
                '16 Wood', 
                '17 Paper', 
                '18 Printing', 
                '19 Petroleum' , 
                '20 Chemicals and Pharma',
                '22 Rubber and Plastics',
                '23 Non-Metallic Minerals', 
                '24 Basic Metals', 
                '25 Fabricated Metals', 
                '26 Computer and Electronic', 
                '27 Electrical', 
                '28 Machinery Equipment N.E.C',
                '29 Motor Vehicles', 
                '30 Other Transport', 
                '31 Furniture', 
                '32 Other']
    markers = ["o" , "v" ,"*" , "+" , "x","^"]
    s = ['tab:blue','tab:green','tab:red','tab:gray']
    counter = 0
    mcounter = 0 
    ccounter = 0   
    fig, (ax1,ax2) = plt.subplots(1,2, figsize=(12,4))
    filename_1 = str(prefix)+str(estimator)+'_'+str(suffix)+'.csv'
    filename_2 = str(prefix)+str(estimator)+'_'+str(altv)+'_'+str(suffix)+'.csv'
    
    df = pd.read_csv(open(str(filename_1), 'rb'))
    print(df)
    for i in range(len(indlist)): 
        bl = str('bl')+'_'+str(indlist[i])
        bk = str('bk')+'_'+str(indlist[i])
        xi = df[bk]
        yi = df[bl]
        ci = s[ccounter]
        mi = markers[mcounter]
        if ccounter<3:
            ccounter = ccounter+1
        else:
            ccounter = 0 
        if ccounter==0:
            mcounter = mcounter+1 
            if mcounter==len(markers):
                mcounter = 0 

        ax1.scatter(xi,yi,marker=mi, color=ci,label=str(namelist[i]),alpha=.7)
    ax1.set_xlabel(r'$\beta_k$', fontsize=15)
    ax1.set_ylabel(r'$\beta_l$', fontsize=15)   
    lgd = ax1.legend(loc='center', bbox_to_anchor=(1.05, -.40), shadow=False, ncol=4)
    # fig.subplots_adjust(left=.15)
    # fig.subplots_adjust(bottom=.5)
    #ax.plot([max(1,min(ax.get_ylim()[1],ax.get_xlim()[1])),0])
    ax1.plot(([0,1],[1,0]),color='black',alpha=.25)
    counter = 0
    mcounter = 0 
    ccounter = 0   
    df2 = pd.read_csv(open(str(filename_2), 'rb'))
    for i in range(len(indlist)): 
        bl = str('bl')+'_'+str(indlist[i])
        bk = str('bk')+'_'+str(indlist[i])
        xi = df2[bk]
        yi = df2[bl]
        ci = s[ccounter]
        mi = markers[mcounter]
        if ccounter<3:
            ccounter = ccounter+1
        else:
            ccounter = 0 
        if ccounter==0:
            mcounter = mcounter+1 
            if mcounter==len(markers):
                mcounter = 0 

        ax2.scatter(xi,yi,marker=mi, color=ci,label=str(namelist[i]),alpha=.7)
    ax2.set_xlabel(r'$\beta_k$ IV', fontsize=15)
    ax2.set_ylabel(r'$\beta_l$', fontsize=15)   
    # fig.subplots_adjust(left=.15)
    # fig.subplots_adjust(bottom=.5)
    #ax.plot([max(1,min(ax.get_ylim()[1],ax.get_xlim()[1])),0])
    ax1.plot(([1,0]),color='black',alpha=.25)
    ax1.axvline(x=.2,color='lightsteelblue',alpha=.2)
    ax1.axvline(x=.3,color='lightsteelblue',alpha=.3)
    ax1.axvline(x=.4,color='lightsteelblue',alpha=.4)
    ax1.axvline(x=.5,color='lightsteelblue',alpha=.5)
    ax1.axvline(x=.6,color='lightsteelblue',alpha=.6)
    ax1.axhline(y=.4,color='lightsteelblue',alpha=.2)
    ax1.axhline(y=.5,color='lightsteelblue',alpha=.3)
    ax1.axhline(y=.6,color='lightsteelblue',alpha=.4)
    ax1.axhline(y=.7,color='lightsteelblue',alpha=.5)
    ax1.axhline(y=.8,color='lightsteelblue',alpha=.6)

    sn = str(savepath)+'/'+str(savename)+".pdf"  
    fig.savefig(sn,dpi=400,format='pdf', bbox_extra_artists=(lgd,),
                bbox_inches='tight')   

def createfigspr(path,prefix,estimator,altv,suffix,savename,savepath):
    import csv
    import glob
    import os
    import re

    import matplotlib.pyplot as plt
    import numpy as np
    import pandas as pd
    from matplotlib.backends.backend_pdf import PdfPages
    os.chdir(path)
    indlist = [10, 11, 12, 13, 14, 15 , 16 ,17 ,18 , 19, 20, 22, 23 , 24, 25, 26, 27, 28, 29, 30, 31, 32]
    namelist = ['10 Food',
                '11 Beverages',
                '12 Tobacco', 
                '13 Textiles',
                '14 Apparel',
                '15 Leather and Footwear',
                '16 Wood', 
                '17 Paper', 
                '18 Printing', 
                '19 Coke and Petroleum' , 
                '20 Chemicals and Pharma',
                '22 Rubber and Plastics',
                '23 Non-Metallic Minerals', 
                '24 Basic Metals', 
                '25 Fabricated Metals', 
                '26 Computer and Electronic', 
                '27 Electrical', 
                '28 Machinery Equipment N.E.C',
                '29 Motor Vehicles', 
                '30 Other Transport Equipment', 
                '31 Furniture', 
                '32 Other Manufacturing']
    markers = ["o" , "v" ,"*" , "+" , "x","^"]
    s = ['tab:blue','tab:green','tab:red','tab:gray']
    counter = 0
    mcounter = 0 
    ccounter = 0   
    fig, (ax1,ax2) = plt.subplots(1,2, figsize=(12,4))
    filename_1 = str(prefix)+str(estimator)+'_'+str(suffix)+'.csv'
    filename_2 = str(prefix)+str(estimator)+'_'+str(suffix)+'_'+str(altv)+'.csv'
    
    df = pd.read_csv(open(str(filename_1), 'rb'))
    print(df)
    for i in range(len(indlist)): 
        bl = str('bl')+'_'+str(indlist[i])
        bk = str('bk')+'_'+str(indlist[i])
        xi = df[bk]
        yi = df[bl]
        ci = s[ccounter]
        mi = markers[mcounter]
        if ccounter<3:
            ccounter = ccounter+1
        else:
            ccounter = 0 
        if ccounter==0:
            mcounter = mcounter+1 
            if mcounter==len(markers):
                mcounter = 0 

        ax1.scatter(xi,yi,marker=mi, color=ci,label=str(namelist[i]),alpha=.7)
    ax1.set_xlabel(r'$\beta_k$', fontsize=15)
    ax1.set_ylabel(r'$\beta_l$', fontsize=15)   
    lgd = ax1.legend(loc='center', bbox_to_anchor=(1.05, -.40), shadow=False, ncol=4)
    # fig.subplots_adjust(left=.15)
    # fig.subplots_adjust(bottom=.5)
    #ax.plot([max(1,min(ax.get_ylim()[1],ax.get_xlim()[1])),0])
    ax1.plot([min(1,max(ax1.get_ylim()[1],ax1.get_xlim()[1])),0],[0,min(1,max(ax1.get_ylim()[1],ax1.get_xlim()[1]))],color='black',alpha=.25)
    counter = 0
    mcounter = 0 
    ccounter = 0   
    df2 = pd.read_csv(open(str(filename_2), 'rb'))
    for i in range(len(indlist)): 
        bl = str('bl')+'_'+str(indlist[i])
        bk = str('bk')+'_'+str(indlist[i])
        xi = df2[bk]
        yi = df2[bl]
        ci = s[ccounter]
        mi = markers[mcounter]
        if ccounter<3:
            ccounter = ccounter+1
        else:
            ccounter = 0 
        if ccounter==0:
            mcounter = mcounter+1 
            if mcounter==len(markers):
                mcounter = 0 

        ax2.scatter(xi,yi,marker=mi, color=ci,label=str(namelist[i]),alpha=.7)
    ax2.set_xlabel(r'$\beta_k$ IV', fontsize=15)
    ax2.set_ylabel(r'$\beta_l$', fontsize=15)   
    # fig.subplots_adjust(left=.15)
    # fig.subplots_adjust(bottom=.5)
    #ax.plot([max(1,min(ax.get_ylim()[1],ax.get_xlim()[1])),0])
    ax1.plot(([1,0]),color='black',alpha=.25)
    ax1.axvline(x=.2,color='lightsteelblue',alpha=.2)
    ax1.axvline(x=.3,color='lightsteelblue',alpha=.3)
    ax1.axvline(x=.4,color='lightsteelblue',alpha=.4)
    ax1.axvline(x=.5,color='lightsteelblue',alpha=.5)
    ax1.axvline(x=.6,color='lightsteelblue',alpha=.6)
    ax1.axhline(y=.4,color='lightsteelblue',alpha=.2)
    ax1.axhline(y=.5,color='lightsteelblue',alpha=.3)
    ax1.axhline(y=.6,color='lightsteelblue',alpha=.4)
    ax1.axhline(y=.7,color='lightsteelblue',alpha=.5)
    ax1.axhline(y=.8,color='lightsteelblue',alpha=.6)


    sn = str(savepath)+'/'+str(savename)+".pdf"  
    fig.savefig(sn,dpi=400,format='pdf', bbox_extra_artists=(lgd,),
                bbox_inches='tight')   



def createfigs(path,prefix,estimator,suffix,savename,savepath):
    import csv
    import glob
    import os
    import re

    import matplotlib.pyplot as plt
    import numpy as np
    import pandas as pd
    from matplotlib.backends.backend_pdf import PdfPages
    os.chdir(path)
    indlist = [10, 11, 12, 13, 14, 15 , 16 ,17 ,18 , 19, 20, 22, 23 , 24, 25, 26, 27, 28, 29, 30, 31, 32]
    namelist = ['10 Food',
                '11 Beverages',
                '12 Tobacco', 
                '13 Textiles',
                '14 Apparel',
                '15 Leather and Footwear',
                '16 Wood', 
                '17 Paper', 
                '18 Printing', 
                '19 Coke and Petroleum' , 
                '20 Chemicals and Pharma',
                '22 Rubber and Plastics',
                '23 Non-Metallic Minerals', 
                '24 Basic Metals', 
                '25 Fabricated Metals', 
                '26 Computer and Electronic', 
                '27 Electrical', 
                '28 Machinery Equipment N.E.C',
                '29 Motor Vehicles', 
                '30 Transport Equipment', 
                '31 Furniture', 
                '32 Other Manufacturing']
    markers = ["o" , "v" ,"*" , "+" , "x","^"]
    s = ['tab:blue','tab:green','tab:red','tab:gray']
    counter = 0
    mcounter = 0 
    ccounter = 0   
    fig, ax1 = plt.subplots(1, figsize=(12,4))
    # fig2, ax2_1 = plt.subplots(1, figsize=(4,4))
    # fig3, ax3_1 = plt.subplots(1,figsize=(2,4))

    filename_1 = str(prefix)+str(estimator)+'_'+str(suffix)+'.csv'    
    df = pd.read_csv(open(str(filename_1), 'rb'))
    print(df)
    for i in range(len(indlist)): 
        bl = str('bl')+'_'+str(indlist[i])
        bk = str('bk')+'_'+str(indlist[i])
        xi = df[bk]
        yi = df[bl]
        ci = s[ccounter]
        mi = markers[mcounter]
        if ccounter<3:
            ccounter = ccounter+1
        else:
            ccounter = 0 
        if ccounter==0:
            mcounter = mcounter+1 
            if mcounter==len(markers):
                mcounter = 0 

        ax1.scatter(xi,yi,marker=mi, color=ci,label=str(namelist[i]),alpha=.7)
        # ax2_1.scatter(xi,yi,marker=mi, color=ci,label=str(namelist[i]),alpha=.7)
        # ax3_1.scatter(label=str(namelist[i]))

    ax1.set_xlabel(r'$\beta_k$', fontsize=15)
    ax1.set_ylabel(r'$\beta_l$', fontsize=15)   
    # ax2_1.set_xlabel(r'$\beta_k$', fontsize=15)
    # ax2_1.set_ylabel(r'$\beta_l$', fontsize=15)   
    lgd = ax1.legend(loc='center', bbox_to_anchor=(0.475, -.40), shadow=False, ncol=4)

    # fig.subplots_adjust(left=.15)
    # fig.subplots_adjust(bottom=.5)
    #ax.plot([max(1,min(ax.get_ylim()[1],ax.get_xlim()[1])),0])
    ax1.plot(([1,0]),color='black',alpha=.25)
    ax1.axvline(x=.2,color='lightsteelblue',alpha=.2)
    ax1.axvline(x=.25,color='lightsteelblue',alpha=.25)
    ax1.axvline(x=.3,color='lightsteelblue',alpha=.3)
    ax1.axvline(x=.35,color='lightsteelblue',alpha=.35)
    ax1.axvline(x=.4,color='lightsteelblue',alpha=.4)
    ax1.axvline(x=.5,color='lightsteelblue',alpha=.5)
    ax1.axvline(x=.6,color='lightsteelblue',alpha=.6)
    ax1.axhline(y=.4,color='lightsteelblue',alpha=.2)
    ax1.axhline(y=.5,color='lightsteelblue',alpha=.3)
    ax1.axhline(y=.6,color='lightsteelblue',alpha=.4)
    ax1.axhline(y=.7,color='lightsteelblue',alpha=.5)
    ax1.axhline(y=.8,color='lightsteelblue',alpha=.6)

    # ax2_1.plot([min(1,max(ax1.get_ylim()[1],ax1.get_xlim()[1])),0],[0,min(1,max(ax1.get_ylim()[1],ax1.get_xlim()[1]))],color='black',alpha=.25)

    sn = str(savepath)+'/'+str(savename)+".pdf"
    # sn2 = str(savepath)+'/'+str(savename)+"nol.pdf"
    # sn3 = str(savepath)+'/'+str(savename)+"legend.pdf"

    fig.savefig(sn,dpi=400,format='pdf', bbox_extra_artists=(lgd,),
                bbox_inches='tight')   
    # fig2.savefig(sn2,dpi=400,format='pdf',bbox_inches='tight')   
    # fig3.savefig(sn3,dpi=400,format='pdf', bbox_extra_artists=(lgd,),
    #             bbox_inches='tight')   



def loopfigs(datapath,savepath,iv,poly):
    import csv
    import glob
    import os
    import re

    import matplotlib.pyplot as plt
    import numpy as np
    import pandas as pd
    from matplotlib.backends.backend_pdf import PdfPages
    if iv==0: 
        ivs = "noiv"
    elif iv==1:
        ivs = "iv"

    for filename in glob.iglob(datapath+'/*', recursive=True):
        if os.path.isfile(filename): # filter dirs
            lims = ['alim','blim']
            sufl = []
            for l in lims: 
                sufl.append(str(ivs)+'_'+'basic_'+str(poly)+'pol_'+l)            
            estl = ['ols_samp','GMM','prodest_acf','basic_bs','basica_bs','basic_pe_bs']
            for suf in sufl:
                for est in estl:
                    if iv==1:             
                        v = filename    
                        fme= str(est)+'_'+str(suf)+'.csv'
                        dd = re.search(fme,v)
                        if dd!=None:
                            d2 = re.search('IV',fme)
                            if d2==None:
                                ss = filename.replace(fme,'',1)
                                s2 = ss.replace(datapath+'\\','',1)
                                print(s2)
                                createfigsiv(datapath,s2,str(est),str('IV'),str(suf),s2+str(est)+str(suf),savepath)        
                    if iv==0: 
                        v = filename    
                        fme= str(est)+'_'+str(suf)+'.csv'
                        print(fme)
                        dd = re.search(fme,v)
                        print(dd)
                        if dd!=None:
                            ss = filename.replace(fme,'',1)
                            s2 = ss.replace(datapath+'\\','',1)
                            print(s2)
                            createfigs(datapath,s2,str(est),str(suf),s2+str(est)+str(suf),savepath)           

loopfigs('C:/Users/Friedrich/Dropbox/UNUWIDER/TFP_Paper_Submitted/FigData/p3_isic4_d19','C:/Users/Friedrich/Dropbox/UNUWIDER/TFP_Paper_Submitted/figs/p3_isic4_d19',0,3)
