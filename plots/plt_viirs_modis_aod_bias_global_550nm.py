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

def plot_map_scatter_aod_viirs_modis(lons_v, lats_v, obs_v, \
                         nodahofx_bckg_v, dahofx_bckg_v, dahofx_anal_v, \
                         lons_m, lats_m, obs_m, \
                         nodahofx_bckg_m, dahofx_bckg_m, dahofx_anal_m, \
                         aodcmap, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    aodt_v='VIIRS/SNPP'
    aodt_m='MODIS/AQUA'
    aodp_v='VIIRS'
    aodp_m='MODIS'
    ptitle='550 nm Aerosol Optical Depth (AOD) wrt VIIRS/SNPP (left) and MODIS/AQUA (right) \n aggregated on %s/%s/%s' % (cm, cd, cy)
    fig=plt.figure(figsize=[10,12]) 
    for ipt in range(8):
        ax=fig.add_subplot(4, 2, ipt+1)
        if ipt==0:
            data=obs_v
            tstr='%s 550 nm AOD' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==1:
            data=obs_m
            tstr='%s 550 nm AOD' % (aodt_m)
            lons=lons_m
            lats=lats_m
        if ipt==2:
            data=nodahofx_bckg_v
            tstr='NODA 6hr fcst wrt %s' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==3:
            data=nodahofx_bckg_m
            tstr='NODA 6hr fcst wrt %s' % (aodt_m)
            lons=lons_m
            lats=lats_m
        if ipt==4:
            data=dahofx_bckg_v
            tstr='DA 6hr fcst wrt %s' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==5:
            data=dahofx_bckg_m
            tstr='DA 6hr fcst wrt %s' % (aodt_m)
            lons=lons_m
            lats=lats_m
        if ipt==6:
            data=dahofx_anal_v
            tstr='DA analysis wrt %s' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==7:
            data=dahofx_anal_m
            tstr='DA analysis wrt %s' % (aodt_m)
            lons=lons_m
            lats=lats_m

        vvend='max'
        ccmap=aodcmap
        bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
        norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-90.,90,15.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        cs=map.scatter(lons,lats, s=0.1, c=data, marker='.', cmap=ccmap, norm=norm)
        ax.set_title(tstr, fontsize=14, fontweight="bold")
        if ipt==3:
            fig.subplots_adjust(right=0.90)
            cbar_ax = fig.add_axes([0.90, 0.15, 0.015, 0.6])
            cb=fig.colorbar(cs, cax=cbar_ax, ticks=bounds[::2], extend=vvend)
            cb.ax.tick_params(labelsize=14)
    
    fig.suptitle(ptitle, fontsize=14,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.00, 0.90, 0.90])
    plt.savefig('%s_%s_AOD_full_0m_f000.png' % (aodp_v, aodp_m))
    plt.close(fig)
    return

