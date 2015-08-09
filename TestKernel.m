
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
model_name = 'mkl.nsc.cm.ch.eoh.lbp.dense6.sift.sparsecoding';

fmodel_dir = fullfile(model_dir, model_name);
if ~checkFile(fmodel_dir),
	mkdir(fmodel_dir);
end

%results dir
result_dir = 'results';

% loading labels
db_dir = 'database';
fprintf('Loading testing db...\n');
db_file = fullfile(db_dir, ['database_test.mat']);
load(db_file, 'database');

%% type of combining kernel: 1: mkl, 2: average kernel
kernel_type = 1; 

n_event = 3;
all_labels = zeros(n_event, length(database.label));

for ii = 1:length(database.label),
	for jj = 1:n_event,
		if database.label(ii) == jj,
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

% number test kf
n_test_kf = size(all_labels, 2);
fprintf('Number test kf %d\n', n_test_kf);

num_part = ceil(n_test_kf/25000);
cols = fix(linspace(1, n_test_kf + 1, num_part+1)) ;
	
nKer = length(features);
initWeights = ones(1, nKer);

weightPath = fullfile(fmodel_dir, [model_name '.weights.mat']);

%% type of combining kernel: 1: mkl, 2: average kernel
if kernel_type == 1,
	if ~checkFile(weightPath),
		error('Learned weights not found! %s \n', weightPath);
	end
	
	svm_ = load(weightPath);
end

scorePath = fullfile(result_dir, [model_name '.scores.mat']);
if checkFile(scorePath), 
	fprintf('Skipped testing %s \n', scorePath);
	return;
end
	

for jj = 1:n_event,

	%load trained model
	event_name = events{jj};
	modelPath = fullfile(fmodel_dir, [event_name '.mat']);
	
	if ~checkFile(modelPath),
		error('Model not found %s \n', modelPath);
	end
	
	fprintf('Loading model ''%s''...\n', event_name);
	models.(event_name) = load(modelPath);
	scores.(event_name) = [];
	
	%load test partition
	for kk = 1:num_part,
		
		fprintf('@Testing event %s partition %d...\n', event_name, kk);
		
		base = [];
		for ki = 1:nKer,
			feature_ext = features{ki};
			kername = sprintf('%s.test_%d_%d.mat', feature_ext, cols(kk), cols(kk+1)-1);
			kerPath = fullfile(ker_dir, kername);
			if ~exist(kerPath, 'file'), 
				error('Kernel does not exist %s \n', kerPath);
			end;
			
			fprintf('Loading kernel %s ...\n', kerPath); 
			kernels_ = load(kerPath) ;
			kernels_.matrix = kernels_.matrix(models.(event_name).svind,:);
			
			if isempty(base)
				base = zeros(size(kernels_.matrix)) ;
			end
			%multiply the kernel matrix with weight
			
			if kernel_type == 1,
				base = base + svm_.(event_name).d(ki) * kernels_.matrix ;
			elseif kernel_type == 2,
				base = base + kernels_.matrix ;
			end
			
		end
		
		sub_scores = models.(event_name).alphay' * base + models.(event_name).b;
		scores.(event_name) = [scores.(event_name) sub_scores];
		
		% clear base
		clear base;
	end	
	
end	

%saving scores
fprintf('\tSaving scores ''%s''.\n', scorePath) ;
ssave(scorePath, '-STRUCT', 'scores') ;
