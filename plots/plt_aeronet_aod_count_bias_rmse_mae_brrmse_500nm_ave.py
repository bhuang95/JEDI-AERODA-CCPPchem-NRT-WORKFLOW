import sys,os
from scipy.stats import gaussian_kde
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
import numpy as np
import math
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mpcrs
import matplotlib.cm as cm

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

def read_aeronet_aod_bias_rmse(datafile):
    f=open(datafile,'r')
    iline=0
    lonvec=[]
    latvec=[]
    cntvec=[]
    obsvec=[]
    hfxvec=[]
    biasvec=[]
    rmsevec=[]
    maevec=[]
    brrmsevec=[]
    for line in f.readlines():
        lon=float(line.split()[0])
        lat=float(line.split()[1])
        cnt=float(line.split()[2])
        obs=float(line.split()[3])
        hfx=float(line.split()[4])
        bias=float(line.split()[5])
        rmse=float(line.split()[6])
        mae=float(line.split()[7])
        brrmse=float(line.split()[8])
        if ~np.isnan(obs):
            lonvec.append(lon)
            latvec.append(lat)
            cntvec.append(cnt)
            obsvec.append(obs)
            hfxvec.append(hfx)
            biasvec.append(bias)
            rmsevec.append(rmse)
            maevec.append(mae)
            brrmsevec.append(brrmse)
        iline=iline+1
    f.close()
    return np.array(lonvec), np.array(latvec), np.array(cntvec), np.array(obsvec), np.array(hfxvec), np.array(biasvec), np.array(rmsevec), np.array(maevec), np.array(brrmsevec)

def read_aeronet_aod_averaged_bias_rmse(datafile):
    f=open(datafile,'r')
    for line in f.readlines():
        biasave = float(line.split()[0])
        rmseave = float(line.split()[1])
        maeave = float(line.split()[2])
        brrmseave = float(line.split()[3])
    f.close()
    return biasave, rmseave, maeave, brrmseave

def plot_map_aeronet_aod_bias_rmse(lons, lats, obss, counts, \
                                   noda_bckg_b, noda_bckg_r, \
                                   da_bckg_b, da_bckg_r, \
                                   da_anal_b, da_anal_r, \
                                   noda_bckg_b_ave, noda_bckg_r_ave, \
                                   da_bckg_b_ave, da_bckg_r_ave, \
                                   da_anal_b_ave, da_anal_r_ave, \
                                   aodcmap, biascmap, rmsecmap, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    aodt='AERONET'
    ptitle='500 nm Aerosol Optical Depth (AOD) bias (left) and RMSE (right) wrt AERONET \n aggregated over 30 days before and at 00%s UTC %s/%s/%s' % (ch, cm, cd, cy)
    fig=plt.figure(figsize=[10,12])
    for ipt in range(8):
        ax=fig.add_subplot(4, 2, ipt+1)
        if ipt==0:
            data=obss
            tstr='AERONET 500 nm AOD'
        if ipt==1:
            data=counts
            tstr="AERONET 500 nm AOD counts"
        if ipt==2:
            data=noda_bckg_b
            mdata=np.mean(data)
            mstr='mean bias = %s' % str("%.4f" % noda_bckg_b_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % noda_bckg_b_ave))
            tstr='NODA 6hr fcst bias wrt %s \n (%s)' % (aodt, mstr)
        if ipt==3:
            data=noda_bckg_r
            mdata=np.mean(data)
            mstr='mean RMSE = %s' % str("%.4f" % noda_bckg_r_ave)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % noda_bckg_r_ave))
            tstr='NODA 6hr fcst RMSE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==4:
            data=da_bckg_b
            mdata=np.mean(data)
            mstr='mean bias = %s' % str("%.4f" % da_bckg_b_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_bckg_b_ave))
            tstr='DA 6hr fcst bias wrt %s \n (%s)' % (aodt, mstr)
        if ipt==5:
            data=da_bckg_r
            mdata=np.mean(data)
            mstr='mean RMSE = %s' % str("%.4f" % da_bckg_r_ave)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_bckg_r_ave))
            tstr='DA 6hr fcst RMSE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==6:
            data=da_anal_b
            mdata=np.mean(data)
            mstr='mean bias = %s' % str("%.4f" % da_anal_b_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_anal_b_ave))
            tstr='DA analysis bias wrt %s \n (%s)' % (aodt, mstr)
        if ipt==7:
            data=da_anal_r
            mdata=np.mean(data)
            mstr='mean RMSE = %s' % str("%.4f" % da_anal_r_ave)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_anal_r_ave))
            tstr='DA analysis RMSE wrt %s \n (%s)' % (aodt, mstr)
        
        if ipt==0:
            vvend='max'
            ccmap=aodcmap
            bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==1:
            vvend='max'
            ccmap=aodcmap
        elif ipt==2 or ipt==4 or ipt==6:
            vvend='both'
            ccmap=biascmap
            boundpos=[0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
            boundneg=[-x for x in boundpos]
            boundneg=boundneg[::-1]
            boundneg.append(0.00)
            bounds=boundneg + boundpos
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==3 or ipt==5 or ipt==7:
            vvend='max'
            ccmap=rmsecmap
            bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
           
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-90.,90,15.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        if ipt==1:
            cs=map.scatter(lons,lats, s=8, c=data, marker='.', cmap=ccmap)
        else:
            cs=map.scatter(lons,lats, s=8, c=data, marker='.', cmap=ccmap, norm=norm)

        cb=map.colorbar(cs,"right", size="2%", pad="2%", extend=vvend)
        ax.set_title(tstr, fontsize=14, fontweight="bold")

    fig.suptitle(ptitle, fontsize=14,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.00, 1.00, 0.90])
    plt.savefig('%s_AOD_BIAS_RMSE_full_0m_f000.png' % (aodt))
    plt.close(fig)
    return

