import datetime
import subprocess
import time
from collections import deque
import zipfile
import sys

#Nirja's exp
#python3 dec_proc.py C:\Users\EngelhardBLab\Desktop\test_act_data\input_noline C:\Users\EngelhardBLab\parrun\output 0 0

#Liza's exp
#python3 dec_proc.py C:\Users\EngelhardBLab\Desktop\test_act_data\input_noline C:\Users\EngelhardBLab\parrun\output 1 1 1

input_folder = sys.argv[1] #INPUT FOLDER (T-SERIES)
output_folder = sys.argv[2] #OUTPUT FOLDER (FOR PATCHES)
param1 = sys.argv[3] #HAVE RED CHANNEL
param2 = sys.argv[4] #USE RED CHANNEL

if 'sys.argv[5]' in locals():
    param3 = sys.argv[5] #WANT RED CHANNEL    
else :
    param3 = 0
    print('>> Want red channel set to 0 ')
    print('-------------------------------')

t0 =datetime.datetime.now() 
print('Starting time:', datetime.datetime.now())

def correct_chunks(input_folder, output_folder):
        #correct chunks paths
        cmd = [
            'matlab',
            '-batch',
            f"rectif_chunks_green('{input_folder}', '{output_folder}'); exit"
        ]

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        
        for line in process.stdout:
            print(line.strip())

def run_matlab_instance(input_folder, output_folder, param1, param2, param3):
    
    print(f"Starting MATLAB for new patch ...")
    #command to start matlab
    #if the script fails at this point it could be a problem with matlab's path
    #try this command on terminal >>>        matlab -batch "disp('hello from MATLAB'); exit"
    #if you get an error it's probably because 'matlab' is not added to PATH, see https://www.computerhope.com/issues/ch000549.htm or any other source
    #if that doesn't solve the problem, the error is somewhere else !!! 
    cmd = [
        'matlab',
        '-batch',
        f"DBMC(\'{input_folder}\', \'{output_folder}\', {param1}, {param2}, {param3}); exit"
    ]


    
    return subprocess.Popen(cmd)
    


def main():
    num_patches = sum(1 for f in zipfile.ZipFile(f"{output_folder}\patches.zip").namelist() if not f.endswith('/'))

    active_processes = []
    do_check = 5  # en min
    num_mats = 3 #number of matlab instances to open RECOMMEDED : 4 MAX

    correct_chunks(input_folder, output_folder)

    #first run
    for _ in range(num_mats):
        active_processes.append(run_matlab_instance(input_folder, output_folder, param1, param2))

        time.sleep(10)

    run_i = num_mats-1 # is acc {num_patches} but for indexing purposes
    k = 1 # CONTINUE ?             k = 1  : Y      /     k = 0    : N
  
    
    while  k == 1 and run_i < num_patches or active_processes :
        print('sleeping...')
        time.sleep(do_check * 60)  # x 60 - in mins
        print('waking up////')

        active_processes = [p for p in active_processes if p.poll() is None] #is it still exec?

        #newprocess if needed
        while len(active_processes) < num_mats and run_i < num_patches+1:
            
            active_processes.append(run_matlab_instance(input_folder, output_folder, param1, param2, param3))
            
            run_i += 1
            print(f">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> proc patch {run_i} of {num_patches} ...")

    
    t =datetime.datetime.now() 
    print('Starting time:', t0)
    print('-------------------------------')
    print(f'Finished at {datetime.datetime.now()} after {t-t0}')

            

if __name__ == "__main__":
    main()