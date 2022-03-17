import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
from netCDF4 import Dataset as NetCDFFile
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.pylab as plb
import matplotlib.colors as mpcrs
import matplotlib.cm as cm
from ndate import ndate
#from datetime import datetime
#from datetime import timedelta

def setup_cmap(name,nbar,mpl,whilte,reverse):
    nclcmap='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg/pyscripts/colormaps/'
    cmapname=name
    f=open(nclcmap+'/'+cmapname+'.rgb','r')
    a=[]
    for line in f.readlines():
        if ('ncolors' in line):
            clnum=int(line.split('=')[1])
        a.append(line)
    f.close()
    b=a[-clnum:]
    c=[]

    selidx=np.trunc(np.linspace(0, clnum-1, nbar))
    selidx=selidx.astype(int)

    for i in selidx[:]:
        if mpl==1:
            c.append(tuple(float(y) for y in b[i].split()))
        else:
            c.append(tuple(float(y)/255. for y in b[i].split()))
            #c.append(tuple(int(y) for y in b[i].split()))

    if reverse==1:
        ctmp=c
        c=ctmp[::-1]
    if white==-1:
        c[0]=[1.0, 1.0, 1.0]
    if white==1:
        c[-1]=[1.0, 1.0, 1.0]
    elif white==0:
        c[int(nbar/2-1)]=[1.0, 1.0, 1.0]
        c[int(nbar/2)]=c[int(nbar/2-1)]

    #np.savetxt('bias.txt', c, fmt='%i', delimiter=' ')
    d=mpcrs.LinearSegmentedColormap.from_list(name,c,selidx.size)
    return d

def concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, cyc, field):
    for itilem1 in range(ntiles):
        itile=itilem1
        filetmp='%s/aod_%s_hofx_3dvar_LUTs_%s_000%s.%s' % (filedir, aodtyp, cyc, str(itile), field)
        try:
            nctmp=NetCDFFile(filetmp)
            if ioda == 1:
                varv=nctmp.variables[var][:]
            else:
                varg=nctmp.groups[g2]
                if g2 == 'hofx':
                   varv=varg[v2][:,0]
                else:
                   varv=varg[v2][:]
            if (itile == 0):
                varvarr=varv.flatten()
            else:
                varvarr=np.concatenate((varvarr, varv.flatten()), axis=0)
            nctmp.close()
        except OSError:
            print('cannot open', filetmp)
    return varvarr

def readaod(aodtype,stcyc,edcyc,cycinc,datadir,field,ntiles):
    ctcyc=stcyc
    while (ctcyc <= edcyc):
        cymd=str(ctcyc)[:8]
        ch=str(ctcyc)[8:]
        if ctcyc >= 2021071206:
            ioda = 2
        else:
            ioda = 1
    
        filedir = '%s/gdas.%s/%s/obs/' % (datadir, cymd, ch)

        var='longitude@MetaData'
        g2='MetaData'
        v2='longitude'
        lon=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(ctcyc), field)

        var='latitude@MetaData'
        g2='MetaData'
        v2='latitude'
        lat=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(ctcyc), field)

        var='aerosol_optical_depth_4@ObsValue'
        g2='ObsValue'
        v2='aerosol_optical_depth'
        obs=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(ctcyc), field)

        var='aerosol_optical_depth_4@hofx'
        g2='hofx'
        v2='aerosol_optical_depth'
        hofx=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(ctcyc), field)

        if (ctcyc == stcyc):
            lonarr=lon
            latarr=lat
            obsarr=obs
            hofxarr=hofx
        else:
            lonarr=np.concatenate((lonarr, lon), axis=0)
            latarr=np.concatenate((latarr, lat), axis=0)
            obsarr=np.concatenate((obsarr, obs), axis=0)
            hofxarr=np.concatenate((hofxarr, hofx), axis=0)
        ctcyc=ndate(ctcyc, cycinc)
    return lonarr, latarr, obsarr, hofxarr

