



ker_dir = '/raid0/plsang/mkl_med/kers';

vl_dir = '/raid0/plsang/sparse_coding/vlfeat-0.9.13/toolbox';
addpath('support');
addpath(genpath('mkl'));
addpath(vl_dir);

% run vl_setup with no prefix
vl_setup('noprefix');

feature_ext = 'nsc.cCV_YCrCb.g6.q3.g_cm';
kerPath = fullfile(ker_dir, [feature_ext '.devel.mat']);
fprintf('Loading kernel %s ...\n', kerPath); 
kernels_ = load(kerPath) ;
base = kernels_.matrix;

%base = base';

info = whos('base') ;
fprintf('\tKernel matrices size %.2f GB\n', info.bytes / 1024^3) ;

%label?

db_dir = 'database';

posWeight = 1;

db_file = fullfile(db_dir, ['traindb.mat']);
load(db_file, 'traindb');

labels = [];
for ii = 1:length(traindb.label),
    if traindb.label(ii) == 3
        labels(ii) = 1;
    else
        labels(ii) = -1;
    end
end

labels = double(labels);
posWeight = ceil(length(find(labels == -1))/length(find(labels == 1)));

tic
fprintf('SVM learning with predefined kernel matrix...\n');
svm = svmkernellearn(base, labels,   ...
                   'type', 'C',        ...
                   'C', 10,            ...
                   'verbosity', 1,     ...
                   'weights', [+1 posWeight ; -1 1]') ;
toc

%svm = svmflip(svm, labels) ;

% test it on train
scores = svm.alphay' * base(svm.svind, :) + svm.b ;
errs = scores .* labels < 0 ;
err  = mean(errs) ;
selPos = find(labels > 0) ;
selNeg = find(labels < 0) ;
werr = sum(errs(selPos)) * posWeight + sum(errs(selNeg)) ;
werr = werr / (length(selPos) * posWeight + length(selNeg)) ;
fprintf('\tSVM training error: %.2f%% (weighed: %.2f%%).\n', ...
      err*100, werr*100) ;
