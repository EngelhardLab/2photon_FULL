function trainPoissonBlocksC_Ben_cohort_test(numDataSync, varargin)

  if nargin < 1
    numDataSync = [];
  end

  runCohortExperiment ( 'C:\Data\Ben\PoissonBlocksC'  ... dataPath
                      , 'Poisson Blocks Shaping C'             ... experName
                      , 'Cohort_test'                           ... cohortName
                      , numDataSync                             ... numDataSync
                      , varargin{:}                             ...
                      );
    
end
