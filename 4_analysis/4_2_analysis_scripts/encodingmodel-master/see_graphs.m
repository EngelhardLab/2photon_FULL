function see_graphs(folder)

sess = dir(folder);
sessions = {sess.name}
for i = 1 : length(sessions)
    if contains(sessions(i),'2025')
        figg = [folder,'\', char(sessions(i)),'\matrices_graph.fig'];
        uiopen(figg,1)    
    end

end
