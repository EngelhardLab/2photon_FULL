function genmot_2check(input_folder, output_folder, have_red_channel)
% This function was created to verify if the general motion was executed
% correctly, as some Ch1 files were filtered along with Ch2, resulting
% in blurring or artifacts in the template_mov.tif file.
% Currently unused as run_first_rigid_mc_and_get_sharp_templates performs a
% better filtering of channels now.


archivos = dirsort([input_folder,'\*_Ch*.tif']);

if have_red_channel
   tiflist_green = archivos(contains({archivos.name}, '_Ch2_') & ~contains({archivos.name}, '_Ch1_'));
   tiflist_red   = archivos(contains({archivos.name}, '_Ch1_') & ~contains({archivos.name}, '_Ch2_'));
else
   tiflist_green = archivos(contains({archivos.name}, '_Ch2_') & ~contains({archivos.name}, '_Ch1_'));
end

load([output_folder,'\final_xy_shifts'],'XX_cell','YY_cell')

if length(cell2mat(XX_cell)) ~= length(tiflist_green) || length(cell2mat(YY_cell)) ~= length(tiflist_green)
    disp('SIZES DONT MATCH')
    disp(length(cell2mat(XX_cell)))
    disp(length(tiflist_green))
else 
    disp('Sizes match. General motion was run correctly.')
    disp(length(cell2mat(XX_cell)))
    disp(length(tiflist_green))
end

if have_red_channel
    disp('checking red channel files...')
    if length(cell2mat(XX_cell)) ~= length(tiflist_red) || length(cell2mat(YY_cell)) ~= length(tiflist_red)
        disp('Correcting input path.')
else 
    disp('Sizes match. General motion was run correctly.')
    end
end 