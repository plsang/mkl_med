
function kerDb = BuildKerDb(varargin)

% Build kernel database,
% call BuildKerDb('baseline'), or BuildKerDb('baseline', 'dense_sift')...
%
kerDb = [];        

for k=1:length(varargin)
	opt = lower(varargin{k}) ;
  
	switch opt
		case 'baseline'
			features = {'nsc.cCV_YCrCb.g6.q3.g_cm',...
						'nsc.cCV_HSV.g6.q8.g_ch',...
						'nsc.cCV_GRAY.g5.q36.g_eoh',...
						'nsc.cCV_GRAY.g5.q59.g_lbp'};
						
			for feature = features
				feature_ext = feature{:};
				ker.type     = 'echi2' ;
				ker.feat     = feature_ext ;
				ker.fea_fmt  = 'dvf';
				ker.ft_dir = '/raid0/plsang/trecvidmed11/feature/keyframe-8';
				ker.num_dim = [];
				ker.pyrLevel = [] ;
				ker.histName = feature_ext ;
				ker.name = feature_ext;
				ker.devname = [feature_ext '.devel'];
				ker.testname = [feature_ext '.test'];
				ker.descname = [feature_ext '.desc'];
				kerDb = [kerDb ker];
			end
			
		case 'dense_sift'
			features = {'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x1-mkl',...
						'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm1x3-mkl',...
						'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm3x1-mkl',...
						'dense6.sift.Soft-500-VL2.trecvidmed11.devel.norm2x2-mkl' };

			num_dims = [500, 1500, 1500, 2000];


			for ii = 1:length(features),
				feature_ext = features{ii};
				ker.type     = 'echi2' ;
				ker.feat     = feature_ext ;
				ker.fea_fmt  = 'svf';
				ker.ft_dir = '/raid0/plsang/trecvidmed11/feature/keyframe-5';
				ker.num_dim = num_dims(ii);
				ker.pyrLevel = [] ;
				ker.histName = feature_ext ;
				ker.name = feature_ext;
				ker.devname = [feature_ext '.devel'];
				ker.testname = [feature_ext '.test'];
				ker.descname = [feature_ext '.desc'];
				kerDb = [kerDb ker];
			end
		case 'sparse_coding'
            
			features = {'RBCSPM_MED',...
						'LLCSPM_MED',...
						'SCSPM_MED'};
                    
            for ii = 1:length(features),
				feature_ext = features{ii};
				ker.type     = 'kl2' ;
				ker.feat     = feature_ext ;
				ker.fea_fmt  = 'sc';
				ker.ft_dir = '/raid0/plsang/sparse_coding';
				ker.num_dim = [];
				ker.pyrLevel = [] ;
				ker.histName = feature_ext ;
				ker.name = feature_ext;
				ker.devname = [feature_ext '.devel'];
				ker.testname = [feature_ext '.test'];
				ker.descname = [feature_ext '.desc'];
				kerDb = [kerDb ker];
            end
            
		otherwise
			error('Unknow option %s!\n', opt);
	end % end switch
end % end for

end