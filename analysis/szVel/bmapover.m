% BMAPOVER   Boon Leng's Map overlay
%    BMAPOVER draws a map overlay on top of the current axis, assuming the
%    the KOUN radar (97.463161W,35.236208N) as the origin (0,0).
%    The axis limit is in units of km.
%
%    More usage options:
%    BMAPOVER(AXES_H) draws map overlay on AXES_H
%
%    BMAPOVER(AXES_H,FLAGS,ORIGIN,ONESTATE) draws the map on AXES_H (can 
%    be a vector) and uses FLAGS to determine which lines to draw.
%    FLAGS is a logical array recognized as:
%    FLAGS = [State, County, Interstate, Local HWY, Capital, County Seat,
%             Big Town, Small Town, Others, OK Mesonet, Weather Station, GUI]
%    SUBSTATE = 0 or 1 to plot only the viewing state only.
%    SUBSTATE = 'OK' to plot only OK state
%    SUBSTATE = {'OK','KS'} to plot OK and KS states
%
%    Usage: bmapover(gca) draws using default options; or
%           bmapover(gca,[1 0 1]) draws state and interstate only
%           bmapover(gca,[1 3]) is the same as above
%           bmapover(gca,[],'KCYR') draws with origin as 'KCYR'
%           bmapover(gca,[],'KDDC',{'NE','KS'}) draws with just NE and KS states
%           bmapover(gca,[],{-104,36,'Radar','OK'}) plots around (lon,lat)
%
%    VIS = BMAPOVER returns a structure containing the mapping details
%
%
%    Created on 6/5/2005
%    Last updated on 
%    Boon Leng Cheong
%
%    Version 0.95 - Updated on 5/18/2008
%                 - Added KFDR.
%    Version 0.95 - Updated on 5/15/2006
%                 - UI is independent from desktop variable VIS.
%                 - New map data from http://www.nationalatlas.gov
%                 - Support 48 continental states for state and county
%                   borders, state capital and interstate highway
%                 - New map data includes Mesonet stations
%                 - Airport labels are removed
%                 - Labels are not drawn first so less objects to handle
%    Version 0.94 - Took out the order option, not used anyway.
%                 - Added flags option, don't plot objectss that are not
%                   requested.  Sometimes this speed things up by 4x !
%    Version 0.93 - Improve compatibility with Matlab v6
%    Version 0.92 - No points for city labels.
%    Version 0.91 - Use rotations, rotate (-longitude) along z-axis, 
%                   then (-latitude) along y-axis, look along x-axis
%                   toward the origin. z = north, y towards greenwich 
%    Version 0.9  - More flexible, uses own axes
%                 - Supports multiple axes, AXES_H can be a vector
%    Version 0.1  - Buggy, use at your own risk
%
function [VIS] = bmapover(axes_handler_set,flags,origin,substate)


if ~exist('axes_handler_set','var')||isempty(axes_handler_set)
    if isempty(get(gcf,'CurrentAxes')), 
        axes_handler_set = axes('Units','Normalized','Position',[0.08 0.06 0.9 0.9]);
        axis(0.5*[-2350 2450 -1500 2100]);
    else
        axes_handler_set = gca;
    end
end
if exist('flags','var')&&~isempty(flags)&&any(flags>1),
    tmp = logical([zeros(1,11) 1]); tmp(flags) = 1; flags = logical(tmp);
end
if ~exist('flags','var')||isempty(flags), flags = logical([ones(1,10) 1 0]); end
if (length(flags)~=12), flags(length(flags)+1:11) = 0; flags(12) = 0; end
if ~exist('origin','var')||isempty(origin), origin = 'KOUN'; end
if ~exist('substate','var')||isempty(flags), substate = 0; end
if ischar(substate)||iscell(substate)
    tmp = {'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA',...
           'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY',...
           'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY'};
    if any(~ismember(substate,tmp))
        fprintf('One of the specified states is not available')
        return
    end
    ref_st = substate;
    substate = true;
end


load('bmapover_map.mat');
r_earth = 6378.1;  % The Earth's Radius = 6378.1 km
% Reminder: When adding a station, lab, lon, lat and st must all be filled
% 'CHILL' -104.63708  40.44625   CO
%{'Blue Canyon', -98.54752, 34.85820, 'OK'};