def plot_map_scatter_7(lons, lats, obs, nodahofx_bckg,dahofx_bckg, dahofx_anal, aodtyp, cmap1, cmap2, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]
    if aodtyp=='viirs_npp':
        paod='VIIRS/SNPP 550 nm AOD'
    elif aodtyp=='viirs_j01':
        paod='VIIRS/NOAA20 550 nm AOD'
    elif aodtyp=='nrt_aqua':
        paod='MODIS/AQUA 550 nm AOD'
    elif aodtyp=='nrt_terra':
        paod='MODIS/TERRA 550 nm AOD'

    ptitle='550 nm Aerosol Optical Depth (AOD) valid at %s/%s/%s (0000-0018 UTC)' % (cm, cd, cy)
    fig=plt.figure(figsize=[15,8]) #,constrained_layout=True)
    for ipt in range(9):
        if ipt!=0 and ipt!=2:
            ax=fig.add_subplot(3, 3, ipt+1)
            if ipt==1:
                data=obs
                tstr=paod
            if ipt==3:
                data=nodahofx_bckg
                tstr='NODA 6hr fcst'
            if ipt==4:
                data=dahofx_bckg
                tstr='DA 6hr fcst'
            if ipt==5:
                data=dahofx_anal
                tstr='DA analysis'

            if ipt==6:
                data=nodahofx_bckg-obs
                tstr='NODA 6hr fcst bias'
            if ipt==7:
                data=dahofx_bckg-obs
                tstr='DA 6hr fcst bias'
            if ipt==8:
                data=dahofx_anal-obs
                tstr='DA analysis bias'

            if ipt<6:
                vvmin=0.0
                vvmax=1.1
                vvend='max'
                ccmap=cmap1
                bounds=[0.0, 0.1, 0.16, 0.23, 0.29, 0.36, 0.42, 0.49, 0.55, 0.61, 0.68, 0.74, 0.81, 0.87, 1]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
                
            else:
                vvmin=-0.2
                vvmax=0.2
                vvend='both'
                ccmap=cmap2
                boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                boundneg=[-x for x in boundpos]
                boundneg=boundneg[::-1]
                boundneg.append(0.00)
                bounds=boundneg + boundpos
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            ax.set_title(tstr, fontsize=18)
            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=0,urcrnrlon=360,resolution='c')
            map.drawcoastlines(color='black', linewidth=0.2)
            parallels = np.arange(-90.,90,15.)
            meridians = np.arange(0,360,45.)
            map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            x,y=map(lons, lats)
            if ipt<6:
                cs=map.scatter(lons,lats, s=1, c=data, marker='.', cmap=ccmap, norm=norm)
                cb=map.colorbar(cs,"right", size="2%", pad="2%", ticks=bounds,  extend=vvend)
            else:
                #cs=map.scatter(lons,lats, s=1, c=data, marker='.', cmap=ccmap, vmin=vvmin, vmax=vvmax)
                cs=map.scatter(lons,lats, s=1, c=data, marker='.', cmap=ccmap, norm=norm)
                cb=map.colorbar(cs,"right", size="2%", pad="2%", extend=vvend)
    
    fig.suptitle(ptitle, fontsize=18)
    fig.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig('%s-AOD-bias-t1-%s.png' % (aodtyp, str(cyc)))
    plt.close(fig)
    return


