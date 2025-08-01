% Compare standard deviations
% This script can read cfRadial files, fortran output tables from John, and nexrad level2 files.
% It calculates spatial standard deviations and plots them.
% It compares standard deviations from two files and calculates and plots
% statistics.

%% IMPORTANT

% The files two input files need to be specified in the file
% "compareFiles_cases2425.txt"
% Each line in this file needs to have the following columns:
% 1. Full path to data file 1
% 2. Full path to data file 2
% 3. Desired output name (will be used for directory and output file name)
% 4.-7. X and Y coordinates of first zoom window
% 8.-11. X and Y coordinates of second zoom window
% 12. "table" or "nc" indicating the data file type of file 1
% 13. "table" or "nc" indicating the data file type of file 1
% 14. Seems to be not used. Not sure why it is there.
% 15. Elevation angle

% I suggest continuing the list of files instead of deleting. This way old
% work can be recreated. You can start the foor loop at the desired new
% file.
%%

clear all;
close all;

addpath(genpath('~/git/lrose-nexrad/analysis/utils/'));

minMaxRangeOrig=[]; % Range interval [min,max] or leave empty
minMaxAz=[]; % Azimuth interval [min,max] or leave empty
kernel=[9,5]; % Az and range of std kernel. Default: [9,5]

censorOnDBZ=0;
censorOnVEL=0;
censorOnCMD=1;
censorOnTRIP=0; % Only use weak trip (0).
%%%%%%%%%%%%%%
censorOnSNR=[]; % Set to empty if not used !!!!!!! Only use areas with SNR above XX dB
%%%%%%%%%%%%%%
halfNyquist=0; % In some files the nyquist needs to be divided by 2
removeZeros=0;

%% Loop through cases

fileID = fopen('compareFiles_cases2425.txt');
inAll=textscan(fileID,'%s %s %s %f %f %f %f %f %f %f %f %s %s %s %f');
fclose(fileID);

showPlot='on';

censor99=1; % 1 if -99 values in John's tables should be converted to nans. Otherwise 0.

