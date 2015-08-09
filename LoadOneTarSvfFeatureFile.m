
function hists = LoadOneTarFeatureFile(tarFile, num_dim)
    tmpDir = 'tmp';
    oFile = untar(tarFile, tmpDir);
    oFile = cell2mat(oFile);

	%codebook size
	c_size = 500;
	
	%size difference between regions
	c_diff = 100;
	
    fid = fopen(oFile, 'r');
    tline = fgets(fid);
    
	hists = [];
	
    while ischar(tline)
        %skip comment lines, start with %
        if strfind(tline, '%') == 1, 
			tline = fgets(fid);
			continue; 
		end
		
        [szFea szAnn] = strread(tline, '%s %s', 'delimiter', '%');
        szFea = cell2mat(szFea);
        szAnn = cell2mat(szAnn);
        
        tmp_fea = sscanf(szFea, '%f');
        % check if read corectly (svf format): numDim 1:n1 2:n2 ... nDim
        if tmp_fea(1) ~= (length(tmp_fea) - 1)/2
            error('ERROR: Reading feature file [Feature Dim: %d / Actual Dim: %d]\n', ...
                fea(1), (length(tmp_fea) - 1)/2); 
        end
        
		%parse svf format
		fea = zeros(num_dim, 1);
		
		idx = tmp_fea(2:2:end);
		idx_val = tmp_fea(3:2:end);
		
		%shrink indexes (not shrinking the first block)
		shrink_times = num_dim/c_size;
		for ii = 1:shrink_times - 1,
			idx(idx > ii*c_size) = idx(idx > ii*c_size) - c_diff;
		end
		
		fea(idx) = idx_val;
		
        hists = [hists fea];
        
        % read next line
        tline = fgets(fid);
    end

    fclose(fid);
    delete(oFile);
end
