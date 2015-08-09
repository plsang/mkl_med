function [database] = retr_database_dir(rt_data_dir, label_files)
%=========================================================================
% inputs
% rt_data_dir   -the rootpath for the database. e.g. '../data/caltech101'
% outputs
% database      -a tructure of the dir
%                   .path   pathes for each image file
%                   .label  label for each image file
% written by Jianchao Yang
% Mar. 2009, IFP, UIUC
%=========================================================================

fprintf('dir the database...');
subfolders = dir(rt_data_dir);

database = [];

database.imnum = 0; % total image number of the database
database.cname = {}; % name of each class
database.label = []; % label of each class
database.path = {}; % contain the pathes for each image of each class
database.nclass = 0;
database.video = []; % it means event types, encoding 1, 2, 3, 4

% load ground-truth

for ii = 1:length(label_files),
	video_list = read_file(label_files(ii));
	videos{ii} = video_list;
end


for ii = 1:length(subfolders),
    subname = subfolders(ii).name;
    
    if ~strcmp(subname, '.') & ~strcmp(subname, '..'),
        database.nclass = database.nclass + 1;
        fprintf('Processing [%d/%d] folders...\n', ii, length(subfolders));
        database.cname{database.nclass} = subname;
        
        frames = dir(fullfile(rt_data_dir, subname, '*.jpg'));
        c_num = length(frames);
                    
        database.imnum = database.imnum + c_num;
        %label = getlabel(subname, videos1, videos2, videos3);
		label = getlabel (subname, videos);
		
        database.label = [database.label; ones(c_num, 1)*label];
		database.video = [database.video; ones(c_num, 1)*database.nclass];
        
        for jj = 1:c_num,
            c_path = fullfile(rt_data_dir, subname, frames(jj).name);
            database.path = [database.path, c_path];
        end;    
    end;
end;
disp('done!');

end


function label = getlabel(vid, videos)

	label = 0;
	for ii = 1:length(videos),
		%% BUG found when using strfind or findstr which will find the first inclusion string
		% if(size(cell2mat(strfind(videos{ii}, vid))) ~= 0),
		%	label = ii;
		% end
		
		if strmatch(vid, videos{ii}, 'exact'),
			label = ii;
		end
	end
	
	if label == 0,
		label = length(videos) + 1; % background label
	end
end


function videos = read_file(gt_file)

    fid = fopen(cell2mat(gt_file), 'r');
    tline = fgets(fid);
    i = 1;
    while ischar(tline)
        %disp(tline)
        videos{i} = strtrim(tline);
        i = i+1;
        tline = fgets(fid);
    end

    fclose(fid);

end