
%kerDb = BuildKerDb('dense_sift');
kerDb = BuildKerDb('sparse_coding');

for ker = kerDb,
    feature_ext = ker.feat;
    
	kerPath = fullfile(ker_dir, ker.devname);
	if ~checkFile(kerPath)
		%% kernel on train-train pat
		fprintf('\tLoading devel features for kernel %s ... \n', feature_ext) ;
		
		dev_hists = LoadTrainDataForOneFeature(ker);
		
		%% Updated: Don't scale for sparse feature, it will cause a big matrix
		%fprintf('Scaling data before cal kernel...\n');
		%dev_hists = scaledata(dev_hists, 0, 1);
		
		fprintf('\tCalculating devel kernel %s ... \n', feature_ext) ;

		kernel = calcKernel(ker, dev_hists);
		
		%save kernel
		fprintf('\tSaving kernel ''%s''.\n', kerPath) ;
		ssave(kerPath, '-STRUCT', 'kernel', '-v7.3');
		
		%save kernel descriptors (without kernel matrix)
		kernel = rmfield(kernel, 'matrix') ;

		% optionally save the kernel descriptor (includes gamma for the RBF)
		if ~isempty(ker.descname)
		  kerDescrPath = fullfile(ker_dir, ker.descname) ;
		  fprintf('\tSaving kernel descriptor ''%s''.\n', kerDescrPath) ;
		  ssave(kerDescrPath, '-STRUCT', 'kernel', '-v7.3') ;
		end    
	else
		fprintf('Skipped calculating devel kernel %s \n', feature_ext);
		continue;
	end
    %% kernel on train-test pat
	
	% cal test kernel using num_part partition
	num_kf = 74393;
	num_part = ceil(num_kf/25000);
	cols = fix(linspace(1, num_kf + 1, num_part+1)) ;
	
	fprintf('Calculating test kernel %s with %d partition \n', feature_ext, num_part);
	
	for jj = 1:num_part,
        
        fprintf('\tLoading test features for kernel %s, partition %d ... \n', feature_ext, jj) ;
	
        %use kernel with paramters from training
	
        test_hists = LoadSCTestData(feature_ext, cols(jj), cols(jj+1)-1);
	
        %fprintf('Scaling data before cal kernel...\n');
        %test_hists = scaledata(test_hists, 0, 1);
    
		part_name = sprintf('%s_%d_%d', ker.testname, cols(jj), cols(jj+1)-1);
		kerPath = fullfile(ker_dir, part_name) ;
		
        
		if ~checkFile(kerPath)
			fprintf('\tCalculating test kernel %s [range: %d-%d]... \n', feature_ext, cols(jj), cols(jj+1)-1) ;
			testKer = calcKernel(kernel, dev_hists, test_hists);
			%save test kernel
			fprintf('\tSaving kernel ''%s''.\n', kerPath) ;
			ssave(kerPath, '-STRUCT', 'testKer', '-v7.3') ;
			
		else
			fprintf('Skipped calculating test kernel %s [range: %d-%d] \n', feature_ext, cols(jj), cols(jj+1)-1);
        end
		
		clear testKer;
        clear test_hists;
    end
    
    %% clean up
    clear dev_hists;
    clear test_hists;
    clear kernel;
    clear testKer;
    
end
