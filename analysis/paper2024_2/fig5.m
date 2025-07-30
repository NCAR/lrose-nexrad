% Plot hit miss table

clear all
close all

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/'));

figdir='/scr/cirrus1/rsfdata/projects/bomb_snowstorm/figures/paper2024_2/';

indir='/scr/sci/romatsch/forJohn/ams22plots/';

infileList={'mvel.txt';
    'Sachimvel.txt'};

titles={'(a) RFSF Order 37';
    '(b) Legacy'};

cm=turbo(32);

figure('Position',[200 500 360 570],'DefaultAxesFontSize',12);
colormap(flipud(cm));
t = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

xtickLoc=2:2:16;
xtickLab={'1','2','3','4','5','6','7','8'};

ytickLoc=1:5:26;
ytickLab={'0','10','20','30','40','50'};

for kk=1:length(infileList)
    infile=infileList{kk};

    indata=table2array(readtable([indir,infile]));

    s=nexttile(kk);
    hold on

    imagesc(flipud(indata+8));
    set(gca,'YDir','normal');
    set(gca,'Xtick',xtickLoc);
    set(gca,'XtickLabel',xtickLab);
    set(gca,'Ytick',ytickLoc);
    set(gca,'YtickLabel',ytickLab);
    clim([-1 3]);

    if kk==2
        cb=colorbar;
        cb.Title.String='m s^{-1}';
    end

    xline=0.5:1:18;
    yline=0.5:1:52;

    for ii=1:length(xline)
        plot([xline(ii),xline(ii)],[0,27],'-k','linewidth',0.5);
    end

    for ii=1:length(yline)
        plot([0,17],[yline(ii),yline(ii)],'-k','linewidth',0.5);
    end

    ax=gca;
    ax.SortMethod = 'childorder';

    xlim([0.5,16.5]);
    ylim([0.5,26.5]);

    if kk==2
        xlabel('W_1 (m s^{-1})')
    end

    ylabel('P_1/P_2 (dB)');


    title(titles{kk})
    % ax.Position=[0.123,0.14,0.75,0.84];
end
cb.Layout.Tile = 'east';
%cb.Position=[0.945,0.3,0.02,0.6];

set(gcf,'PaperPositionMode','auto')
print([figdir,'figure5.png'],'-dpng','-r0')
