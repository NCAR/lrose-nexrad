% Calculate statistics for moments

clear all;
close all;

addpath(genpath('~/gitPriv/nexrad/'));
addpath(genpath('~/gitPriv/utils/'));

figdir=['/scr/sci/romatsch/nexrad/timeSeriesNetCDF/figs/statsDiffMethod/'];

varCalc='dbz';
minRange=10;
maxRange=150;

xPlot=[];
yPlot=[];
% S-Pol
% xPlot=[-30 150];
% yPlot=[-100 120];
% KDDC
xPlot=[-60 15];
yPlot=[-10 65];

kernel=[9,5]; % Kernel size [range,azimuth]
nyquist=26.675;

% File 1
%in1='outvolumeKDDC20200525_030738_3.77_32.59LPRT_SupRes.txt';
%in1='john_20190313_220622_to_20190313_220708.';
%in1='cfrad.20190313_220537.089_to_20190313_221323.838_SPOL_SurKa_SUR.nc';
%in1='cfrad.20190313_220622.932_to_20190313_220707.820_SPOL_SurKa_SUR.nc';
%in1='filt_20190313_220622_to_20190313_220708.mat';
%in1='win_20190313_220622_to_20190313_220708.mat';
%in1='KDDC20200525_030738_3.77_32.59LPRT16Pt_SupResLOW.txt';
in1='KDDC20200525_030738_3.77_32.59LPRT16Pt_SupResMedium.txt';
%in1='KDDC20200525_030738_3.77_32.59LPRT16Pt_SupResHigh.txt';
%in1='SPOL20190313_220622LOW.txt';
%in1='SPOL20190313_220622MEDIUM.txt';
%in1='SPOL20190313_220622HIGH.txt';

% File 2
%in2=[];
%in2='cfrad.20200525_030739.662_to_20200525_031426.047_KDDC_SUR.nc';
%in2='john_20190313_220622_to_20190313_220708.';
%in2='cfrad.20190313_220537.089_to_20190313_221323.838_SPOL_SurKa_SUR.nc';
%in2='cfrad.20190313_220622.932_to_20190313_220707.820_SPOL_SurKa_SUR.nc';
%in2='filt_20190313_220622_to_20190313_220708.mat';
%in2='win_20190313_220622_to_20190313_220708.mat';
%in2='KDDC20200525_030738_3.77_32.59LPRT16Pt_SupResLOW.txt';
%in2='KDDC20200525_030738_3.77_32.59LPRT16Pt_SupResMedium.txt';
in2='KDDC20200525_030738_3.77_32.59LPRT16Pt_SupResHIGH.txt';
%in2='SPOL20190313_220622LOW.txt';
%in2='SPOL20190313_220622MEDIUM.txt';
%in2='SPOL20190313_220622HIGH.txt';

%% Load data

[moments1,moments2]=loadCompareFiles(in1,in2);

%% Get variable and area

%% File 1
areaVar1=moments1.(varCalc);
goodInds1=find(moments1.range>=minRange & moments1.range<=maxRange);
smallVar1=areaVar1(goodInds1,:);
range1=double(moments1.range(goodInds1));

% Re-organize azimuth
[az1,ia,ic]=unique(moments1.azimuth);
smallVar1=smallVar1(:,ia);

