% This code is developed to generate the basecase for power flow analysis
close all
clear all
clc
% cd('D:\Google Drive\mauiMeadows')
%input the path for load/pv data
folder_path ='D:\OpenDSS\DEW_OpenDSS\Trans_Data\'
%load the tree
load Maui_tree_aggr
%load the list of tsf and attached PV/load
load 'tsf and inverter list'
load 'tsf and load list'
%load the tsf rating
filename = 'tsf_rating.xlsx';
A = importdata(filename);
%load the coordinates (note these could be included in the tree in next rev)
filename1 = 'maui_coor_aggr.csv';
B = importdata(filename1);
%constants
%header='Yes';
KVS_1 = [7.2 .24];
KVS_3 = [12.47 .48];
conns_tsf = 'wye,wye';
windings = 2;
KV_load = .240;
mode = 'duty';
step_size = '1s';
number = 4320; % Number of points to expect when defining the curve
sInterval = 1.0; %specify interval in seconds
column_p =1;
column_p_pv =2;
use_actual = 'True'
voltage_bases=[69 12.47 .4157];
%Choose the sample time if not using load shape
single = 'False'
time_point=datenum(2017,07,06,11,15,00);
daystr=datestr(time_point, 'yyyymmdd');
%bus connnection, bus1 is the parent UID_b and bus 2 is the component UID_b
%need to first get the phasing of the component then create the bus
%accordingly 3 phase is .1.2.3.0 and single phase is .1(2)(3).0
%create a new model with a source bus
model= 'Master_Maui_aggr' %Main code name
gen_name='PVSystem_aggr'
load_name='Loads_aggr';
coor_name='Maui_aggr_coor';
create_model(model,coor_name,gen_name,load_name,69,3);
fileID = fopen([model '.dss'],'a');
fileID2 = fopen([coor_name '.dss'],'a');
fileID3 = fopen([gen_name '.dss'],'a');
fileID4 = fopen([load_name '.dss'],'a');
%create the coordinate for the source bus
write_coor(fileID2,'SourceBus',1721378,127366);
% since the substation tsf is not included in the tree, create a substation
% transformer connected to the source bus
sub_bus = create_bus('4_Sub_Xfrm','ABC');
create_tsf(fileID,'4_Sub_Xfrm',3,windings,1.2,[.46,.168],['SourceBus_b, ' sub_bus], conns_tsf ,[69 12.47],[1000 1000],'Yes');
coor_idx=find(strcmp(B.textdata,'4_Sub_Xfrm'));
x_coor=B.data(1,1);
y_coor=B.data(1,2);
write_coor(fileID2,'4_Sub_Xfrm',x_coor,y_coor);
%start from node 2 of the tree since node 1 is the source bus

for i =2:length(Maui_tree.UID.Node)
    i %index
%retrieve the information for a node from the tree
phase = Maui_tree.Phase.get(i);
phase_num = check_phase(phase);
name = strtrim(Maui_tree.UID.get(i));
type = Maui_tree.Type.get(i);
[bus, p_num] = create_bus(name,phase);
length = 1;
parent_idx = Maui_tree.UID.Parent(i);
impedance = Maui_tree.impedance.get(i);
%get the coordinate of the node and write to file
coor_idx=find(strcmp(B.textdata,name));
x_coor=B.data(coor_idx,1);
y_coor=B.data(coor_idx,2);
if strcmp(type,'Load Bus')==1 || strcmp(type,'Inverter Type DR')==1 
else
    write_coor(fileID2,name,x_coor,y_coor);
end
%calculate the appropriate impedance for the line and asign 0 for other
%type of node, tsf will get information from rating
if phase_num == 1
    if strcmp(type,'Inverter Type DR')==1 || strcmp(type,'Load Bus')==1 || strcmp(type, 'One-Phase Distribution Transformer') == 1 ...
            || strcmp(type, 'Rated BusBar') == 1 || strcmp(type,'Bus Bar')==1 || strcmp(type, 'One-Ph Ugrd Distribution Transformer') == 1;
    r_matrix = 0;
    x_matrix = 0;
    else
    r_matrix = real(diag(impedance));
    x_matrix = imag(diag(impedance));
    non_zero = find(r_matrix);
    r_matrix = r_matrix(non_zero(1));
    x_matrix = x_matrix(non_zero(1));
    end
else
    Z_012 = matrix_to_sequence(impedance);
    real_imp = real(Z_012);
    imag_imp = imag(Z_012);
    r_matrix(1) = real_imp(2);
    r_matrix(2) = real_imp(1);
    x_matrix(1) = imag_imp(2);
    x_matrix(2) = imag_imp(1);