%     origin = {-97.930556,34.81278,'KRSP','OK'};
%     origin = {-97.956111,35.03139,'KSAO','OK'};


MAP(11).lab  = {'KOUN','KTLX','KLWX','KFTG'};
MAP(11).lon = [-97.463161 -97.277831 -77.48746, -104.54572];
MAP(11).lat = [ 35.236208  35.333411  38.97625    39.78661];
MAP(11).st = {'OK','OK','VA','CO'};


if iscell(origin)
    if numel(origin)==4
        MAP(11).lab{end+1} = origin{3};
        MAP(11).lon(end+1) = origin{1};
        MAP(11).lat(end+1) = origin{2};
        MAP(11).st{end+1} = origin{4};
        origin = origin{3};
    else
        fprintf('Invalid input structure, should be {lat,lon,''Label'',''ST''}.\n');
        return;
    end
end
if ismember(origin,{'KCRI','PAR','KOUN'}), origin = 'KOUN'; end
if ~ischar(origin)&&~isstruct(origin), error('Origin must be either a string or a structure'); end
if ~ismember(origin,MAP(11).lab), error(['No origin: ',origin]); end


[yesno,pos] = ismember(origin,MAP(11).lab);
lon_o = MAP(11).lon(pos);
lat_o = MAP(11).lat(pos);


% Get the properties of the plotting axes
axes_handler = axes_handler_set(1);
axes(axes_handler)
alim = [get(axes_handler,'XLim'),get(axes_handler,'YLim')];  % Axis limit in m
% Initialize some handles before plotting the map
num_ax = length(axes_handler_set);
tmp = -1*ones(num_ax,6);
VIS = struct('fh',[],'peer',[],'ax',axes_handler_set,'h',tmp,'ht1',tmp(:,1),'ht2',tmp(:,1),'ht3',tmp(:,1),...
             'ht4',tmp(:,1),'ht5',tmp(:,1),'ht6',tmp(:,1),'ht7',tmp(:,1));
% Coverage in km to plot, the buffer is a bit tricky, some segments are 50km long!
if max(alim(2)-alim(1),alim(4)-alim(3))>100
    tmp = alim+0.3*(alim(2)-alim(1))*[-1 1 -1 1];
else
    tmp = alim+40*[-1 1 -1 1];
end
% Another extra a little bit to work with
LL = [tmp(1:2)/cos(lat_o/180*pi) tmp(3:4)]./r_earth*180/pi+[lon_o lon_o lat_o lat_o]+...
     [max(0.1*(tmp(2)-tmp(1))/cos(lat_o/180*pi),10)*[-1 1] max(0.1*(tmp(4)-tmp(3)),10)*[-1 1]]./r_earth*180/pi;
% Pre-processing to focus on needed subsets
if ((LL(1)>-118)||(LL(2)<-74)||(LL(3)>30)||(LL(4)<45))
    lon_v = 0.5*(LL(1)+LL(2)); lat_v = 0.5*(LL(3)+LL(4));
    if ~exist('ref_st','var')
        % Find a state bounding box that encloses the viewing center and use it as ref_st
        yn = (lon_v>MAP(2).box(1,:))&(lon_v<MAP(2).box(2,:))&(lat_v>MAP(2).box(3,:))&(lat_v<MAP(2).box(4,:));
        idx = find(yn); ref_st = unique(MAP(2).st(idx));
        %if (length(ref_st)>1), fprintf('I''m guessing the reference is %s\n',ref_st{1}); end
        if isempty(ref_st), fprintf('Sorry out of data.\n'); return; end
    end
    if (~any(ismember(ref_st,{'OK'}))&&substate), flags(10) = 0; end
    
    for idx = find(flags(1:4))
        if substate
            yn = ismember(MAP(idx).st,ref_st);
        else
            yn = isoverlap(LL,MAP(idx).box);
        end
        MAP(idx).lon = [MAP(idx).lon{yn}];
        MAP(idx).lat = [MAP(idx).lat{yn}];
        MAP(idx).st = MAP(idx).st(yn);
    end
    if substate
        for idx = 4+find(flags(5:11))
            yn = ismember(MAP(idx).st,ref_st);
            MAP(idx).lon = MAP(idx).lon(yn);
            MAP(idx).lat = MAP(idx).lat(yn);
            MAP(idx).lab = MAP(idx).lab(yn);
            MAP(idx).st = MAP(idx).st(yn);
        end
    end