def plot_map_scatter_13(snpp_lon, snpp_lat, snpp_obs, \
                        snpp_nodahofx_bckg, snpp_dahofx_bckg, snpp_dahofx_anal, \
                        aqua_lon, aqua_lat, aqua_obs, \
                        aqua_nodahofx_bckg, aqua_dahofx_bckg, aqua_dahofx_anal, \
                        cmapaod, cmapbias, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    ptitle='550 nm Aerosol Optical Depth \n valid at %s/%s/%s (0000-0018 UTC)' % (cm, cd, cy)
    fig=plt.figure(figsize=[20,18]) #,constrained_layout=True)
    for ipt in range(15):
        ax=fig.add_subplot(5, 3, ipt+1)
        if ipt==0:
            text_kwargs = dict(ha='center', va='center', fontsize=16, fontweight="bold")
            plt.text(0.5, 0.5, ptitle, **text_kwargs)
            ax.set_axis_off()
        else:
            if ipt==1:
                data=snpp_obs
                tstr='VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==2:
                data=aqua_obs
                tstr='MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat
            if ipt==3:
                data=snpp_nodahofx_bckg
                tstr='NODA 6hr fcst wrt VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==4:
                data=snpp_dahofx_bckg
                tstr='DA 6hr fcst wrt VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==5:
                data=snpp_dahofx_anal
                tstr='DA analysis wrt VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==6:
                data=aqua_nodahofx_bckg
                tstr='NODA 6hr fcst wrt MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat
            if ipt==7:
                data=aqua_dahofx_bckg
                tstr='DA 6hr fcst wrt MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat
            if ipt==8:
                data=aqua_dahofx_anal
                tstr='DA analysis wrt MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat
            if ipt==9:
                data=snpp_nodahofx_bckg - snpp_obs
                tstr='NODA 6hr fcst bias wrt VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==10:
                data=snpp_dahofx_bckg - snpp_obs
                tstr='DA 6hr fcst bias wrt VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==11:
                data=snpp_dahofx_anal - snpp_obs
                tstr='DA analysis bias wrt VIIRS/SNPP'
                lons=snpp_lon
                lats=snpp_lat
            if ipt==12:
                data=aqua_nodahofx_bckg - aqua_obs
                tstr='NODA 6hr fcst bias wrt MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat
            if ipt==13:
                data=aqua_dahofx_bckg - aqua_obs
                tstr='DA 6hr fcst bias wrt MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat
            if ipt==14:
                data=aqua_dahofx_anal - aqua_obs
                tstr='DA analysis bias wrt MODIS/AQUA'
                lons=aqua_lon
                lats=aqua_lat

            if ipt<9:
                vvend='max'
                ccmap=cmapaod
                bounds=[0.0, 0.1, 0.16, 0.23, 0.29, 0.36, 0.42, 0.49, 0.55, 0.61, 0.68, 0.74, 0.81, 0.87, 1]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
                
            else:
                vvend='both'
                ccmap=cmapbias
                boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                boundneg=[-x for x in boundpos]
                boundneg=boundneg[::-1]
                print(type(boundpos))
                print(type(boundneg))
                boundneg.append(0.00)
                bounds=boundneg + boundpos
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=0,urcrnrlon=360,resolution='c')
            map.drawcoastlines(color='black', linewidth=0.2)
            parallels = np.arange(-90.,90,15.)
            meridians = np.arange(0,360,45.)
            map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            x,y=map(lons, lats)
            cs=map.scatter(lons,lats, s=1, c=data, marker='.', cmap=ccmap, norm=norm)
            ax.set_title(tstr, fontsize=18, fontweight="bold")
            if ipt==8:
                fig.subplots_adjust(right=0.9)
                cbar_ax = fig.add_axes([0.94, 0.57, 0.01, 0.25])
                cb=fig.colorbar(cs, cax=cbar_ax, extend=vvend)
                cb.ax.tick_params(labelsize=16)
                #cb=map.colorbar(cs,"right", size="2%", pad="2%", ticks=bounds,  extend=vvend)
            elif ipt==11:
                fig.subplots_adjust(right=0.9)
                cbar_ax = fig.add_axes([0.94, 0.07, 0.01, 0.25])
                cb=fig.colorbar(cs, cax=cbar_ax, extend=vvend)
                cb.ax.tick_params(labelsize=16)
                #cs=map.scatter(lons,lats, s=1, c=data, marker='.', cmap=ccmap, norm=norm)
                #cb=map.colorbar(cs,"right", size="2%", pad="2%", extend=vvend)
    
    #fig.suptitle(ptitle, fontsize=18)
    fig.tight_layout(rect=[0, 0.00, 0.94, 1.0])
    plt.savefig('VIIRS-MODIS-AOD-bias-%s%s%s.png' % (cy,cm,cd))
    plt.close(fig)
    return

