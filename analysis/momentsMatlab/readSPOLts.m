function data=readSPOLts(channel,file)

channelLow=lower(channel);

% Read HCR time series data
baseTime=ncread(file,'base_time');
timeOffset=ncread(file,['time_offset_',channelLow]);

fileStartTime=datetime(1970,1,1)+seconds(baseTime);
data.time=fileStartTime+seconds(timeOffset)';

data.range=ncread(file,'range');
data.elevation=ncread(file,['elevation_',channelLow])';
data.azimuth=ncread(file,['azimuth_',channelLow]);
data.prt=ncread(file,['prt_',channelLow]);
data.pulse_width=ncread(file,['pulse_width_',channelLow])';

data.I=ncread(file,['I',channel]);
data.Q=ncread(file,['Q',channel]);

data.noiseLev=ncreadatt(file,'/',['cal_noise_dbm_',channelLow]);
data.rx_gain=ncreadatt(file,'/',['cal_receiver_gain_db_',channelLow]);
data.dbz1km=ncreadatt(file,'/',['cal_base_dbz_1km_',channelLow]);
data.lambda=ncreadatt(file,'/','radar_wavelength_cm')/100;

end