else
    % Convert cell to double array
    for idx = 1:4
        MAP(idx).lon = [MAP(idx).lon{:}]; MAP(idx).lat = [MAP(idx).lat{:}];
    end
end


% Convert longitude/latitude to 3-D on the earth surface as a sphere, then
% rotate along z-axis, then along y-axis.  View the map from x-axis, which 
% is viewing Y vs. Z as East vs. North.
%thx = 0/180*pi;
thy = lat_o/180*pi;
thz = -lon_o/180*pi;
%Rx = [1 0 0; 0 cos(thx) -sin(thx); 0 sin(thx) cos(thx)];
Ry = [cos(thy) 0 sin(thy); 0 1 0; -sin(thy) 0 cos(thy)];
Rz = [cos(thz) -sin(thz) 0; sin(thz) cos(thz) 0; 0 0 1];
R = Ry*Rz;


% Earth's equitorial radius a = 6,378.137 km
a = 6378.137;
% Earth's polar radius b = 6,356.7523 km
b = 6356.7523;


% r_earth = sqrt(((a^2+cos(phi)).^2+(b^2*sin(phi)).^2)./((a*cos(phi)).^2+(b*sin(phi)).^2));


for idx = find(flags(1:4))
	
    % Absolute position for the points/lines
    xyz = r_earth*[cos(MAP(idx).lat*pi/180).*cos(MAP(idx).lon*pi/180); ...
                   cos(MAP(idx).lat*pi/180).*sin(MAP(idx).lon*pi/180); ...
                   sin(MAP(idx).lat*pi/180)];
