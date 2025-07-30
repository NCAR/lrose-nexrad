% Calculate S-Pol moments

clear all;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Input variables %%%%%%%%%%%%%%%%%%%%%%%%%%
dataDir='/scr/cirrus2/rsfdata/projects/precip/spolField/time_series/sband/netcdf/';
infile='20220608_000235_1.49_319.86.sur.nc';

saveFig=0; % Set to 1 if figure should be saved
figdir='.';

showPlot='on';
sampleNum=64;

% For window and notch filter
windowIn='hamming';
winWidth=7;

file=[dataDir,infile(1:8),'/',infile];

%% Read data

disp('Loading data ...')
channel='Hc';
dataHc=readSPOLts(channel,file);

%% Get correct samples
azWanted=cat(2,ceil(dataHc.azimuth(1)):359,0:floor(dataHc.azimuth(end)));
azWanted=unique(azWanted,'stable');

azRound=round(dataHc.azimuth,1);
azRound=unique(azRound,'stable');

beamInds=[];

for ii=1:length(azWanted)
    [thisMin,thisInd]=min(abs(azRound-azWanted(ii)));
    beamInds=[beamInds,thisInd];
end

beamInds=unique(beamInds,'stable');

startInds=beamInds-floor(sampleNum/2)+1;
endInds=beamInds+floor(sampleNum/2);

while startInds(1)<1
    startInds(1)=[];
    endInds(1)=[];
    beamInds(1)=[];
end
if endInds(end)>size(dataHc.I,2)
    startInds(end)=[];
    endInds(end)=[];
    beamInds(end)=[];
end

%% Loop through azimuth angles

beamNum=length(startInds);

moments.powerDB=nan(size(dataHc.range,1),beamNum);
moments.vel=nan(size(dataHc.range,1),beamNum);
moments.width=nan(size(dataHc.range,1),beamNum);
moments.snr=nan(size(dataHc.range,1),beamNum);
moments.dbz=nan(size(dataHc.range,1),beamNum);

timeBeams=[];
azBeams=nan(1,beamNum);
elBeams=nan(1,beamNum);

% Loop through beams

for ii=1:length(startInds)

    startInd=startInds(ii);
    endInd=endInds(ii);

    azBeams(ii)=azRound(beamInds(ii));
   
    %% IQ

    if strcmp(windowIn,'hamming')
        win=window(@hamming,sampleNum);  % Default window is Hamming
    end
    winWeight=sampleNum/sum(win);
    winNorm=win*winWeight;

    % Regular
    cIQhc=winNorm'.*(dataHc.I(:,startInd:endInd)+i*dataHc.Q(:,startInd:endInd));

    %% Calculate moments

    R0hc=mean(real(cIQhc).^2+imag(cIQhc).^2,2);
    R1hc=mean(cIQhc(:,1:end-1).*conj(cIQhc(:,2:end)),2);
    R2hc=mean(cIQhc(:,1:end-2).*conj(cIQhc(:,3:end)),2);

    moments.powerDB(:,ii)=single(10*log10(R0hc)-dataHc.rx_gain);
    moments.vel(:,ii)=single(dataHc.lambda/(4*pi*mode(dataHc.prt))*angle(R1hc));
    moments.width(:,ii)=dataHc.lambda/(2*pi.*mode(dataHc.prt)*6^.5)*abs(log(abs(R1hc./R2hc))).^0.5;

    % SNR
    noiseLin=10.^(dataHc.noiseLev./10);
    snrLin=(R0hc-noiseLin)./noiseLin;
    snrLin(snrLin<0)=nan;
    moments.snr(:,ii)=single(10*log10(snrLin));

    % DBZ
    moments.dbz(:,ii)=moments.snr(:,ii)+20*log10(dataHc.range./1000)+dataHc.dbz1km;
end

%% Set up plot

ang_p = deg2rad(90-azBeams');

XX = double((dataHc.range./1000*cos(ang_p')).');
YY = double((dataHc.range./1000*sin(ang_p')).');

%% Plot

disp('Plotting ...');

xlimits=[-150 150];
ylimits=[-150 150];

f1 = figure('Position',[510 500 1500 1200],'DefaultAxesFontSize',12,'visible',showPlot);

s1=subplot(2,2,1);

surf(XX',YY',moments.powerDB,'edgecolor','none');
view(2);
colorbar
caxis([-120 0])
title('DBM (dB)')
xlabel('km');
ylabel('km');
s1.Colormap=dbz_default;
axis equal
xlim(xlimits)
ylim(ylimits)

s2=subplot(2,2,2);

surf(XX',YY',moments.dbz,'edgecolor','none');
view(2);
colorbar
caxis([-15 75]);
title('DBZ (dBZ)')
xlabel('km');
ylabel('km');
s2.Colormap=dbz_default;
axis equal
xlim(xlimits)
ylim(ylimits)

s3=subplot(2,2,3);

surf(XX',YY',moments.vel,'edgecolor','none');
view(2);
colorbar
caxis([-24 24])
title('VEL (m s^{-1})')
xlabel('km');
ylabel('km');
s3.Colormap=vel_default;
axis equal
xlim(xlimits)
ylim(ylimits)

s4=subplot(2,2,4);

surf(XX',YY',moments.width,'edgecolor','none');
view(2);
colorbar
caxis([0 17])
title('WIDTH (m s^{-1})')
xlabel('km');
ylabel('km');
s4.Colormap=width_default;
axis equal
xlim(xlimits)
ylim(ylimits)

if saveFig
    set(gcf,'PaperPositionMode','auto')
    print(f1,[figdir,'moments_',channel,'_',datestr(data.time(1),'yyyymmdd_HHMMSS'),'_to_',datestr(data.time(end),'yyyymmdd_HHMMSS')],'-dpng','-r0');
end