def plot_map_aeronet_aod_mae_brrmse(lons, lats, obss, counts, \
                                   noda_bckg_a, noda_bckg_r, \
                                   da_bckg_a, da_bckg_r, \
                                   da_anal_a, da_anal_r, \
                                   noda_bckg_a_ave, noda_bckg_r_ave, \
                                   da_bckg_a_ave, da_bckg_r_ave, \
                                   da_anal_a_ave, da_anal_r_ave, \
                                   aodcmap, maecmap, rmsecmap, cyc):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    aodt='AERONET'
    ptitle='500 nm Aerosol Optical Depth (AOD) MAE (left) and bias-removed RMSE (right) \n wrt AERONET aggregated over 30 days before and at 00%s UTC %s/%s/%s' % (ch, cm, cd, cy)
    fig=plt.figure(figsize=[10,12])
    for ipt in range(8):
        ax=fig.add_subplot(4, 2, ipt+1)
        if ipt==0:
            data=obss
            tstr='AERONET 500 nm AOD'
        if ipt==1:
            data=counts
            tstr="AERONET 500 nm AOD counts"
        if ipt==2:
            data=noda_bckg_a
            mdata=np.mean(data)
            mstr='mean MAE = %s' % str("%.4f" % noda_bckg_a_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % noda_bckg_b_ave))
            tstr='NODA 6hr fcst MAE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==3:
            data=noda_bckg_r
            mdata=np.mean(data)
            mstr='mean brRMSE = %s' % str("%.4f" % noda_bckg_r_ave)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % noda_bckg_r_ave))
            tstr='NODA 6hr fcst brRMSE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==4:
            data=da_bckg_a
            mdata=np.mean(data)
            mstr='mean MAE = %s' % str("%.4f" % da_bckg_a_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_bckg_b_ave))
            tstr='DA 6hr fcst MAE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==5:
            data=da_bckg_r
            mdata=np.mean(data)
            mstr='mean brRMSE = %s' % str("%.4f" % da_bckg_r_ave)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_bckg_r_ave))
            tstr='DA 6hr fcst brRMSE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==6:
            data=da_anal_a
            mdata=np.mean(data)
            mstr='mean MAE = %s' % str("%.4f" % da_anal_a_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_anal_b_ave))
            tstr='DA analysis MAE wrt %s \n (%s)' % (aodt, mstr)
        if ipt==7:
            data=da_anal_r
            mdata=np.mean(data)
            mstr='mean brRMSE = %s' % str("%.4f" % da_anal_r_ave)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_anal_r_ave))
            tstr='DA analysis brRMSE wrt %s \n (%s)' % (aodt, mstr)
        
        if ipt==0:
            vvend='max'
            ccmap=aodcmap
            bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==1:
            vvend='max'
            ccmap=aodcmap
        elif ipt==2 or ipt==4 or ipt==6:
            vvend='max'
            ccmap=maecmap
            bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==3 or ipt==5 or ipt==7:
            vvend='max'
            ccmap=maecmap
            bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
           
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-90.,90,15.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        if ipt==1:
            cs=map.scatter(lons,lats, s=8, c=data, marker='.', cmap=ccmap)
        else:
            cs=map.scatter(lons,lats, s=8, c=data, marker='.', cmap=ccmap, norm=norm)
        cb=map.colorbar(cs,"right", size="2%", pad="2%", extend=vvend)
        ax.set_title(tstr, fontsize=14, fontweight="bold")

    fig.suptitle(ptitle, fontsize=14,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.00, 1.00, 0.90])
    plt.savefig('%s_AOD_MAE_BRRMSE_full_0m_f000.png' % (aodt))
    plt.close(fig)
    return


