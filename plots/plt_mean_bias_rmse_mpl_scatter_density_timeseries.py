import sys,os
from scipy.stats import gaussian_kde
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import mpl_scatter_density
from matplotlib.colors import LinearSegmentedColormap
from astropy.visualization import LogStretch
from astropy.visualization.mpl_normalize import ImageNormalize

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
    

def plot_scatter_density(obs, nodabckg, daanal, xmax, bmax, season):
    #obs_nodabckg_kde, nodabckg_kde, nodabckg_z, nodabckg_zmax=calcpdf(obs, nodabckg)
    #obs_dabckg_kde, dabckg_kde, dabckg_z, dabckg_zmax=calcpdf(obs, dabckg)
    #obs_daanal_kde, daanal_kde, daanal_z, daanal_zmax=calcpdf(obs, daanal)
    #bmax1=int(max([nodabckg_zmax, dabckg_zmax, daanal_zmax]))
    #bmax=5*round(bmax1/5)

    #csy=str(cycs)[:4]
    #csm=str(cycs)[4:6]
    #csd=str(cycs)[6:8]
    #csh=str(cycs)[8:]

    #cey=str(cyce)[:4]
    #cem=str(cyce)[4:6]
    #ced=str(cyce)[6:8]
    #ceh=str(cyce)[8:]

    #fig=plt.figure(figsize=[20,8])
    xlabstr='AERONET 500 nm AOD'
    ylabstr='GEFS 500 nm AOD'
    for ipt in range(2):
        if ipt == 0:
            hfx=nodabckg
            expname='noda_AOD20'
        if ipt == 1:
            hfx=daanal
            expname='anal_AOD20'

        fig=plt.figure(figsize=[4,4])
        correlation_matrix = np.corrcoef(obs, hfx)
        correlation_xy = correlation_matrix[0,1]
        r_squared = correlation_xy**2
        bias=np.mean(hfx)-np.mean(obs)
        ssize=len(obs)

        ax=fig.add_subplot(1,1,1)
        #sc=plt.scatter(obs, hfx, c=z, s=1., cmap='jet', marker='o', vmin=0, vmax=bmax, )
        sc=plt.scatter(obs, hfx, color='blue', marker='o', s=1,  vmin=0, vmax=bmax, norm=norm)

        plt.plot([0.0, xmax],[0.0, xmax], color='gray', linewidth=2, linestyle='--')
        plt.xlim(0.01, xmax)
        plt.ylim(0.01, xmax)

        R2str='R\u00b2 = %s' % (str("%.3f" % r_squared))
        biasstr='Bias = %s' % (str("%.3f" % bias))
        sizestr='N = %s' % (str("%.0f" % ssize))
        #ttname= '%s \n(%s, %s)' % (tstr, R2str, biasstr)
        #ax.set_title(ttname, fontsize=10, fontweight="bold")

        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.set_aspect('equal')

        plt.grid(alpha=0.5)
        plt.xlabel(xlabstr, fontsize=11)
        plt.ylabel(ylabstr, fontsize=11)
        plt.xticks(fontsize=10)
        plt.yticks(fontsize=10)
        ax.annotate(sizestr, (0.012, 7), ha='left', va='center', fontsize=12,fontweight="bold")
        ax.annotate(biasstr, (0.012, 4.0), ha='left', va='center', fontsize=12,fontweight="bold")
        ax.annotate(R2str, (0.012, 2.2), ha='left', va='center', fontsize=12,fontweight="bold")

        #fig.suptitle(ptitle, fontsize=12, fontweight="bold")
        #fig.subplots_adjust(right=0.9)
        #cbar_ax = fig.add_axes([0.95, 0.22, 0.015, 0.6])
        #cb=fig.colorbar(sc, cax=cbar_ax, extend='max')
        #cb.ax.tick_params(labelsize=10)
        #fig.tight_layout(rect=[0, 0.00, 0.95, 1.0])
        fig.tight_layout()
        plt.savefig('%s_%s.png'%(expname, season), format='png')
        plt.close(fig)
        outfile='Stats_%s_%s_N_Bias_R2.txt'%(expname, season)
        np.savetxt(outfile, [ssize,bias,r_squared], delimiter='\b')
    return