def plot_map_scatter_aod(lons, lats, obs, \
                         nodahofx_bckg, dahofx_bckg, dahofx_anal, \
                         aodtyp, aodcmap, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    if aodtyp=='viirs_npp':
        aodt='VIIRS/SNPP'
        aodp='viirs'
    if aodtyp=='nrt_aqua':
        aodt='MODIS/AQUA'
        aodp='modis'

    ptitle='550 nm Aerosol Optical Depth valid at 0000-0018 UTC %s/%s/%s' % (cm, cd, cy)
    fig=plt.figure(figsize=[8,5.3]) #,constrained_layout=True)
    for ipt in range(4):
        ax=fig.add_subplot(2, 2, ipt+1)
        if ipt==0:
            data=nodahofx_bckg
            tstr='NODA 6hr fcst wrt %s' % (aodt)
        if ipt==1:
            data=obs
            tstr=aodt
        if ipt==2:
            data=dahofx_bckg
            tstr='DA 6hr fcst wrt %s' % (aodt)
        if ipt==3:
            data=dahofx_anal
            tstr='DA analysis wrt %s' % (aodt)

        vvend='max'
        ccmap=aodcmap
        bounds=[0.0, 0.1, 0.16, 0.23, 0.29, 0.36, 0.42, 0.49, 0.55, 0.61, 0.68, 0.74, 0.81, 0.87, 1]
        norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=0,urcrnrlon=360,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-90.,90,15.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        cs=map.scatter(lons,lats, s=0.1, c=data, marker='.', cmap=ccmap, norm=norm)
        ax.set_title(tstr, fontsize=12, fontweight="bold")
        if ipt==3:
            #fig.subplots_adjust(right=0.9)
            cbar_ax = fig.add_axes([0.2, 0.05, 0.6, 0.02])
            cb=fig.colorbar(cs, cax=cbar_ax, orientation='horizontal', extend=vvend)
            cb.ax.tick_params(labelsize=12)
    
    fig.suptitle(ptitle, fontsize=12,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.03, 1.00, 0.90])
    plt.savefig('%sAod.png' % (aodp))
    plt.close(fig)
    return

def plot_map_scatter_bias(lons, lats, obs, \
                         nodahofx_bckg, dahofx_bckg, dahofx_anal, \
                         aodtyp, biascmap, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    if aodtyp=='viirs_npp':
        aodt='VIIRS/SNPP'
        aodp='viirs'
    if aodtyp=='nrt_aqua':
        aodt='MODIS/AQUA'
        aodp='modis'

    ptitle='Bias of 550 nm Aerosol Optical Depth \n valid at 0000-0018 UTC %s/%s/%s' % (cm, cd, cy)
    fig=plt.figure(figsize=[4.5,8.0]) #,constrained_layout=True)
    for ipt in range(3):
        ax=fig.add_subplot(3, 1, ipt+1)
        if ipt==0:
            data=nodahofx_bckg-obs
            tstr='NODA 6hr fcst bias wrt %s' % (aodt)
        if ipt==1:
            data=dahofx_bckg-obs
            tstr='DA 6hr fcst bias wrt %s' % (aodt)
        if ipt==2:
            data=dahofx_anal-obs
            tstr='DA analysis bias wrt %s' % (aodt)

        vvend='both'
        ccmap=biascmap
        boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
        boundneg=[-x for x in boundpos]
        boundneg=boundneg[::-1]
        boundneg.append(0.00)
        bounds=boundneg + boundpos
        norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=0,urcrnrlon=360,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-90.,90,15.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        cs=map.scatter(lons,lats, s=0.1, c=data, marker='.', cmap=ccmap, norm=norm)
        ax.set_title(tstr, fontsize=12, fontweight="bold")
        if ipt==2:
            fig.subplots_adjust(bottom=0.1)
            cbar_ax = fig.add_axes([0.05, 0.04, 0.9, 0.012])
            cb=fig.colorbar(cs, cax=cbar_ax, orientation='horizontal', extend=vvend)
            cb.ax.tick_params(labelsize=9)
    
    fig.suptitle(ptitle, fontsize=12,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.05, 1.00, 0.90])
    #fig.tight_layout
    plt.savefig('%sAodBias.png' % (aodp))
    plt.close(fig)
    return

