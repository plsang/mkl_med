
function hists = LoadSCFeatureForOneVideo(feature_ext, dbobj, feature_pat, video)

% feature_ext: RBCSPM_MED, LLCSPM_MED
% feature_pat: MEDDEV10, MEDTEST10

% feature dir settings
rt_feature_dir = '/raid0/plsang/sparse_coding';
exp_name = 'dense6.patch32.2048';
feature_dir = fullfile(rt_feature_dir, feature_ext, 'features', ...
    feature_pat, exp_name);

%% update: due to loading database is expensive, database is pass to
%% this function
%% Update: database is embeded in a class object to force pass by reference

% db dir
% db_dir = '/raid0/plsang/sparse_coding/data';
% db_file = fullfile(db_dir, ['database_' feature_pat '.mat']);

% load(db_file, 'database');
% if isempty(database)
%    error('database error!\n');
% end




kk = strcmpi(video, dbobj.database.cname);
idx = find(kk == 1);
if isempty(idx) || length(idx) ~= 1
    error('Video name is not correct!! %s \n', video);
end

%kf_idx = find(dbobj.database.video == idx);

%check if labeling is correct: all kfs must have same label
label = unique(dbobj.database.label(dbobj.database.video == idx));
if length(label) ~= 1
    error('Labeling error!\n');
end

%load
hists = [];
kf_paths = dbobj.database.path(dbobj.database.video == idx);
for ii=1:length(kf_paths),
   kf_path = kf_paths{ii};
   [dir fname] = fileparts(kf_path);
   fea_path = fullfile(feature_dir, num2str(label), [fname '.mat']);
   load(fea_path, 'fea');
   if isempty(hists),
        hists = zeros(size(fea, 1), length(kf_paths));
   end
   hists(:, ii) = fea(:);
end

end