% 	phi = MAP(idx).lat*pi/180;
% 	theta = MAP(idx).lon*pi/180;
% 	r_earth = sqrt(((a^2+cos(phi)).^2+(b^2*sin(phi)).^2)./((a*cos(phi)).^2+(b*sin(phi)).^2));
% 	xyz = ([1 1 1]'*r_earth).*[cos(phi).*cos(theta); cos(phi).*sin(theta); sin(phi)];


    if size(xyz,1)~=3
        MAP(idx).x = [];
        MAP(idx).y = [];
        %MAP(idx).z = [];
    else
        MAP(idx).x = R(2,:)*xyz;
        MAP(idx).y = R(3,:)*xyz;
        %MAP(idx).z = R(1,:)*xyz-r_earth;
    end
    % Within plotting domain or NaN (need them for different lines)
    mask = (MAP(idx).x>=tmp(1)&MAP(idx).x<=tmp(2)&...
            MAP(idx).y>=tmp(3)&MAP(idx).y<=tmp(4))|...
           ~isfinite(MAP(idx).x);
    mask2 = ~isfinite(MAP(idx).x);
    stidx = [1 find(mask2)];
    for jdx = 1:length(stidx)-1
        % If only some segments of the line are inside
        if any(mask(stidx(jdx)+1:stidx(jdx+1)-1))&&~all(mask(stidx(jdx)+1:stidx(jdx+1)-1)),
            % Points between NaN that are outside plotting domain
            eidx = find(~mask(stidx(jdx)+1:stidx(jdx+1)-1));
            mask(stidx(jdx)+eidx) = 1;
            MAP(idx).x(stidx(jdx)+eidx) = nan;
        end
    end
    if all(~mask)
        % Put a dummy point if there is nothing to plot
        MAP(idx).x = nan;
        MAP(idx).y = nan;
        %MAP(idx).z = nan;
        flags(idx) = 0;
    else
        % Extract the okay points
        MAP(idx).x = MAP(idx).x(mask);
        MAP(idx).y = MAP(idx).y(mask);
        %MAP(idx).z = MAP(idx).z(mask);
    end
    % Take out consecutive NaN
    mask = [true,isfinite(MAP(idx).x(1:end-1))|isfinite(MAP(idx).x(2:end))];
    MAP(idx).x = MAP(idx).x(mask);
    MAP(idx).y = MAP(idx).y(mask);
    %MAP(idx).z = MAP(idx).z(mask);
end


% For labels: Extract the labels that might be used later
for idx = 4+find(flags(5:11))


    xyz = r_earth*[cos(MAP(idx).lat*pi/180).*cos(MAP(idx).lon*pi/180); ...
                   cos(MAP(idx).lat*pi/180).*sin(MAP(idx).lon*pi/180); ...
                   sin(MAP(idx).lat*pi/180)];
% 	phi = MAP(idx).lat*pi/180;
% 	theta = MAP(idx).lon*pi/180;
% 	r_earth = sqrt(((a^2+cos(phi)).^2+(b^2*sin(phi)).^2)./((a*cos(phi)).^2+(b*sin(phi)).^2));
% 	xyz = ([1 1 1]'*r_earth).*[cos(phi).*cos(theta); cos(phi).*sin(theta); sin(phi)];


    x = R(2,:)*xyz;
    y = R(3,:)*xyz;
    %z = R(1,:)*xyz-r_earth;
    mask = (x>=tmp(1))&(x<=tmp(2))&(y>=tmp(3))&(y<=tmp(4));
    % Special case: copy all the mesonet stations out
    if (idx==10), VIS.mnet_x = x; VIS.mnet_y = y; VIS.mnet_stid = MAP(idx).lab; end
    if isempty(mask)||all(~mask)
        % Put a dummy point if there is nothing to plot
        MAP(idx).x = nan;
        MAP(idx).y = nan;
        %MAP(idx).z = nan;
        MAP(idx).lab = {''};
        MAP(idx).st = {''};
        flags(idx) = 0;
    else
        MAP(idx).x = x(mask);
        MAP(idx).y = y(mask);
        %MAP(idx).z = z(mask)-r_earth;
        MAP(idx).lab = MAP(idx).lab(mask);
        MAP(idx).st = MAP(idx).st(mask);
    end
end


br = get(gca,'Color');
br = [0.3 0.59 0.11]*br(:);      % Brightness of gca's color


if br>0.5
    clr = [0.7843  0.7451  0.4706; ... % State
           0.4000  0.4000  0.4000; ... % County
           0.6275  0.5490  0.4706; ... % Interstate
           0.9804  0.7059  0.2118; ... % Local HWY
                0       0       0; ... % State Capital
           0.6000  0.3000  1.0000; ... % KOUN/PAR, etc
           0.3500  0.2800  0.2000; ... % County Seat
           0.3000  0.2000  0.1000; ... % Pop>10k
           0.3000  0.3000  0.3000; ... % Pop>1000
           0.3000  0.3000  0.3000; ... % Others
           0.3500  0.2000       0];    % Mesonet
else
    clr = [1.0000  0.9630  0.7037; ... % State
           0.4000  1.0000  0.2500; ... % County
           1.0000  0.9262  0.8525; ... % Interstate
           0.7000  0.7000  0.7000; ... % Local HWY
           1.0000  1.0000  1.0000; ... % State Capital
           0.7300  0.5250  1.0000; ... % KOUN/PAR, etc
           1.0000  0.9338  0.7500; ... % County Seat
           1.0000  0.9000  0.6500; ... % Pop>10k
           1.0000  0.8000  0.5000; ... % Pop>1000
           1.0000  0.7000  0.3500; ... % Others
           1.0000  0.9075  0.8151];    % Mesonet
end


% Drawing
for iax=1:num_ax
    axes(axes_handler_set(iax))
    hold on
    if flags(2), VIS.h(iax,2) = plot(MAP(2).x,MAP(2).y,'Color',clr(2,:)); end                 % County
    if flags(4), VIS.h(iax,4) = plot(MAP(4).x,MAP(4).y,'Color',clr(4,:),'LineWidth',2); end   % Local HWY
    if flags(3), VIS.h(iax,3) = plot(MAP(3).x,MAP(3).y,'Color',clr(3,:),'LineWidth',2); end   % Interstate
    if flags(1), VIS.h(iax,1) = plot(MAP(1).x,MAP(1).y,'Color',clr(1,:),'LineWidth',2); end   % State
    if flags(10), VIS.h(iax,5:4+double(~isempty(MAP(10).x))) = plot(MAP(10).x,MAP(10).y,'^',...
        'Clipping','On','Color',clr(11,:),'MarkerFaceColor',clr(11,:),'MarkerSize',4); end    % OK Mesonet
    if flags(5), VIS.ht2(iax,1:length(MAP(5).x)) = text(MAP(5).x,MAP(5).y,MAP(5).lab,...
        'Color',clr(5,:),'FontWeight','Bold','FontSize',12,'Clipping','On',...
        'HorizontalAlignment','Center','VerticalAlignment','Middle'); end                     % State Capital
    if flags(11), VIS.ht1(iax,1:length(MAP(11).lab)) = text(MAP(11).x,MAP(11).y,MAP(11).lab,...
        'Color',clr(6,:),'FontWeight','Bold','FontSize',10,'Clipping','On',...
        'HorizontalAlignment','Left','VerticalAlignment','Bottom'); end                       % KOUN/PAR, etc
    if flags(11), VIS.h(iax,6) = plot(MAP(11).x,MAP(11).y,'o',...
        'Color',clr(6,:),'Markersize',3,'MarkerFaceColor',clr(6,:),'Clipping','On'); end      % KOUN/PAR, etc
    VIS.ht3(iax,1) = text(0,0,'','Color',clr(7,:));
    VIS.ht4(iax,1) = text(0,0,'','Color',clr(8,:));
    VIS.ht5(iax,1) = text(0,0,'','Color',clr(9,:));
    VIS.ht6(iax,1) = text(0,0,'','Color',clr(10,:));
    VIS.ht7(iax,1) = text(0,0,'','Color',clr(11,:));
    hold off
    set(gca,'XLim',alim(1:2),'YLim',alim(3:4),'DataAspect',[1 1 1],'Layer','Top')
end
% Decide zoom level if no flags were supplied, hide some lines. Labels are a bit tricky at this point
%if (nargin<2)
    scl = [250 100];
    cvg = 0.5*(alim(2)-alim(1))+0.5*(alim(4)-alim(3));
    if (cvg>scl(1))  % Almost entire state
        if flags(4), set(VIS.h(:,4),'Visible','Off'); end
        if flags(10), set(VIS.h(:,5),'Visible','Off'); end
    end
%end


% A GUI for showing/hiding plotted objects
if flags(12)
    if br>0.5, bgcolor = '[1 1 1]'; else bgcolor = ['[ ',num2str(get(gca,'color'),'%.3f '),']']; end
    VIS.peer = get(axes_handler_set(1),'Parent');
    VIS.fh = VIS.peer+99;
    tmp = get(VIS.peer,'DeleteFcn');
    if isempty(tmp)
        set(VIS.peer,'DeleteFcn',['if ishandle(',num2str(VIS.fh),'); delete(',num2str(VIS.fh),'); end']);
    else
        tmp = [tmp '; if ishandle(',num2str(VIS.fh),'); delete(',num2str(VIS.fh),'); end'];
        set(VIS.peer,'DeleteFcn',tmp);
    end
    figure(VIS.fh)
    clf
    ibn = 1; uiysize = sum(flags([1:10 10 11]))*25+15;
    set(gcf,'Menubar','None','NumberTitle','Off','Color',[0.842 0.794 0.721]) % [0.65 0.55 0.45]
    tmp = get(gcf,'Position'); set(gcf,'Position',[tmp(1:2) 150 uiysize+5]);
    figui = get(VIS.fh,'Position'); figui = figui([1 3 2 4])+[0 figui(1) 0 figui(2)];
    figax = get(VIS.peer,'Position'); figax = figax([1 3 2 4])+[0 figax(1) 0 figax(2)];
    if isoverlap(figax,figui), set(gcf,'Position',[figax(1)-155 figui(3) 150 uiysize+5]); end
    for idx = find(flags([1:10 10 11]))
        switch idx
            case 1, lab = 'State Borders'; hdl = 'VIS.h(:,1)'; fs = '11'; w = 'Bold';
            case 2, lab = 'County Borders'; hdl = 'VIS.h(:,2)'; fs = '11'; w = 'Bold';
            case 3, lab = 'Interstate'; hdl = 'VIS.h(:,3)'; fs = '11'; w = 'Bold';
            case 4, lab = 'Local HWY'; hdl = 'VIS.h(:,4)'; fs = '11'; w = 'Bold';
            case 5, lab = 'State Capital'; hdl = 'VIS.ht2'; fs = '11'; w = 'Bold';
            case 6, lab = 'County Seat'; hdl = 'VIS.ht3'; fs = '10'; w = 'Bold';
            case 7, lab = 'Pop>10k'; hdl = 'VIS.ht4'; fs = '10'; w = 'Normal';
            case 8, lab = 'Pop>1000'; hdl = 'VIS.ht5'; fs = '9'; w = 'Normal';
            case 9, lab = 'Others'; hdl = 'VIS.ht6'; fs = '9'; w = 'Normal';
            case 10, lab = 'OK MESONET'; hdl = 'VIS.h(:,5)'; fs = '7'; w = 'Normal';
            case 11, lab = 'OK MESONET ID'; hdl = 'VIS.ht7'; fs = '7'; w = 'Normal';
            case 12, lab = 'Radar'; hdl = '[VIS.ht1(:); VIS.h(:,6)]'; fs = '10'; w = 'Bold';
        end
        if (idx<=10), lset = num2str(idx); else lset = num2str(idx-1); end
        eval(['c = ',hdl,'; if ishandle(c(1)), c = sprintf(''[%.3f %.3f %.3f]'',0.9*get(c(1),''Color'')); ',...
              'else, c = ''[0 0 0]'', end']);
        comm = ['VIS.hb(',num2str(ibn),') = uicontrol(''Style'',''PushButton'',''Unit'',''Pixel'',',...
                '''Position'',[15 ',num2str(uiysize-25*ibn),' 120 20],''String'',''',lab,''',',...
                '''FontSize'',',fs,',''ForegroundColor'',',c,',''FontWeight'',''',w,''',',...
                '''BackgroundColor'',',bgcolor,',''Visible'',''On'');'];
        eval(comm);
        if ((idx>=5)&&(idx<=9))||(idx==11),
            % For text objects, only draw them when it's needed because they take one handle per string!
            if (idx==11), pad1 = 'smll = 0.015*(alims(4)-alims(3)); '; pad2 = '-smll'; else pad1 = ''; pad2 = ''; end
            comm = ['set(VIS.hb(',num2str(ibn),'),'...
            '''Callback'',', ...
            '''a = exist(''''VIS'''',''''var''''); ',...
            'VIS = get(gcf,''''UserData''''); ',...
            'if any(ishandle(',hdl,')), ',...
                'delete(',hdl,'(ishandle(',hdl,'))), ',...
                hdl,' = repmat(1.001,[length(VIS.ax) 1]); ',...
            'else, ',...
              'alims = [get(VIS.ax(1),''''XLim'''') get(VIS.ax(1),''''YLim'''')]; ',...
              'alims = alims+0.05*(alims(2)-alims(1))*[1 -1 1 -1]; ',pad1,...
              'loc = (VIS.MAP(',lset,').x>alims(1))&(VIS.MAP(',lset,').x<alims(2))&',...
                    '(VIS.MAP(',lset,').y>alims(3))&(VIS.MAP(',lset,').y<alims(4)); ',...
              'for iax = 1:length(VIS.ax), ',...
                'axes(VIS.ax(iax)), ',...
                 hdl,'(iax,1:sum(loc)) = ',...
                    'text(VIS.MAP(',lset,').x(loc),VIS.MAP(',lset,').y(loc)',pad2,',VIS.MAP(',lset,').lab(loc),',...
                          '''''Color'''',get(VIS.hb(',num2str(ibn),'),''''ForegroundColor''''),'...
                          '''''FontSize'''',get(VIS.hb(',num2str(ibn),'),''''FontSize''''),',...
                          '''''FontWeight'''',get(VIS.hb(',num2str(ibn),'),''''FontWeight''''),'...
                          '''''Clipping'''',''''On'''', ', ...
                          '''''HorizontalAlignment'''',''''Center'''', ', ...
                          '''''VerticalAlignment'''',''''Middle''''); ', ...
              'end; ',...
            'end; ',...
            'set(VIS.fh,''''UserData'''',VIS); if ~a, clear VIS; end; clear a alims smll iax loc;'');'];
        else
            % For lines, just hide/show them using a toggle switch.
            comm = ['set(VIS.hb(',num2str(ibn),'),'...
                '''Callback'',', ...
                '''VIS = get(gcf,''''UserData''''); ',...
                'if any(strcmp(lower(get(',hdl,',''''Visible'''')),''''on'''')),',...
                'set(',hdl,',''''Visible'''',''''Off''''); ', ...
                'else, set(',hdl,',''''Visible'''',''''On''''); end; clear VIS;'');'];
        end
        eval(comm);
        ibn = ibn+1;
    end
    % Final touch, avoid returning handle = 0 (root handle)
    VIS.hb = VIS.hb(VIS.hb~=0);
    tmp = {'lon','lat','box'};
    VIS.MAP = rmfield(MAP,intersect(tmp,fieldnames(MAP)));
    set(gcf,'UserData',VIS,'Tag','bmapover');
    figure(VIS.peer)
end


% Delete empty text labels, they were used to initialize a process only
delete([VIS.ht3 VIS.ht4 VIS.ht5 VIS.ht6 VIS.ht7])


% Decide zoom level again if no flags were supplied, hide some labels this time
%if (nargin<1)
    if (cvg<scl(1))  % More zoom-in, probably half of a state
        tmp = findobj(VIS.fh,'String','County Seat');
        if ~isempty(tmp), figure(VIS.fh), eval(get(tmp(1),'Callback')); end
    end
    if (cvg<scl(2))  % Even more zoom-in
        tmp = findobj(VIS.fh,'String','Pop>10k');
        if ~isempty(tmp), figure(VIS.fh), eval(get(tmp(1),'Callback')); end
        tmp = findobj(VIS.fh,'String','Pop>1000');
        if ~isempty(tmp), figure(VIS.fh), eval(get(tmp(1),'Callback')); end
   end
%end




% If user does not want VIS variable, clear it
if nargout<1, clear VIS; end
return






function [x pos] = ismember(test_ele, ele_set)
pos = [];
if iscell(test_ele)&&iscell(ele_set)
    x = repmat(false,size(test_ele));
    for jdx = 1:length(test_ele)
        for idx = 1:length(ele_set)
            if strcmp(test_ele{jdx},ele_set{idx}), x(jdx) = 1; pos(jdx) = idx; end
        end
    end
elseif iscell(test_ele)&&~iscell(ele_set)
    x = false;
    for idx = 1:length(test_ele)
        if strcmp(test_ele{idx},ele_set), x(idx) = 1; end
    end
elseif ~iscell(test_ele)&&iscell(ele_set)
    x = false;
    for idx = 1:length(ele_set)
        if strcmp(test_ele,ele_set{idx}), x = 1; pos = idx; end
    end
end
return




function [yn] = isoverlap(L,R)
if numel(L)~=4
    fprintf('The first input must be a 4-element vector only.\n');
    yn = -1;
    return
end
if size(R,1)~=4,
    if numel(R)==4,
        R = R(:);
    else
        fprintf('Sorry I can''t compute.\n');
        yn = -1;
        return
    end
end
yn = ( (L(1)>R(1,:))&(L(1)<R(2,:))&(L(3)>R(3,:))&(L(3)<R(4,:)) )|...
     ( (L(1)>R(1,:))&(L(1)<R(2,:))&(L(4)>R(3,:))&(L(4)<R(4,:)) )|...
     ( (L(2)>R(1,:))&(L(2)<R(2,:))&(L(3)>R(3,:))&(L(3)<R(4,:)) )|...
     ( (L(2)>R(1,:))&(L(2)<R(2,:))&(L(4)>R(3,:))&(L(4)<R(4,:)) )|...
     ( (R(1,:)>L(1))&(R(1,:)<L(2))&(R(3,:)>L(3))&(R(3,:)<L(4)) )|...
     ( (R(1,:)>L(1))&(R(1,:)<L(2))&(R(4,:)>L(3))&(R(4,:)<L(4)) )|...
     ( (R(2,:)>L(1))&(R(2,:)<L(2))&(R(3,:)>L(3))&(R(3,:)<L(4)) )|...
     ( (R(2,:)>L(1))&(R(2,:)<L(2))&(R(4,:)>L(3))&(R(4,:)<L(4)) );
return
