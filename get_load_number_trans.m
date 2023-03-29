close all
clear all
clc
load Maui_tree

b=find(strcmp(Maui_tree.UID,'632_Xfrm'));
path = Maui_tree.UID.findpath(1,b) 
imp=0;
for i=1:length(path)-1
    imp=imp+Maui_tree.impedance.get(path(i));
end