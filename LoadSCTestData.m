
function hists = LoadSCTestData(feature_ext, start_idx, end_idx)
% NOTE: only use for test pat

% feature dir settings
rt_feature_dir = '/raid0/plsang/sparse_coding';
exp_name = 'dense6.patch32.2048';
feature_dir = fullfile(rt_feature_dir, feature_ext, 'features', ...
    'MEDTEST10', exp_name);

fprintf('Loading database...\n');
load('/raid0/plsang/sparse_coding/data/database_MEDTEST10.mat', 'database');

hists = [];
for ii = start_idx:end_idx, %
	label = database.label(ii);
    kf_path = database.path{ii};
	[dir fname] = fileparts(kf_path);
	fea_path = fullfile(feature_dir, num2str(label), [fname '.mat']);
    load(fea_path, 'fea');
    if isempty(hists),
        hists = zeros(size(fea, 1), end_idx - start_idx + 1);
    end
    hists(:, ii - start_idx+1) = fea(:);
    fprintf('[%d--> %d -->%d] features loaded!\n', start_idx, ii, end_idx);
end

end