wav='500' 
aodtyp='AERONET'
sensor='aeronet'
fs=open('DATES.info', 'r')
fe=open('DATEE.info', 'r')
cycs=fs.read().replace('\n', '')
cyce=fe.read().replace('\n', '')
fs.close()
fe.close()

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
cmapbias=mpcrs.LinearSegmentedColormap.from_list(cmapbias_name, tcol_bias, N=32)

cmaprmse=cmapaod
cmapmae=cmapaod

cyc2='%s-%s'  % (cycs, cyce)


expname='global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst'
field='cntlBckg'
datafile='./%s-%s-%sAOD-%s-collect-lon-lat-count-obs-hofx-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
          % (expname, field, aodtyp, sensor, cyc2, wav)
noda_bckg_lon, noda_bckg_lat, noda_bckg_cnt, noda_bckg_obs, noda_bckg_hfx, noda_bckg_bias, noda_bckg_rmse, noda_bckg_mae, noda_bckg_brrmse = read_aeronet_aod_bias_rmse(datafile)
datafile='./%s-%s-%sAOD-%s-averaged-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
          % (expname, field, aodtyp, sensor, cyc2, wav)
noda_bckg_bias_ave, noda_bckg_rmse_ave, noda_bckg_mae_ave, noda_bckg_brrmse_ave = read_aeronet_aod_averaged_bias_rmse(datafile)

expname='global-workflow-CCPP2-Chem-NRT-clean'
field='cntlBckg'
datafile='./%s-%s-%sAOD-%s-collect-lon-lat-count-obs-hofx-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
          % (expname, field, aodtyp, sensor, cyc2, wav)
da_bckg_lon, da_bckg_lat, da_bckg_cnt, da_bckg_obs, da_bckg_hfx, da_bckg_bias, da_bckg_rmse, da_bckg_mae, da_bckg_brrmse = read_aeronet_aod_bias_rmse(datafile)
datafile='./%s-%s-%sAOD-%s-averaged-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
          % (expname, field, aodtyp, sensor, cyc2, wav)
da_bckg_bias_ave, da_bckg_rmse_ave, da_bckg_mae_ave, da_bckg_brrmse_ave = read_aeronet_aod_averaged_bias_rmse(datafile)

expname='global-workflow-CCPP2-Chem-NRT-clean'
field='cntlAnal'
datafile='./%s-%s-%sAOD-%s-collect-lon-lat-count-obs-hofx-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
          % (expname, field, aodtyp, sensor, cyc2, wav)
da_anal_lon, da_anal_lat, da_anal_cnt, da_anal_obs, da_anal_hfx, da_anal_bias, da_anal_rmse, da_anal_mae, da_anal_brrmse = read_aeronet_aod_bias_rmse(datafile)
datafile='./%s-%s-%sAOD-%s-averaged-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
          % (expname, field, aodtyp, sensor, cyc2, wav)
da_anal_bias_ave, da_anal_rmse_ave, da_anal_mae_ave, da_anal_brrmse_ave = read_aeronet_aod_averaged_bias_rmse(datafile)

plot_map_aeronet_aod_bias_rmse(noda_bckg_lon, noda_bckg_lat, noda_bckg_obs, noda_bckg_cnt, \
                           noda_bckg_bias, noda_bckg_rmse,                                 
                           da_bckg_bias, da_bckg_rmse,                                 
                           da_anal_bias, da_anal_rmse,                                 
                           noda_bckg_bias_ave, noda_bckg_rmse_ave,                                 
                           da_bckg_bias_ave, da_bckg_rmse_ave,                                 
                           da_anal_bias_ave, da_anal_rmse_ave,                                 
                           cmapaod, cmapbias, cmaprmse, cyce)
          
plot_map_aeronet_aod_mae_brrmse(noda_bckg_lon, noda_bckg_lat, noda_bckg_obs, noda_bckg_cnt, \
                           noda_bckg_mae, noda_bckg_brrmse,                                 
                           da_bckg_mae, da_bckg_brrmse,                                 
                           da_anal_mae, da_anal_brrmse,                                 
                           noda_bckg_mae_ave, noda_bckg_brrmse_ave,                                 
                           da_bckg_mae_ave, da_bckg_brrmse_ave,                                 
                           da_anal_mae_ave, da_anal_brrmse_ave,                                 
                           cmapaod, cmapmae, cmaprmse, cyce)

exit
