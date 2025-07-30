% Read and diplay radar data

clear all;
close all;

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/'));

showPlot='on';

figdir='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/figures/paper2024/';

%% Load data

infileWN='/scr/sleet1/rsfdata/projects/eolbase/cfradial/kftg/moments/20220329/cfrad.20220329_221646.829_to_20220329_222242.984_KFTG_SUR.nc';

dataWN=[];

dataWN.DBZ=[];
dataWN.VEL=[];
dataWN.WIDTH=[];
dataWN.ZDR=[];
dataWN.PHIDP=[];
dataWN.RHOHV=[];

dataWN=read_spol(infileWN,dataWN);

dataWN=dataWN(1);

infileR='/scr/cirrus1/rsfdata/projects/nexrad/tables/KFTG_LPRT_SR_20220329_221645_1.91_253.46_14ptFlt28pt-V4.txt';
dataR=readDataTables(infileR,' ');

%% Plot preparation
ang_p = deg2rad(90-dataWN.azimuth);

angMat=repmat(ang_p,size(dataWN.range,1),1);

xlimits1=[-120,60];
ylimits1=[-110,70];

XX = (dataWN.range.*cos(angMat));
YY = (dataWN.range.*sin(angMat));

ang_p2 = deg2rad(90-dataR.azimuth);

angMat2=repmat(ang_p2,size(dataR.range,1),1);

XX2 = (dataR.range.*cos(angMat2));
YY2 = (dataR.range.*sin(angMat2));

%% Plot
close all

f1=figure('Position',[200 500 1000 900],'DefaultAxesFontSize',12,'visible',showPlot);
t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

s1=nexttile(1);
hold on
surf(XX,YY,dataWN.DBZ,'edgecolor','none');
view(2);
clim([-3 63])
s1.Colormap=dbz_default3;
cb1=colorbar('XTick',-3:4:67);
title('(a) Reflectivity Level2 (dBZ)')
ylabel('km');

scatter(0,0,60,'filled','MarkerFaceColor','w','MarkerEdgeColor','k');
text(-10,7,['KFTG'],'Color','w','FontSize',12,'FontWeight','bold');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)
daspect(s1,[1 1 1]);

%rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);
%scatter(0,0,90,'filled','MarkerFaceColor','w','MarkerEdgeColor','k');
%text(-20,0,['S-Pol'],'Color','w','FontSize',12,'FontWeight','bold');

s1.SortMethod='childorder';

% Refl. Reg.

s2=nexttile(2);
hold on
surf(XX2,YY2,dataR.DBZ_F,'edgecolor','none');
view(2);
clim([-3 63])
s2.Colormap=dbz_default3;
cb1=colorbar('XTick',-3:4:67);
title('(b) Reflectivity Regression (dBZ)')

scatter(0,0,60,'filled','MarkerFaceColor','w','MarkerEdgeColor','k');

grid on
box on

xlim(xlimits1)
ylim(ylimits1)
daspect(s2,[1 1 1]);

%rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);

s2.SortMethod='childorder';


% ZDR WN

s3=nexttile(3);
hold on
h3=surf(XX,YY,dataWN.ZDR,'edgecolor','none');
view(2);
title('(c) Z_{DR} Level2 (dB)')
xlabel('km');
ylabel('km');

grid on
box on

colLims=[-inf,-20,-2,-1,-0.8,-0.6,-0.4,-0.2,0,0.2,0.4,0.6,0.8,1,1.5,2,2.5,3,4,5,6,8,10,15,20,50,99,inf];
applyColorScale(h3,dataWN.ZDR,zdr_default,colLims);

scatter(0,0,60,'filled','MarkerFaceColor','w','MarkerEdgeColor','k');

xlim(xlimits1)
ylim(ylimits1)
daspect(s3,[1 1 1]);

%rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);

s3.SortMethod='childorder';

% ZDR Reg.

s4=nexttile(4);
hold on
h4=surf(XX2,YY2,dataR.ZDR_F,'edgecolor','none');
view(2);
title('(d) Z_{DR} Regression (dB)')
xlabel('km');

grid on
box on

colLims=[-inf,-20,-2,-1,-0.8,-0.6,-0.4,-0.2,0,0.2,0.4,0.6,0.8,1,1.5,2,2.5,3,4,5,6,8,10,15,20,50,99,inf];
applyColorScale(h4,dataR.ZDR_F,zdr_default,colLims);

grid on
box on

scatter(0,0,60,'filled','MarkerFaceColor','w','MarkerEdgeColor','k');

xlim(xlimits1)
ylim(ylimits1)
daspect(s4,[1 1 1]);

%rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);

s4.SortMethod='childorder';

%print([figdir,'figure22.png'],'-dpng','-r0');
exportgraphics(f1,[figdir,'figure19.png'],'Resolution','300');