def plot_mpl_scatter_density(obs, nodabckg, daanal, xmax, bmax, season):
    xlabstr='AERONET 500 nm AOD'
    ylabstr='GEFS 500 nm AOD'
    for ipt in range(2):
        if ipt == 0:
            hfx=nodabckg
            expname='noda_AOD20'
        if ipt == 1:
            hfx=daanal
            expname='anal_AOD20'

        fig=plt.figure(figsize=[4,4])
        correlation_matrix = np.corrcoef(obs, hfx)
        correlation_xy = correlation_matrix[0,1]
        r_squared = correlation_xy**2
        bias=np.mean(hfx)-np.mean(obs)
        ssize=len(obs)
        norm = ImageNormalize(vmin=0., vmax=bmax, stretch=LogStretch())

        ax=fig.add_subplot(1,1,1, projection='scatter_density')
        #sc=plt.scatter(obs, hfx, c=z, s=1., cmap='jet', marker='o', vmin=0, vmax=bmax, )
        sc=ax.scatter_density(obs, hfx, dpi=40, cmap=white_jet,  vmin=0, vmax=bmax, norm=norm)

        plt.plot([0.0, xmax],[0.0, xmax], color='gray', linewidth=2, linestyle='--')
        plt.xlim(0.01, xmax)
        plt.ylim(0.01, xmax)

        R2str='R\u00b2 = %s' % (str("%.3f" % r_squared))
        biasstr='Bias = %s' % (str("%.3f" % bias))
        sizestr='N = %s' % (str("%.0f" % ssize))
        #ttname= '%s \n(%s, %s)' % (tstr, R2str, biasstr)
        #ax.set_title(ttname, fontsize=10, fontweight="bold")

        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.set_aspect('equal')

        plt.grid(alpha=0.5)
        plt.xlabel(xlabstr, fontsize=11)
        plt.ylabel(ylabstr, fontsize=11)
        plt.xticks(fontsize=10)
        plt.yticks(fontsize=10)
        #ax.annotate(sizestr, (0.012, 7), ha='left', va='center', fontsize=12,fontweight="bold")
        #ax.annotate(biasstr, (0.012, 4.0), ha='left', va='center', fontsize=12,fontweight="bold")
        #ax.annotate(R2str, (0.012, 2.2), ha='left', va='center', fontsize=12,fontweight="bold")

        #fig.suptitle(ptitle, fontsize=12, fontweight="bold")
        #fig.subplots_adjust(right=0.9)
        #cbar_ax = fig.add_axes([0.95, 0.22, 0.015, 0.6])
        #cb=fig.colorbar(sc, cax=cbar_ax, extend='max')
        #cb.ax.tick_params(labelsize=10)
        #fig.tight_layout(rect=[0, 0.00, 0.95, 1.0])
        fig.tight_layout()
        plt.savefig('%s_%s.png'%(expname, season), format='png')
        plt.close(fig)
        outfile='Stats_%s_%s_N_Bias_R2.txt'%(expname, season)
        np.savetxt(outfile, [ssize,bias,r_squared], delimiter='\b')
    return

daexp='anal_AOD20'
nodaexp='noda_AOD20'
datadir='/work/noaa/gsd-fv3-dev/bhuang/JEDI-FV3/expRuns/PaperPlots/Reanalysis/Aeronet/plots_months/data/'
seasons=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
aodtyp='AERONET'
sensor='aeronet'
wav='500'
xmax=5.0
bmax=100


noda_bias=list()
noda_r2=list()
anal_bias=list()
anal_r2=list()
for season in seasons:
    print(season)
    datafile='%s/%s/%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
                  % (datadir, season, nodaexp, 'cntlBckg', aodtyp, sensor, season, wav)
    nodabckg_obs1, nodabckg_hfx1=readsample(datafile)
    datafile='%s/%s//%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
                  % (datadir, season, daexp, 'cntlAnal', aodtyp, sensor,  season, wav)
    daanal_obs1, daanal_hfx1=readsample(datafile)

    nodabckg_obs=np.array(nodabckg_obs1)
    nodabckg_hfx=np.array(nodabckg_hfx1)
    daanal_hfx=np.array(daanal_hfx1)

    vinds=np.where((nodabckg_obs>0.01) & (nodabckg_hfx>0.01) & (daanal_hfx>0.01) \
                 & (nodabckg_obs<xmax) & (nodabckg_hfx<xmax) & (daanal_hfx<xmax))

    obsarr=nodabckg_obs[vinds]
    daanalarr=daanal_hfx[vinds]
    nodabckgarr=nodabckg_hfx[vinds]

    cmat = np.corrcoef(obsarr, nodabckgarr)
    cxy = cmat[0,1]
    r2 = cxy**2
    bias=np.mean(nodabckgarr)-np.mean(obsarr)
    noda_bias.append(bias)
    noda_r2.append(r2)

    cmat = np.corrcoef(obsarr, daanalarr)
    cxy = cmat[0,1]
    r2 = cxy**2
    bias=np.mean(daanalarr)-np.mean(obsarr)
    anal_bias.append(bias)
    anal_r2.append(r2)
    #print(len(anal_bias))


fig=plt.figure(figsize=[12,4])
for ipt in range(1,3):
    if ipt==1:
        data1 = noda_bias
        data2 = anal_bias
        mdata1 = -0.093
        mdata2 = -0.046
        tstr='(a) AOD bias'
        ystr='AOD bias'
        ymin=-0.15
        ymax=0.0
    if ipt==2:
        data1 = noda_r2
        data2 = anal_r2
        mdata1 = 0.502
        mdata2 = 0.705
        tstr='(b) AOD R\u00b2'
        ystr='AOD R\u00b2'
        ymin=0.3
        ymax=0.9
    ax=fig.add_subplot(1,2,ipt)
    print(len(seasons), len(data1))
    l1=ax.plot(seasons, data1, marker='o', color='blue', linewidth=2, label='Free Forecast')
    l2=ax.plot(seasons, data2, marker='o', color='red', linewidth=2, label='Reanalysis')
    ax.plot(seasons, np.repeat(mdata1,12), linestyle='--', color='blue', linewidth=2)
    ax.plot(seasons, np.repeat(mdata2,12), linestyle='--', color='red', linewidth=2)
    #ax.legend(handles=[l1, l2])
    ax.legend(fontsize=14)
    plt.title(tstr, fontsize=14)
    plt.ylim([ymin, ymax])
    plt.xlabel('Month', fontsize=14)
    plt.ylabel(ystr, fontsize=14)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

fig.tight_layout()
plt.savefig('Bias_R2.png', format='png')
plt.close(fig)
