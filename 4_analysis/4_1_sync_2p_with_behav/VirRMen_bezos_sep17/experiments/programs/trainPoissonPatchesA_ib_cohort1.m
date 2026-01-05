function trainPoissonPatchesA_ib_cohort1(numDataSync, varargin)

  if nargin < 1
    numDataSync = [];
  end

  runCohortExperiment ( 'C:\Data\ibusack\PoissonPatchesA_1'   ... dataPath
                      , 'Poisson Patches'                     ... experName
                      , 'cohort1'                             ... cohortName
                      , numDataSync                           ... numDataSync
                      , varargin{:}                           ...
                      );
    
end
