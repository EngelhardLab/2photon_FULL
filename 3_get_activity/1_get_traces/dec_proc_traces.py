import datetime
import subprocess
import time
from collections import deque
import zipfile
import sys


#python3 dec_proc_traces.py C:\Users\EngelhardBLab\parrun\output


input_folder = sys.argv[1]



t0 =datetime.datetime.now() 
print('Starting time:', datetime.datetime.now())


def run_matlab_instance(input_folder):
    
    print(f"Starting MATLAB for new patch ...")
    cmd = [
        'matlab',
        '-batch',
        f"get_traces(\'{input_folder}\'); exit"
    ]


    return subprocess.Popen(cmd)




def main():
    num_patches = sum(1 for f in zipfile.ZipFile(f"{input_folder}\patches.zip").namelist() if not f.endswith('/'))
    #archivos_a_procesar = deque(range(1, num_parches + 1))  # parches del 1 al 20
    active_processes = []
    do_check = 5  # en min
    num_mats = 3

    #first run
    for _ in range(num_mats):
        active_processes.append(run_matlab_instance(input_folder))
        time.sleep(30)
    
    run_i = num_mats-1 # is acc {num_patches} but for indexing purposes
    k = 1 #change to 0 when re-running single ROIs or when necessary to stop new MATLABs from opening
        # otherwise, keep it as ` k = 1 `

    
    while  run_i < num_patches or active_processes and k == 1:
        #print('sleeping...')
        time.sleep(do_check * 60)  # x 60  >> in mins
        #print('waking up////')

        active_processes = [p for p in active_processes if p.poll() is None] #is it still exec?

        #newprocess if needed
        while len(active_processes) < num_mats and run_i < num_patches+1:
            #parche_id = archivos_a_procesar.popleft()
            active_processes.append(run_matlab_instance(input_folder))
            time.sleep(30)
            #threading.Thread(target=run_matlab_instance, args=(input_folder, output_folder, param1, param2), daemon=True).start()
            run_i += 1
            print(f">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> proc patch {run_i} of {num_patches} ...")

    
    t =datetime.datetime.now() 
    print('Starting time:', t0)
    print(f'Finished at {datetime.datetime.now()} after {t-t0}')

            

if __name__ == "__main__":
    main()