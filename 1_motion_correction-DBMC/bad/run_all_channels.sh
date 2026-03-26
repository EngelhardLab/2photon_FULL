#!/bin/bash

# --- CONFIGURATION ---
INPUT="/mnt/nas2/2Photon_Data/LIZA/Imaging_data/m4324/12252025/TSeries-12242025-1145-1537"
OUTPUT="/mnt/nas2/2Photon_Data/LIZA/Imaging_data/m4324/12252025/TSeries-12242025-1145-1537/Processed"

echo "------------------------------------------------------"
echo "CLEANUP: Removing old tracking files and temp folders"
echo "------------------------------------------------------"
# Remove 'taken' markers so every patch is processed again
rm -f "$OUTPUT"/Patch_*taken.txt
# Remove the tempsaves folder to avoid mixing data from old runs
rm -rf "$OUTPUT/tempsaves"

echo "------------------------------------------------------"
echo "STEP 1: Starting RED Channel (Ch1) Processing"
echo "Using patches.zip"
echo "------------------------------------------------------"
# have_red=1, use_red=1, want_red=1
python3 dec_proc_2Ch.py "$INPUT" "$OUTPUT" 1 1 1

echo "------------------------------------------------------"
echo "STEP 2: Starting GREEN Channel (Ch2) Processing"
echo "Using patches_g.zip"
echo "------------------------------------------------------"
# have_red=1, use_red=0, want_red=0
python3 dec_proc_2Ch.py "$INPUT" "$OUTPUT" 1 0 0

echo "------------------------------------------------------"
echo "ALL CHANNELS FINISHED SUCCESSFULLY"
echo "------------------------------------------------------"