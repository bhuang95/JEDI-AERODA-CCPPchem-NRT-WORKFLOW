import sys,os
from scipy.stats import gaussian_kde
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
import numpy as np
import math
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt

expnames=['global-workflow-CCPP2-Chem-NRT-clean','global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst']
aodtyp='AERONET'
sensor='aeronet'
epison=0.01
wavs=['500']
#cycs='2021070900'
#cyce='2021073118'
fs=open('DATES.info', 'r')
fe=open('DATEE.info', 'r')
cycs=fs.read().replace('\n', '')
cyce=fe.read().replace('\n', '')
fs.close()
fe.close()

cyc1='runs_AERONET_%s_%s' % (cycs, cyce)
cyc2='%s-%s'  % (cycs, cyce)

nexps=len(expnames)
nwavs=len(wavs)

for iexp in range(nexps):
    expname=expnames[iexp]
    if expname == 'global-workflow-CCPP2-Chem-NRT-clean':
        expleg='DA'
        nflds=2
        fields=['cntlBckg', 'cntlAnal']
    else:
        expleg='NODA'
        nflds=1
        fields=['cntlBckg']
    print(expname)
    for ifld in range(nflds):
        field=fields[ifld]
        print(field)
        for iwav in range(nwavs):
            wav=wavs[iwav]
            datafile='./%s-%s-%sAOD-%s-lon-lat-obs-hofx-Cyc-%s-wav-%s.txt' \
                      % (expname, field, aodtyp, sensor, cyc2, wav)
            print(wav)
            f=open(datafile,'r')
            iline=0
            lonvec=[]
            latvec=[]
            obsvec=[]
            hfxvec=[]
            for line in f.readlines():
                lon=float(line.split()[0])
                lat=float(line.split()[1])
                obs=float(line.split()[2])
                hfx=float(line.split()[3])
                if ~np.isnan(obs):
                    lonvec.append(lon)
                    latvec.append(lat)
                    obsvec.append(obs)
                    hfxvec.append(hfx)
                iline=iline+1
            f.close()
            lonarr=np.array(lonvec)
            latarr=np.array(latvec)
            obsarr=np.array(obsvec)
            hfxarr=np.array(hfxvec)
            lonarr_nonan=lonarr[~np.isnan(obsarr)]
            latarr_nonan=latarr[~np.isnan(obsarr)]
            obsarr_nonan=obsarr[~np.isnan(obsarr)]
            hfxarr_nonan=hfxarr[~np.isnan(obsarr)]
            
            bias_all=hfxarr_nonan-obsarr_nonan
            biasm_all=np.mean(bias_all)
            maem_all=np.mean(np.absolute(bias_all))
            rmsem_all=np.sqrt(np.mean(np.square(bias_all)))
            brrmsem_all=np.sqrt(np.mean(np.square(bias_all-biasm_all)))
            meanarr=np.empty([1,4])
            meanarr[0,:]=[biasm_all, rmsem_all, maem_all, brrmsem_all]

            lonlatarr_nonan=np.column_stack([lonarr_nonan, latarr_nonan])
       
            lonlat_uni,indices_uni=np.unique(lonlatarr_nonan, axis=0, return_inverse='True')
            npts=len(lonlat_uni)
            iptarr=np.empty([npts,9])
            for ipt in range(npts):
                lonlat_ipt=lonlat_uni[ipt]
                indice_ipt=np.where(indices_uni==ipt)
                count_ipt=np.size(indice_ipt)  #len(indice_ipt)
                obs_ipt=obsarr_nonan[indice_ipt]
                hfx_ipt=hfxarr_nonan[indice_ipt]
                obsm_ipt=np.mean(obs_ipt)
                hfxm_ipt=np.mean(hfx_ipt)
                bias_ipt=hfx_ipt-obs_ipt
                biasm_ipt=np.mean(bias_ipt)
                if count_ipt > 1:
                    rmsem_ipt=np.sqrt(np.mean(np.square(bias_ipt)))
                    brrmsem_ipt=np.sqrt(np.mean(np.square(bias_ipt-biasm_ipt)))
                else:
                    rmsem_ipt=np.absolute(bias_ipt)
                    brrmsem_ipt=0
                maem_ipt=np.mean(np.absolute(bias_ipt))
                iptarr[ipt,:]=[lonlat_ipt[0], lonlat_ipt[1], count_ipt, obsm_ipt, hfxm_ipt, biasm_ipt, rmsem_ipt, maem_ipt, brrmsem_ipt]
            outfile='./%s-%s-%sAOD-%s-collect-lon-lat-count-obs-hofx-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
                      % (expname, field, aodtyp, sensor, cyc2, wav)
            np.savetxt(outfile, iptarr, delimiter = '\t')
            outfile1='./%s-%s-%sAOD-%s-averaged-bias-rmse-mae-brrmse-Cyc-%s-wav-%s.txt' \
                      % (expname, field, aodtyp, sensor, cyc2, wav)
            np.savetxt(outfile1, meanarr, delimiter = '\t')
exit
