
function hists = LoadSCTrainData(feature_ext)
% NOTE: only use for test pat

% feature dir settings
rt_feature_dir = '/raid0/plsang/sparse_coding';
exp_name = 'dense6.patch32.2048';
feature_dir = fullfile(rt_feature_dir, feature_ext, 'features', ...
    feature_pat, exp_name);

fprintf('Loading database...\n');
load('/raid0/plsang/sparse_coding/data/database_MEDTEST10.mat', 'database');

hists = [];
for ii = start_idx:end_idx, %
    
    kf_path = database.path{ii};
	[dir fname] = fileparts(kf_path);
	fea_path = fullfile(feature_dir, num2str(label), [fname '.mat']);
    load(fea_path, 'fea');
    
    if isempty(hists),
        hists = zeros(size(fea, 1), end_idx - start_idx + 1);
    end
    hists(:, ii) = fea;
	
    fprintf('[%d] Video %s - %d features loaded! (%d new features added)\n', ii, video, size(hists, 2), size(fea, 1));
end

end