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
from fast_histogram import histogram2d

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
    
def plot_mpl_scatter_density(hist2d, axis, R2str, biasstr, sizestr, xmax, vmax, expname,season):
    xlabstr='AERONET AOD 500 nm'
    ylabstr='GEFS AOD 500 nm'

    fig=plt.figure(figsize=[4,4])
    #norm = ImageNormalize(vmin=0., vmax=1., stretch=LogStretch())

    ax=fig.add_subplot(1,1,1, projection='scatter_density')
    cn=ax.contourf(axis[:-1],axis[:-1],hist2d.swapaxes(0,1),vmin=0.,vmax=vmax,levels=256,cmap=white_gist_earth)#,norm=norm)
    #sc=ax.scatter_density(obs, hfx, dpi=50, cmap=white_gist_earth,  vmin=0, vmax=bmax, norm=norm)

    plt.plot([0.0, xmax],[0.0, xmax], color='gray', linewidth=2, linestyle='--')
    plt.xlim(0.01, xmax)
    plt.ylim(0.01, xmax)
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
    #cb=fig.colorbar(cn, cax=cbar_ax, extend='max')
    #cb.ax.tick_params(labelsize=10)
    #fig.tight_layout(rect=[0, 0.00, 0.95, 1.0])
    fig.tight_layout()
    plt.savefig('%s_%s.png'%(expname, season), format='png',dpi=300)
    plt.close(fig)
    return

daexp='anal_AOD20'
nodaexp='noda_AOD20'
datadir='/work2/noaa/gsd-fv3-dev/swei/scatterdensity/data'
seasons=['DJF', 'JJA', 'MAM', 'SON']
aodtyp='AERONET'
sensor='aeronet'
wav='500'
xmax=5.0
bmax=100
bins=30

white_gist_earth = LinearSegmentedColormap.from_list('white_gist_earth', [
    (0,     (1,        1,        1       )),
    (1e-20, (0.965882, 0.915975, 0.913378)),
    (0.2,   (0.772885, 0.646409, 0.444171)),
    (0.4,   (0.568932, 0.677541, 0.340330)),
    (0.6,   (0.249216, 0.576471, 0.342046)),
    (0.8,   (0.143740, 0.396564, 0.488306)),
    (1,     (0.013067, 0.000000, 0.348089)),
    ], N=256)

