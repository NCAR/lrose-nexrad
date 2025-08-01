%Default colormap for reflectivity values

function x = dbz_default2(n);


if nargin==1 & isempty(n)
    n = size(get(gcf,'Colormap'),1);
end;

cmap = [...
    0,100,0; ...
    85,107,47; ...
    34,139,34; ...
    0,205,102; ...
    60,179,113; ...
    102,205,170; ...
    123,104,238; ...
    0,0,255; ...
    0,0,139; ...
    104,34,139; ...
    139,58,98; ...
    176,48,96; ...
    139,34,82; ...
    160,82,45; ...
    210,105,30; ...
    218,165,32; ...
    255,210,0; ...
    233,150,122; ...
    250,128,114; ...
    238,44,44; ...
    255,20,147; ...
    250,92,176; ...
    250,136,196; ...
    250,171,213; ...
    250,195,223; ...
    250,211,229; ...
    255,255,255; ...
    220,220,220; ...
    200,200,200; ...
    150,150,150; ...
    100,100,100; ...
    50,50,50; ...
    0,0,0; ...
    ];

cmap=cmap./255;

if nargin < 1
    n = size(cmap,1);
end;

x = interp1(linspace(0,1,size(cmap,1)),cmap(:,1),linspace(0,1,n)','linear');
x(:,2) = interp1(linspace(0,1,size(cmap,1)),cmap(:,2),linspace(0,1,n)','linear');
x(:,3) = interp1(linspace(0,1,size(cmap,1)),cmap(:,3),linspace(0,1,n)','linear');

x = min(x,1);
x = max(x,0);