for aa=71:size(inAll{1,1},1)

    nyquist=[];

    %% Read file 1
    infile1=inAll{1,1}(aa);

    disp(['File 1: ',infile1{:}]);

    figdir=['/scr/cirrus1/rsfdata/projects/nexrad/figures/cases2425/stdCompare/'];    

    fileType=inAll{1,12}(aa);

    if strcmp(fileType{:},'nc')
        data1in=[];

        data1in.DBZ_F=[];
        data1in.VEL_F=[];
        data1in.WIDTH_F=[];
        data1in.ZDR_F=[];
        data1in.PHIDP_F=[];
        data1in.RHOHV_F=[];
        data1in.REGR_FILT_POLY_ORDER=[];
        data1in.CMD_FLAG=[];

        data1in=read_spol(infile1{:},data1in);
        nyquist=ncread(infile1{:},'nyquist_velocity');

    elseif strcmp(fileType{:},'nexrad')
        data1in=[];

        data1in.DBZ=[];
        data1in.VEL=[];
        data1in.WIDTH=[];
        data1in.ZDR=[];
        data1in.PHIDP=[];
        data1in.RHOHV=[];

        data1in=read_spol(infile1{:},data1in);
        nyquist=ncread(infile1{:},'nyquist_velocity');

        data1in=data1in(inAll{1,15}(aa));

        data1in.DBZ_F=data1in.DBZ;
        data1in.VEL_F=data1in.VEL;
        data1in.WIDTH_F=data1in.WIDTH;
        data1in.ZDR_F=data1in.ZDR;
        data1in.PHIDP_F=data1in.PHIDP;
        data1in.RHOHV_F=data1in.RHOHV;

    elseif strcmp(fileType{:},'nexradLevel2')
        data1in=[];

        data1in.REF=[];
        data1in.VEL=[];
        data1in.SW=[];
        data1in.ZDR=[];
        data1in.PHI=[];
        data1in.RHO=[];

        data1in=read_spol(infile1{:},data1in);
        nyquist=ncread(infile1{:},'nyquist_velocity');

        data1in=data1in(inAll{1,15}(aa));

        data1in.DBZ_F=data1in.REF;
        data1in.VEL_F=data1in.VEL;
        data1in.WIDTH_F=data1in.SW;
        data1in.ZDR_F=data1in.ZDR;
        data1in.PHIDP_F=data1in.PHI;
        data1in.RHOHV_F=data1in.RHO;

    elseif strcmp(fileType{:},'table')
        data1in=readDataTables(infile1{:},' ');
        %data1in.azimuth=round(data1in.azimuth);
        data1in.RHOHV_F=data1in.RHOHV_NNC_F;

        if censor99
            dataFields=fields(data1in);
            for ll=1:length(dataFields)
                if size(data1in.(dataFields{ll}),1)==length(data1in.azimuth) & size(data1in.(dataFields{ll}),2)==length(data1in.range)
                    data1in.(dataFields{ll})(data1in.(dataFields{ll})==-99)=nan;
                end
            end
        end
    end

    %% Read file 2
    infile2=inAll{1,2}(aa);

    disp(['File 2: ',infile2{:}]);

    fileType=inAll{1,13}(aa);

    if strcmp(fileType{:},'nc')
        data2in=[];

        data2in.DBZ_F=[];
        data2in.VEL_F=[];
        data2in.WIDTH_F=[];
        data2in.ZDR_F=[];
        data2in.PHIDP_F=[];
        data2in.RHOHV_F=[];
        data2in.REGR_FILT_POLY_ORDER=[];
        data2in.CMD_FLAG=[];

        data2in=read_spol(infile2{:},data2in);
        nyquist=ncread(infile2{:},'nyquist_velocity');

    elseif strcmp(fileType{:},'nexrad')
        data2in=[];

        data2in.DBZ=[];
        data2in.VEL=[];
        data2in.WIDTH=[];
        data2in.ZDR=[];
        data2in.PHIDP=[];
        data2in.RHOHV=[];

        data2in=read_spol(infile2{:},data2in);
        nyquist=ncread(infile2{:},'nyquist_velocity');

        data2in=data2in(inAll{1,15}(aa));

        data2in.DBZ_F=data2in.DBZ;
        data2in.VEL_F=data2in.VEL;
        data2in.WIDTH_F=data2in.WIDTH;
        data2in.ZDR_F=data2in.ZDR;
        data2in.PHIDP_F=data2in.PHIDP;
        data2in.RHOHV_F=data2in.RHOHV;

    elseif strcmp(fileType{:},'nexradLevel2')
        data2in=[];

        data2in.REF=[];
        data2in.VEL=[];
        data2in.SW=[];
        data2in.ZDR=[];
        data2in.PHI=[];
        data2in.RHO=[];

        data2in=read_spol(infile1{:},data2in);
        nyquist=ncread(infile1{:},'nyquist_velocity');

        data2in=data2in(inAll{1,15}(aa));

        data2in.DBZ_F=data2in.REF;
        data2in.VEL_F=data2in.VEL;
        data2in.WIDTH_F=data2in.SW;
        data2in.ZDR_F=data2in.ZDR;
        data2in.PHIDP_F=data2in.PHI;
        data2in.RHOHV_F=data2in.RHO;

    elseif strcmp(fileType{:},'table')
        data2in=readDataTables(infile2{:},' ');
        %data2in.azimuth=round(data2in.azimuth);
        data2in.RHOHV_F=data2in.RHOHV_NNC_F;

        if censor99
            dataFields=fields(data2in);
            for ll=1:length(dataFields)
                if size(data2in.(dataFields{ll}),1)==length(data2in.azimuth) & size(data2in.(dataFields{ll}),2)==length(data2in.range)
                    data2in.(dataFields{ll})(data2in.(dataFields{ll})==-99)=nan;
                end
            end
        end
    elseif strcmp(fileType{:},'mat')
        load(infile2{:});
        addnan=nan(size(data.REF,1),8);
        data2in.DBZ_F=cat(2,addnan,data.REF(:,1:end-1));
        data2in.VEL_F=cat(2,addnan,data.VEL(:,1:end-1));
        data2in.WIDTH_F=cat(2,addnan,data.SW(:,1:end-1));
        data2in.ZDR_F=cat(2,addnan,data.ZDR(:,1:end-1));
        data2in.PHIDP_F=cat(2,addnan,data.PHI(:,1:end-1));
        data2in.azimuth=data.azimuth;
        data2in.range=data1in.range;

        data2in.azimuth=floor(data2in.azimuth);
        data2in.azimuth(2:2:length(data2in.azimuth))=data2in.azimuth(2:2:length(data2in.azimuth))+0.5;
    end

    if isempty(nyquist)
        warning('No nyquist velocity found. Using 26.675 m/s')
        nyquist=26.675;
    else
        nyquist=mode(nyquist);
    end

    if halfNyquist
        nyquist=nyquist/2;
    end

    %% Cut range
    inFields1=fields(data1in);
    inFields2=fields(data2in);
    inFields=intersect(inFields1,inFields2);

    if isempty(minMaxRangeOrig)
        minMaxRange=max([data1in.range(1),data2in.range(1)]);
        minMaxRange=[minMaxRange,min([data1in.range(end),data2in.range(end)])];
    else
        minMaxRange=minMaxRangeOrig;
    end
    goodInds1=find(data1in.range>=minMaxRange(1)-0.001 & data1in.range<=minMaxRange(2)+0.001);
    goodInds2=find(data2in.range>=minMaxRange(1)-0.001 & data2in.range<=minMaxRange(2)+0.001);

    for ii=1:size(inFields,1)
        if ~(strcmp(inFields{ii},'azimuth') | strcmp(inFields{ii},'elevation') | strcmp(inFields{ii},'time'))
            data1in.(inFields{ii})=data1in.(inFields{ii})(:,goodInds1);
            data2in.(inFields{ii})=data2in.(inFields{ii})(:,goodInds2);
        end
    end


    %% Match azimuths and nans

    azRes=round((data1in.azimuth(2)-data1in.azimuth(1))*10)/10;
    if azRes==0.5
        pastDot=data1in.azimuth(1)-floor(data1in.azimuth(1));
        if (pastDot>0.125 & pastDot<0.375) | (pastDot>0.625 & pastDot<0.875)
            allAz=0.25:azRes:359.75;
        else
            allAz=0:azRes:359.5;
        end
    else
        allAz=0:359;
    end

    if ~isempty(minMaxAz)
        %         data1in.azimuth(data1in.azimuth<minMaxAz(1) | data1in.azimuth>minMaxAz(2))=nan;
        %         data2in.azimuth(data2in.azimuth<minMaxAz(1) | data2in.azimuth>minMaxAz(2))=nan;
        allAz(allAz<minMaxAz(1))=[];
        allAz(allAz>minMaxAz(2))=[];
    end

    ib1=[];
    ib2=[];
    ibAll=[];
    for kk=1:length(allAz)
        [minDiff1,minInd1]=min(abs(data1in.azimuth-allAz(kk)));
        [minDiff2,minInd2]=min(abs(data2in.azimuth-allAz(kk)));
        if minDiff1<azRes/2-0.01 & minDiff2<azRes/2-0.01
            ib1=cat(1,ib1,minInd1);
            ib2=cat(1,ib2,minInd2);
            ibAll=cat(1,ibAll,kk);
        else
            error('Azimuths do not match.')
        end
    end

    data1=[];
    data1.range=data1in.range;
    data2=[];
    data2.range=data2in.range;

    for ii=1:size(inFields,1)
        if ~strcmp(inFields{ii},'range') & ~strcmp(inFields{ii},'time')
            data1.(inFields{ii})=nan(length(allAz),size(data1in.(inFields{ii}),2));
            data1.(inFields{ii})(ibAll,:)=data1in.(inFields{ii})(ib1,:);
            data2.(inFields{ii})=nan(length(allAz),size(data2in.(inFields{ii}),2));
            data2.(inFields{ii})(ibAll,:)=data2in.(inFields{ii})(ib2,:);
        end
    end

    % CMD
    if censorOnCMD
        cmd=zeros(size(data1.DBZ_F));
        cmd1=zeros(size(data1.DBZ_F));
        cmd2=zeros(size(data1.DBZ_F));
        if isfield(data1in,'CMD_FLAG')
            data1in.CMD_FLAG=data1in.CMD_FLAG(:,goodInds1);
            cmd1(ibAll,:)=data1in.CMD_FLAG(ib1,:);
        elseif isfield(data2in,'CMD_FLAG')
            data2in.CMD_FLAG=data2in.CMD_FLAG(:,goodInds2);
            cmd2(ibAll,:)=data2in.CMD_FLAG(ib2,:);
        end
        cmd(cmd1>0)=1;
        cmd(cmd2>0)=1;
        if sum(cmd,'all')==0
            censorOnCMD=0;
            warning('No CMD flag found.')
        end
    end

    % SNR
    if ~isempty(censorOnSNR)
        snr=zeros(size(data1.DBZ_F));
        if isfield(data1in,'SNR')
            data1in.SNR=data1in.SNR(:,goodInds1);
            snr(ibAll,:)=data1in.SNR(ib1,:);
        elseif isfield(data2in,'SNR')
            data2in.SNR=data2in.SNR(:,goodInds2);
            snr(ibAll,:)=data2in.SNR(ib2,:);
        end
        if isempty(snr)
            censorOnSNR=0;
            disp('No SNR found.')
        end
    end

    % TRIP
    if censorOnTRIP
        trip=zeros(size(data1.DBZ_F));
        if isfield(data1in,'TRIP')
            data1in.TRIP=data1in.TRIP(:,goodInds1);
            trip(ibAll,:)=data1in.TRIP(ib1,:);
        elseif isfield(data2in,'TRIP')
            data2in.TRIP=data2in.TRIP(:,goodInds2);
            trip(ibAll,:)=data2in.TRIP(ib2,:);
        end
        if isempty(trip)
            censorOnTRIP=0;
            disp('No TRIP flag found.')
        end
    end

    for ii=1:size(inFields,1)
        if ~strcmp(inFields{ii},'range') & ~strcmp(inFields{ii},'time')
            % Censor on DBZ
            if censorOnDBZ & size(data1.(inFields{ii}))==size(data1.DBZ_F)
                data1.(inFields{ii})(isnan(data1.DBZ_F))=nan;
                data2.(inFields{ii})(isnan(data2.DBZ_F))=nan;
            end
            % Censor on VEL
            if censorOnVEL & size(data1.(inFields{ii}))==size(data1.DBZ_F)
                data1.(inFields{ii})(data1.VEL_F>-2 & data1.VEL_F<2)=nan;
                data2.(inFields{ii})(isnan(data2.DBZ_F))=nan;
            end
            % Censor on CMD
            if censorOnCMD & size(data1.(inFields{ii}))==size(data1.DBZ_F)
                if ~strcmp(inFields{ii},'CMD_FLAG')
                    data1.(inFields{ii})(cmd<0.5)=nan;
                    data2.(inFields{ii})(cmd<0.5)=nan;
                end
            end
            % Censor on SNR
            if ~isempty(censorOnSNR) & size(data1.(inFields{ii}))==size(data1.DBZ_F)
                data1.(inFields{ii})(snr<censorOnSNR)=nan;
                data2.(inFields{ii})(snr<censorOnSNR)=nan;
            end
            % Censor on TRIP
            if censorOnTRIP & size(data1.(inFields{ii}))==size(data1.DBZ_F)
                data1.(inFields{ii})(trip==1)=nan;
                data2.(inFields{ii})(trip==1)=nan;
            end
            % Match nans
            data1.(inFields{ii})(isnan(data2.(inFields{ii})))=nan;
            data2.(inFields{ii})(isnan(data1.(inFields{ii})))=nan;
        end
    end

    data1.PHIDP_F=wrapTo360(data1.PHIDP_F);
    data2.PHIDP_F=wrapTo360(data2.PHIDP_F);

    %% Plot preparation

    ang_p = deg2rad(90-data1.azimuth);

    angMat=repmat(ang_p,size(data1.range,1),1);

    XX = (data1.range.*cos(angMat));
    YY = (data1.range.*sin(angMat));

    %% Loop through fields
    outstr=inAll{1,3}(aa);
    outstr=outstr{:};

    outDots=strsplit(outstr,'.');
    outParts=strsplit(outDots{1},'VS');

     for jj=1:length(inFields)

        if strcmp(inFields{jj},'azimuth') | strcmp(inFields{jj},'elevation') | ...
                strcmp(inFields{jj},'range') | strcmp(inFields{jj},'time') | strcmp(inFields{jj},'CMD_FLAG')
            continue
        end

        %% Standard deviations

        if strcmp(inFields{jj},'VEL_F')
            [stdVar1,~]=fast_nd_std(data1.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',nyquist);
            [stdVar2,~]=fast_nd_std(data2.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',nyquist);
        elseif strcmp(inFields{jj},'PHIDP_F')
            [stdVar1,~]=fast_nd_std(data1.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',180);
            [stdVar2,~]=fast_nd_std(data2.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',180);
        else
            [stdVar1,~]=fast_nd_std(data1.(inFields{jj}),kernel,'mode','partial','nan_std',1);
            [stdVar2,~]=fast_nd_std(data2.(inFields{jj}),kernel,'mode','partial','nan_std',1);
        end

        stdVar1(isnan(data1.(inFields{jj})))=nan;
        stdVar2(isnan(data2.(inFields{jj})))=nan;

        %% Plot
        close all

        f1 = figure('Position',[200 500 1800 750],'DefaultAxesFontSize',12,'visible',showPlot);
        t = tiledlayout(2,4,'TileSpacing','tight','Padding','compact');
        colormap('jet');
       
        s1=nexttile(1);
        pBottom=prctile(data1.(inFields{jj}),1,'all');
        pTop=prctile(data1.(inFields{jj}),99,'all');
        if pTop==pBottom
            pBottom=pBottom-0.1;
            pTop=pTop+0.1;
        end
        surf(XX,YY,data1.(inFields{jj}),'edgecolor','none');
        view(2);
        caxis([pBottom,pTop]);
        colorbar;
        title([inFields{jj},' ',outParts{1}],'Interpreter','none');
        xlabel('km');
        ylabel('km');

        grid on
        box on

        s2=nexttile(2);
        surf(XX,YY,data2.(inFields{jj}),'edgecolor','none');
        view(2);
        caxis([pBottom,pTop]);
        colorbar;
        title([inFields{jj},' ',outParts{2}],'Interpreter','none');
        xlabel('km');
        ylabel('km');

        grid on
        box on

        s3=nexttile(3);
        diffField=data2.(inFields{jj})-data1.(inFields{jj});
        pBottom=prctile(diffField,1,'all');
        pTop=prctile(diffField,99,'all');
        lim=max(abs([pTop,pBottom]));
        if lim==0
            lim=0.1;
        end
        surf(XX,YY,diffField,'edgecolor','none');
        view(2);
        caxis([-lim,lim]);
        s3.Colormap=velCols;
        colorbar;
        title([inFields{jj},' ',outParts{2},' - ',outParts{1}],'Interpreter','none');
        xlabel('km');
        ylabel('km');

        grid on
        box on

        diffFieldKeep=diffField;
        limKeep=lim;

        s5=nexttile(5);
        pBottom=prctile(stdVar1,10,'all');
        pTop=prctile(stdVar1,90,'all');
        surf(XX,YY,stdVar1,'edgecolor','none');
        view(2);
        caxis([pBottom,pTop]);
        colorbar;
        title(['std ',outParts{1}],'Interpreter','none');
        xlabel('km');
        ylabel('km');

        grid on
        box on

        s6=nexttile(6);
        surf(XX,YY,stdVar2,'edgecolor','none');
        view(2);
        caxis([pBottom,pTop]);
        colorbar;
        title(['std ',outParts{2}],'Interpreter','none');
        xlabel('km');
        ylabel('km');

        grid on
        box on

        s7=nexttile(7);
        diffField=stdVar2-stdVar1;
        pBottom=prctile(diffField,1,'all');
        pTop=prctile(diffField,99,'all');
        lim=max(abs([pTop,pBottom]));
        if lim==0
            lim=0.1;
        end
        surf(XX,YY,diffField,'edgecolor','none');
        view(2);
        caxis([-lim,lim]);
        s7.Colormap=velCols;
        colorbar;
        title(['std ',outParts{2},' - std ',outParts{1}],'Interpreter','none');
        xlabel('km');
        ylabel('km');

        grid on
        box on

        outstr=inAll{1,3}(aa);
        outstr=outstr{:};
        mtit([outstr],'fontsize',14,'xoff',0,'yoff',0.05,'interpreter','none');
        f1.Visible=showPlot;

        %% Save first zoom

        if ~isnan(minMaxRangeOrig)
            outstr=[outstr,'_range',num2str(minMaxRange(1)),'to',num2str(minMaxRange(2))];
        end
        if ~isnan(minMaxAz)
            outstr=[outstr,'_az',num2str(minMaxAz(1)),'to',num2str(minMaxAz(2))];
        end
        if censorOnCMD
            outstr=[outstr,'_CMDcensor'];
        end
        if ~isempty(censorOnSNR)
            outstr=[outstr,'_SNRcensor'];
        end
        if censorOnTRIP
            outstr=[outstr,'_TRIPcensor'];
        end

        %outstr=[outstr,'_5-3'];

        mkdir(figdir,outstr);

        linkaxes([s1,s2,s3,s5,s6,s7],'xy');

        xlimits1=[inAll{1,4}(aa),inAll{1,5}(aa)];
        ylimits1=[inAll{1,6}(aa),inAll{1,7}(aa)];

        xlim(xlimits1)
        ylim(ylimits1)
        daspect(s1,[1 1 1]);
        daspect(s2,[1 1 1]);
        daspect(s3,[1 1 1]);
        daspect(s5,[1 1 1]);
        daspect(s6,[1 1 1]);
        daspect(s7,[1 1 1]);

        s4=nexttile(4);
        if removeZeros
            diffFieldKeep(diffFieldKeep>-limKeep/100 & diffField<limKeep/100)=nan;
        end
        pBottom2=prctile(diffFieldKeep,15,'all');
        pTop2=prctile(diffFieldKeep,85,'all');
        lim2=max(abs([pTop2,pBottom2]));
        if lim2==0
            lim2=0.1;
        end

        hold on
        edges=-limKeep:limKeep/60:limKeep;
        hc=histcounts(diffFieldKeep(:),edges);
        bar(edges(1:end-1)+(edges(2)-edges(1))/2,hc,1)
        xlim([-lim2,lim2]);

        ylims=s4.YLim;
        plot([0,0],ylims,'-r','LineWidth',2);

        s4.SortMethod='childorder';

        grid on
        box on
        title([inFields{jj},' ',outParts{2},' - ',outParts{1}],'Interpreter','none');

        s8=nexttile(8);
        if removeZeros
            diffField(diffField>-lim/100 & diffField<lim/100)=nan;
        end
        pBottom2=prctile(diffField,15,'all');
        pTop2=prctile(diffField,85,'all');
        lim2=max(abs([pTop2,pBottom2]));
        if lim2==0
            lim2=0.1;
        end

        hold on
        edges=-lim:lim/60:lim;
        hc=histcounts(diffField(:),edges);
        bar(edges(1:end-1)+(edges(2)-edges(1))/2,hc,1)
        xlim([-lim2,lim2]);

        ylims=s8.YLim;
        plot([0,0],ylims,'-r','LineWidth',2);

        s8.SortMethod='childorder';

        grid on
        box on
        title(['std ',outParts{2},' - std ',outParts{1}],'Interpreter','none');

        print([figdir,outstr,'/',outstr,'_',inFields{jj},'_zoom1.png'],'-dpng','-r0');

        %% Save second zoom

        xlimits2=[inAll{1,8}(aa),inAll{1,9}(aa)];
        ylimits2=[inAll{1,10}(aa),inAll{1,11}(aa)];

        s1.XLim=xlimits2;
        s1.YLim=ylimits2;
        daspect(s1,[1 1 1]);
        daspect(s2,[1 1 1]);
        daspect(s3,[1 1 1]);
        daspect(s5,[1 1 1]);
        daspect(s6,[1 1 1]);
        daspect(s7,[1 1 1]);

        print([figdir,outstr,'/',outstr,'_',inFields{jj},'_zoom2.png'],'-dpng','-r0');
     end
end