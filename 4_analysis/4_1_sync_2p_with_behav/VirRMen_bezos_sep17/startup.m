virmenDir = fileparts(mfilename('fullpath'));
guiDir    = fullfile(virmenDir, 'bin', 'gui');

addpath(genpath(virmenDir));
rmpath(genpath(fullfile(virmenDir, '.git')));
omits     = dir(fullfile(guiDir, 'builtin*'));
for iDir = 1:numel(omits)
  rmpath(genpath(fullfile(guiDir, omits(iDir).name)));
end

clear('virmenDir', 'guiDir', 'iDir', 'omits');
