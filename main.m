
clear all;

ker_dir = '/raid0/plsang/mkl_med/kers';
vl_dir = '/raid0/plsang/sparse_coding/vlfeat-0.9.13/toolbox';
addpath('support');
addpath(genpath('mkl'));
addpath(vl_dir);

% run vl_setup with no prefix
vl_setup('noprefix');

%CalKernel;
LearnKernel
TestKernel
ConvertScore
%CalKernelSC
%TrainAllKernel
%TestAllKernel
%ConvertScore

