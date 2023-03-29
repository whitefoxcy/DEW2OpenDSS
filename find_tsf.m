close all
clear all
clc

load Maui_tree
indx=find(strcmp(Maui_tree.Type, 'One-Phase Distribution Transformer'));
count=0;
for i=1:length(indx)
    tsf(i).name=Maui_tree.UID.get(indx(i));
    temp.UID=Maui_tree.UID.subtree(indx(i));
    temp.Type=Maui_tree.Type.subtree(indx(i));
    temp.Rating=Maui_tree.rating.subtree(indx(i));
    temp.kw=Maui_tree.rating.subtree(indx(i));
    inx=find(strcmp(temp.Type, 'Inverter Type DR'));
    if ~isempty(inx)
    for j=1:length(inx)
        count=count+1;
        data(count).name=tsf(i).name;
        data(count).DG=temp.UID.get(inx(j));
        data(count).Rating=temp.Rating.get(inx(j));
        data(count).kw=temp.kw.get(inx(j));
    end
    end
end