% code to analyze the images of CoSnS sample (for imsubV3)

Field_Loc=find(strcmp(Info(1,:),'Field_Sweep [G]'));
Name_Loc=find(strcmp(Info(1,:),'Name'));
for k=1:14
    
    if k<10
        Bacth=['0',num2str(k)]
    else
        Bacth=num2str(k)
    end
    Folder_Diff=['C:\Users\Owner\Google Drive\4K microscope\data\AHE\Data\Apr\AviaSR\Bacth_',Bacth,'\Diff']
    if ~ exist(Folder_Diff,'dir')
                mkdir(Folder_Diff)
                mkdir([Folder_Diff,'\png'])
                mkdir([Folder_Diff,'\txt'])
    end
    dir=['C:\Users\Owner\Google Drive\4K microscope\data\AHE\Data\Apr\AviaSR\Bacth_',Bacth,'\Matrices'];
    %establish the list of files

    %Sort the list by name
    file_list = ls(strcat(dir,'/AHEAM0*.txt'));

    [N_file,~]=size(file_list);

    % Update the folder diraction
%     Info_Loc=fullfile('C:\Users\Owner\Google Drive\4K microscope\data\AHE\Data',sprintf(['Info','.dat']));  %Be awre
%     Info=readcell(Info_Loc);
    %setting the figure
    newfig=figure(112);
    clf
    set(newfig,'Units','pixel')
    set(newfig,'Position',[10 100 990 500],'Color',[1 1 1]*0)
    fontcolor=[0 0 0];
    linewidth=1;
    fontsize=10;

    taille=450;
    posfig1=[30 10 taille taille];
    posfig2=[30+taille+30 10 taille taille];

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


    load gold.mat
    set(newfig,'colormap',[r g b])


    %setting of the titles of the figures
    fig1_title=annotation(newfig,'textbox','Units','pixel','position',[posfig1(1) posfig1(2)+posfig1(4)+10 posfig1(3) 20 ],'linestyle','none','fontsize',fontsize,'color',[1 1 0],'horizontalalignment','center');
    fig2_title=annotation(newfig,'textbox','Units','pixel','position',[posfig2(1) posfig2(2)+posfig2(4)+10 posfig2(3) 20 ],'linestyle','none','fontsize',fontsize,'color',[1 1 0],'horizontalalignment','center');



    for i=1:N_file-1
            try
            %Loading the data
            M1=load(strcat(dir,'\',file_list(i,:)));
            M2=load(strcat(dir,'\',file_list(i+1,:)));

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
           surf(diffM);view(2);shading interp;
           axis tight
           set(fig2,'xticklabel',{''},'yticklabel',{''})


           %writing the figure titles
           % Avia add:

           % Put atentian to the file_list location
           Tit1=find(strcmp(Info(:,Name_Loc),file_list(i,end-13:end-4)));
           Tit2=find(strcmp(Info(:,Name_Loc),file_list(i+1,end-13:end-4)));
           Fil1=num2str(Info{Tit1,Field_Loc});
           Fil2=num2str(Info{Tit2,Field_Loc});

           set(fig1_title,'String',strcat('Field [G]:  ',Fil1));
           set(fig2_title,'String',strcat('Image difference: Field [G] ',Fil1,' - ',Fil2))
           figure(112)

           set(newfig,'inverthardcopy','off')

           print(strcat([Folder_Diff,'\png'],'\diff_',M1_index,'-',M2_index,'.png'),'-dpng')
           save (strcat(Folder_Diff,'\txt','\diff_',M1_index,'-',M2_index,'.txt'),'diffM','-ascii')

           pause(0.01)

        end
    end
end