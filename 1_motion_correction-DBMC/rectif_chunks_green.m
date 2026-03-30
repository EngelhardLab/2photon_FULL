function rectif_chunks_green(input_folder,output_folder)

nueva_ruta = input_folder;

slashind = '\';
if isunix
    slashind ='/';
end

if ~strcmp(output_folder(end),slashind)
    output_folder=[output_folder,slashind];
end

%% get raw tif files
load([output_folder,'chunks_info'],'num_chunks','chunks_lengths_vec','chunks_green_filenames','chunks_red_filenames')
%%
[carpeta_base, ~, ~] = fileparts(chunks_green_filenames{1}{2}); %gobteniendo la ruta a partir de cualquier chunck

if size(carpeta_base,2) ~= size(nueva_ruta,2)
    disp('Correcting input path.')
    for i = 1:num_chunks    
        for j=1:chunks_lengths_vec(i)            
            chunks_green_filenames{i}{j}=strrep(chunks_green_filenames{i}{j}, carpeta_base, nueva_ruta);
            %chunks_green_filenames{chunk_ctr}{j}
        end
    end
    save([output_folder,'chunks_info'],'*chunk*')
else
    disp('Input path matches.')
end

end
