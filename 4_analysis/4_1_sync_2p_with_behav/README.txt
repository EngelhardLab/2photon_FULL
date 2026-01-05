to run the sync :

(MATLAB)    addpath('E:\My_scripts_to_sync\path_to_VirRMen_bezos_sep17')

(MATLAB)    process_sync_2p_and_behavior(imaging_folder_tseries,behav_mat_file);


note1 : keep the semicolon at the end (although is not crucial) so the matrices are not displayed 

note2 : don't forget to add the path to VirRMen_bezos_sep17 beforehand so the behaviour data can be read 

note3 : process_sync_2p_and_behavior needs all the other functions inside this folder, do not separate them