end

if  isempty(parent_idx)
    fprint(fileID,'no parent found for this node %s \r\n',name)
end

if ~isempty(parent_idx)
    name_p = strtrim(Maui_tree.UID.get(parent_idx));
    bus_p = create_bus(name_p,phase);
    buses = join_str(bus_p,bus);
end

units = 'kFt';
%Creating the lines in the model
if strcmp(type,'3-Phase Line')==1 || strcmp(type,'3-Phase Underground Cable')==1
   if i==2
   create_line(fileID,name,phase_num,'4_Sub_Xfrm_b.1.2.3.0',bus,length,units,r_matrix,x_matrix);
   else
   create_line(fileID,name,phase_num,bus_p,bus,length,units,r_matrix,x_matrix);
   end
elseif strcmp(type,'1-Phase Line')==1 || strcmp(type,'2-Phase Cable')==1  ||strcmp(type,'1-Phase Underground Cable')==1 
    create_line(fileID,name,phase_num,bus_p,bus,length,units,r_matrix,x_matrix);
elseif strcmp(type,'Bus Bar')==1 && phase_num == 1  
   create_line(fileID,name,phase_num,bus_p,bus,length,units,[1e-5],[1e-5]);   
elseif strcmp(type,'Bus Bar')==1 && phase_num == 3  
   create_line(fileID,name,phase_num,bus_p,bus,length,units,[1e-5,1e-5],[1e-5,1e-5]); 
elseif strcmp(type,'Rated BusBar')==1 && phase_num == 1  
   create_line(fileID,name,phase_num,bus_p,bus,.01,units,[1e-5],[1e-5]); 
elseif strcmp(type,'Rated BusBar')==1 && phase_num == 3  
   create_line(fileID,name,phase_num,bus_p,bus,.01,units,[1e-5,1e-5],[1e-5,1e-5]); 
end
%creating the transformers
if strcmp(type,'One-Phase Distribution Transformer')==1 || strcmp(type,'One-Ph Ugrd Distribution Transformer')==1 
   [XHL,load_loss,KVAS] = check_tsf_data(A,name);
   create_tsf(fileID,name,phase_num,windings,XHL,load_loss,buses,conns_tsf,KVS_1,KVAS,'no')
end
%creating the house load
if strcmp(type,'Load Bus')==1 
   shape = [name '_1'];
   %file = [name '.csv']
   f_idx = find(strcmp({load_data.DG},name));
   tsf_name= load_data(f_idx).name;
   data_path=[folder_path tsf_name];
   file=[tsf_name '_LB_' daystr '.csv'];
   column_q =3;
   if strcmp(single,'False')
   create_loadshape(fileID4,shape,number,sInterval,file,column_p,column_q,use_actual)
   end
   create_house_load(time_point,daystr,folder_path,load_data,fileID4,name,phase_num,KV_load,bus_p,shape,single)
end

if strcmp(type,'Inverter Type DR')==1 
    % KW_DG = 1;
    % KVA_DG = 1;
    KW_DG = Maui_tree.kw.get(i);
    KVA_DG = Maui_tree.rating.get(i);
    shape = [name '_1'];
    f_idx = find(strcmp({data.DG},name));
    tsf_name= data(f_idx).name;
    data_path=[folder_path tsf_name];
    file=[tsf_name '_LB_' daystr '.csv'];
    column_q =0;
    if strcmp(single,'False')
    create_loadshape(fileID3,shape,number,sInterval,file,column_p_pv,column_q,use_actual)
    end
    create_DG(p_num,time_point,daystr,folder_path,data,fileID3,name,phase_num,KV_load,bus_p,KW_DG,KVA_DG,shape,single)
end

end
%write the model configuration at the end of model file
config_model(fileID,model,coor_name,gen_name,load_name,mode,step_size,number,voltage_bases);
%closing all files
fclose(fileID);
fclose(fileID2);
fclose(fileID3);
fclose(fileID4);

function create_model(name,coor_name,gen_name,load_name,base_kv,phase)
%create a new model 
fileID = fopen([name '.dss'],'w');
fprintf(fileID,'Clear\r\n');
fprintf(fileID,'//------creating new model %s -----------// \r\n',name);
fprintf(fileID,'New circuit.%s basekv=%d bus1= SourceBus_b Phases = %d\r\n',name,base_kv,phase);
fileID2 = fopen([coor_name '.dss'],'w');
fileID3 = fopen([gen_name '.dss'],'w');
fileID4 = fopen([load_name '.dss'],'w');
fclose(fileID);
fclose(fileID2);
fclose(fileID3);
fclose(fileID4);
end

