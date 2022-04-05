import sys,os
from scipy.stats import gaussian_kde
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt

def readsample(datafile):
    
    try: 
        f=open(datafile,'r')
    except OSError:
        print('Cannot open file: ', datafile)
        quit()

    iline=0
    obsvec=[]
    hfxvec=[]
    for line in f.readlines():
        obs=float(line.split()[2])
        hfx=float(line.split()[3])
        if ~np.isnan(obs):
            obsvec.append(obs)
            hfxvec.append(hfx)
        iline=iline+1
    f.close()
    return obsvec, hfxvec

def calcpdf(data1, data2):
    den=np.vstack([data1,data2])
    z=gaussian_kde(den)(den)
    idx = z.argsort()
    data1, data2, z = data1[idx.astype(int)], data2[idx.astype(int)], z[idx.astype(int)]
    zmax=z[-1]
    return data1, data2, z, zmax
    

def plot_scatter_density(obs, nodabckg, dabckg, daanal, xmax, bmax, cycs, cyce):
    obs_nodabckg_kde, nodabckg_kde, nodabckg_z, nodabckg_zmax=calcpdf(obs, nodabckg)
    obs_dabckg_kde, dabckg_kde, dabckg_z, dabckg_zmax=calcpdf(obs, dabckg)
    obs_daanal_kde, daanal_kde, daanal_z, daanal_zmax=calcpdf(obs, daanal)
    bmax1=int(max([nodabckg_zmax, dabckg_zmax, daanal_zmax]))
    bmax=5*round(bmax1/5)

    csy=str(cycs)[:4]
    csm=str(cycs)[4:6]
    csd=str(cycs)[6:8]
    csh=str(cycs)[8:]

    cey=str(cyce)[:4]
    cem=str(cyce)[4:6]
    ced=str(cyce)[6:8]
    ceh=str(cyce)[8:]

    ptitle='500 nm Aerosol Optical Depth (AOD) wrt AERONET \n aggregated over 30 days before and at 00%s UTC %s/%s/%s' % (ceh, cem, ced, cey)
    #fig=plt.figure(figsize=[20,8])
    fig=plt.figure(figsize=[10,4])
    xlabstr='AERONET 500 nm AOD'
    ylabstr='Modeled 500 nm AOD'
    for ipt in range(3):
        if ipt==0:
            obs=obs_nodabckg_kde
            hfx=nodabckg_kde
            z=nodabckg_z
            tstr='NODA 6hr fcst'
        if ipt==1:
            obs=obs_dabckg_kde
            hfx=dabckg_kde
            z=dabckg_z
            tstr='DA 6hr fcst'
        if ipt==2:
            obs=obs_daanal_kde
            hfx=daanal_kde
            z=daanal_z
            tstr='DA analysis'

        correlation_matrix = np.corrcoef(obs, hfx)
        correlation_xy = correlation_matrix[0,1]
        r_squared = correlation_xy**2
        bias=np.mean(hfx)-np.mean(obs)

        ax=fig.add_subplot(1,3,ipt+1)
        sc=plt.scatter(obs, hfx, c=z, s=1., cmap='jet', marker='o', vmin=0, vmax=bmax, )

        plt.plot([0.0, xmax],[0.0, xmax], color='gray', linewidth=2, linestyle='--')
        plt.xlim(0.01, xmax)
        plt.ylim(0.01, xmax)

        R2str='R\u00b2 = %s' % (str("%.4f" % r_squared))
        biasstr='bias = %s' % str("%.4f" % bias)
        ttname= '%s \n(%s, %s)' % (tstr, R2str, biasstr)
        ax.set_title(ttname, fontsize=10, fontweight="bold")

        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.set_aspect('equal')

        plt.grid(alpha=0.5)
        plt.xlabel(xlabstr, fontsize=10)
        plt.ylabel(ylabstr, fontsize=10)
        plt.xticks(fontsize=10)
        plt.yticks(fontsize=10)

    fig.suptitle(ptitle, fontsize=12, fontweight="bold")
    fig.subplots_adjust(right=0.9)
    cbar_ax = fig.add_axes([0.95, 0.12, 0.015, 0.6])
    cb=fig.colorbar(sc, cax=cbar_ax, extend='max')
    cb.ax.tick_params(labelsize=8)
    fig.tight_layout(rect=[0, 0.05, 0.95, 0.8])
    plt.savefig('AERONET-AOD_full_0m_f000.png', format='png')
    plt.close(fig)
    return

daexp='global-workflow-CCPP2-Chem-NRT-clean'
nodaexp='global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst'
aodtyp='AERONET'
sensor='aeronet'
wav='500'
xmax=1.5
bmax=100


fs=open('DATES.info', 'r')
fe=open('DATEE.info', 'r')
cycs=fs.read().replace('\n', '')
cyce=fe.read().replace('\n', '')
fs.close()
fe.close()

cyc='%s-%s'  % (cycs, cyce)

datafile='./%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
              % (daexp, 'cntlBckg', aodtyp, sensor, cyc, wav)
dabckg_obs1, dabckg_hfx1=readsample(datafile)
datafile='./%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
              % (daexp, 'cntlAnal', aodtyp, sensor, cyc, wav)
daanal_obs1, daanal_hfx1=readsample(datafile)
datafile='./%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
              % (nodaexp, 'cntlBckg', aodtyp, sensor, cyc, wav)
nodabckg_obs1, nodabckg_hfx1=readsample(datafile)

dabckg_obs=np.array(dabckg_obs1)
dabckg_hfx=np.array(dabckg_hfx1)
daanal_hfx=np.array(daanal_hfx1)
nodabckg_hfx=np.array(nodabckg_hfx1)

vinds=np.where((dabckg_obs>=0.01) & (dabckg_hfx>=0.01) \
             & (daanal_hfx>=0.01) & (nodabckg_hfx>=0.01))

obsarr=dabckg_obs[vinds]
dabckgarr=dabckg_hfx[vinds]
daanalarr=daanal_hfx[vinds]
nodabckgarr=nodabckg_hfx[vinds]

plot_scatter_density(obsarr,nodabckgarr, dabckgarr, daanalarr, xmax, bmax, cycs,cyce)
quit()
