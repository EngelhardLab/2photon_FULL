import tkinter as tk
from tkinter import filedialog, scrolledtext
import subprocess
import threading
import datetime
import zipfile
import time

from io import StringIO  # Python 3
import sys

class DBMC_patches:
    def __init__(self, root):
        self.t0 = datetime.datetime.now()
        self.active_processes = []
        self.running = False  # buena práctica¿¿
        self.runs = 0
        self.chunks_rectif = False
        
        self.root = root
        self.root.title("DBMC_patches")
        self.root.geometry("900x900")

        # params
        tk.Label(root, text="Input Folder:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.input_entry = tk.Entry(root, width=60)
        self.input_entry.grid(row=0, column=1, padx=5, pady=5)
        tk.Button(root, text="Browse", command=self.select_input).grid(row=0, column=2, padx=5, pady=5)

        tk.Label(root, text="Output Folder:").grid(row=1, column=0, padx=5, pady=5, sticky="w")
        self.output_entry = tk.Entry(root, width=60)
        self.output_entry.grid(row=1, column=1, padx=5, pady=5)
        tk.Button(root, text="Browse", command=self.select_output).grid(row=1, column=2, padx=5, pady=5)

        tk.Label(root, text="Have red channel?").grid(row=2, column=0, padx=5, pady=5, sticky="w")
        self.param1_entry = tk.Entry(root, width=10)
        self.param1_entry.grid(row=2, column=1, padx=5, pady=5, sticky="w")
        self.param1_entry.insert(0, "0") 

        tk.Label(root, text="Use red channel?").grid(row=3, column=0, padx=5, pady=5, sticky="w")
        self.param2_entry = tk.Entry(root, width=10)
        self.param2_entry.grid(row=3, column=1, padx=5, pady=5, sticky="w")
        self.param2_entry.insert(0, "0") 

        tk.Label(root, text="Number of MATLAB instances:").grid(row=4, column=0, padx=5, pady=5, sticky="w")
        self.nm_entry = tk.Entry(root, width=10)
        self.nm_entry.grid(row=4, column=1, padx=5, pady=5, sticky="w")
        self.nm_entry.insert(0, "5") 

        tk.Label(root, text=" (5 or less recommended)").grid(row=4, column=2, padx=2, pady=2)

        # start but
        self.start_button = tk.Button(root, text="Start Processing", command=self.start_thread)
        self.start_button.grid(row=5, column=0, columnspan=2, pady=10)

        # cancel
        self.cancel_button = tk.Button(root, text="CANCEL", command=self.cancel_processes, state=tk.DISABLED)
        self.cancel_button.grid(row=5, column=1, columnspan=2, pady=10)
        
        # Exit
        exit_button = tk.Button(root, text="Exit", command=root.destroy) 
        exit_button.grid(row=5, column=2, columnspan=2, pady=10)

        
        # Logs
        tk.Label(root, text="Python Logs:").grid(row=6, column=0, padx=5, pady=5, sticky="w")
        self.python_log = scrolledtext.ScrolledText(root, width=90, height=15)
        self.python_log.grid(row=7, column=0, columnspan=3, padx=5, pady=5)

        tk.Label(root, text="MATLAB Logs:").grid(row=8, column=0, padx=5, pady=5, sticky="w")
        self.matlab_log = scrolledtext.ScrolledText(root, width=90, height=15)
        self.matlab_log.grid(row=9, column=0, columnspan=3, padx=5, pady=5)

    def select_input(self):
        folder = filedialog.askdirectory()
        if folder:
            self.input_entry.delete(0, tk.END)
            self.input_entry.insert(0, folder)

    def select_output(self):
        folder = filedialog.askdirectory()
        if folder:
            self.output_entry.delete(0, tk.END)
            self.output_entry.insert(0, folder)


    def log_python(self, message, error=False):
        self.python_log.tag_configure("error", foreground="red")
    
        if error:
            self.python_log.insert(tk.END, message + "\n", "error")
        else:
            self.python_log.insert(tk.END, message + "\n")
    
        self.python_log.see(tk.END)

    def log_matlab(self, message, error=False):
        
        self.matlab_log.tag_configure("error", foreground="red")
    
        if error:
            self.matlab_log.insert(tk.END, message + "\n", "error")
        else:
            self.matlab_log.insert(tk.END, message + "\n")
    
        self.matlab_log.see(tk.END)



    def correct_chunks(self, input_folder, output_folder):
        #correct chunks paths
        cmd = [
            'matlab',
            '-batch',
            f"rectif_chunks_green('{input_folder}', '{output_folder}'); exit"
        ]

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        
        for line in process.stdout:
            #self.log_matlab(line.strip())
            self.log_python(line.strip(), error=True)

        for line in process.stderr:
            self.log_matlab("MATLAB ERROR: " + line.strip(), error=True)

        self.chunks_rectif = True
        self.chunks_rectif_proc = process
        process.wait()
        #time.sleep(10000)
        process.kill()


    def run_matlab_instance(self, input_folder, output_folder, param1, param2):
        
        comando = [
            'matlab',
            '-batch',
            f"DBMC_fast('{input_folder}', '{output_folder}', {param1}, {param2}); exit"
        ]

        process = subprocess.Popen(comando, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.active_processes.append(process)


        # output matlab FALTAN AGREGAR LAS ALERTAS DE ERRORES --- STDERR
        for line in process.stdout:
            self.log_matlab(line.strip())
            if line.startswith("Now working on patch"):
                self.log_python(line.strip())


        for line in process.stderr:
            self.log_matlab("MATLAB ERROR: " + line.strip(), error=True)


        #process.wait()
        process.kill()  
    
        

        
    

    def start_processing(self):
        self.running = True
        self.start_button.config(state=tk.DISABLED)
        self.cancel_button.config(state=tk.NORMAL)

        input_folder = self.input_entry.get()
        output_folder = self.output_entry.get()
        param1 = self.param1_entry.get()
        param2 = self.param2_entry.get()
        num_mats = self.nm_entry.get()

        do_check = 20

        self.log_python(f'Starting time:{datetime.datetime.now()}')


        if not input_folder or not output_folder or not param1 or not param2 or not num_mats:
            self.log_python("ERROR: Please fill all fields")
            return

        num_patches = sum(1 for f in zipfile.ZipFile(f"{output_folder}/patches.zip").namelist() if not f.endswith('/'))
        num_mats = int(num_mats)

        self.log_python('--------------------------------------------')
        self.log_python('Analizing chunks file, does path matches?...')
        self.correct_chunks(input_folder, output_folder)
            

        self.log_python(f"Processing {num_patches} patches with {num_mats} MATLAB instances...")
        if self.chunks_rectif : 
            self.chunks_rectif_proc.kill()
            self.chunks_rectif = False

        for _ in range(num_mats):
            self.run_matlab_instance(input_folder, output_folder, param1, param2)
            time.sleep(10)
            self.runs += 1
            self.log_python(f">>>>>>>>>>>>>>>>>>>>>>>>> proc patch {self.runs} of {num_patches} ... Time:{datetime.datetime.now()}", error=True)
            
            
        
        while  self.runs < num_patches + 1 or self.active_processes:
            self.log_python("sleeping...")
            time.sleep(do_check * 60)  # x 60 - in mins
            self.log_python("waking up... checking for finished processes")

            try :
                self.active_processes = [p for p in self.active_processes if p.poll() is None] #is it still exec?
            except Exception as e :
                self.log_python(f"ERROR: {str(e)}")

            #newprocess if needed
            while len(self.active_processes) < num_mats and self.runs < num_patches:
                #parche_id = archivos_a_procesar.popleft()
                #self.run_matlab_instance(input_folder, output_folder, param1, param2)
                
                threading.Thread(target=self.run_matlab_instance, args=(input_folder, output_folder, param1, param2), daemon=True).start()
                self.runs += 1
                self.log_python(f">>>>>>>>>>>>>>>>>>>>>>>>> proc patch {self.runs} of {num_patches} ... Time:{datetime.datetime.now()}", error=True)               
                
                time.sleep(10)


        t = datetime.datetime.now()
        self.log_python(f"Processing finished! at {t} after {t -self.t0}")
        self.start_button.config(state=tk.NORMAL)
        self.cancel_button.config(state=tk.DISABLED)

    def start_thread(self):
        #threading.Thread(target=self.start_processing, daemon=True).start()
        self.start_processing()

    def cancel_processes(self):
        self.running = False
        self.log_python("Cancelling all MATLAB processes...")

        if self.chunks_rectif : 
            self.chunks_rectif_proc.kill()

        for process in self.active_processes:
            process.kill()

        self.start_button.config(state=tk.NORMAL)
        self.cancel_button.config(state=tk.DISABLED)

# Crear interfaz
root = tk.Tk()
app = DBMC_patches(root)
root.mainloop()
