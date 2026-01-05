%% Load GUI for training animals
function runCohortExperiment(dataPath, experName, cohortName, numDataSync)

  % Default arguments
  if nargin < 4
    numDataSync         = [];
  end
  
  
  % Make sure to randomize the random number sequence!
  rng('shuffle');

  % Default to ViRMEn experiment directory
  cd([parsePath(mfilename('fullpath')) filesep '..']);

  vr.rotation_transform=0;
  
  % Load training schedule
  vr.regiment     = TrainingRegiment( experName                     ...
                                    , [ dataPath filesep            ...
                                        strrep(experName,' ','')    ...
                                        '_'                         ...
                                        cohortName '_'              ...
                                        RigParameters.rig           ...
                                        '.mat'                      ...
                                      ]                             ...
                                    , '', numDataSync               ...
                                    );
  vr.regiment.sort();   % Alphabetical order of animals
  
  
  % Ask user to select an animal
  vr.regiment.guiSelectAnimal({'TRAIN', 'Training'}, @trainAnimal, @cleanup);
  vr.regiment.selectValveButton();
  

  
  %% Start training the given animal
  function trainAnimal(info)
    vr.trainee  = info;
  
    % Load experiment of interest
    if ~exist(vr.trainee.experiment, 'file')
      hError    = errordlg( sprintf ( 'Invalid experiment "%s" for animal %s. Please specify it correctly in the schedule.' ...
                                    , vr.trainee.experiment, vr.trainee.name                                                ...
                                    )                                                                                       ...
                          , 'Invalid experiment', 'modal'                                                                   ...
                          );
      uiwait(hError);
      vr.regiment.guiSelectAnimal({'TRAIN', 'Training'}, @trainAnimal, @cleanup);
      return;
    end
    
    % Set custom info 
    load(vr.trainee.experiment);
    exper.userdata                  = vr;

    if RigParameters.simulationMode
      exper.movementFunction        = @moveWithAutoKeyboard;
      if ~RigParameters.hasDAQ
        exper.transformationFunction= @transformPerspectiveMex;
      end
      
    elseif RigParameters.hasDAQ
      switch vr.trainee.virmenSensor
        case MovementSensor.BottomVelocity
          exper.movementFunction    = @moveArduinoLinearVelocityMEX_FAKE;
        case MovementSensor.BottomPosition
          exper.movementFunction    = @moveArduinoLiteralMEX;
        case MovementSensor.FrontVelocity
          exper.movementFunction    = @moveArduino;
        otherwise
          error('runCohortExperiment:sensor', 'Unsupported movement sensor type "%s".', char(vr.trainee.sensor));
      end
      
    % Special case for testing on laptop
    else
      exper.movementFunction        = @moveWithAutoKeyboard;
      exper.transformationFunction  = @transformPerspectiveMex;
      exper.variables.trialEndPauseDuration     = '0.1';
      exper.variables.interTrialCorrectDuration = '0.3';
      exper.variables.interTrialWrongDuration   = '0.3';
    end

    % Archive code if so desired
    if vr.regiment.doStoreCode
      logFile     = vr.regiment.whichLog(vr.trainee);
      [dir,name]  = parsePath(logFile);
      if ~exist(dir, 'dir')
        mkdir(dir);
      end
      
      virmenDir   = parsePath(parsePath(parsePath(which('virmenEngine'))));
      zip(fullfile(dir, [name '.zip']), virmenDir);
    end

    % Run experiment
    status        = exper.run();
    if isstruct(status)
      TrainingRegiment.enableFigureClosing();
      errordlg(status.message, 'ViRMEn runtime error', 'modal');
      rethrow(status);
    end
    
    % Refresh GUI
    vr.regiment.guiSelectAnimal({'TRAIN', 'Training'}, @trainAnimal, @cleanup);
  end


  %% Cleanup 
  function cleanup()
    delete(vr.regiment);
  end

end


