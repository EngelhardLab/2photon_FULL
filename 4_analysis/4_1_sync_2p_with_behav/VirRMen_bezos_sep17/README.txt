ViRMEn engine and experiments used in the Accumulating Towers task.

INSTALLATION on a fresh computer:

(1)   Install git for windows (https://msysgit.github.io/), presumably the
      64-bit version. You MUST:
        *  Select "Use Git from the Windows Command Prompt" (4th section in
           setup procedure).
        *  Select "Checkout as-is, commit as-is" for line endings (5th
           section in setup procedure).

(2)   Install tortoisegit (https://code.google.com/p/tortoisegit/). The
      default settings should be fine.

(3)   Install WinMerge (http://winmerge.org/). Check "Plugins" (4th section
      in setup procedure).

(4)   Make a directory called C:\Experiments.



IMPORTANT things to do/note when pulling the latest code change:

(*)   Run install_virmen.m. This will compile the mex files with the proper
      calibration constants for the VR projector display, amongst other things.

(1)   extras/RigParameters.m needs to be created (starting from
      extras/RigParameters.m.example) for each rig. This file should never 
      be checked into the repository as each rig will have different settings.
      install_virmen.m will create this file if it doesn't exist, and it is 
      then your responsibility to modify it appropriately.

(2)   The projector screen calibration constants toroidXFormP1 and 
      toroidXFormP2 are stored in RigParameters.m.

(4)   Always git-commit changes before running a behavioral experiment! This 
      will ensure proper update of version.txt and consequent tracking of code
      changes in the session log files.
      
(5)   When major changes are made in the code and/or world design, you should 
      typically update the mazeVersion and codeVersion variables in the ViRMEn
      MAT files for that experiment.