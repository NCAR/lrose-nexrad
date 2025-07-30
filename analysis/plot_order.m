% Read and diplay radar data

clear all;
close all;

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/utils/'));

infile='/scr/cirrus1/rsfdata/projects/nexrad/cfradial/kftg.longprt.regr/20220329/cfrad.20220329_175334.757_to_20220329_175405.283_KFTG_SUR.nc';

outstr='kftg_20220329_175334_';

figdir=['/scr/cirrus1/rsfdata/projects/nexrad/figures/kftg/'];

data=[];

data.REGR_ORDER=[];

data=read_spol(infile,data);


%% Plot preparation

ang_p = deg2rad(90-data.azimuth);

angMat=repmat(ang_p,size(data.range,1),1);

XX = (data.range.*cos(angMat));
YY = (data.range.*sin(angMat));

%% Z
close all

figure('Position',[200 500 600 500],'DefaultAxesFontSize',12);

s1=subplot(1,1,1);
h=surf(XX,YY,data.REGR_ORDER,'edgecolor','none');
view(2);
title('ORDER')
xlabel('km');
ylabel('km');

s1.Colormap=turbo(10);
caxis([0,10]);
colorbar;

grid on
box on

xlim([-110,-20]);
ylim([-10,100]);
daspect(s1,[1 1 1]);

print([figdir,outstr,'ORDER_zoomDeep_WF1.png'],'-dpng','-r0');