scyc=int(sys.argv[1])  #2021070900
inc_day=18 # in hour
inc_cyc=6
ecyc=ndate(scyc,inc_day)

topdir='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/'
daexp='global-workflow-CCPP2-Chem-NRT-clean'
nodaexp='global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst'

ntiles=6

#lcol=[[255, 255, 255], [211, 215, 231], [168, 177, 212], \
#      [138, 147, 186], [165, 166, 148], [189, 187, 118], \
#      [215, 206 , 94], [241, 225,  89], [236, 198,  78], \
#      [232, 167,  68], [230, 136,  60], [228, 105,  52], \
#      [229,  79,  46], [230,  58,  43], [129,  57, 195]]

lcol=[[255, 255, 255], [211, 215, 231], [168, 177, 212], \
      [138, 147, 186], [165, 166, 148], [189, 187, 118], \
      [215, 206 , 94], [241, 225,  89], [236, 198,  78], \
      [232, 167,  68], [230, 136,  60], [233, 78,  40], \
      [175,  35,  25], [118,  20,  12], [129,  57, 195]]
acol=np.array(lcol)/255.0
tcol=tuple(map(tuple, acol))
cmapaod_name='aod_list'
cmapaod=mpcrs.LinearSegmentedColormap.from_list(cmapaod_name, tcol, N=16)

#nbar=30
#cbarname='ViBlGrWhYeOrRe_removeWhite'
#mpl=0
#white=0
#reverse=0
#cmapbias=setup_cmap(cbarname,nbar,mpl,white,reverse)

"""
lcol_bias=[[ 46,   0, 192], [ 29,   0, 215], [ 12,   0, 239], \
           [  1,  11, 240], [  2,  45, 195], [  4,  78, 150], \
           [  5, 112, 105], [  7, 145,  60], [ 24, 184,  31], \
           [ 74, 199,  79], [123, 214, 127], [173, 230, 175], \
           [222, 245, 223], [250, 250, 250], [255, 255, 255], \
           [255, 255, 255], [255, 255, 170], [255, 255, 119], \
           [255, 255,  68], [255, 255,  17], [255, 244,   0], \
           [255, 227,   0], [255, 204,   0], [255, 188,   0], \
           [255, 171,   0], [255, 143,   0], [255, 110,   0], \
           [255,  77,   0], [255,  44,   0], [255,   0,   0]]
"""

lcol_bias=[[115,  25, 140], [  50, 40, 105], [  0,  18, 120], [   0,  35, 160], \
           [  0,  30, 210], [  5,  60, 210], [  4,  78, 150], \
           [  5, 112, 105], [  7, 145,  60], [ 24, 184,  31], \
           [ 74, 199,  79], [123, 214, 127], [173, 230, 175], \
           [222, 245, 223], [250, 250, 250], [255, 255, 255], \
           [255, 255, 255], [255, 255, 190], [255, 255, 100], \
           [255, 255,   0], [255, 220,   0], [255, 200,   0], \
           [255, 180,   0], [255, 160,   0], [255, 140,   0], \
           [255, 120,   0], [255,  90,   0], [255,  60,   0], \
           [235,  55,   35], [190,  40, 25], [175,  35,  25], [116,  20,  12]]