function create_house_load(time_point,daystr,folder_path,data,fileID,name,phase,KV_load,bus,duty,single)
if strcmp(single,'False')
    fprintf(fileID,'//------adding new house load %s -----------// \r\n',name);
    fprintf(fileID,'New Load.%s phases = %d KV=%.3f kW=1 kVAr=1 Bus1=%s duty=%s \r\n'...
        ,name,phase,KV_load,bus,duty);
else
    f_idx = find(strcmp({data.DG},name));
    tsf_name= data(f_idx).name;
    data_path=[folder_path tsf_name];
    data_file=[tsf_name '_LB_' daystr '.csv'];
    cd(data_path);
    fileID5=fopen(data_file);
    C=textscan(fileID5,'%s %f %f %f %s','delimiter',',','HeaderLines',1,'EmptyValue',-Inf);
    temp_t=datenum(C{1}(:,1));
    data_inx=find(temp_t==time_point);
    P_refkW = C{2}(data_inx);
    Q_refkVAr= C{4}(data_inx);
    fclose(fileID5);
    fprintf(fileID,'//------adding new Load %s -----------// \r\n',name);
    fprintf(fileID,'New Load.%s bus=%s phases = %d Conn=Wye model=1 kV=%.2f kW=%f kVAr=%f \r\n'...
        ,name,bus,phase,KV_load,P_refkW,Q_refkVAr);
    
end
end

function create_DG(p_num,time_point,daystr,folder_path,data,fileID,name,phase,KV_load,bus,KW_DG,KVA_DG,duty,single)
if strcmp(single,'False')
    fprintf(fileID,'//------adding new DG %s -----------// \r\n',name);
    fprintf(fileID,'New Generator.%s phases = %d KV=%.2f Bus1=%s KW=%4.1f KVA=%4.1f Pf=1.0 duty=%s \r\n'...
        ,name,phase,KV_load,bus,KW_DG,KVA_DG,duty);
else
    f_idx = find(strcmp({data.DG},name));
    tsf_name= data(f_idx).name;
    data_path=[folder_path tsf_name];
    data_file=[tsf_name '_LB_' daystr '.csv'];
    cd(data_path);
    fileID5=fopen(data_file);
    C=textscan(fileID5,'%s %f %f %f %s','delimiter',',','HeaderLines',1,'EmptyValue',-Inf);
    temp_t=datenum(C{1}(:,1));
    data_inx=find(temp_t==time_point);
    P_refkW = C{3}(data_inx);
    fclose(fileID5);
    if P_refkW > KVA_DG
        KVA_DG = P_refkW*1.1;
        KW_DG = P_refkW*1.1;
    end
    fprintf(fileID,'//------adding new DG %s -----------// \r\n',name);
    fprintf(fileID,'New PVSystem.%s bus1=%s phases = %d KVA=%4.1f KV=%.2f Pmpp=%4.1f EffCurve=Eff P-TCurve=FatorPvsT pctPmpp=100 Temperature=25 irradiance=1 \r\n'...
        ,name,bus,phase,KVA_DG,KV_load,P_refkW);
    
end
end

function [XHL,load_loss,KVAS] = check_tsf_data(A,name)
     idx = find(strcmp(A.textdata,name));
     rating = A.data(idx);
     switch rating
         case 15
             XHL = 1.689;
             load_loss = [1.367 .253];
             KVAS = [15 15];
         case 25
             XHL = 1.749;
             load_loss = [1.568 .172];
             KVAS = [25 25];
         case 38
             XHL = 2.279;
             load_loss = [1.139 .165];
             KVAS = [38 38];
         case 50
             XHL = 2.199;
             load_loss = [1.056 .158];
             KVAS = [50 50];
        case 75
             XHL = 1.609;
             load_loss = [.934 .190];
             KVAS = [75 75];
        case 100
             XHL = 2.272;
             load_loss = [.823 .056];
             KVAS = [100 100];
     end

end

function create_loadshape(fileID,name,npts,sInterval,file,column_p,column_q,use_actual)
%use info from the tree to create load
fprintf(fileID,'//------adding new loadshape %s -----------// \r\n',name);
if ~isequal(column_q,0)
    fprintf(fileID,'New LoadShape.%s npts = %d sInterval =%4.1f mult =(File=%s Column=%d) Qmult=(File=%s Column=%d) useactual=%s \r\n'...
        ,name,npts,sInterval,file,column_p,file,column_q,use_actual);
