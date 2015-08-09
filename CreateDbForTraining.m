
szPat = 'devel';
% load database
db_dir = 'database';

db_file = fullfile(db_dir, ['database_' szPat '.mat']);
load(db_file, 'database');

max_kf_per_non_bg_video = +inf; % only applied for background videos
max_kf_per_bg_video = 5; % only applied for background videos
max_num_kf = +inf;

use_bg_video = 0;

ntype = unique(database.label);

% make sure non background clips appear first
num_non_bg_video = 0;
vids = [];
lbs = [];

for ii = ntype' %
    vid_ii = unique(database.video(database.label == ii));
    vids = [vids; vid_ii];
    lbs = [lbs; ones(length(vid_ii), 1)*ii];
    num_non_bg_video = num_non_bg_video + length(vid_ii);
end

num_non_bg_video = num_non_bg_video - length(vid_ii);

traindb_file = fullfile(db_dir, 'traindb.mat');
if exist(traindb_file, 'file')~= 0,
	fprintf('Traindb already exist!!\n');
    return;
end

traindb.video = {}; 
traindb.sel = [];
traindb.label = [];

for ii = 1:length(vids), %

	if ~use_bg_video && ii > num_non_bg_video, break; end;
	
    video = database.cname{vids(ii)};
    
    n_kfs = length(find(database.video == vids(ii)));
    
	if ii <= num_non_bg_video && n_kfs > max_kf_per_non_bg_video		
		sel = randperm(n_kfs);
		sel = sel(1:max_kf_per_non_bg_video);
		n_kfs = max_kf_per_non_bg_video;
		
	elseif ii > num_non_bg_video && n_kfs > max_kf_per_bg_video
		sel = randperm(n_kfs);
		sel = sel(1:max_kf_per_bg_video);
		% or just simply: sel = randi(100, 1, max_kf_per_bg_video);
		n_kfs = max_kf_per_bg_video;
		
	else
		sel = [1:n_kfs];
	end
    
	
    traindb.video{ii} = video;
	traindb.sel.(video) = sel;
	traindb.label = [traindb.label; ones(n_kfs, 1) * lbs(ii)];
	
	if length(traindb.label) > max_num_kf,
		break;
	end
end

% save seldb for next kernel computing
save(traindb_file, 'traindb');
