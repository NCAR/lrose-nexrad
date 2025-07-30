% Read and diplay radar data

clear all;
close all;

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/'));

showPlot='on';

figdir='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/figures/paper2024/';

%% Load data

infileWN='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/tables/SPOL20190313_220622_INDX_CMD_RHV_GAUSS_WN_V3_1.txt';
dataWN=readDataTables(infileWN,' ');

infileR='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/tables/SPOL20190313_220622_INDX_CMD_RHV_GAUSS_REG_V3.txt';
dataR=readDataTables(infileR,' ');

%% Plot preparation

ang_p = deg2rad(90-dataWN.azimuth);

angMat=repmat(ang_p,size(dataWN.range,1),1);

xlimits1=[-20,100];
ylimits1=[-20,100];

XX = (dataWN.range.*cos(angMat));
YY = (dataWN.range.*sin(angMat));

%% Plot
close all

f1=figure('Position',[200 500 1000 900],'DefaultAxesFontSize',12,'visible',showPlot);
t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

s1=nexttile(1);
hold on
h1=surf(XX,YY,dataWN.PHIDP_F,'edgecolor','none');
view(2);
clim([-60 92])
title(['(a) \phi_{DP} WN (',char(176),')'])
ylabel('km');
s1.Colormap=phidp_default;
colorbar

grid on
box on

xlim(xlimits1)
ylim(ylimits1)
daspect(s1,[1 1 1]);

rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);
scatter(0,0,90,'filled','MarkerFaceColor','w','MarkerEdgeColor','k');
text(-20,0,['S-Pol'],'Color','w','FontSize',12,'FontWeight','bold');

s1.SortMethod='childorder';

% Width Reg.

s2=nexttile(2);
hold on
h3=surf(XX,YY,dataR.PHIDP_F,'edgecolor','none');
view(2);
clim([-60 92])
title(['(b) \phi_{DP} Regression (',char(176),')'])
s2.Colormap=phidp_default;
colorbar

grid on
box on

xlim(xlimits1)
ylim(ylimits1)
daspect(s2,[1 1 1]);

rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);

s2.SortMethod='childorder';

% Rho WN

s3=nexttile(3);
h2=surf(XX,YY,dataWN.RHOHV_NNC_F,'edgecolor','none');
view(2);
title('(c) \rho_{HV} WN')
xlabel('km');
ylabel('km');

grid on
box on

colLims=[-inf,0,0.7,0.8,0.85,0.9,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.975,0.98,0.985,0.99,0.995,1.1,inf];
applyColorScale(h2,dataWN.RHOHV_NNC_F,rhohv_default,colLims);

grid on
box on

xlim(xlimits1)
ylim(ylimits1)
daspect(s3,[1 1 1]);

rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);

s3.SortMethod='childorder';

% ZDR Reg.

s4=nexttile(4);
h4=surf(XX,YY,dataR.RHOHV_NNC_F,'edgecolor','none');
view(2);
title('(d) \rho_{HV} Regression')
xlabel('km');

grid on
box on

colLims=[-inf,0,0.7,0.8,0.85,0.9,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.975,0.98,0.985,0.99,0.995,1.1,inf];
applyColorScale(h4,dataR.RHOHV_NNC_F,rhohv_default,colLims);

grid on
box on

xlim(xlimits1)
ylim(ylimits1)
daspect(s4,[1 1 1]);

rectangle('Position',[5 -17 40 55],'EdgeColor','w','LineWidth',1.5);

s4.SortMethod='childorder';

%print([figdir,'figure15.png'],'-dpng','-r0');
exportgraphics(f1,[figdir,'figure12.png'],'Resolution','300');