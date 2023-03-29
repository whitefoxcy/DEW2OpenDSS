close all
clear all
clc

cd('E:\YanChen\OpenDSS\DEW_OpenDSS\Trans_Data\Trans_20170706')
a=pwd;
files=dir(fullfile(a, '*.csv'));
for n=1:length(files)
name=files(n).name
fileID=fopen(name,'rt')
temp =textscan(fileID,'%s %f %f %f %s','delimiter',',','HeaderLines',1,'EmptyValue',-Inf);
fclose(fileID)
fid = fopen('E:\YanChen\OpenDSS\DEW_OpenDSS\Trans_Data\test.csv','wt');
for i=1:length(temp{1,1})
    val1 = temp{1}{i};
    val2 = temp{2}(i);
    val3 = temp{3}(i);
    val4 = temp{4}(i);
    val5 = temp{5}{i};
    fprintf(fid, '%s,%f,%s,%f,%s', val1, val2, val3, val4, val5);
end
fclose(fid);
movefile('E:\YanChen\OpenDSS\DEW_OpenDSS\Trans_Data\test.csv', name,'f')
end