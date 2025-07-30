% Read and diplay radar data

clear all;
close all;

addpath(genpath('~/git/lrose-test/bomb_snowstorm/analysis/utils/'));

indir='/scr/cirrus2/rsfdata/projects/precip/spolField/time_series/sband/netcdf/20220608/';
infile=[indir,'20220608_000235_1.49_319.86.sur.nc'];

dataIn.base_time=ncread(infile,'base_time');
dataIn.range=ncread(infile,'range');
dataIn.time_offset_hc=ncread(infile,'time_offset_hc');
dataIn.time_offset_vc=ncread(infile,'time_offset_vc');
dataIn.elevation_hc=ncread(infile,'elevation_hc');
dataIn.elevation_vc=ncread(infile,'elevation_vc');
dataIn.azimuth_hc=ncread(infile,'azimuth_hc');
dataIn.azimuth_vc=ncread(infile,'azimuth_vc');
dataIn.prt_hc=ncread(infile,'prt_hc');
dataIn.prt_vc=ncread(infile,'prt_vc');
dataIn.pulse_width_hc=ncread(infile,'pulse_width_hc');
dataIn.pulse_width_vc=ncread(infile,'pulse_width_vc');
dataIn.IHc=ncread(infile,'IHc');
dataIn.QHc=ncread(infile,'QHc');
dataIn.IVc=ncread(infile,'IVc');
dataIn.QVc=ncread(infile,'QVc');