def plot_map_scatter_aod_bias_viirs_modis(lons_v, lats_v, obs_v, \
                         nodahofx_bckg_v, dahofx_bckg_v, dahofx_anal_v, \
                         lons_m, lats_m, obs_m, \
                         nodahofx_bckg_m, dahofx_bckg_m, dahofx_anal_m, \
                         biascmap, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    aodt_v='VIIRS/SNPP'
    aodt_m='MODIS/AQUA'
    aodp_v='VIIRS'
    aodp_m='MODIS'
    ptitle='550 nm Aerosol Optical Depth Bias (AOD) wrt VIIRS/SNPP (left) and MODIS/AQUA (right) \n aggregated on %s/%s/%s' % (cm, cd, cy)
   
    fig=plt.figure(figsize=[10,8])
    for ipt in range(6):
        ax=fig.add_subplot(3, 2, ipt+1)
        if ipt==0:
            data=nodahofx_bckg_v - obs_v
            tstr='NODA 6hr fcst bias wrt %s' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==1:
            data=nodahofx_bckg_m - obs_m
            tstr='NODA 6hr fcst bias wrt %s' % (aodt_m)
            lons=lons_m
            lats=lats_m
        if ipt==2:
            data=dahofx_bckg_v - obs_v
            tstr='DA 6hr fcst bias wrt %s' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==3:
            data=dahofx_bckg_m - obs_m
            tstr='DA 6hr fcst bias wrt %s' % (aodt_m)
            lons=lons_m
            lats=lats_m
        if ipt==4:
            data=dahofx_anal_v - obs_v
            tstr='DA analysis bias wrt %s' % (aodt_v)
            lons=lons_v
            lats=lats_v
        if ipt==5:
            data=dahofx_anal_m - obs_m
            tstr='DA analysis bias wrt %s' % (aodt_m)
            lons=lons_m
            lats=lats_m

        vvend='both'
        ccmap=biascmap
        boundpos=[0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
        boundneg=[-x for x in boundpos]
        boundneg=boundneg[::-1]
        boundneg.append(0.00)
        bounds=boundneg + boundpos
        norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-90.,90,15.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        cs=map.scatter(lons,lats, s=0.1, c=data, marker='.', cmap=ccmap, norm=norm)
        ax.set_title(tstr, fontsize=12, fontweight="bold")
        if ipt==3:
            fig.subplots_adjust(right=0.90)
            cbar_ax = fig.add_axes([0.90, 0.1, 0.015, 0.7])
            cb=fig.colorbar(cs, cax=cbar_ax,  ticks=bounds[::2], extend=vvend)
            cb.ax.tick_params(labelsize=12)
    
    fig.suptitle(ptitle, fontsize=12,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.00, 0.90, 0.90])
    plt.savefig('%s_%s_AOD_BIAS_full_0m_f000.png' % (aodp_v, aodp_m))
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

nbars=21
cbarname='WhiteBlueGreenYellowRed-v1'
mpl=0
white=-1
reverse=0
cmapaod=setup_cmap(cbarname,nbars,mpl,white,reverse)

lcol_bias=[[115,  25, 140], [  50, 40, 105], [  0,  18, 120], [   0,  35, 160], \
           [  0,  30, 210], [  5,  60, 210], [  4,  78, 150], \
           [  5, 112, 105], [  7, 145,  60], [ 24, 184,  31], \
           [ 74, 199,  79], [123, 214, 127], [173, 230, 175], \
           [222, 245, 223], [250, 250, 250], [255, 255, 255], \
           [255, 255, 255], [255, 255, 210], [255, 255, 150], \
           [255, 255,   0], [255, 220,   0], [255, 200,   0], \
           [255, 180,   0], [255, 160,   0], [255, 140,   0], \
           [255, 120,   0], [255,  90,   0], [255,  60,   0], \
           [235,  55,   35], [190,  40, 25], [175,  35,  25], [116,  20,  12]]
acol_bias=np.array(lcol_bias)/255.0
tcol_bias=tuple(map(tuple, acol_bias))
cmapbias_name='aod_bias_list'
cmapbias=mpcrs.LinearSegmentedColormap.from_list(cmapbias_name, tcol_bias, N=35)


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

plot_map_scatter_aod_viirs_modis(lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, \
                                 hfx_snpp_nodabckg, hfx_snpp_dabckg, hfx_snpp_daanal, \
                                 lon_aqua_daanal, lat_aqua_daanal, obs_aqua_daanal, \
                                 hfx_aqua_nodabckg, hfx_aqua_dabckg, hfx_aqua_daanal, \
                                 cmapaod, scyc)

plot_map_scatter_aod_bias_viirs_modis(lon_snpp_daanal, lat_snpp_daanal, obs_snpp_daanal, \
                                 hfx_snpp_nodabckg, hfx_snpp_dabckg, hfx_snpp_daanal, \
                                 lon_aqua_daanal, lat_aqua_daanal, obs_aqua_daanal, \
                                 hfx_aqua_nodabckg, hfx_aqua_dabckg, hfx_aqua_daanal, \
                                 cmapbias, scyc)

quit()

