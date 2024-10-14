% code to analyze the images of Co3Sn2S2 sample (for imsubV3)

Folder_Data ='/Users/avianoah/Google Drive/University/Research/AHE/Data/Tip20200426/Batch44';
p = genpath(fullfile('/Users/avianoah/Google Drive/University/Research/AHE/Scripts','Diff'));
% Folder_Data='C:\Users\Owner\Google Drive\4K microscope\data\AHE\Data\Tip20200426\Batch44'


addpath (p)
Dir=[Folder_Data,'/Output_BW/Matrices'];

%establish the list of files

file_list = dir(Dir)

[N_file,~]=size(file_list);

% Update the folder diraction
Info_Loc=fullfile(Folder_Data,sprintf(['Batch_44','.dat']));  %Be awre
Info=readcell(Info_Loc);
Field_Loc=find(strcmp(Info(1,:),'Field_Sweep [G]'));
Name_Loc=find(strcmp(Info(1,:),'Name'));



% Save


Save_Loc=fullfile(fileparts(Dir),'Diff_Only');

if ~ exist(Save_Loc,'dir')
    mkdir(Save_Loc)
end
            

%%
for i=3:N_file-1
    

    % Plot only the diff image
    Scan_Range=[1,1];
    [r,g,b]=Analyze_Good.Get_Gold();
    newfig=figure;
    fontcolor='b';
    linewidth=1;
    fontsize=18;
    posfig1=[1 1 2^9 2^9];

    Fig=axes('Parent',newfig,'ZColor',fontcolor,'YColor',fontcolor,...
            'XColor',fontcolor,...
            'LineWidth',linewidth,...
            'FontSize',fontsize,...  
            'Color','none',...
            'Units','Pixel',...
            'xticklabel',{''},...
            'yticklabel',{''},...
            'xtick',[],...
            'ytick',[],...
            'Position',posfig1);

    box(Fig,'on');    
    hold(Fig,'all');    


    %Loading the data
    M1=load(fullfile(Dir,file_list(i).name));
    M2=load(fullfile(Dir,file_list(i+1).name));
    
    %doing the image difference 
   [diffM,~]=ABdiff2(M1,M2);
   
   %ploting
    Data_Size=size(diffM);
    X0=linspace(0,Scan_Range(1)*10^6,Data_Size(1));
    Y0=linspace(0,Scan_Range(2)*10^6,Data_Size(2));
    [X,Y]=meshgrid(X0,Y0);

    surf(X,Y,diffM./1e9);
    view(2);
    shading interp;
    set(gcf,'position',posfig1)
    set(gcf,'colormap',[r g b])
    saveas(Fig,fullfile(Save_Loc,[file_list(i).name(end-7:end-4),'-',file_list(i+1).name(end-7:end-4) ]), 'jpg');   
   pause(0.01)
end