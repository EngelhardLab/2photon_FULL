function trainPoissonBlocks_lp_cohort1(numDataSync, varargin)

 if nargin < 1
    numDataSync = [];
  end

  runCohortExperiment ( 'C:\Data\lucas\blocksReboot' ... dataPath
                      , 'PoissonBlocksReboot'                     ... experName
                      , 'cohort1'                             ... cohortName
                      , numDataSync                           ... numDataSync
                      , varargin{:}                           ...
                      );
    
end
