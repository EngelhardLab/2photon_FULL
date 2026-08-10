function template=get_med_of_avg_template(stack,avg_win)

if nargin<2
    avg_win=50;
end

if size(stack,3 ) < avg_win
    avg_win=round(size(stack,3)/2) ;
end

if canUseGPU
    avgs_stack = zeros(size(stack,1),size(stack,2),floor(size(stack,3)/avg_win),"gpuArray");
else
    avgs_stack = zeros(size(stack,1),size(stack,2),floor(size(stack,3)/avg_win));
end

for i=1:size(avgs_stack,3)
    avgs_stack(:,:,i) = mean(stack(:,:,(i-1)*avg_win+1:i*avg_win),3);    
end
    
template=median(avgs_stack,3);
