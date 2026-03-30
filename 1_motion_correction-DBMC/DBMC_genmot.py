import tkinter as tk
from tkinter import filedialog, scrolledtext
import subprocess
import threading
import datetime
import zipfile
import time

class DBMC_genmot:
    def __init__(self, root):
        self.running = False  # ?? buena practica//
        
        self.process = True
        self.t0 =datetime.datetime.now()
        self.root = root
        self.root.title("DBMC Runner")
        self.root.geometry("600x500")

        # args
        tk.Label(root, text="Input Folder:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.input_entry = tk.Entry(root, width=60)
        self.input_entry.grid(row=0, column=1, padx=5, pady=5)
        tk.Button(root, text="Browse", command=self.select_input).grid(row=0, column=2, padx=5, pady=5)

        tk.Label(root, text="Output Folder:").grid(row=1, column=0, padx=5, pady=5, sticky="w")
        self.output_entry = tk.Entry(root, width=60)
        self.output_entry.grid(row=1, column=1, padx=5, pady=5)
        tk.Button(root, text="Browse", command=self.select_output).grid(row=1, column=2, padx=5, pady=5)

        # usea n have red channel
        tk.Label(root, text="Have red channel?:").grid(row=2, column=0, padx=5, pady=5, sticky="w")
        self.param1_entry = tk.Entry(root, width=10)
        self.param1_entry.grid(row=2, column=1, padx=5, pady=5, sticky="w")
        self.param1_entry.insert(0, "1")  # Valor por defecto

        tk.Label(root, text="Use red channel?:").grid(row=3, column=0, padx=5, pady=5, sticky="w")
        self.param2_entry = tk.Entry(root, width=10)
        self.param2_entry.grid(row=3, column=1, padx=5, pady=5, sticky="w")
        self.param2_entry.insert(0, "0")  # Valor por defecto

        # start
        self.start_button = tk.Button(root, text="Start Processing", command=self.start_thread)
        self.start_button.grid(row=5, column=0, columnspan=2, pady=10)

        # cancel but
        self.cancel_button = tk.Button(root, text="CANCEL", command=self.cancel_processes)
        self.cancel_button.grid(row=5, column=1, columnspan=2, pady=10)

        # logs python/matlab
        tk.Label(root, text="Python Logs:").grid(row=6, column=0, padx=5, pady=5, sticky="w")
        self.python_log = scrolledtext.ScrolledText(root, width=70, height=5)
        self.python_log.grid(row=7, column=0, columnspan=3, padx=5, pady=5)

        tk.Label(root, text="MATLAB Logs:").grid(row=8, column=0, padx=5, pady=5, sticky="w")
        self.matlab_log = scrolledtext.ScrolledText(root, width=70, height=5)
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

    def log_python(self, message):
        self.python_log.insert(tk.END, message + "\n")
        self.python_log.see(tk.END)

    def log_matlab(self, message):
        self.matlab_log.insert(tk.END, message + "\n")
        self.matlab_log.see(tk.END)

    def run_matlab_instance(self, input_folder, output_folder, param1, param2):
        comando = [
            'matlab',
            '-batch',
            f"DBMC('{input_folder}', '{output_folder}', {param1}, {param2}); exit"
        ]

        process = subprocess.Popen(comando, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        #self.active_processes.append(process)

        # prints matlba output
        for line in process.stdout:
            self.log_matlab(line.strip())
            #t =datetime.datetime.now()
            #ddtime = (t- self.t0).total_seconds()
            #if ddtime % 1 = 0:
            #    self.log_python(f'30 mins since start. Time now > {t-self.t0}')
                


        process.wait()  # waits for the process to end *but doesn;t wait to start another instance
        t =datetime.datetime.now() 
        self.log_python(f'Finished at {datetime.datetime.now()} after {t-self.t0}')


    def start_processing(self):
        
        self.running = True
        self.start_button.config(state=tk.DISABLED)
        self.cancel_button.config(state=tk.NORMAL)

        input_folder = self.input_entry.get()
        output_folder = self.output_entry.get()
        param1 = self.param1_entry.get()
        param2 = self.param2_entry.get()

        if not input_folder or not output_folder or not param1 or not param2:
            self.log_python("ERROR: Please fill all fields")
            return

        self.log_python(f"Starting general motion correction...")
        self.process = threading.Thread(target=self.run_matlab_instance, args=(input_folder, output_folder, param1, param2), daemon=True).start()

        #self.log_python("Processing finished!")
        

        

    def start_thread(self):
         
        self.log_python(f'Starting time:{self.t0} ')
        threading.Thread(target=self.start_processing, daemon=True).start()
        

    def cancel_processes(self):
        self.running = False
        self.log_python("Cancelling all MATLAB processes...NO FUNCIONAAAAAAAA")

        self.process.terminate()

        #self.start_button.config(state=tk.NORMAL)
        self.cancel_button.config(state=tk.DISABLED)
        exit()

# Crear interfaz
root = tk.Tk()
app = DBMC_genmot(root)
root.mainloop()

