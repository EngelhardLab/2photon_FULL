function run_first_rigid_mc(input_folder,output_folder,have_red_channel,use_red_channel)

if have_red_channel
    if use_red_channel
        frames_to_take = 2;
    else
        frames_to_take = 1;
    end
else
    frames_to_take = 0;
end

tiflist_green = dirsort([input_folder,'*Ch2*.tif']);
tiflist_red   = dirsort([input_folder,'*Ch1*.tif']);

%artifically divide in chunks of 1500 for drift analysis
num_chunks = ceil(length(tiflist_green)/1500);
length_of_last_chunk = length(tiflist_green)-1500*(num_chunks-1);
chunks_lengths_vec = [ones(1,num_chunks-1)*1500 length_of_last_chunk];


XX_cell = cell(1,num_chunks;
YY_cell = cell(1,num_chunks);

for i=1:num_chunks
    for j=1:chunks_lengths_vec(i)
        chunks_green_filenames{i}{j,1} = [input_folder,tiflist_green{1500*(i-1)+j}.name];
        chunks_red_filenames  {i}{j,1} = [input_folder,tiflist_red  {1500*(i-1)+j}.name];
    end
end

save([input_folder,'chunk_info'],'*chunk*')

%first motion correct each chunk separately

%get the size of the images
first_frame = imread(chunks_green_filenames{1}{1});
nImage = size(first_frame,1);
mImage = size(first_frame,2);

for i=1:num_chunks
    stack=zeros(nImage,mImage,chunks_lengths_vec(i),'single');
    if use_red_channel
        for j=1:length(chunks_lengths_vec(i))
            stack(:,:,j)=imread(chunks_red_filenames{i}{j});
        end
    else
        for j=1:length(chunks_lengths_vec(i))
            stack(:,:,j)=imread(chunks_green_filenames{i}{j});
        end
    end
    [total_i_vec,total_j_vec,template] = mc_rigid...
        (stack,50,10,1,30,0,1,-1,1);

    XX_cell{i} = total_j_vec;
    YY_cell{i} = total_i_vec;

    if i==1
        template_file = zeros([size(template) num_chunks],'single');
    end
    template_file(:,:,i) = template;
end

saveastiff(template_file,[output_folder,'template_mov_uncorr.tif']);
%now motion correct the templates and add the shifts to the separate file shifts obtained earlier.

[i_vec_templates,j_vec_templates,~,~,~,templates_stack_mc] = mc_rigid...
    (template_file,size(template_file,3),10,30,1,0,1,-1,1);

for i=1:length(XX_cell)
    XX_cell{i} = XX_cell{i} + j_vec_templates(i);
    YY_cell{i} = YY_cell{i} + i_vec_templates(i);

end

save([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')
saveastiff(templates_stack_mc,[output_folder,'template_mov.tif']);

% if we are using the red channel, then also make a frames file for the
% green channel
if have_red_channel && use_red_channel
    templates_green = zeros(size(templates_stack_mc));
    for i=1:num_chunks
        stack=zeros(nImage,mImage,chunks_lengths_vec(i),'single');
        for j=1:length(chunks_lengths_vec(i))
            stack(:,:,j)=imread(chunks_green_filenames{i}{j});
        end
        mc_stack = apply_mc(stack,YY_cell{i},XX_cell{i});
        templates_green(:,:,i)=get_med_of_avg_template(mc_stack,50);
    end
    saveastiff(templates_green,[output_folder,'template_mov_green.tif']);
end