acol_bias=np.array(lcol_bias)/255.0
tcol_bias=tuple(map(tuple, acol_bias))
cmapbias_name='aod_bias_list'
cmapbias=mpcrs.LinearSegmentedColormap.from_list(cmapaod_name, tcol_bias, N=30)


aodtyp='viirs_npp'
datadir='%s/%s/dr-data-backup/' % (topdir, nodaexp)
field='nc4.ges'
lon_snpp_nodabckg, lat_snpp_nodabckg, obs_snpp_nodabckg, hfx_snpp_nodabckg=readaod(aodtyp, scyc, ecyc, inc_cyc, datadir, field, ntiles)

datadir='%s/%s/dr-data-backup/' % (topdir, daexp)
field='nc4.ges'
lon_snpp_dabckg, lat_snpp_dabckg, obs_snpp_dabckg, hfx_snpp_dabckg=readaod(aodtyp, scyc, ecyc, inc_cyc, datadir, field, ntiles)

datadir='%s/%s/dr-data-backup/' % (topdir, daexp)
field='nc4'
lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, hfx_snpp_daanal=readaod(aodtyp, scyc, ecyc, inc_cyc, datadir, field, ntiles)

lon_snpp_daanal = ((360 + (lon_snpp_daanal % 360)) % 360)
plot_map_scatter_aod(lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, \
                     hfx_snpp_nodabckg, hfx_snpp_dabckg, hfx_snpp_daanal,  \
                     aodtyp, cmapaod, scyc)
plot_map_scatter_bias(lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, \
                     hfx_snpp_nodabckg, hfx_snpp_dabckg, hfx_snpp_daanal,  \
                     aodtyp, cmapbias, scyc)
"""
plot_map_scatter_7(lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, \
                   hfx_snpp_nodabckg, hfx_snpp_dabckg, hfx_snpp_daanal, \
                   aodtyp, cmapaod, cmapbias, scyc)
"""

aodtyp='nrt_aqua'
datadir='%s/%s/dr-data-backup/' % (topdir, nodaexp)
field='nc4.ges'
lon_aqua_nodabckg, lat_aqua_nodabckg, obs_aqua_nodabckg, hfx_aqua_nodabckg=readaod(aodtyp, scyc, ecyc, inc_cyc, datadir, field, ntiles)

datadir='%s/%s/dr-data-backup/' % (topdir, daexp)
field='nc4.ges'
lon_aqua_dabckg, lat_aqua_dabckg, obs_aqua_dabckg, hfx_aqua_dabckg=readaod(aodtyp, scyc, ecyc, inc_cyc, datadir, field, ntiles)

datadir='%s/%s/dr-data-backup/' % (topdir, daexp)
field='nc4'
lon_aqua_daanal, lat_aqua_daanal, obs_aqua_daanal, hfx_aqua_daanal=readaod(aodtyp, scyc, ecyc, inc_cyc, datadir, field, ntiles)

lon_aqua_daanal = ((360 + (lon_aqua_daanal % 360)) % 360)
plot_map_scatter_aod(lon_aqua_daanal, lat_aqua_daanal, obs_aqua_daanal, \
                     hfx_aqua_nodabckg, hfx_aqua_dabckg, hfx_aqua_daanal,  \
                     aodtyp, cmapaod, scyc)
plot_map_scatter_bias(lon_aqua_daanal, lat_aqua_daanal, obs_aqua_daanal, \
                     hfx_aqua_nodabckg, hfx_aqua_dabckg, hfx_aqua_daanal,  \
                     aodtyp, cmapbias, scyc)

"""
plot_map_scatter_13(lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, \
                    hfx_snpp_nodabckg, hfx_snpp_dabckg, hfx_snpp_daanal, \
                    lon_aqua_daanal, lat_aqua_daanal, obs_aqua_daanal, \
                    hfx_aqua_nodabckg, hfx_aqua_dabckg, hfx_aqua_daanal, \
                    cmapaod, cmapbias, scyc)
		    """
quit()

