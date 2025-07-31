function data=readDataTables(filename, del1)
% Reads John's data tables

data.azimuth=[];
data.elevation=[];

fid=fopen(filename,'r');
slurp=fscanf(fid,'%c');
fclose(fid);
first=1;

M=strread(slurp,'%s','delimiter','\n');

% Find first az= line
azInd=0;
searchInd=1;
while azInd==0
    thisLine=M{searchInd};
    if strcmp(thisLine(1:2),'az')
        azInd=searchInd;
    end
    searchInd=searchInd+1;
end

varString=M{azInd-1};
varNames=strsplit(varString,' ');

for kk=1:length(varNames)
    data.(varNames{kk})=[];
end

for ii=azInd:length(M)
    thisLine=M{ii};
    if strcmp(thisLine(1:2),'az')
        thisStr=strsplit(thisLine,del1);
        data.azimuth=cat(1,data.azimuth,str2double(thisStr{2}));
        data.elevation=cat(1,data.elevation,str2double(thisStr{4}));
        if first==0
            for kk=1:length(varNames)
                data.(varNames{kk})=cat(1,data.(varNames{kk}),rayMat(:,kk)');
            end
        end
        rayMat=[];
    else
        temp=strread(M{ii},'%f','delimiter',del1);
        rayMat=cat(1,rayMat,temp');
        first=0;
    end
end
for kk=1:length(varNames)
    data.(varNames{kk})=cat(1,data.(varNames{kk}),rayMat(:,kk)');
end

data.range=data.Rng(1,:);
data=rmfield(data,'Rng');
data.DBZ_F=data.Zh;
data=rmfield(data,'Zh');
data.ZDR_F=data.Zdr;
data=rmfield(data,'Zdr');
data.VEL_F=data.Vel;
data=rmfield(data,'Vel');
data.PHIDP_F=data.Phidp;
data=rmfield(data,'Phidp');
data.RHOHV_NNC_F=data.Rohv;
data=rmfield(data,'Rohv');
data.WIDTH_F=data.Width;
data=rmfield(data,'Width');
data.CMD_FLAG=data.CMD_Flg;
data=rmfield(data,'CMD_Flg');
if isfield(data,'Order')
    data.REGR_ORDER=data.Order;
    data=rmfield(data,'Order');
end
if isfield(data,'Trip')
    data.REGR_ORDER=data.Trip;
    data=rmfield(data,'Trip');
end
end