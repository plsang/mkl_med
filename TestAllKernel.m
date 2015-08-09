



ker_dir = '/raid0/plsang/mkl_med/kers';

vl_dir = '/raid0/plsang/sparse_coding/vlfeat-0.9.13/toolbox';
addpath('support');
addpath(genpath('mkl'));
addpath(vl_dir);

% run vl_setup with no prefix
vl_setup('noprefix');

%models dir
model_dir = 'models';

%results dir
result_dir = 'results';

% loading labels
db_dir = 'database';
fprintf('Loading testing db...\n');
db_file = fullfile(db_dir, ['database_test.mat']);
load(db_file, 'database');

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

% number test kf
n_test_kf = size(all_labels, 2);
fprintf('Number test kf %d\n', n_test_kf);

num_part = ceil(n_test_kf/25000);
cols = fix(linspace(1, n_test_kf + 1, num_part+1)) ;
	
for fea = features,
	feature_ext = fea{:};
	
	fmodel_dir = fullfile(model_dir, feature_ext);
	if ~exist(fmodel_dir, 'file'), 
		fprintf('Dir not found! %s \n', fmodel_dir);
		continue;
	end;
	
	scorePath = fullfile(result_dir, [feature_ext '.scores.mat']);
	if checkFile(scorePath), 
		fprintf('Skipped testing %s \n', scorePath);
		continue;
	end;
	
	for jj = 1:n_event,
		event_name = events{jj};
		modelPath = fullfile(fmodel_dir, [event_name '.mat']);
		
		if ~checkFile(modelPath),
			fprintf('Model not found %s \n', modelPath);
			continue;
		end
		
		fprintf('Loading model ''%s''...\n', event_name);
		models.(event_name) = load(modelPath);
		scores.(event_name) = [];
	end
	
	%load test partition
	for kk = 1:num_part,
		sel = [cols(kk):cols(kk+1)-1];
		kername = sprintf('%s.test_%d_%d.mat', feature_ext, cols(kk), cols(kk+1)-1);
		kerPath = fullfile(ker_dir, kername);
		fprintf('Loading kernel %s ...\n', kerPath); 
		kernels_ = load(kerPath) ;
		base = kernels_.matrix;
		info = whos('base') ;
		fprintf('\tKernel matrices size %.2f GB\n', info.bytes / 1024^3) ;
		
		for jj = 1:n_event,
			event_name = events{jj};
			fprintf('Testing model model ''%s''...\n', event_name);
			%only test at svind
			test_base = base(models.(event_name).svind,:);
			sub_scores = models.(event_name).alphay' * test_base + models.(event_name).b;
			scores.(event_name) = [scores.(event_name) sub_scores];
		end
		
		clear base;
	end
	
	%saving scores
	fprintf('\tSaving scores ''%s''.\n', scorePath) ;
	ssave(scorePath, '-STRUCT', 'scores') ;
	
	
end % end for