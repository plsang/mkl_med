

% clear
clear all

ker_dir = '/raid0/plsang/mkl_med/kers';

vl_dir = '/raid0/plsang/sparse_coding/vlfeat-0.9.13/toolbox';
addpath('support');
addpath(genpath('mkl'));
addpath(vl_dir);

% run vl_setup with no prefix
vl_setup('noprefix');

%models dir
model_dir = 'models';
%model_name = 'mkl.nsc.cm.ch.eoh.lbp.dense6.sift.sparsecoding';
model_name = 'mkl.nsc.cm.ch.eoh.lbp.dense6.sift.sparsecoding';

%% type of combining kernel: 1: mkl, 2: average kernel
kernel_type = 1; 

fmodel_dir = fullfile(model_dir, model_name);
if ~checkFile(fmodel_dir),
	mkdir(fmodel_dir);
end

% loading labels
db_dir = 'database';
db_file = fullfile(db_dir, ['traindb.mat']);
load(db_file, 'traindb');

n_event = 3;
all_labels = zeros(n_event, length(traindb.label));

for ii = 1:length(traindb.label),
	for jj = 1:n_event,
		if traindb.label(ii) == jj,
			all_labels(jj, ii) = 1;
		else
			all_labels(jj, ii) = -1;
		end
	end
end
	
% loading all kernel 

features{1} = 'nsc.cCV_YCrCb.g6.q3.g_cm';
features{2} = 'nsc.cCV_HSV.g6.q8.g_ch';
features{3} = 'nsc.cCV_GRAY.g5.q36.g_eoh';
features{4} = 'nsc.cCV_GRAY.g5.q59.g_lbp';
features{5} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x1-mkl';
features{6} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x3-mkl';
features{7} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm3x1-mkl';
features{8} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm2x2-mkl';
features{9} = 'RBCSPM_MED';
features{10} = 'LLCSPM_MED';
features{11} = 'SCSPM_MED';

% event names
events{1} = 'assembling_shelter';
events{2} = 'batting_in_run';
events{3} = 'making_cake';

% load all kernels
nKer = length(features);
initWeights = ones(1, nKer);

weightPath = fullfile(fmodel_dir, [model_name '.weights.mat']);

switch kernel_type
	case 1
		if checkFile(weightPath),
			fprintf('Skipped learning weights %s \n', weightPath);
			svm_ = load(weightPath);
		else
			base = [];	
			for ki = 1:nKer,
				feature_ext = features{ki};
				kerPath = fullfile(ker_dir, [feature_ext '.devel.mat']);
				if ~exist(kerPath, 'file'), 
					fprintf('Kernel does not exist %s \n', kerPath);
					continue; 
				end;
				fprintf('Loading kernel %s ...\n', kerPath); 
				kernels_ = load(kerPath) ;
				if isempty(base)
					base = zeros([size(kernels_.matrix) nKer]) ;
				end
				base(:,:,ki) = kernels_.matrix ;
			end

			info = whos('base') ;
			fprintf('\tKernel matrices size %.2f GB (%g) \n', info.bytes / 1024^3, info.size) ;
			
			% use mkl to learn weights
			for jj = 1:n_event,
				event_name = events{jj};
				
				labels = double(all_labels(jj,:));
				fprintf('Learning weights for event ''%s''...\n', event_name);
				
				tic
				svm_.(event_name) = learnGmklSvm(base, labels(:)) ;
				toc
				svm_.(event_name) = svmflip(svm_.(event_name), labels) ;
				weights = svm_.(event_name).d' .* initWeights ;
				svm_.(event_name).d = weights ;
				fprintf('\tComputed weights: %s\n', sprintf('%g ', weights)) ;
			end
			
			fprintf('\tSaving weights ''%s''.\n', weightPath) ;
			ssave(weightPath, '-STRUCT', 'svm_') ;
		end
	otherwise
	
end


	
% clear base
fprintf('Clearing base kernel...\n');
clear base;
	
% loading kernels again with weighting into a single matrix
for jj = 1:n_event,

	event_name = events{jj};
	labels = double(all_labels(jj,:));
	
	modelPath = fullfile(fmodel_dir, event_name);
	
	if checkFile(modelPath),
		fprintf('Skipped training %s \n', modelPath);
		continue;
	end
	
	fprintf('MKL learning loading base for event ''%s''...\n', event_name);
	
	base = []; %empty base
	for ki = 1:nKer,
		feature_ext = features{ki};
		kerPath = fullfile(ker_dir, [feature_ext '.devel.mat']);
		if ~exist(kerPath, 'file'), 
			fprintf('Kernel does not exist %s \n', kerPath);
			continue; 
		end;
		fprintf('Loading kernel %s ...\n', kerPath); 
		kernels_ = load(kerPath) ;
		
		% multiply with a weight
		if kernel_type == 1, % mkl
			kernels_.matrix = kernels_.matrix * svm_.(event_name).d(ki);
		end
		% otherwise, doing nothing means average kernel
		
		if isempty(base)
			base = zeros(size(kernels_.matrix)) ;
		end
		base = base + kernels_.matrix ;
	end
	
	info = whos('base') ;
	fprintf('\tKernel matrices size %.2f GB\n', info.bytes / 1024^3) ;
	
	fprintf('MKL learning weights for event ''%s''...\n', event_name);
	
	posWeight = ceil(length(find(labels == -1))/length(find(labels == 1)));
	
	tic
	svm = svmkernellearn(base, labels(:)',   ...
                       'type', 'C',        ...
                       'C', 10,            ...
                       'verbosity', 1,     ...
					   ...%'crossvalidation', 5,     ...
                       'weights', [+1 posWeight ; -1 1]') ;
	toc
	svm = svmflip(svm, labels) ;
	
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
	  
	% save model
	fprintf('\tNumber of support vectors: %d\n', length(svm.svind)) ;

	fprintf('\tSaving model ''%s''.\n', modelPath) ;
	ssave(modelPath, '-STRUCT', 'svm') ;

	% clear base
	fprintf('Clearing base kernel...\n');
	clear base;
end