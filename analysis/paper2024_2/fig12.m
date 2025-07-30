% Read and diplay radar data

clear all;
close all;

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/utils/'));

figdir='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/figures/paper2024_2/';

xlimits1=[-120,200];
ylimits1=[-200,220];

kernel=[9,5]; % Az and range of std kernel. Default: [9,5]

censorOnCMD=0;
%%%%%%%%%%%%%%
censorOnSNR=[]; % Set to empty if not used !!!!!!! Only use areas with SNR above XX dB
%%%%%%%%%%%%%%
halfNyquist=0; % In some files the nyquist needs to be divided by 2

%% Read data

infile1='/scr/cirrus1/rsfdata/projects/nexrad/cfradial/nexrad.level2/kftg/20220329/cfrad.20220329_190500.493_to_20220329_191029.825_KFTG_SUR.nc';

data1in=[];

data1in.VEL=[];

data1in=read_spol(infile1,data1in);
nyquist=ncread(infile1,'nyquist_velocity');

data1in=data1in(1);

data1in.VEL_F=data1in.VEL;

data1in.azimuth=round(data1in.azimuth);

infile2='/scr/cirrus1/rsfdata/projects/nexrad/tables/KFTG_SZ_20220329_190532_0.48_272.92_O37_32pts_V3.txt';

data2in=readDataTables(infile2,' ');
%data2in.azimuth=round(data2in.azimuth);
if isfield(data2in,'TRIP')
    data2in.SNR=data2in.TRIP;
    data2in=rmfield(data2in,'TRIP');
end

%% Cut range
inFields1=fields(data1in);
inFields2=fields(data2in);
inFields=intersect(inFields1,inFields2);

minMaxRangeOrig=[];
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
    if (pastDot>=0.2 & pastDot<=0.3) | (pastDot>=0.7 & pastDot<=0.8)
        allAz=0.25:azRes:360;
    else
        allAz=0.5:azRes:360;
    end
else
    allAz=1:360;
end

minMaxAz=[];
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
    if minDiff1<azRes/2 & minDiff2<azRes/2
        ib1=cat(1,ib1,minInd1);
        ib2=cat(1,ib2,minInd2);
        ibAll=cat(1,ibAll,kk);
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
if censorOnCMD
    cmd=zeros(size(data2.DBZ_F));
    if isfield(data1in,'CMD_FLAG')
        data1in.CMD_FLAG=data1in.CMD_FLAG(:,goodInds1);
        cmd(ibAll,:)=data1in.CMD_FLAG(ib1,:);
    elseif isfield(data2in,'CMD_FLAG')
        data2in.CMD_FLAG=data2in.CMD_FLAG(:,goodInds2);
        cmd(ibAll,:)=data2in.CMD_FLAG(ib2,:);
    end
    if isempty(cmd)
        censorOnCMD=0;
        disp('No CMD flag found.')
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

for ii=1:size(inFields,1)
    if ~strcmp(inFields{ii},'range') & ~strcmp(inFields{ii},'time')
        % Censor on CMD
        if censorOnCMD & size(data1.(inFields{ii}))==size(data1.DBZ_F)
            data1.(inFields{ii})(cmd==0)=nan;
            data2.(inFields{ii})(cmd==0)=nan;
        end
        % Censor on SNR
        if ~isempty(censorOnSNR) & size(data1.(inFields{ii}))==size(data1.DBZ_F)
            data1.(inFields{ii})(snr<censorOnSNR)=nan;
            data2.(inFields{ii})(snr<censorOnSNR)=nan;
        end
        % Match nans
        data1.(inFields{ii})(isnan(data2.(inFields{ii})))=nan;
        data2.(inFields{ii})(isnan(data1.(inFields{ii})))=nan;
    end
end

%% Loop through fields

jj=1;
inFields{jj}='VEL_F';

%% Standard deviations
nyquist=nyquist(1);

if strcmp(inFields{jj},'VEL_F')
    [stdVar1_1,~]=fast_nd_std(data1.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',nyquist);
    [stdVar2_1,~]=fast_nd_std(data2.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',nyquist);
elseif strcmp(inFields{jj},'PHIDP_F')
    [stdVar1_1,~]=fast_nd_std(data1.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',180);
    [stdVar2_1,~]=fast_nd_std(data2.(inFields{jj}),kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',180);
else
    [stdVar1_1,~]=fast_nd_std(data1.(inFields{jj}),kernel,'mode','partial','nan_std',1);
    [stdVar2_1,~]=fast_nd_std(data2.(inFields{jj}),kernel,'mode','partial','nan_std',1);
end

stdVar1_1(isnan(data1.(inFields{jj})))=nan;
stdVar2_1(isnan(data2.(inFields{jj})))=nan;

stdVar1_1(stdVar1_1==Inf)=nan;
stdVar2_1(stdVar2_1==Inf)=nan;


%% Plot preparation

ang_p = deg2rad(90-data1.azimuth);

angMat=repmat(ang_p,size(data1.range,1),1);

XX = (data1.range.*cos(angMat));
YY = (data1.range.*sin(angMat));

%% Loop through fields

jj=1;
inFields{jj}='VEL_F';

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

stdVar1(stdVar1==Inf)=nan;
stdVar2(stdVar2==Inf)=nan;


%% Plot
close all

figure('Position',[200 500 800 1200],'DefaultAxesFontSize',12);

t = tiledlayout(3,2,'TileSpacing','tight','Padding','tight');

s1=nexttile(1);
surf(XX,YY,data1.(inFields{jj}),'edgecolor','none');
view(2);
clim([-15,15]);
s1.Colormap=velCols;
colorbar;
title('(a) Level 2, VEL (m s^{-1})');
ylabel('km');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)

s2=nexttile(2);
surf(XX,YY,stdVar1,'edgecolor','none');
view(2);
clim([0,4]);
s2.Colormap=jet;
colorbar;
title('(b) Level 2, VEL SD (m s^{-1})');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)

s3=nexttile(3);
surf(XX,YY,data2.(inFields{jj}),'edgecolor','none');
view(2);
clim([-15,15]);
s3.Colormap=velCols;
colorbar;
title(['(c) Regression, VEL (m s^{-1})']);
ylabel('km');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)

s4=nexttile(4);
surf(XX,YY,stdVar2,'edgecolor','none');
view(2);
clim([0,4]);
s4.Colormap=jet;
colorbar;
title('(d) Regression, VEL SD (m s^{-1})');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)

s5=nexttile(5);
diffField=data2.(inFields{jj})-data1.(inFields{jj});
surf(XX,YY,diffField,'edgecolor','none');
view(2);
clim([-8,8]);
s5.Colormap=velCols;
colorbar;
title('(e) Regression - Level 2, VEL (m s^{-1})');
xlabel('km');
ylabel('km');

xlim(xlimits1)
ylim(ylimits1)

s6=nexttile(6);
diffField=stdVar2-stdVar1;
surf(XX,YY,diffField,'edgecolor','none');
view(2);
clim([-5,5]);
s6.Colormap=velCols;
colorbar;
title('(f) Regression - Level 2, VEL SD (m s^{-1})');
xlabel('km');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)

daspect(s1,[1 1 1]);
daspect(s2,[1 1 1]);
daspect(s3,[1 1 1]);
daspect(s4,[1 1 1]);
daspect(s5,[1 1 1]);
daspect(s6,[1 1 1]);

print([figdir,'figure12.png'],'-dpng','-r0');
