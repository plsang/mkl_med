
function hists = LoadTrainDataForOneFeature(ker)

%%Update change parameter to ker

fea_fmt = ker.fea_fmt;
n_dim = ker.num_dim;
feature_ext = ker.feat;

% load database
db_dir = 'database';
ft_dir = ker.ft_dir;
ft_dir = fullfile(ft_dir, feature_ext);

db_file = fullfile(db_dir, ['traindb.mat']);
load(db_file, 'traindb');
hists = [];

szPat = 'devel';

if isempty(traindb)
    error('Empty training db!!\n');
end

%loading database
if strcmp(fea_fmt, 'sc'),
    fprintf('Loading database...\n');
    load('/raid0/plsang/sparse_coding/data/database_MEDDEV10.mat', 'database');
    dbobj = DbHandle; % construct an object of myClass
    dbobj.database = database; % set some fancy values to the object
end

for ii = 1:length(traindb.video), %
    video = traindb.video{ii};
	
	%skip non-seletecd videos
	if ~isfield(traindb.sel, video), continue; end;
	
    ft_file = fullfile(ft_dir, szPat, [video '.' feature_ext '.tar.gz']);
	switch fea_fmt
		case 'dvf'
			hists_ = LoadOneTarFeatureFile(ft_file);
		case 'svf'
			hists_ = LoadOneTarSvfFeatureFile(ft_file, n_dim);
        case 'sc'
            
            hists_ = LoadSCFeatureForOneVideo(feature_ext, dbobj, 'MEDDEV10', video);
		otherwise
			error('Unknow feature format: %s!!!\n', fea_fmt);
	end
    
    sel = traindb.sel.(video);
    hists = [hists hists_(:, sel)];
    fprintf('[%d] Video %s - %d features loaded (%d new features added)!\n', ii, video, size(hists, 2), length(sel));
end


end


