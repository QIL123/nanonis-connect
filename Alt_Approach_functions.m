classdef Alt_Approach_functions
    %ALT_APPROACH_FUNCTIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    methods(Static)
    
        function get_noise(app)
            % Suppress an annoying warning
            warning('off','MATLAB:table:ModifiedAndSavedVarnames')
            app.Lamp.Color = 'green';
            app.disp_message('Noise Measurement Started')

            Nanonis.OutputOn();
            Nanonis.PllOn();
            Nanonis.Uti_RTOversamplSet(1)
            Nanonis.DataLog_Open()
            pause(0.2)
            Nanonis.DataLog_ChsSet(app.fshift_ch)
            pause(0.2)
            Nanonis.DataLog_PropsSet(app.BaseName, app.Acq_dur)
            Nanonis.DataLog_Start()
            pause(app.Acq_dur + 1)
            Nanonis.Uti_RTOversamplSet(10)

            % get and calculate noise satistics
            A = read_noise_data();
            app.sigma = std(A); app.mu = mean(A);
            B = A - ones(length(A),1)*app.mu;
            app.noise_max = max(abs(B));
            
            % Updating Fields
            app.STDmHzEditField.Value = round(app.sigma*1000);
            app.NoisemaxmHzEditField.Value = round(app.noise_max*1000);
            
            % Updating Threshold
            app.Threshold = app.sigma*app.sig_no; % Calculating
            app.ThresholdmHzEditField.Value = app.Threshold*1000; % Updating Field
            Nanonis.SafeTip_SetThreshold(app.Threshold) % Setting Threshold
            
            % Updating Average
            Nanonis.Set(app.mu_ch,app.mu)
            if app.sigma>25e-3
                app.disp_message('Noise Level is high, Try reducing LPF cut-off frequency')
            end
            
            app.disp_message('Noise Measurement Ended')
            app.Lamp.Color = 'white';
            
        end
        
       
        
     
        
        function poke(app)
            
            app.ZEncoderumEditField.Value = Nanonis.Get_Encoder_Z();
            app.Lamp_2.Color = 'yellow';
            app.disp_message('Poke Initiated')
            Nanonis.set_ZCtrl(app.Ctrl_index,app.PI_Const,app.tip_speed,app.retract)
            Nanonis.OutputOn();
            Nanonis.PllOn();           
            app.construct_mu() % Initial mu calculation
            

            pause(3);
            Nanonis.SafeTip_SetOnOff(1) % SafeTip On
            
            Nanonis.ZCtrl_SetOnOff(1) % Turning Z-Controller On
            app.disp_message('Z-Controller On')
            app.Lamp_2.Color = 'green';
            pause(0.1)
            
            % Main Loop
            
            while 1
                drawnow
                
                if app.Stop % Stop Button Pressed
                    Nanonis.ZCtrl_SetOnOff(0)
                    Nanonis.Set_Scanner_Z(Nanonis.Get_Scanner_Z - app.retract*10^-3)
                    
                    app.disp_message('Poke Stopped')
                    app.Stop = 0;
                    app.TouchPointumEditField.Value = 0;
                    break
                end
                
                if Nanonis.Get_Scanner_Z() >= app.scanner_limit % Scanner Limit Reached
                    Nanonis.ZCtrl_SetOnOff(0)
                    app.TouchPointumEditField.Value = 0;
                    
                    % The following if condition is for the different modes
                    
                    if app.ApproachModeCheckBox.Value % "Approach" mode
                        app.disp_message('Scanner Limit reached. Withdrawing Tip')
                        Nanonis.ZCtrl_Withdraw()
                        pause(1)
                        Nanonis.Motors_Move_Steps(app.nomotorstepsEditField.Value,'z+')
                        pause(1)
                        message = strcat('Z Motor Porpogated. Encoder Value: ', num2str(Nanonis.Get_Encoder_Z()));
                        app.disp_message(message)
                        
                        if app.BlinkCheckBox.Value % Blinking
                            DAC.Blink(app.blink_ch)
                            pause(1)
                            app.disp_message('Blink Performed')
                        end
                        
                        app.poke() % recursive
                        
                    else % "Poke" mode
                        app.disp_message('Scanner Limit reached. Retracting Tip')
                        Nanonis.Set_Scanner_Z(Nanonis.Get_Scanner_Z - app.retract*10^-3)
                    end
                    
                    break
                end
                
                if ~Nanonis.ZCtrl_GetOnOff() % ZCtrl is Off (Assuming SafeTip Triggered)
                    pause(0.2)
                    app.TouchPointumEditField.Value = double(Nanonis.Get_Scanner_Z()) + app.retract*10^-3; % in um;
                    app.disp_message(char(strcat('SafeTip Triggered, touch point=',string(app.TouchPointumEditField.Value))))
                    General.Beep();
                    break
                end
                app.update_mu() % Updating Average
                app.ZScannerumEditField.Value = round(double(Nanonis.Get_Scanner_Z()),3); % Field
                
            end
            
            app.ZScannerumEditField.Value = round(double(Nanonis.Get_Scanner_Z()),3);
            app.Lamp_2.Color = 'white';
            Nanonis.SafeTip_SetOnOff(2); %turn off safe tip

            
        end
        %--------------------------------
   function construct_mu(app)
            
            app.fshift = zeros(app.mu_avg,1);
            for i=1:app.mu_avg
                app.fshift(i) = Nanonis.Getfshift();
%                 app.fshift(i) = Nanonis.Get(18); %Test!
                pause(0.01)
            end
            app.mu = mean(app.fshift);
            Nanonis.Set(app.mu_ch,app.mu)
            
        end
        
        function update_mu(app)
            
            app.fshift = circshift(app.fshift,-3);
            for i=1:3
                app.fshift(end + i - 3) = Nanonis.Getfshift();
%                 app.fshift(end + i - 3) = Nanonis.Get(18); % For Test Only!
                pause(0.01)
            end
            app.mu = mean(app.fshift);
            Nanonis.Set(app.mu_ch,app.mu)
            
        end
            function A = read_noise_data()
            % Importing file and calculating
            k = ceil(0.8*app.Acq_dur); % File can only hold 25,000 points, so this calculation is for how many files are needed
            A = [];
            currentDate = date;
            for i=1:k
%                 file_name = strcat(app.Session_Folder, app.BaseName, "00",num2str(i),".dat");
                file_name = strcat(app.Session_Folder(1:end-11),currentDate(4:6),'\',...
                    currentDate(1:2),'\SXM\', app.BaseName, "00",num2str(i),".dat");

                ifA = [A; table2array(readtable(file_name))];
                delete(file_name)
            end
        end
        function disp_message(app,new_message)
            
            time_date = datestr(now);
            message = [time_date(end - 7:end),'   ',new_message];
            app.TextArea.Value = [message;app.TextArea.Value];
            
        end
    end
    end


