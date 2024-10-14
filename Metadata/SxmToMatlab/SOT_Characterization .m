function SOT_Characterization(Initial_Field,Final_Field,Number_OF_Fields,Initial_I,Final_I,Number_OF_Is)    
  
    Magnet.Connect() ;   % ConnectMagnet

    if ~exist('d')
        d=DAC.Connect('COM10');
    end

    DAC.Set(d,0,0)
    DAC.Set(d,1,0)
    DAC.Set(d,2,5)
    
    Blink = 1;  % 1 if you want to Blink
    Output_ch=0; % SQUID output channel
    Input_ch=0;    % SQUID input channel
%     Input_ch_2=1;
    % Field: - For now work without control the field
%      Initial_Field=-200;   % In Gause
%      Final_Field=200; 
%      Number_OF_Fields=81;
     Fields=linspace(Initial_Field,Final_Field,Number_OF_Fields);

    %I2 - from 0 to ???V  for R bias
%      Initial_I=0.0;
%      Final_I=2;  %????
%      Number_OF_Is=200;    
    I1=linspace(Initial_I,Final_I,Number_OF_Is);
    
    IVs_UP=zeros(Number_OF_Fields,Number_OF_Is);
    IVs_Down=zeros(Number_OF_Fields,Number_OF_Is);

    % If you want to use another DAC channel

%     IVs_UP_2=zeros(Number_OF_Fields,Number_OF_Is);
%     IVs_Down_2=zeros(Number_OF_Fields,Number_OF_Is);
%     fileName2 = 'Channel 1';

    delay=1; %delay in us
    avg=10;
    
    fileName = 'Channel 0' ;

    [file_path,sweep_up_filename,sweep_down_filename]=Squid_Functions.Save_Data_Continuesly(Initial_I,Final_I,Number_OF_Is,Initial_Field,Final_Field,Number_OF_Fields,fileName) 
    %[file_path,sweep_up_filename2,sweep_down_filename2]=Squid_Functions.Save_Data_Continuesly(Initial_I,Final_I,Number_OF_Is,Initial_Field,Final_Field,Number_OF_Fields,fileName2) 

    %=========================================================================
    for i=1:length(Fields)
        Magnet.Control(Fields(i),0)

        voltages_Up = DAC.BufferRamp(d, Output_ch, Input_ch, Initial_I, Final_I, Number_OF_Is, delay,avg);
        voltages_Down = DAC.BufferRamp(d, Output_ch, Input_ch, Final_I, Initial_I, Number_OF_Is, delay,avg);
        IVs_UP(i,:)=voltages_Up;   
        IVs_Down(i,:)=voltages_Down;
        
        
        %  Save data on the go
        save([file_path,'\',sweep_up_filename,'.dat'],'voltages_Up','-append','-ascii')
        save([file_path,'\',sweep_down_filename,'.dat'],'voltages_Down','-append','-ascii')
        
        if Blink
            DAC.Set(d,2,0)
            pause(0.15)
            DAC.Set(d,2,5)
        end
        
        % Meusare the second channel
              
        % If you want to use another DAC channel
%         voltages_Up_2 = DAC.BufferRamp(d, Output_ch, Input_ch_2, Initial_I, Final_I, Number_OF_Is, delay,avg);
%         voltages_Down_2 = DAC.BufferRamp(d, Output_ch, Input_ch_2, Final_I, Initial_I, Number_OF_Is, delay,avg);         
%         save([file_path,'\',sweep_up_filename2,'.dat'],'voltages_Up_2','-append','-ascii')
%         save([file_path,'\',sweep_down_filename2,'.dat'],'voltages_Down_2','-append','-ascii')
%         IVs_UP_2(i,:)=voltages_Up_2;   
%         IVs_Down_2(i,:)=voltages_Down_2;
        
%         if Blink
%             DAC.Set(d,2,0)
%             pause(0.15)
%             DAC.Set(d,2,5)
%         end
%         
        
        
        % Plotting on the go
        
        % Plot as surf
        figure(3)
        subplot(2,1,1)
        [X,Y]=meshgrid(I1,Fields);
        surf(X,Y,IVs_UP)
        view(2)

        shading interp;
        colormap jet
        fsize = 20;
        colorbar EastOutside
        h=colorbar;
        xlabel('V_{bias} (V)');
        ylabel('Field (G)');
        grid off
        
        subplot(2,1,2)
        [X2,Y2]=meshgrid(flip(I1),Fields);
        surf(X2,Y2,IVs_Down)
        shading interp;
        colormap jet
        fsize = 20;
        view(2)
        colorbar EastOutside
        h=colorbar;
        xlabel('V_{bias} (V)');
        ylabel('Field (G)');

        
        % Plot as Ivs

        figure(1)
        if i==1
            hold off
        else
            hold on
        end
        plot(I1,voltages_Up)
        xlabel('V bias')
        ylabel('Vfb')
        title('Ivs Up')

        figure(2)
        if i==1
            hold off
        else
            hold on
        end
        
        plot(flip(I1),voltages_Down)
        xlabel('V bias')
        ylabel('Vfb')
        title('Ivs Down')
        

        percentage_of_run = round(100*i./Number_OF_Fields)

    end
    
    DAC.Set(d,0,0)
    DAC.Set(d,1,0)
    DAC.Set(d,2,5)
    
    Magnet.Control(0,1)
    %Magnet.Disconnect()

end



 

