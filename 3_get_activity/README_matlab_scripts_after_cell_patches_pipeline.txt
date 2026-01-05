


1. Have all cell patches & background ready



2. Copy the folder path were patches are  ( <ex> : 'D:\DBMC_bruker\m9399\23022025_patches' )



3. Get the traces using the python script called dec_proc_traces.py 

	> Open the terminal in the current folder (Right click > Open in Terminal)	
	> Run this command 
			python3 dec_proc_traces.py <insert folder path>
		
	(for example -->   python3 dec_proc_traces.py D:\DBMC_bruker\m9399\23022025_patches )
	> This might take around 5 hours (depends on the number of cells)



4. When traces are done open MATLAB and run 'is_zzero.m' function. For this folder example :  

	<ex>		is_zzero('D:\DBMC_bruker\m9399\23022025_patches')
	
	> This script checks if any {trace_cell - 0.58 * trace_annulus} is zero
	> If no zeros are found, you might continue
	> Else, redo the cell and annulus patches for the ones that the script found zeros for.


5. When no zeros are found, run 'get_all_dffs.m' function. For this folder example :  

	<ex>		 get_all_dffs('D:\DBMC_bruker\m9399\23022025_patches')

	> This will calculate all dffs for each trace and generate a file for each cell in each trace folder
	  (for example in D:\DBMC_bruker\m9399\23022025_patches\patch_1_tracesfolder\dffs_traces__patch_1 )
 
>>> Now, depending on how you want to visualize the data, there are two options
	OPT A. 
	OPT B. Hierarchical clustering ordering (without following any vector order) // Without taking into 
	       account only reward times

6.A Run ''

6.B Run 'graph_N_corrmat.m' to visualize the traces and the correlation matrix for this data. For 
   this example :
	
	<ex>		graph_N_corrmat('D:\DBMC_bruker\m9399\23022025_patches')

