import datetime
import subprocess
import time
import zipfile
import sys
import os

# --- CONFIGURATION ---
# Full path to the MATLAB executable on your Linux workstation
MATLAB_EXE = "/usr/local/MATLAB/R2024b/bin/matlab"
num_mats = 4  # Number of parallel MATLAB workers to launch

# --- ARGUMENT PARSING ---
if len(sys.argv) < 5:
    print("Usage: python3 dec_proc_2Ch.py <input_folder> <output_folder> <have_red> <use_red> [want_red]")
    sys.exit(1)

# Converting to absolute paths to ensure MATLAB finds the NAS directories
input_folder = os.path.abspath(sys.argv[1])
output_folder = os.path.abspath(sys.argv[2])
param1 = sys.argv[3] # have_red
param2 = sys.argv[4] # use_red
param3 = sys.argv[5] if len(sys.argv) > 5 else "0" # want_red

t0 = datetime.datetime.now() 
print(f"Starting time: {t0}")
print(f"Params: have_red={param1}, use_red={param2}, want_red={param3}")
print('-------------------------------')

def correct_chunks(in_f, out_f):
    """Initial pass: Calculates rigid translation shifts (rectif_chunks_green)."""
    print("Running initial rectification...")
    # Standard DBMC pipeline uses rectif_chunks_green for the first pass
    cmd = [
        MATLAB_EXE,
        '-batch',
        f"rectif_chunks_green('{in_f}', '{out_f}'); exit"
    ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        print(f"Error in rectification: {stderr}")
        sys.exit(1)
    print("Rectification complete.")

def run_matlab_worker(in_f, out_f, p1, p2, p3):
    """Launches the DBMC orchestrator to process untaken patches."""
    # Calling 'DBMC' instead of 'DBMC_2Ch'
    cmd = [
        MATLAB_EXE,
        '-batch',
        f"DBMC('{in_f}', '{out_f}', {p1}, {p2}, {p3}); exit"
    ]
    return subprocess.Popen(cmd)

# 1. Setup Folders and Initial Correction
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# Check if rectification is already done by looking for metadata
if not os.path.exists(os.path.join(output_folder, 'chunks_info.mat')):
    correct_chunks(input_folder, output_folder)
else:
    print("Metadata (chunks_info.mat) found. Skipping rectification.")

# 2. Count Patches to process
zip_path = os.path.join(output_folder, 'patches.zip')
if not os.path.exists(zip_path):
    print(f"Error: {zip_path} not found. Please place your ImageJ ROI zip file there.")
    sys.exit(1)

with zipfile.ZipFile(zip_path) as z:
    num_patches = sum(1 for f in z.namelist() if f.endswith('.roi'))

print(f"Total patches to process: {num_patches}")

# 3. Launch Workers
active_processes = []
for i in range(min(num_mats, num_patches)):
    print(f"Launching MATLAB Worker {i+1}...")
    p = run_matlab_worker(input_folder, output_folder, param1, param2, param3)
    active_processes.append(p)
    time.sleep(10) # Stagger start to prevent simultaneous I/O spikes on the NAS

# 4. Monitor Progress
print("Monitoring progress (checking for saved .tif files)...")
while active_processes:
    active_processes = [p for p in active_processes if p.poll() is None]
    
    # We count files starting with 'mc_image_stack_full_patch_' (Green)
    # This serves as a proxy for completed patches.
    done_files = [f for f in os.listdir(output_folder) if f.startswith('mc_image_stack_full_patch_') and f.endswith('.tif')]
    done_count = len(done_files)
    
    elapsed = datetime.datetime.now() - t0
    print(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] Active: {len(active_processes)} | Patches Done: {done_count}/{num_patches} | Elapsed: {elapsed}")
    
    if len(active_processes) == 0:
        break
        
    time.sleep(60)

print(f"Finished at {datetime.datetime.now()}. Total runtime: {datetime.datetime.now() - t0}")
