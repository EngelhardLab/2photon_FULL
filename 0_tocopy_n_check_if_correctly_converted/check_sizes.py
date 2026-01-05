import subprocess
import re
import os
import sys

to_check_folder = sys.argv[1] #folder where the copies are saved now
NAS_folder = sys.argv[2]

#this only works with WINDOWS 

print("Starting...")

def get_folder_size_bytes(path):
    #command dir <folder> /s 
    try:
        result = subprocess.run(['cmd', '/c', 'dir', path,'/s'], capture_output=True, text=True, check=True)
        output = result.stdout.strip().splitlines()
       
        for line in reversed(output[-4:]):
            if 'File(s)' in line and 'bytes' in line:
                match = re.search(r'File\(s\)\s+([\d,]+)\s+bytes', line)
                if match:
                    size_str = match.group(1).replace(',', '')
                    return int(size_str)
        print(f"not found : {path[-8:]}")
        return None
    except Exception as e:
        print(f"Error processing {path}: {e}")
        return None

def compare_folder(carpeta1_root, carpeta2_root):
    same_siz = []
    diff_siz = []
    misssing = []

    for nombre in os.listdir(carpeta1_root):
        path1 = os.path.join(carpeta1_root, nombre)
        path2 = os.path.join(carpeta2_root, nombre)

        if not os.path.isdir(path1):
            continue  

        if not os.path.exists(path2):
            misssing.append(nombre)
            continue

        size1 = get_folder_size_bytes(path1)
        size2 = get_folder_size_bytes(path2)

        if size1 is None or size2 is None:
            print(f"couldn't process :  {nombre}")
            continue

        if size1 == size2:
            same_siz.append([nombre,size1,size2])
        else:
            diff_siz.append((nombre, size1, size2))

    print("\n same size folders:")
    for name, s1, s2 in same_siz:
        print(name)

    print("\n different size folders !!!!!!:")
    for name, s1, s2 in diff_siz:
        print(f"{name}: {s1} vs {s2} bytes")

    print("\n folders not found @ NAS :")
    for name in misssing:
        print(name)


compare_folder(to_check_folder, NAS_folder)