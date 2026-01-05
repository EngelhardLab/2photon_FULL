import datetime
import subprocess
import time
import zipfile
import sys
import os

# --- CONFIGURATION ---
# Providing the full path to the MATLAB executable as found on your system
MATLAB_EXE = "/usr/local/MATLAB/R2024b/bin/matlab"

# --- ARGUMENT PARSING ---
if len(sys.argv) < 5:
    print("Usage: python3 dec_proc_2Ch.py <input_folder> <output_folder> <have_red> <use_red> [want_red]")
    sys.exit(1)

input_folder = sys.argv[1]
output_folder = sys.argv[2]
param1 = sys.argv[3]
param2 = sys.argv[4]
param3 = sys.argv[5] if len(sys.argv) > 5 else "0"

t0 = datetime.datetime.now() 
print(f"Starting time: {t0}")
print(f"Params: have_red={param1}, use_red={param2}, want_red={param3}")
print('-------------------------------')

def correct_chunks(input_folder, output_folder):
    """Initial step to rectify chunks for the green channel."""
    print("Running rectif_chunks_green...")
    # Use the full path for MATLAB_EXE
    cmd = [
        MATLAB_EXE,
        '-batch',
        f"rectif_chunks_green('{input_folder}', '{output_folder}'); exit"
    ]
    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        for line in process.stdout:
            print(f"[MATLAB Chunks]: {line.strip()}")
        process.wait()
    except Exception as e:
        print(f"Failed to run MATLAB Chunks: {e}")

def run_matlab_instance(input_folder, output_folder, p1, p2, p3):
    """Starts one instance of the DBMC_2Ch MATLAB function."""
    # Use the full path for MATLAB_EXE
    cmd = [
        MATLAB_EXE,
        '-batch',
        f"DBMC_2Ch('{input_folder}', '{output_folder}', {p1}, {p2}, {p3}); exit"
    ]
    return subprocess.Popen(cmd)

def main():
    # Logic to select the correct zip file based on the channel
    if str(param2) == '1':
        zip_name = "patches.zip"
    else:
        zip_name = "patches_g.zip"
        if not os.path.exists(os.path.join(output_folder, zip_name)):
            zip_name = "patches.zip"

    zip_path = os.path.join(output_folder, zip_name)
    
    if not os.path.exists(zip_path):
        print(f"Error: Could not find {zip_path}")
        return

    # Count patches inside the zip
    with zipfile.ZipFile(zip_path) as z:
        num_patches = sum(1 for f in z.namelist() if not f.endswith('/') and f.endswith('.roi'))

    print(f"Total patches to process in {zip_name}: {num_patches}")

    active_processes = []
    do_check_min = 2    # Check frequency in minutes
    num_mats = 3        # Number of parallel instances

    # Run initial correction
    correct_chunks(input_folder, output_folder)

    # Launch initial batch
    for _ in range(min(num_mats, num_patches)):
        proc = run_matlab_instance(input_folder, output_folder, param1, param2, param3)
        active_processes.append(proc)
        time.sleep(15) 

    run_i = len(active_processes) 
    
    while run_i < num_patches or active_processes:
        print(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] Active: {len(active_processes)}. Processed: {run_i}/{num_patches}")
        time.sleep(do_check_min * 60) 

        active_processes = [p for p in active_processes if p.poll() is None]

        while len(active_processes) < num_mats and run_i < num_patches:
            run_i += 1
            proc = run_matlab_instance(input_folder, output_folder, param1, param2, param3)
            active_processes.append(proc)
            print(f">>> Started patch {run_i}...")
            time.sleep(10)

    t_end = datetime.datetime.now()
    print('-------------------------------')
    print(f'Finished at {t_end} (Duration: {t_end - t0})')

if __name__ == "__main__":
    main()