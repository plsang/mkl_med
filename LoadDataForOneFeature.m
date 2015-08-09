
function hists = LoadDataForOneFeature(ker)
% NOTE: only use for test pat

fea_fmt = ker.fea_fmt;
n_dim = ker.num_dim;
feature_ext = ker.feat;
szPat = 'test';

% load database
db_dir = 'database';
ft_dir = ker.ft_dir;
ft_dir = fullfile(ft_dir, feature_ext);

db_file = fullfile(db_dir, ['database_' szPat '.mat']);
load(db_file, 'database');
hists = [];

if ~strcmp(szPat, 'test')
    error('Unsupported partition!');
end

if strcmp(fea_fmt, 'sc'),
    fprintf('Loading database...\n');
    load('/raid0/plsang/sparse_coding/data/database_MEDTEST10.mat', 'database');
    dbobj = DbHandle; % construct an object of myClass
    dbobj.database = database; % set some fancy values to the object
end

for ii = 1:length(database.cname), %
    video = database.cname{ii};
    ft_file = fullfile(ft_dir, szPat, [video '.' feature_ext '.tar.gz']);
	
	switch fea_fmt
		case 'dvf'
			hists_ = LoadOneTarFeatureFile(ft_file);
		case 'svf'
			hists_ = LoadOneTarSvfFeatureFile(ft_file, n_dim);
        case 'sc'
            hists_ = LoadSCFeatureForOneVideo(feature_ext, dbobj, 'MEDTEST10', video);
		otherwise
			error('Unknow feature format: %s!!!\n', fea_fmt);
	end
    
    n_kfs = size(hists_, 2);
    hists = [hists hists_];
	
    fprintf('[%d] Video %s - %d features loaded!\n', ii, video, size(hists, 2));
end

end