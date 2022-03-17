close all;
clear all;

diagtopdir='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/';
expnames={'global-workflow-CCPP2-Chem-NRT-clean';'global-workflow-CCPP2-Chem-NRT-clean-cntlFreeFcst'};
aodtyp='AERONET';
sensors={'aeronet'};
wav='500';
wavind=4;
cyc=textread('DATE.info');
svar=[aodtyp,'AOD'];

iodav2date=2021071206;

sobs='aerosol_optical_depth_4@ObsValue';;
shfx='aerosol_optical_depth_4@hofx';;
gobs='ObsValue';
ghfx='hofx';
geqc='EffectiveQC';
gmet='MetaData';
gaod='aerosol_optical_depth';
glon='longitude';
glat='latitude';

nexps=size(expnames,1);
nsens=size(sensors,1);

for iexp=1:nexps
    expname=expnames{iexp};
    if strcmp(expname,'global-workflow-CCPP2-Chem-NRT-clean')
       nflds=2;
    else
       nflds=1;
    end

for ifld=1:nflds
    if ifld==1
       fncname='.nc4.ges';
       fidname='cntlBckg';
    elseif ifld==2
       fncname='.nc4';
       fidname='cntlAnal';
    end

    for isen=1:nsens
        sensor=sensors{isen};

        cycname=num2str(cyc)
	cycymd=cycname(1:8);
	cych=cycname(9:10);
        expdir=[diagtopdir,'/', expname, '/dr-data-backup/gdas.',cycymd,'/',cych,'/obs/'];

	for iproc=1:6
	    prcname=['000', num2str(iproc-1)];
            diagfile=[expdir, 'aod_',sensor,'_hofx_3dvar_LUTs_',cycname,'_',prcname,fncname];

            diagid=netcdf.open(diagfile,'NC_NOWRITE');

	    gobsid=netcdf.inqNcid(diagid,gobs);
	    ghfxid=netcdf.inqNcid(diagid,ghfx);
	    geqcid=netcdf.inqNcid(diagid,geqc);
	    gmetid=netcdf.inqNcid(diagid,gmet);

            sobsid=netcdf.inqVarID(gobsid, gaod);
            shfxid=netcdf.inqVarID(ghfxid, gaod);
            seqcid=netcdf.inqVarID(geqcid, gaod);
	    slonid=netcdf.inqVarID(gmetid, glon);
	    slatid=netcdf.inqVarID(gmetid, glat);
	
            sobsdatatmp1=netcdf.getVar(gobsid, sobsid, 'single');
            shfxdatatmp1=netcdf.getVar(ghfxid, shfxid, 'single');
            seqcdatatmp1=netcdf.getVar(geqcid, seqcid, 'single');
	    slondatatmp1=netcdf.getVar(gmetid, slonid, 'single');
	    slatdatatmp1=netcdf.getVar(gmetid, slatid, 'single');

	    sobsdatatmp=sobsdatatmp1';
	    shfxdatatmp=shfxdatatmp1';
	    seqcdatatmp=seqcdatatmp1';
	    slondatatmp=slondatatmp1;
	    slatdatatmp=slatdatatmp1;

	    netcdf.close(diagid);

	    if iproc==1
	       sobsdata=sobsdatatmp;
	       shfxdata=shfxdatatmp;
	       seqcdata=seqcdatatmp;
	       slondata=slondatatmp;
	       slatdata=slatdatatmp;
            else
               sobsdata=[sobsdata; sobsdatatmp];
               shfxdata=[shfxdata; shfxdatatmp];
               seqcdata=[seqcdata; seqcdatatmp];
	       slondata=[slondata; slondatatmp];
	       slatdata=[slatdata; slatdatatmp];
	    end
        end

	seqcdata(seqcdata>0)=NaN;
	seqcdata=seqcdata+1;

	sobsdata=sobsdata.*seqcdata;
	shfxdata=shfxdata.*seqcdata;
	sobsdata500=sobsdata(:,wavind);
	shfxdata500=shfxdata(:,wavind);

	nonnaninds=find(~isnan(sobsdata500));
        
	slondata_save=slondata(nonnaninds);
	slatdata_save=slatdata(nonnaninds);
	sobsdata_save=sobsdata500(nonnaninds);
	shfxdata_save=shfxdata500(nonnaninds);

        wfile=[expname,'-', fidname,'-', svar,'-',sensor, '-lon-lat-obs-hofx-Cyc-',num2str(cyc), '-', num2str(cyc), '-wav-',wav,'.txt'];
	data=[slondata_save slatdata_save sobsdata_save shfxdata_save];
        dlmwrite(wfile, data, 'delimiter', '\t');

    end % isen
end % ifld
end % iexp