app=0
for season in seasons:

    datafile='%s/%s/%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
                  % (datadir, season, nodaexp, 'cntlBckg', aodtyp, sensor, season, wav)
    nodabckg_obs1, nodabckg_hfx1=readsample(datafile)
    datafile='%s/%s//%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-%s-wav-%s.txt' \
                  % (datadir, season, daexp, 'cntlAnal', aodtyp, sensor, season, season, wav)
    daanal_obs1, daanal_hfx1=readsample(datafile)

    nodabckg_obs=np.array(nodabckg_obs1)
    nodabckg_hfx=np.array(nodabckg_hfx1)
    daanal_hfx=np.array(daanal_hfx1)

    vinds=np.where((nodabckg_obs>0.01) & (nodabckg_hfx>0.01) & (daanal_hfx>0.01) \
                 & (nodabckg_obs<xmax) & (nodabckg_hfx<xmax) & (daanal_hfx<xmax))

    obsarr=nodabckg_obs[vinds]
    daanalarr=daanal_hfx[vinds]
    nodabckgarr=nodabckg_hfx[vinds]

    obs=obsarr
    for ipt in range(2):
        if ipt == 0:
            hfx=nodabckgarr
            expname='noda_AOD20'
        if ipt == 1:
            hfx=daanalarr
            expname='anal_AOD20'

        correlation_matrix = np.corrcoef(obs, hfx)
        correlation_xy = correlation_matrix[0,1]
        r_squared = correlation_xy**2
        bias=np.mean(hfx)-np.mean(obs)
        moratio=np.mean(hfx)/np.mean(obs)
        rbias=bias/np.mean(obs)
        ssize=len(obs)

        R2str='R\u00b2 = %s' % (str("%.3f" % r_squared))
        biasstr='Bias = %s' % (str("%.3f" % bias))
        sizestr='N = %s' % (str("%.0f" % ssize))

        outfile='Stats_%s_%s_N_Bias_R2_M2ORatio_ReBias.txt'%(expname, season)
        np.savetxt(outfile, [ssize,bias,r_squared, moratio, rbias], delimiter='\b')

        axis=np.linspace(np.log(0.01),np.log(xmax),bins+1)
        axis=np.exp(axis)
        hist2d,x_edge,y_edge=np.histogram2d(obs, hfx, bins=axis)
        counts=hist2d.sum()
        print('%s largest counts: %i' %(season,hist2d.max()),flush=1)
        hist2d/=counts
        if ipt == 0:
           data = np.expand_dims(hist2d,axis=0)
        elif ipt == 1:
           tmpda = np.expand_dims(hist2d,axis=0)
           data = np.concatenate((data,tmpda),axis=0)
        print(data.shape)
        vmax=data.max()

    for ipt in range(2):
        if ipt == 0:
           expname='noda_AOD20'
        if ipt == 1:
           expname='anal_AOD20'
        plot_mpl_scatter_density(data[ipt,:,:], axis, R2str, biasstr ,sizestr, xmax, vmax, expname, season)

    if app==0:
        obsarr_glb=obsarr
        nodabckgarr_glb=nodabckgarr
        daanalarr_glb=daanalarr
        app=1
    elif app==1:
        obsarr_glb=np.append(obsarr_glb,obsarr)
        nodabckgarr_glb=np.append(nodabckgarr_glb,nodabckgarr)
        daanalarr_glb=np.append(daanalarr_glb,daanalarr)
    print(len(obsarr_glb), len(obsarr), flush=1)
# Global
print(len(obsarr_glb), len(nodabckgarr_glb), len(daanalarr_glb), flush=1)
obs=obsarr_glb
for ipt in range(2):
    if ipt == 0:
        hfx=nodabckgarr_glb
        expname='noda_AOD20'
    if ipt == 1:
        hfx=daanalarr_glb
        expname='anal_AOD20'
    correlation_matrix = np.corrcoef(obs, hfx)
    correlation_xy = correlation_matrix[0,1]
    r_squared = correlation_xy**2
    bias=np.mean(hfx)-np.mean(obs)
    moratio=np.mean(hfx)/np.mean(obs)
    rbias=bias/np.mean(obs)
    ssize=len(obs)

    R2str='R\u00b2 = %s' % (str("%.3f" % r_squared))
    biasstr='Bias = %s' % (str("%.3f" % bias))
    sizestr='N = %s' % (str("%.0f" % ssize))

    outfile='Stats_%s_%s_N_Bias_R2_M2ORatio_ReBias.txt'%(expname, 'GLOBAL')
    np.savetxt(outfile, [ssize,bias,r_squared, moratio, rbias], delimiter='\b')

    axis=np.linspace(np.log(0.01),np.log(xmax),bins+1)
    axis=np.exp(axis)
    hist2d,x_edge,y_edge=np.histogram2d(obs, hfx, bins=axis)
    counts=hist2d.sum()
    print('GLOBAL largest counts: %i' %(hist2d.max()),flush=1)
    hist2d/=counts
    if ipt == 0:
       data = np.expand_dims(hist2d,axis=0)
    elif ipt == 1:
       tmpda = np.expand_dims(hist2d,axis=0)
       data = np.concatenate((data,tmpda),axis=0)
    print(data.shape)
    vmax=data.max()

for ipt in range(2):
    if ipt == 0:
       expname='noda_AOD20'
    if ipt == 1:
       expname='anal_AOD20'
    plot_mpl_scatter_density(data[ipt,:,:], axis, R2str, biasstr,sizestr, xmax, vmax, expname, 'GLOBAL')
#quit()
