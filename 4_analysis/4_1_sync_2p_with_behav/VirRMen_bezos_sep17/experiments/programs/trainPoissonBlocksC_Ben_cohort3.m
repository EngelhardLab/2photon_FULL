function trainPoissonBlocksC_Ben_cohort3(numDataSync, varargin)

  if nargin < 1
    numDataSync = [];
  end

  runCohortExperiment ( 'C:\Data\Ben\PoissonBlocksC'  ... dataPath
                      , 'Poisson Blocks Shaping C'             ... experName
                      , 'Cohort3'                           ... cohortName
                      , numDataSync                             ... numDataSync
                      , varargin{:}                             ...
                      );
    
end