else
    fprintf(fileID,'New LoadShape.%s npts = %d sInterval =%4.1f mult =(File=%s Column=%d) Qmult=0 useactual=%s \r\n'...
        ,name,npts,sInterval,file,column_p,use_actual);
end
end

function create_tsf(fileID,name,phase,winding,XHL,load_loss,buses,conns,KVS,KVAS,sub)
fprintf(fileID,'//------adding new tsf %s -----------// \r\n',name);
fprintf(fileID,'New Transformer.%s phases = %d windings =%d XHL=%4.2f %%loadloss=%.4f %%noloadloss=%.4f Buses=(%s) Conns=(%s) KVS=(%4.2f, %4.2f) KVAS=(%d, %d) Sub=%s \r\n'...
    ,name,phase,winding,XHL,load_loss,buses,conns,KVS,KVAS,sub);
end

function create_line(fileID,name,phase_num,bus,bus_p,length,units,r_matrix,x_matrix)
fprintf(fileID,'//------adding new line %s -----------// \r\n',name);
if phase_num == 1
    fprintf(fileID,'New line.%s phases =%d Bus1=%s Bus2=%s length=%4.4f units=%s rmatrix=[%f] xmatrix=[%f] \r\n'...
    ,name,phase_num,bus,bus_p,length,units,r_matrix,x_matrix);
else
    fprintf(fileID,'New line.%s phases =%d Bus1=%s Bus2=%s length=%4.4f units=%s r1=[%f] r0=[%f] x1=[%f] x0=[%f] \r\n'...
    ,name,phase_num,bus,bus_p,length,units,r_matrix,x_matrix);
end
end



function config_model(fileID,model,coor_name,gen_name,load_name,mode,step_size,number,voltage_bases)
fprintf(fileID,'//------adding new PVs and Loads -----------//\r\n');
fprintf(fileID,'\r\nRedirect %s.dss\r\n',gen_name);
fprintf(fileID,'\r\nRedirect %s.dss\r\n',load_name);
fprintf(fileID,'//------simulation mode-----------//\r\n');
fprintf(fileID,'set mode =%s\r\n',mode);
fprintf(fileID,'set stepsize =%s\r\n',step_size);
fprintf(fileID,'set number =%d\r\n',number);
fprintf(fileID,'set voltagebases =(%4.2f, %4.2f,% 4.2f)\r\n',voltage_bases);
fprintf(fileID,'Calcvoltagebases\r\n');
fprintf(fileID,'//-----------------Set a Energy Meter after substation------------------//\r\n');
fprintf(fileID,'New Energymeter.Meter1 element=line.227595_UG terminal=1\r\n');
fprintf(fileID,'//------Import Bus coordinate for %s -----------//\r\n',model);
fprintf(fileID,'BusCoords %s.dss\r\n',coor_name);
end

function write_coor(fileID,name,x_coor,y_coor)
a = find(name=='.');
if ~isempty(a)
    name(a)='_';
end
fprintf(fileID,'%s_b, %.1f, %.1f \r\n',name,x_coor,y_coor);
end

function [bus, p_num] = create_bus(node_uid,phase_node)
a = find(node_uid=='.');
if ~isempty(a)
    node_uid(a)='_';
end
    
if length(phase_node) == 3
    bus = [node_uid '_b.1.2.3.0'];
    p_num =4;
elseif strcmp(phase_node(1),'B')
    bus = [node_uid '_b.2.0'];
    p_num =2;
elseif  length(phase_node) == 1 && strcmp(phase_node(1),'A')
    bus = [node_uid '_b.1.0'];
    p_num =1;
elseif length(phase_node) == 1 && strcmp(phase_node(1),'C')
    bus = [node_uid '_b.3.0'];
    p_num =3;
elseif  length(phase_node) == 2 && strcmp(phase_node(1),'A') && strcmp(phase_node(2),'C')
    bus = [node_uid '_b.3.0'];
    p_num =3;
elseif  length(phase_node) == 2 && strcmp(phase_node(1),'A') && strcmp(phase_node(2),'B')
    bus = [node_uid '_b.1.0'];
    p_num =1;
end  

end

function phase_num = check_phase(phase)
if length(phase) == 3
    phase_num = 3;
else 
    phase_num = 1;
end
end

function joint_str = join_str(from,to)
 joint_str = [from ',' to];
end

function Z_012 = matrix_to_sequence(impedance)
a=exp(2/3*pi*i);
A_inv=1/3*[1 1 1;1 a a^2; 1 a^2 a];
A=[1 1 1; 1 a^2 a; 1 a a^2];
Z_012 = diag(A_inv*impedance*A);
end
