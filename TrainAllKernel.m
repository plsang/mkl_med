



ker_dir = '/raid0/plsang/mkl_med/kers';

vl_dir = '/raid0/plsang/sparse_coding/vlfeat-0.9.13/toolbox';
addpath('support');
addpath(genpath('mkl'));
addpath(vl_dir);

% run vl_setup with no prefix
vl_setup('noprefix');

%models dir
model_dir = 'models';

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
%features{1} = 'nsc.cCV_YCrCb.g6.q3.g_cm';
%features{2} = 'nsc.cCV_HSV.g6.q8.g_ch';
%features{3} = 'nsc.cCV_GRAY.g5.q36.g_eoh';
%features{4} = 'nsc.cCV_GRAY.g5.q59.g_lbp';
%features{5} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x1-mkl';
%features{6} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x3-mkl';
%features{7} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm3x1-mkl';
%features{8} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm2x2-mkl';
features{1} = 'RBCSPM_MED';
features{2} = 'LLCSPM_MED';
features{3} = 'SCSPM_MED';

% event names
events{1} = 'assembling_shelter';
events{2} = 'batting_in_run';
events{3} = 'making_cake';

for fea = features,
	feature_ext = fea{:};
	
	fmodel_dir = fullfile(model_dir, feature_ext);
	if ~exist(fmodel_dir, 'file'), mkdir(fmodel_dir); end;
	
	kerPath = fullfile(ker_dir, [feature_ext '.devel.mat']);
	if ~exist(kerPath, 'file'), 
		fprintf('Kernel does not exist %s \n', kerPath);
		continue; 
	end;
	
	fprintf('Loading kernel %s ...\n', kerPath); 
	kernels_ = load(kerPath) ;
	base = kernels_.matrix;

	%base = base';

	info = whos('base') ;
	fprintf('\tKernel matrices size %.2f GB\n', info.bytes / 1024^3) ;

	%label?

	for jj = 1:n_event,
		event_name = events{jj};
		modelPath = fullfile(fmodel_dir, event_name);
		if checkFile(modelPath),
			fprintf('Skipped training %s \n', modelPath);
			continue;
		end
		fprintf('Training event ''%s''...\n', event_name);
		
		labels = double(all_labels(jj,:));
		posWeight = ceil(length(find(labels == -1))/length(find(labels == 1)));

		tic
		fprintf('SVM learning with predefined kernel matrix...\n');
		svm = svmkernellearn(base, labels,   ...
						   'type', 'C',        ...
						   'C', 10,            ...
						   'verbosity', 1,     ...
						   ...%'crossvalidation', 5, ...
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
	end
	
	clear kernels_;
	
end % end for