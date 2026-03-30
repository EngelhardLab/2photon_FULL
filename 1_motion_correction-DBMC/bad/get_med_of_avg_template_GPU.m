function template_gpu = get_med_of_avg_template_GPU(stack, avg_win)

if nargin < 2
    avg_win = 50;
end

% stack a gpuArray
stack_gpu = gpuArray(stack);

%num_avg_frames = floor(size(stack,3)/avg_win);
avgs_stack_gpu = zeros(size(stack,1),size(stack,2),floor(size(stack,3)/avg_win),"gpuArray");
num_avg_frames = size(avgs_stack_gpu,3);

for i = 1:num_avg_frames
    avgs_stack_gpu(:, :, i) = mean(stack_gpu(:, :, (i-1)*avg_win + 1:i*avg_win), 3);
end

template_gpu = median(avgs_stack_gpu, 3);

end
