% code to analyze the images of CoSnS sample (for imsubV3)
% M1=load('/Users/avianoah/Google Drive/University/Research/AHE/Data/Tip20200426/Batch30/Output_BW/Matrices/AHE3M02303.txt');
% M2=load('/Users/avianoah/Google Drive/University/Research/AHE/Data/Tip20200426/Batch30/Output_BW/Matrices/AHE3M02305.txt');


Folder_Data =['/Users/avianoah/Google Drive/University/Research/AHE/Data/',mon];

Folder_Matrices =  [Folder_Data,'/','Matrices'];

% filename = [day,'.',m,'.',year,'-','NanoisData'];
dir=Folder_Matrices;
%establish the list of files

%Sort the list by name
file_list = ls(strcat(dir,'/AHEAM0*.txt'))
file_list=split(file_list,'.txt')
file_list(end)=[]
file_list(1)=strcat('  ',file_list(1))
file_list=cell2mat(file_list(:,:))
[N_file,~]=size(file_list);

%setting the figure
newfig=figure();
clf
set(newfig,'Units','pixel')
set(newfig,'Position',[10 100 1000 350],'Color',[1 1 1]*0)
fontcolor=[0 0 0];
linewidth=1;
fontsize=10;

taille=300;
posfig1=[30 10 taille taille];
posfig2=[30+taille+30 10 taille taille];
posfig3=[30+(taille+30)*2 10 taille taille];

%setting the axes
fig1=axes('Parent',newfig,'ZColor',fontcolor,'YColor',fontcolor,...
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
box(fig1,'off');    
hold(fig1,'off');


fig2=axes('Parent',newfig,'ZColor',fontcolor,'YColor',fontcolor,...
        'XColor',fontcolor,...
        'LineWidth',linewidth,...
        'FontSize',fontsize,...   
        'Color','none',...
        'Units','Pixel',...
        'xticklabel',{''},...
        'yticklabel',{''},...
        'xtick',[],...
        'ytick',[],...
        'Position',posfig2);
box(fig2,'off');    
hold(fig2,'off');

fig3=axes('Parent',newfig,'ZColor',fontcolor,'YColor',fontcolor,...
        'XColor',fontcolor,...
        'LineWidth',linewidth,...
        'FontSize',fontsize,...   
        'Color','none',...
        'Units','Pixel',...
        'xticklabel',{''},...
        'yticklabel',{''},...
        'xtick',[],...
        'ytick',[],...
        'Position',posfig3);
box(fig3,'off');    
hold(fig3,'off');



load gold.mat
set(newfig,'colormap',[r g b])


%setting of the titles of the figures
fig1_title=annotation(newfig,'textbox','Units','pixel','position',[posfig1(1) posfig1(2)+posfig1(4)+10 posfig1(3) 20 ],'linestyle','none','fontsize',fontsize,'color',[1 1 0],'horizontalalignment','center');
fig2_title=annotation(newfig,'textbox','Units','pixel','position',[posfig2(1) posfig2(2)+posfig2(4)+10 posfig2(3) 20 ],'linestyle','none','fontsize',fontsize,'color',[1 1 0],'horizontalalignment','center');
fig3_title=annotation(newfig,'textbox','Units','pixel','position',[posfig3(1) posfig3(2)+posfig3(4)+10 posfig3(3) 20 ],'linestyle','none','fontsize',fontsize,'color',[1 1 0],'horizontalalignment','center');

for i=1:N_file-2
    
    %Loading the data
    M1=load(strcat(dir,'/',file_list(i,end-10:end),'.txt'));
    M2=load(strcat(dir,'/',file_list(i+1,end-10:end),'.txt'));
    
    %extracting the index of the files using regexp
    
%     %!! Will only work if the all the numbers in the file name are part of
%     %the index) !!!  
    [~,token]=regexp(file_list(i,:),'\d','tokens');
    M1_index=file_list(i,token(1):token(end));
    
    [~,token]=regexp(file_list(i+1,:),'\d','tokens');
    M2_index=file_list(i+1,token(1):token(end));
    


    %doing the image difference 
   [diffM,~]=ABdiff2(M1,M2);
   
   %ploting
   
   axes(fig1)
   surf(M1);view(2);shading interp;
   axis tight
   set(fig1,'xticklabel',{''},'yticklabel',{''})
   
   axes(fig2)
   surf(M2);view(2);shading interp;
   axis tight
   set(fig2,'xticklabel',{''},'yticklabel',{''})
   
   axes(fig3)
   surf(diffM);view(2);shading interp;
   axis tight
   set(fig3,'xticklabel',{''},'yticklabel',{''})
   
   
   %writing the figure titles
   
   
   % Set Titles
   set(fig1_title,'String',file_list(i,1:end-4));
   set(fig2_title,'String',file_list(i+1,1:end-4));
   set(fig3_title,'String',strcat('Image difference: ',file_list(i,1:end-4),' - ',file_list(i+1,1:end-4)))
   figure(112)
   
   set(newfig,'inverthardcopy','off')
  
   print(strcat(dir,'\diff_',M1_index,'-',M2_index,'.tif'),'-dtiff')
   save (strcat(dir,'\diff_',M1_index,'-',M2_index,'.txt'),'diffM','-ascii')
  
   pause(1)
   
 
end