%% File 2
if ~isempty(in2)
    areaVar2=moments2.(varCalc);
    goodInds2=find(moments2.range>=minRange & moments2.range<=maxRange);
    smallVar2orig=areaVar2(goodInds2,:);
    range2=double(moments2.range(goodInds2));

    % Re-organize azimuth
    [az2,ia,ic]=unique(moments2.azimuth);
    smallVar2orig=smallVar2orig(:,ia);

    % Interpolate var2 to var1 grid
    smallVar2=interp2(az2,range2,smallVar2orig,repmat(az1',1,length(range1))',repmat(range1,1,length(az1)),'nearest');

    % Make nans agree
    smallVar1(isnan(smallVar2))=nan;
    smallVar2(isnan(smallVar1))=nan;
end

%% Standard deviation
if strcmp(varCalc,'vel')
    [stdVar1,~]=fast_nd_std(smallVar1,kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',nyquist);
else
    [stdVar1,~]=fast_nd_std(smallVar1,kernel,'mode','partial','nan_std',1);
end

% For plot
ang_p1=deg2rad(90-az1');

XX1=double((range1*cos(ang_p1')).');
XX1=XX1';
YY1=double((range1*sin(ang_p1')).');
YY1=YY1';

if strcmp(varCalc,'dbz')
    collims=[max([-10,min(smallVar1(:))]),min([70,max(smallVar1(:))])];
elseif strcmp(varCalc,'vel')
    collims=[-30,30];
end

%% File 2
if ~isempty(in2)
    % Standard deviation
    if strcmp(varCalc,'vel')
        [stdVar2,~]=fast_nd_std(smallVar2,kernel,'mode','partial','nan_std',1,'circ_std',1,'nyq',nyquist);
    else
        [stdVar2,~]=fast_nd_std(smallVar2,kernel,'mode','partial','nan_std',1);
    end

    ang_p2=deg2rad(90-az2');

    XX2=double((range2*cos(ang_p2')).');
    XX2=XX2';
    YY2=double((range2*sin(ang_p2')).');
    YY2=YY2';

    %% Plot

    close all

    f1 = figure('Position',[510 500 2000 1000],'DefaultAxesFontSize',12);
    colormap('jet');

    s2=subplot(2,3,2);

    surf(XX1,YY1,smallVar1,'edgecolor','none');
    view(2);
    caxis(collims)
    colorbar
    title(['File 1 ',varCalc])
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    s3=subplot(2,3,3);

    surf(XX1,YY1,stdVar1,'edgecolor','none');
    view(2);
    caxis([0 15]);
    colorbar
    title(['File 1 ',varCalc,' std']);
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    s4=subplot(2,3,4);

    surf(XX2,YY2,smallVar2orig,'edgecolor','none');
    view(2);
    caxis(collims)
    colorbar
    title(['File 2 ',varCalc])
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    s5=subplot(2,3,5);

    surf(XX1,YY1,smallVar2,'edgecolor','none');
    view(2);
    caxis(collims)
    colorbar
    title(['File 2 ',varCalc,' interpolated']);
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    s6=subplot(2,3,6);

    surf(XX1,YY1,stdVar2,'edgecolor','none');
    view(2);
    caxis([0 15]);
    colorbar
    title(['File 2 ',varCalc,' std']);
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    s1=subplot(2,3,1);

    surf(XX1,YY1,stdVar2-stdVar1,'edgecolor','none');
    view(2);
    caxis([-5 5]);
    s1.Colormap=velCols;
    colorbar
    title(['std2-std1 ',varCalc]);
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    dot1=strfind(in1,'.');
    fn1=in1(1:dot1(end)-1);
    dot2=strfind(in2,'.');
    fn2=in2(1:dot2(end)-1);

    p=mtit(['File 1: ',fn1,'. File 2: ',fn2,'.'],...
        'fontsize',14,'xoff',0,'yoff',0.05,'interpreter','none');

    linkaxes([s1 s2 s3 s4 s5 s6],'xy');

    if isempty(xPlot) | isempty(yPlot)
        print(f1,[figdir,varCalc,'__',fn1,'__',fn2,'_',num2str(maxRange),'km.png'],'-dpng','-r0');
    else
        print(f1,[figdir,varCalc,'__',fn1,'__',fn2,'_custom.png'],'-dpng','-r0');
    end
else
     %% Plot

    close all

    f1 = figure('Position',[510 500 1200 500],'DefaultAxesFontSize',12);
    colormap('jet');

    s1=subplot(1,2,1);

    surf(XX1,YY1,smallVar1,'edgecolor','none');
    view(2);
    caxis(collims)
    colorbar
    title(['File 1 ',varCalc])
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    s2=subplot(1,2,2);

    surf(XX1,YY1,stdVar1,'edgecolor','none');
    view(2);
    caxis([0 15]);
    colorbar
    title(['File 1 ',varCalc,' std']);
    xlabel('km');
    ylabel('km');
    axis equal
    if isempty(xPlot) | isempty(yPlot)
        xlim([-maxRange,maxRange]);
        ylim([-maxRange,maxRange]);
    else
        xlim(xPlot);
        ylim(yPlot);
    end
    grid on
    box on

    dot1=strfind(in1,'.');
    fn1=in1(1:dot1(end)-1);
    
    p=mtit(['File 1: ',fn1,'.'],...
        'fontsize',14,'xoff',0,'yoff',0.0,'interpreter','none');

    linkaxes([s1 s2],'xy');

    if isempty(xPlot) | isempty(yPlot)
        print(f1,[figdir,varCalc,'__',fn1,'_',num2str(maxRange),'km.png'],'-dpng','-r0');
    else
        print(f1,[figdir,varCalc,'__',fn1,'_custom.png'],'-dpng','-r0');
    end
end