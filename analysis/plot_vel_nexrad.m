% Read and diplay radar data

clear all;
close all;

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/utils/'));

showPlot='on';

figdir='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/figures/timFigsVel/';

%% Loop through cases

fileID = fopen('plotFiles_velNEXRAD.txt');
inAll=textscan(fileID,'%s %s %f %f %f %f %s %f');
fclose(fileID);

for aa=1:size(inAll{1,1},1)

    infile=inAll{1,1}(aa);

    disp(['File ',num2str(aa), ' of ',num2str(size(inAll{1,1},1))]);
    disp(infile{:});

    fileType=inAll{1,7}(aa);

    if strcmp(fileType{:},'nc')
        data=[];

        data.VEL=[];
        %data.prt=[];

        data=read_spol(infile{:},data);

        data=data(inAll{1,8}(aa));
    elseif strcmp(fileType{:},'table')
        data=readDataTables(infile{:},' ');
    end

    outstr=inAll{1,2}(aa);
    outstr=outstr{:};

    %% Plot preparation

    ang_p = deg2rad(90-data.azimuth);

    angMat=repmat(ang_p,size(data.range,1),1);

    XX = (data.range.*cos(angMat));
    YY = (data.range.*sin(angMat));

    %% VEL
    close all

    figure('Position',[200 500 800 700],'DefaultAxesFontSize',12);

    s1=subplot(1,1,1);
    h1=surf(XX,YY,data.VEL,'edgecolor','none');
    view(2);
    title('VEL (m s^{-1})')
    xlabel('km');
    ylabel('km');

    grid on
    box on

    colLims=[-inf,-30,-26,-21,-17,-13,-10,-8,-6,-4,-2,-1,0,1,2,4,6,8,10,13,17,21,26,30,inf];
    applyColorScale(h1,data.VEL,vel_default2,colLims);

    xlimits1=[inAll{1,3}(aa),inAll{1,4}(aa)];
    ylimits1=[inAll{1,5}(aa),inAll{1,6}(aa)];
    
    xlim(xlimits1)
    ylim(ylimits1)

    daspect(s1,[1 1 1]);

    print([figdir,outstr,'_VEL.png'],'-dpng','-r0');

end