import subprocess
import os

#txt with the files's path sources
arkv_txt = "listforrobocopy.txt"

#modify this destino_base with the folder path where you want to save the copies
destino_base = r"C:\Users\Engelhardblab\Desktop\m9397\input9397"

print("starting>>")

# read arkv txt
with open(arkv_txt, 'r', encoding='utf-8') as f:
    folders_origin = [line.strip() for line in f if line.strip()]


for folder_origen in folders_origin:
    name_folder = os.path.normpath(folder_origen)
    name_destn = os.path.join(destino_base, f"{name_folder[-8:]}")

    print(" ")
    print(f"Robocopy for {name_folder} is starting...")
    
    cmd = [
        "robocopy",
        name_folder,
        name_destn,
        #uncomment the next line to  run a robocopy of only ch2 files
        # "*_Ch2_*.ome.tif", "*.env", "*.xml", "*.csv", "/njh", "/njs", "/ndl", "/nc", "/ns", "/np", "/nfl", "/E", "/MT:64"
        "/njh", "/njs", "/ndl", "/nc", "/ns", "/np", "/nfl", "/E", "/MT:64"  #command taken from https://docs.google.com/document/d/18VvelrUZvasc0ycSYt_RQBnan8AyWhOQuKR5ncfOjAo/edit?tab=t.0
    ]


    subprocess.run(cmd)

    print(f"Robocopy for {name_folder} is done !      >:)")
    print(" ")
    
    

print('*****************************************')
print(">>> Finished robocopy for all folders! <<<")
