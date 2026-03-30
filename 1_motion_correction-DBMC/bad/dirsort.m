function res = dirsort(argument)

res = dir(argument); 
[~,ind]=sort({res.name});
res = res(ind);