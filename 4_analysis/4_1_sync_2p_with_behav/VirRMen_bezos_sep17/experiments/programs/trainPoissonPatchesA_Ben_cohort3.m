function trainPoissonPatchesA_Ben_cohort3(numDataSync, varargin)

  if nargin < 1
    numDataSync = [];
  end

  runCohortExperiment ( 'C:\Data\Ben\PoissonPatchesA'  ... dataPath
                      , 'Poisson Patches Shaping A'             ... experName
                      , 'Cohort3'                           ... cohortName
                      , numDataSync                             ... numDataSync
                      , varargin{:}                             ...
                      );
    
end
