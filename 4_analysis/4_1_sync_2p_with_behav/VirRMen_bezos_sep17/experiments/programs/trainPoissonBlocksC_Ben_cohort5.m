function trainPoissonBlocksC_Ben_cohort5(numDataSync, varargin)

  if nargin < 1
    numDataSync = [];
  end

  runCohortExperiment ( 'C:\Data\Ben\PoissonBlocksC'  ... dataPath
                      , 'Poisson Blocks Shaping C'             ... experName
                      , 'Cohort5'                           ... cohortName
                      , numDataSync                             ... numDataSync
                      , varargin{:}                             ...
                      );
    
end
