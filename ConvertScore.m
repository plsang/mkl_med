clear all

result_dir = 'results';
addpath('support');

% loading labels
db_dir = 'database';
fprintf('Loading testing db...\n');
db_file = fullfile(db_dir, ['database_test.mat']);
load(db_file, 'database');

n_event = 3;
% loading all kernel 
features{1} = 'nsc.cCV_YCrCb.g6.q3.g_cm';
features{2} = 'nsc.cCV_HSV.g6.q8.g_ch';
features{3} = 'nsc.cCV_GRAY.g5.q36.g_eoh';
features{4} = 'nsc.cCV_GRAY.g5.q59.g_lbp';
features{5} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x1-mkl';
features{6} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x3-mkl';
features{7} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm3x1-mkl';
features{8} = 'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm2x2-mkl';
features{9} = 'mkl.nsc.cm.ch.eoh.lbp';
features{10} = 'mkl.nsc.cm.ch.eoh.lbp.dense6.sift';
features{11} = 'mkl.dense6.sift.norm1x1.norm1x3.norm3x1.norm2x2';
features{12} = 'mkl.nsc.cm.ch.eoh.lbp.dense6.sift.sparsecoding';
features{13} = 'RBCSPM_MED';
features{14} = 'LLCSPM_MED';
features{15} = 'SCSPM_MED';
features{16} = 'mkl.sparsecoding.rbcspm.llcspm.scspm';


% event names
events{1} = 'assembling_shelter';
events{2} = 'batting_in_run';
events{3} = 'making_cake';

for fea = features,
	feature_ext = fea{:};
	fprintf('Scoring for feature %s...\n', feature_ext);
	
	scorePath = fullfile(result_dir, [feature_ext '.scores.mat']);
	if ~checkFile(scorePath), 
		fprintf('File not found!! %s \n', scorePath);
		continue;
	end;
	
	fresult_dir = fullfile(result_dir, feature_ext);
	
	if ~checkFile(fresult_dir),
		mkdir(fresult_dir);
	else
		fprintf('Folder fould! Assuming already processed!. Skipped!\n');
		continue;
	end
	
	scores = load(scorePath);
	
	for jj = 1:n_event,
		event_name = events{jj};
		fprintf('Scoring for feature %s , event %s...\n', feature_ext, event_name);
		feresult_dir = fullfile(fresult_dir, event_name);
	
		if ~checkFile(feresult_dir),
			mkdir(feresult_dir);
		end
	
		this_scores = scores.(event_name);
		p_scores = scaledata(this_scores, 0, 1);
		
		for kk=1:length(database.path),
			rawPath = database.path{kk};
			[rawDir kfName] = fileparts(rawPath);
			[vidDir vidName] = fileparts(rawDir);
			outFName = fullfile(feresult_dir, [vidName '.' feature_ext '.svm.res']);
			fid = fopen(outFName, 'a');
			fprintf(fid, '%s #$# %f\n', kfName, p_scores(kk));			
			fclose(fid);
		end
		
	end
	
end
