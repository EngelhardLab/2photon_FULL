
function res=process_fast(i,input_folder,output_folder,patch_file,patch_ctr,have_red_channel,use_red_channel)

disp(['Sleeping on patch >>>> ',num2str(i)])
disp('??????')
k = 0;
if k == 0
    causeException = MException('MATLAB:notEnoughInputs','Not enough input arguments.');
end

n = 0.5 * 60 ;
pause(n)
disp(['woke up : patch >>>> ',num2str(i)])
%%
throw(causeException)
disp('Now saving ds5 movie...')













