
function CreateDatabase

devel_img_dir = fullfile('/raid0/plsang/trecvidmed11/keyframe-8/devel');       % directory for the image database                             
test_img_dir = fullfile('/raid0/plsang/trecvidmed11/keyframe-8/test');       % directory for the image database                             
db_dir = 'database';
ann_dir = 'label';

% create db for dev part

outDevFN = fullfile(db_dir, ['database_devel.mat']);

if exist(outDevFN,'file')~=0,
	fprintf('Skipped creating db [%s]!!\n', outDevFN);
else
	dev_file1 = fullfile(ann_dir, 'assembling_shelter.devel.lst'); 	% label 1
	dev_file2 = fullfile(ann_dir, 'batting_in_run.devel.lst'); 		% label 2
	dev_file3 = fullfile(ann_dir, 'making_cake.devel.lst'); 	% label 3

	dev_files = {dev_file1; dev_file2; dev_file3};

	% retrieve the directory of the database and load the codebook
	database = retr_database_dir(devel_img_dir, dev_files);
	save(outDevFN, 'database');
end

% create db for test part
outTestFN = fullfile(db_dir, ['database_test.mat'])
if exist(outTestFN, 'file')~=0,
	fprintf('Skipped creating db [%s]!!\n', outTestFN);
else
	test_file1 = fullfile(ann_dir, 'assembling_shelter.test.lst'); 	% label 1
	test_file2 = fullfile(ann_dir, 'batting_in_run.test.lst'); 		% label 2
	test_file3 = fullfile(ann_dir, 'making_cake.test.lst'); 	% label 3

	test_files = {test_file1; test_file2; test_file3};

	database = retr_database_dir(test_img_dir, test_files);
	save(outTestFN, 'database');
end



end
