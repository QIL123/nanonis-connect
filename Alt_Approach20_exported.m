classdef Alt_Approach20_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        IterationscompletedEditField   matlab.ui.control.NumericEditField
        IterationscompletedEditFieldLabel  matlab.ui.control.Label
        ApproachSettingsPanel          matlab.ui.container.Panel
        MaxIterationsSpinner           matlab.ui.control.Spinner
        MaxIterationsSpinnerLabel      matlab.ui.control.Label
        TipSpeednmsSpinnerLabel_2      matlab.ui.control.Label
        Zs_PauseStep_Text              matlab.ui.control.Label
        Zenc_PauseStep_Box             matlab.ui.control.EditField
        Zencoded_Max_Box               matlab.ui.control.EditField
        ApproachModeCheckBox           matlab.ui.control.CheckBox
        nomotorstepsEditField          matlab.ui.control.NumericEditField
        nomotorstepsEditFieldLabel     matlab.ui.control.Label
        ZEncoderumEditField            matlab.ui.control.NumericEditField
        ZEncoderumEditFieldLabel       matlab.ui.control.Label
        ControlPanel                   matlab.ui.container.Panel
        WithdrawButton                 matlab.ui.control.Button
        ZScannerumEditField            matlab.ui.control.NumericEditField
        ZScannerumEditFieldLabel       matlab.ui.control.Label
        ContinueButton                 matlab.ui.control.Button
        Lamp_2                         matlab.ui.control.Lamp
        PokeButton                     matlab.ui.control.Button
        BlinkButton                    matlab.ui.control.Button
        PokeSettingsPanel              matlab.ui.container.Panel
        ZScannerlimitumEditField       matlab.ui.control.NumericEditField
        ZScannerlimitumEditFieldLabel  matlab.ui.control.Label
        TouchPointumEditField          matlab.ui.control.NumericEditField
        TouchPointumEditFieldLabel     matlab.ui.control.Label
        ThresholdmHzEditField          matlab.ui.control.NumericEditField
        ThresholdmHzEditFieldLabel     matlab.ui.control.Label
        AvgSpinner                     matlab.ui.control.Spinner
        AvgSpinnerLabel                matlab.ui.control.Label
        UpdateThresholdButton          matlab.ui.control.Button
        RetractnmSpinner               matlab.ui.control.Spinner
        RetractnmSpinnerLabel          matlab.ui.control.Label
        sig_noSpinner                  matlab.ui.control.Spinner
        sig_noSpinnerLabel             matlab.ui.control.Label
        TipSpeednmsSpinner             matlab.ui.control.Spinner
        TipSpeednmsSpinnerLabel        matlab.ui.control.Label
        NoisePanel                     matlab.ui.container.Panel
        Lamp                           matlab.ui.control.Lamp
        NoisemaxmHzEditField           matlab.ui.control.NumericEditField
        NoisemaxmHzEditFieldLabel      matlab.ui.control.Label
        STDmHzEditField                matlab.ui.control.NumericEditField
        STDmHzEditFieldLabel           matlab.ui.control.Label
        GetNoiseButton                 matlab.ui.control.Button
        TextArea                       matlab.ui.control.TextArea
    end

    
    properties (Access = public)
        Ctrl_index = 10;
        %fshift_ch_index = 34; % Fshift Index in the Data Logger module
        fshift_ch = 76;%24; % Channel Index in the Data Logger module (Test!)
        mu_ch = 3; % Channel Index that holds the average (Output 3)
        blink_ch = 2; % Channel Index for DAC
        
        Acq_dur = 5; BaseName = "noise";
        
        % find a better directory to log the noise! so it will be automatic
        
        Session_Folder = [Nanonis.Get_Session_Folder(),'\']; 
    
        sigma; mu; noise_max; Threshold; Z_Pos; Stop = 0; fshift;
        high_noise_threshold =25e-3;
        retract = 200; tip_speed = 10; scanner_limit = 22; sig_no = 6; mu_avg = 200;
        PI_Const = 10^-6;
        Time_const = 10^-6;
        false_poke_distance = 40e-3;
        MaxIterations = inf;
        max_extension = 0;
        extention_pause= 5;
        poke_end_command = "retract";
        continue_flag = false;
        log_name = 'approach_log.txt';
        %----

        currentDate = date; 
        
    end
    

    methods (Access = public)
        
        function disp_message(app,new_message)
            
            time_date = datestr(now);
            message = [time_date(end - 7:end),'   ',new_message];
            app.TextArea.Value = [message;app.TextArea.Value];
            
        end
        
        function get_noise(app)
            % Suppress an annoying warning
            warning('off','MATLAB:table:ModifiedAndSavedVarnames')
            
            Nanonis.OutputOn();
            Nanonis.PllOn();
            app.Lamp.Color = 'green';
            
            Nanonis.Uti_RTOversamplSet(1)
            
            app.disp_message('Noise Measurement Started')
            
            Nanonis.DataLog_Open()
            pause(0.2)
            Nanonis.DataLog_ChsSet(app.fshift_ch)
            pause(0.2)
            Nanonis.DataLog_PropsSet(app.BaseName, app.Acq_dur)
            pause(0.2)
            Nanonis.DataLog_Start()
            pause(app.Acq_dur + 1)
            Nanonis.Uti_RTOversamplSet(10)
            
            % Importing file and calculating
            k = ceil(0.8*app.Acq_dur); % File can only hold 25,000 points, so this calculation is for how many files are needed
            A = [];
            
            for i=1:k
%                 file_name = strcat(app.Session_Folder, app.BaseName, "00",num2str(i),".dat");
                file_name = strcat(app.Session_Folder(1:end-17),'\',app.currentDate(end-3:end),'\',app.currentDate(4:6),'\',...
                    app.currentDate(1:2),'\SXM\', app.BaseName, "0000",num2str(i),".dat");

                A = [A; table2array(readtable(file_name))];
                delete(file_name)
            end
            
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
            if app.sigma>app.high_noise_threshold
                app.disp_message('Noise Level is high, Try reducing LPF cut-off frequency')
            end
            pause(6) % pause after noise measurments for signal to stabalize 3 seconds may be too large
            app.disp_message('Noise Measurement Ended')
            app.Lamp.Color = 'white';
            
        end
        
        function set_ZCtrl(app)
            
            Nanonis.ZCtrl_SetCtrl(app.Ctrl_index) % Choosing specific controller
            Nanonis.ZCtrl_SetOnOff(0) % Making sure controller is off
            if ~app.continue_flag
            Nanonis.ZCtrl_SetPoint(0.2)%Nanonis.ZCtrl_SetPoint(app.PI_Const) % Sets Setpoint 
            end
            % (should be same value as time constant and very small, as it may cause a jump at the start of the approach)
            Nanonis.ZCtrl_SetGain(app.tip_speed*10^-16, app.Time_const, 0) % Tip Speed and time constant (same as setpoint)
            Nanonis.SafeTip_SetOnOff(2) % Turning SafeTip Off
            Nanonis.ZCtrl_SetHome(app.retract*10^-9) % Setting home relative and retract amount
            
        end
        
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



        function poke_stop_code = single_poke(app)
            %function that does a single poke operation 
            poke_stop_code = -1;
            % until stop or scanner_limit
            while ~(app.Stop || Nanonis.Get_Scanner_Z() >= app.scanner_limit)
                drawnow    
                
                if ~Nanonis.ZCtrl_GetOnOff() % ZCtrl is Off (Assuming SafeTip Triggered)
                    %upposed to retract
                    pause(0.2)
                    app.TouchPointumEditField.Value = double(Nanonis.Get_Scanner_Z()) + app.retract*10^-3; % in um;
                    app.disp_message(char(strcat('SafeTip Triggered, touch point=',string(app.TouchPointumEditField.Value))))     
                    poke_stop_code = 1;
                    General.Beep();
                    return
                end
%                 if app.ZScannerumEditField.Value > 0.2
%                      Nanonis.ZCtrl_SetOnOff(0) % Turning Z-Controller off
%                      pause(0.5)
%                      Nanonis.SafeTip_SetOnOff(1) % start safetip
%                      Nanonis.ZCtrl_SetOnOff(1) % Turning Z-Controller On
%                 end
                app.update_mu() % Updating Average
                app.ZScannerumEditField.Value = round(double(Nanonis.Get_Scanner_Z()),3); % Field
               
                
            end
            if app.Stop % Stop Button Pressed
                    Nanonis.ZCtrl_SetOnOff(0)
                    Nanonis.Set_Scanner_Z(Nanonis.Get_Scanner_Z - app.retract*10^-3)
                    try
                        DAC.Blink(app.blink_ch)
                    catch
                        warning('no DAC')
                    end
                    
                    app.disp_message('Poke Stopped')
                    app.Stop = 0;
                    app.TouchPointumEditField.Value = 0;
                    return
   
            end
            

            if Nanonis.Get_Scanner_Z() >= app.scanner_limit
                Nanonis.ZCtrl_SetOnOff(0)
                app.TouchPointumEditField.Value = 0;
                if app.poke_end_command == "retract"
                    app.disp_message('Scanner Limit reached. Retracting Tip')
                    Nanonis.Set_Scanner_Z(Nanonis.Get_Scanner_Z - app.retract*10^-3)
                else 
                    if app.poke_end_command == "withdraw"
                    app.disp_message('Scanner Limit reached. Withdrawing Tip')
                    Nanonis.ZCtrl_Withdraw()
                    app.ZEncoderumEditField.Value = round(double(Nanonis.Get_Encoder_Z()),3);
                    pause(1)
                    end
                end
                poke_stop_code =0;
            end
            return
            

        end
        function multi_poke(app)
             % 1-safetip, 0-limit, -1-stop
             num = num2str(app.MaxIterations);
             app.disp_message(['Max iterations ' num])
             app.disp_message('Poke Initiated')
             poke_result = app.single_poke();
             if poke_result == -1
                 return
             end
                
             pause(0.5) % may not be needed? for stabalizing noise...
             app.get_noise();
             iteration_count = app.IterationscompletedEditField.Value;
             
             while  poke_result ~= -1 
                     
                    
         
                    % fully extended, withdraw and start again
                    if poke_result == 0
                         if Nanonis.Get_Encoder_Z()<app.max_extension
                                Nanonis.Motors_Move_Steps(app.nomotorstepsEditField.Value,'z+');
                                pause(app.extention_pause)
                                message = strcat('Z Motor Porpogated. Encoder Value: ', num2str(round(double(Nanonis.Get_Encoder_Z()),3)));
                                app.disp_message(message)
                                
                                
                                try
                                    DAC.Blink(app.blink_ch)
                                catch
                                    warning('no DAC')
                                end
                                app.ZEncoderumEditField.Value = round(double(Nanonis.Get_Encoder_Z()),3);
                                iteration_count = iteration_count + 1;
                                app.IterationscompletedEditField.Value = iteration_count;
                                if iteration_count > app.MaxIterations
                                    app.disp_message('Max iterations reached. Stopping approach')
                                    break 
                                end
                         else
                             app.disp_message('Max extension reached. Stopping approach')
                             break
                         end
                  
                        
%                          if app.BlinkCheckBox.Value % Blinking
%                             DAC.Blink(app.blink_ch)
%                             pause(1)
%                             app.disp_message('Blink Performed')
%                          end
                         %add
                         
                         % this is important  
                         pause(0.5) % may not be needed?
                         app.get_noise();
                         app.initate_safetip();
                    end
                    % safetip triggered, do false trigger check
                    if poke_result == 1
                        %does safetp auto retract cause issue with false
                        %positive check?
                        pause(0.5)
                        app.get_noise(); % recalculate noise
                        %check new noise high/low
                        if app.sigma>app.high_noise_threshold
                            %noise high, withdraw and stop
                            Nanonis.ZCtrl_SetOnOff(0)
                            app.TouchPointumEditField.Value = 0;
                            app.disp_message('Noise Level high. Withdrawing Tip')
                            Nanonis.ZCtrl_Withdraw()
                            break
                        else
                            %noise low, do single poke to check
                            z_value1 = app.TouchPointumEditField.Value;                          
                            Nanonis.ZCtrl_SetOnOff(1)
                            poke_result = app.single_poke();
                            pause(0.5) % may not be needed?
                            app.get_noise();
                            z_value2  = app.TouchPointumEditField.Value;
                            % if the difference is leq than 40 um then
                            if abs(z_value2-z_value1) <= app.false_poke_distance || poke_result == -1
                                app.disp_message('Approach End');
                                
                                if app.retract < 1000
                                        Nanonis.Set_Scanner_Z(Nanonis.Get_Scanner_Z - (1-app.retract*10^-3))
                                end
                                if poke_result ~= 1
                                    Nanonis.ZCtrl_SetOnOff(0)
                                    app.TouchPointumEditField.Value = 0;                                    
                                end
                               
                                break
                            else
                                app.disp_message(strcat('False positive, distance: ',num2str(abs(z_value2-z_value1))))
                                continue
                            end
                        end
                    end
                    poke_result = app.single_poke();
                    
             end
           
        end
        function initate_safetip(app)
            %function to initate safetip and z controller before poke
                app.ZEncoderumEditField.Value = round(double(Nanonis.Get_Encoder_Z()),3);
                
                app.set_ZCtrl() % Reseting Z-Controller
               
                app.construct_mu() % Initial mu calculation
                pause(3);
               
                Nanonis.SafeTip_SetOnOff(1) % SafeTip On
                
                Nanonis.ZCtrl_SetOnOff(1) % Turning Z-Controller On
                
                
            end
        function poke(app)
            if app.ApproachModeCheckBox.Value && app.max_extension == 0  
                warndlg('Need to define max Z-Encoder extension for approach','Warning');
                return
            end
            app.Lamp_2.Color = 'yellow';
            app.disp_message('Poke Initiated')
            
            Nanonis.OutputOn();
            Nanonis.PllOn();
            pause(2) % pause after turning Pll on as it causes spike in noise (maybe less than 2 is ok)

            
            app.initate_safetip()
            app.disp_message('Z-Controller On')
            app.Lamp_2.Color = 'green';
            pause(0.1)

            if app.ApproachModeCheckBox.Value % "Approach" mode 
               app.multi_poke();
            else
                
                app.single_poke();
            end
            app.save_log()
            app.ZScannerumEditField.Value = round(double(Nanonis.Get_Scanner_Z()),3);
            app.Lamp_2.Color = 'white';
            app.ContinueButton.Text = 'Continue';
            Nanonis.SafeTip_SetOnOff(2); %turn off safe tip
            
            
        end
        function save_log(app)
              % Assuming 'app.TextArea' is the name of your text area component
             text_content = app.TextArea.Value; 
             % Open a file for writing (replace 'filename.txt' with your desired name)
             filename = strcat(app.Session_Folder, app.log_name);
             
             old_data = nan;
             if exist(filename,'file')
                 % need to handle when the file is just one row!!
                old_data = readcell(filename);
                mask = cellfun(@(x) any(isa(x,'missing')), old_data);
                old_data(mask) = {' '}; % 
             end
             fid = fopen(filename, 'w'); 
             % Write the text content to the file
             fprintf(fid,'%s\n',text_content{:});
             
             if iscell(old_data)
             fprintf(fid,'%s\n',old_data{:});
             end
             % Close the file
             fclose(fid);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            expected_folder =strcat(app.Session_Folder(1:end-13),'\',app.currentDate(end-3:end),'\',app.currentDate(4:6),'\',...
                    app.currentDate(1:2),'\SXM\');
            if ~strcmp(expected_folder,app.Session_Folder) 
                selection = uiconfirm(app.UIFigure, 'Nanonis session folder not to current date. change session folder?', 'Warning','Icon','warning',...
                    'Options',{'Yes','No'});
                if strcmp(selection,'Yes')
                    Nanonis.Set_Session_Folder(expected_folder);
                end
            end
            app.TextArea.Value = 'Welcome to the new Approach app. Hope you like it!';
            % Deleting Files
            k = ceil(0.8*app.Acq_dur);
            for i=1:k
                file_name = strcat(app.Session_Folder, app.BaseName, "0000",num2str(i),".dat");
                if isfile(file_name)
                    delete(file_name)
                end
            end
            % Z-Encoder
            
             app.ZEncoderumEditField.Value = round(double(Nanonis.Get_Encoder_Z()),3);
             app.ZScannerlimitumEditField.Value = app.scanner_limit;
        end

        % Value changed function: TipSpeednmsSpinner
        function TipSpeednmsSpinnerValueChanged(app, event)
            app.tip_speed = app.TipSpeednmsSpinner.Value;
            Nanonis.ZCtrl_SetGain(app.tip_speed*10^-16, app.Time_const, 0)
        end

        % Value changed function: RetractnmSpinner
        function RetractnmSpinnerValueChanged(app, event)
            app.retract = app.RetractnmSpinner.Value;
            Nanonis.ZCtrl_SetHome(app.retract*10^-9)
        end

        % Button pushed function: GetNoiseButton
        function GetNoiseButtonPushed(app, event)
            app.get_noise()
        end

        % Button pushed function: PokeButton
        function PokeButtonPushed(app, event)
            app.ContinueButton.Text = 'Stop';
            app.IterationscompletedEditField.Value =0;
            Nanonis.ZCtrl_Withdraw()
            app.ZScannerumEditField.Value = round(double(Nanonis.Get_Scanner_Z()),3);
            app.poke()
            Nanonis.PllOff();
            Nanonis.OutputOff();
        end

        % Button pushed function: UpdateThresholdButton
        function UpdateThresholdButtonPushed(app, event)
            app.Threshold = app.sigma*app.sig_no; % Calculating Threshold
            app.ThresholdmHzEditField.Value = app.Threshold*1000; % Update Field
            Nanonis.SafeTip_SetThreshold(app.Threshold) % Setting Threshold
        end

        % Value changed function: sig_noSpinner
        function sig_noSpinnerValueChanged(app, event)
            app.sig_no = app.sig_noSpinner.Value;
        end

        % Button pushed function: ContinueButton
        function ContinueButtonPushed(app, event)
            if app.ContinueButton.Text == "Stop"
                app.Stop = 1;
            else
                app.ContinueButton.Text = 'Stop';
                app.poke()
                Nanonis.PllOff();
                Nanonis.OutputOff();
            end
        end

        % Value changed function: AvgSpinner
        function AvgSpinnerValueChanged(app, event)
            app.mu_avg = app.AvgSpinner.Value;
        end

        % Button pushed function: BlinkButton
        function BlinkButtonPushed(app, event)
            DAC.Blink(app.blink_ch);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.set_ZCtrl()
            Nanonis.SafeTip_SetOnOff(2)
            app.save_log()
            delete(app)
            
        end

        % Value changed function: ApproachModeCheckBox
        function ApproachModeCheckBoxValueChanged(app, event)
            value = app.ApproachModeCheckBox.Value;
            if value
                app.poke_end_command = "withdraw";
                app.PokeButton.Text = 'Approach';
            else
                app.poke_end_command = "retract";
                app.PokeButton.Text = 'Poke';
            end
        end

        % Value changed function: ZScannerlimitumEditField
        function ZScannerlimitumEditFieldValueChanged(app, event)
            app.scanner_limit = app.ZScannerlimitumEditField.Value;
            
        end

        % Value changed function: Zencoded_Max_Box
        function Zencoded_Max_BoxValueChanged(app, event)
            app.max_extension = str2num(app.Zencoded_Max_Box.Value);
           
        end

        % Value changed function: Zenc_PauseStep_Box
        function Zenc_PauseStep_BoxValueChanged(app, event)
            app.extention_pause = app.Zenc_PauseStep_Box.Value;
            
        end

        % Value changed function: MaxIterationsSpinner
        function MaxIterationsSpinnerValueChanged(app, event)
            app.MaxIterations = app.MaxIterationsSpinner.Value;
            
        end

        % Callback function
        function continuefromlastpositionSwitchValueChanged(app, event)
            app.continue_flag = app.continuefromlastpositionSwitch.Value;
            
        end

        % Button pushed function: WithdrawButton
        function WithdrawButtonPushed(app, event)
            Nanonis.ZCtrl_Withdraw()
            app.ZScannerumEditField.Value = round(double(Nanonis.Get_Scanner_Z()),3);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 693 591];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Position = [289 220 407 372];

            % Create NoisePanel
            app.NoisePanel = uipanel(app.UIFigure);
            app.NoisePanel.TitlePosition = 'centertop';
            app.NoisePanel.Title = 'Noise';
            app.NoisePanel.FontSize = 24;
            app.NoisePanel.Position = [1 277 289 140];

            % Create GetNoiseButton
            app.GetNoiseButton = uibutton(app.NoisePanel, 'push');
            app.GetNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @GetNoiseButtonPushed, true);
            app.GetNoiseButton.FontSize = 20;
            app.GetNoiseButton.FontWeight = 'bold';
            app.GetNoiseButton.Position = [71 2 116 34];
            app.GetNoiseButton.Text = 'Get Noise';

            % Create STDmHzEditFieldLabel
            app.STDmHzEditFieldLabel = uilabel(app.NoisePanel);
            app.STDmHzEditFieldLabel.HorizontalAlignment = 'right';
            app.STDmHzEditFieldLabel.FontSize = 18;
            app.STDmHzEditFieldLabel.Position = [51 74 95 22];
            app.STDmHzEditFieldLabel.Text = 'STD (mHz)';

            % Create STDmHzEditField
            app.STDmHzEditField = uieditfield(app.NoisePanel, 'numeric');
            app.STDmHzEditField.FontSize = 18;
            app.STDmHzEditField.Position = [180 73 50 23];

            % Create NoisemaxmHzEditFieldLabel
            app.NoisemaxmHzEditFieldLabel = uilabel(app.NoisePanel);
            app.NoisemaxmHzEditFieldLabel.HorizontalAlignment = 'right';
            app.NoisemaxmHzEditFieldLabel.FontSize = 18;
            app.NoisemaxmHzEditFieldLabel.Position = [31 44 145 22];
            app.NoisemaxmHzEditFieldLabel.Text = 'Noise max (mHz)';

            % Create NoisemaxmHzEditField
            app.NoisemaxmHzEditField = uieditfield(app.NoisePanel, 'numeric');
            app.NoisemaxmHzEditField.FontSize = 18;
            app.NoisemaxmHzEditField.Position = [181 43 49 23];

            % Create Lamp
            app.Lamp = uilamp(app.NoisePanel);
            app.Lamp.Position = [191 7 26 26];
            app.Lamp.Color = [0.9412 0.9412 0.9412];

            % Create PokeSettingsPanel
            app.PokeSettingsPanel = uipanel(app.UIFigure);
            app.PokeSettingsPanel.TitlePosition = 'centertop';
            app.PokeSettingsPanel.Title = 'Poke Settings';
            app.PokeSettingsPanel.FontSize = 24;
            app.PokeSettingsPanel.Position = [1 -2 289 280];

            % Create TipSpeednmsSpinnerLabel
            app.TipSpeednmsSpinnerLabel = uilabel(app.PokeSettingsPanel);
            app.TipSpeednmsSpinnerLabel.HorizontalAlignment = 'right';
            app.TipSpeednmsSpinnerLabel.FontSize = 20;
            app.TipSpeednmsSpinnerLabel.Position = [1 222 158 24];
            app.TipSpeednmsSpinnerLabel.Text = 'Tip Speed (nm/s)';

            % Create TipSpeednmsSpinner
            app.TipSpeednmsSpinner = uispinner(app.PokeSettingsPanel);
            app.TipSpeednmsSpinner.Step = 5;
            app.TipSpeednmsSpinner.Limits = [5 200];
            app.TipSpeednmsSpinner.ValueChangedFcn = createCallbackFcn(app, @TipSpeednmsSpinnerValueChanged, true);
            app.TipSpeednmsSpinner.FontSize = 20;
            app.TipSpeednmsSpinner.Position = [174 221 64 25];
            app.TipSpeednmsSpinner.Value = 10;

            % Create sig_noSpinnerLabel
            app.sig_noSpinnerLabel = uilabel(app.PokeSettingsPanel);
            app.sig_noSpinnerLabel.HorizontalAlignment = 'right';
            app.sig_noSpinnerLabel.FontSize = 20;
            app.sig_noSpinnerLabel.Position = [1 145 64 24];
            app.sig_noSpinnerLabel.Text = 'sig_no';

            % Create sig_noSpinner
            app.sig_noSpinner = uispinner(app.PokeSettingsPanel);
            app.sig_noSpinner.ValueChangedFcn = createCallbackFcn(app, @sig_noSpinnerValueChanged, true);
            app.sig_noSpinner.FontSize = 20;
            app.sig_noSpinner.Position = [67 144 51 25];
            app.sig_noSpinner.Value = 6;

            % Create RetractnmSpinnerLabel
            app.RetractnmSpinnerLabel = uilabel(app.PokeSettingsPanel);
            app.RetractnmSpinnerLabel.HorizontalAlignment = 'right';
            app.RetractnmSpinnerLabel.FontSize = 20;
            app.RetractnmSpinnerLabel.Position = [1 184 117 24];
            app.RetractnmSpinnerLabel.Text = 'Retract (nm)';

            % Create RetractnmSpinner
            app.RetractnmSpinner = uispinner(app.PokeSettingsPanel);
            app.RetractnmSpinner.Step = 50;
            app.RetractnmSpinner.Limits = [0 1000];
            app.RetractnmSpinner.ValueChangedFcn = createCallbackFcn(app, @RetractnmSpinnerValueChanged, true);
            app.RetractnmSpinner.FontSize = 20;
            app.RetractnmSpinner.Position = [174 183 64 25];
            app.RetractnmSpinner.Value = 200;

            % Create UpdateThresholdButton
            app.UpdateThresholdButton = uibutton(app.PokeSettingsPanel, 'push');
            app.UpdateThresholdButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateThresholdButtonPushed, true);
            app.UpdateThresholdButton.FontSize = 18;
            app.UpdateThresholdButton.FontWeight = 'bold';
            app.UpdateThresholdButton.Position = [41 47 169 29];
            app.UpdateThresholdButton.Text = 'Update Threshold';

            % Create AvgSpinnerLabel
            app.AvgSpinnerLabel = uilabel(app.PokeSettingsPanel);
            app.AvgSpinnerLabel.HorizontalAlignment = 'right';
            app.AvgSpinnerLabel.FontSize = 20;
            app.AvgSpinnerLabel.Position = [128 145 40 24];
            app.AvgSpinnerLabel.Text = 'Avg';

            % Create AvgSpinner
            app.AvgSpinner = uispinner(app.PokeSettingsPanel);
            app.AvgSpinner.Step = 50;
            app.AvgSpinner.Limits = [50 500];
            app.AvgSpinner.ValueChangedFcn = createCallbackFcn(app, @AvgSpinnerValueChanged, true);
            app.AvgSpinner.FontSize = 20;
            app.AvgSpinner.Position = [174 144 73 25];
            app.AvgSpinner.Value = 200;

            % Create ThresholdmHzEditFieldLabel
            app.ThresholdmHzEditFieldLabel = uilabel(app.PokeSettingsPanel);
            app.ThresholdmHzEditFieldLabel.HorizontalAlignment = 'right';
            app.ThresholdmHzEditFieldLabel.FontSize = 18;
            app.ThresholdmHzEditFieldLabel.Position = [21 84 140 22];
            app.ThresholdmHzEditFieldLabel.Text = 'Threshold (mHz)';

            % Create ThresholdmHzEditField
            app.ThresholdmHzEditField = uieditfield(app.PokeSettingsPanel, 'numeric');
            app.ThresholdmHzEditField.FontSize = 18;
            app.ThresholdmHzEditField.Position = [172 83 58 23];

            % Create TouchPointumEditFieldLabel
            app.TouchPointumEditFieldLabel = uilabel(app.PokeSettingsPanel);
            app.TouchPointumEditFieldLabel.HorizontalAlignment = 'right';
            app.TouchPointumEditFieldLabel.FontSize = 18;
            app.TouchPointumEditFieldLabel.Position = [20 8 142 22];
            app.TouchPointumEditFieldLabel.Text = 'Touch Point (um)';

            % Create TouchPointumEditField
            app.TouchPointumEditField = uieditfield(app.PokeSettingsPanel, 'numeric');
            app.TouchPointumEditField.ValueDisplayFormat = '%.3f';
            app.TouchPointumEditField.FontSize = 18;
            app.TouchPointumEditField.Position = [173 7 66 23];

            % Create ZScannerlimitumEditFieldLabel
            app.ZScannerlimitumEditFieldLabel = uilabel(app.PokeSettingsPanel);
            app.ZScannerlimitumEditFieldLabel.HorizontalAlignment = 'right';
            app.ZScannerlimitumEditFieldLabel.FontSize = 18;
            app.ZScannerlimitumEditFieldLabel.Position = [21 114 164 22];
            app.ZScannerlimitumEditFieldLabel.Text = 'Z-Scanner limit(um)';

            % Create ZScannerlimitumEditField
            app.ZScannerlimitumEditField = uieditfield(app.PokeSettingsPanel, 'numeric');
            app.ZScannerlimitumEditField.ValueDisplayFormat = '%.3f';
            app.ZScannerlimitumEditField.ValueChangedFcn = createCallbackFcn(app, @ZScannerlimitumEditFieldValueChanged, true);
            app.ZScannerlimitumEditField.FontSize = 18;
            app.ZScannerlimitumEditField.Position = [190 113 70 23];

            % Create ControlPanel
            app.ControlPanel = uipanel(app.UIFigure);
            app.ControlPanel.TitlePosition = 'centertop';
            app.ControlPanel.Title = 'Control';
            app.ControlPanel.FontSize = 24;
            app.ControlPanel.Position = [0 416 290 176];

            % Create BlinkButton
            app.BlinkButton = uibutton(app.ControlPanel, 'push');
            app.BlinkButton.ButtonPushedFcn = createCallbackFcn(app, @BlinkButtonPushed, true);
            app.BlinkButton.FontSize = 20;
            app.BlinkButton.FontWeight = 'bold';
            app.BlinkButton.Position = [181 100 100 32];
            app.BlinkButton.Text = 'Blink';

            % Create PokeButton
            app.PokeButton = uibutton(app.ControlPanel, 'push');
            app.PokeButton.ButtonPushedFcn = createCallbackFcn(app, @PokeButtonPushed, true);
            app.PokeButton.FontSize = 20;
            app.PokeButton.FontWeight = 'bold';
            app.PokeButton.Position = [18 101 100 31];
            app.PokeButton.Text = 'Poke';

            % Create Lamp_2
            app.Lamp_2 = uilamp(app.ControlPanel);
            app.Lamp_2.Position = [131 103 29 29];
            app.Lamp_2.Color = [0.9412 0.9412 0.9412];

            % Create ContinueButton
            app.ContinueButton = uibutton(app.ControlPanel, 'push');
            app.ContinueButton.ButtonPushedFcn = createCallbackFcn(app, @ContinueButtonPushed, true);
            app.ContinueButton.FontSize = 20;
            app.ContinueButton.FontWeight = 'bold';
            app.ContinueButton.Position = [18 49 102 33];
            app.ContinueButton.Text = 'Continue';

            % Create ZScannerumEditFieldLabel
            app.ZScannerumEditFieldLabel = uilabel(app.ControlPanel);
            app.ZScannerumEditFieldLabel.HorizontalAlignment = 'right';
            app.ZScannerumEditFieldLabel.FontSize = 18;
            app.ZScannerumEditFieldLabel.Position = [53 3 127 22];
            app.ZScannerumEditFieldLabel.Text = 'Z-Scanner(um)';

            % Create ZScannerumEditField
            app.ZScannerumEditField = uieditfield(app.ControlPanel, 'numeric');
            app.ZScannerumEditField.ValueDisplayFormat = '%.3f';
            app.ZScannerumEditField.FontSize = 18;
            app.ZScannerumEditField.Position = [185 2 70 23];

            % Create WithdrawButton
            app.WithdrawButton = uibutton(app.ControlPanel, 'push');
            app.WithdrawButton.ButtonPushedFcn = createCallbackFcn(app, @WithdrawButtonPushed, true);
            app.WithdrawButton.FontSize = 20;
            app.WithdrawButton.FontWeight = 'bold';
            app.WithdrawButton.Position = [178 49 105 33];
            app.WithdrawButton.Text = 'Withdraw';

            % Create ApproachSettingsPanel
            app.ApproachSettingsPanel = uipanel(app.UIFigure);
            app.ApproachSettingsPanel.TitlePosition = 'centertop';
            app.ApproachSettingsPanel.Title = 'Approach Settings';
            app.ApproachSettingsPanel.FontSize = 24;
            app.ApproachSettingsPanel.Position = [289 1 407 184];

            % Create ZEncoderumEditFieldLabel
            app.ZEncoderumEditFieldLabel = uilabel(app.ApproachSettingsPanel);
            app.ZEncoderumEditFieldLabel.HorizontalAlignment = 'right';
            app.ZEncoderumEditFieldLabel.FontSize = 16;
            app.ZEncoderumEditFieldLabel.FontWeight = 'bold';
            app.ZEncoderumEditFieldLabel.Position = [8 5 124 22];
            app.ZEncoderumEditFieldLabel.Text = 'Z-Encoder (um)';

            % Create ZEncoderumEditField
            app.ZEncoderumEditField = uieditfield(app.ApproachSettingsPanel, 'numeric');
            app.ZEncoderumEditField.FontSize = 16;
            app.ZEncoderumEditField.Position = [142 5 59 22];

            % Create nomotorstepsEditFieldLabel
            app.nomotorstepsEditFieldLabel = uilabel(app.ApproachSettingsPanel);
            app.nomotorstepsEditFieldLabel.HorizontalAlignment = 'right';
            app.nomotorstepsEditFieldLabel.FontSize = 16;
            app.nomotorstepsEditFieldLabel.FontWeight = 'bold';
            app.nomotorstepsEditFieldLabel.Position = [14 90 126 22];
            app.nomotorstepsEditFieldLabel.Text = 'no. motor steps';

            % Create nomotorstepsEditField
            app.nomotorstepsEditField = uieditfield(app.ApproachSettingsPanel, 'numeric');
            app.nomotorstepsEditField.FontSize = 16;
            app.nomotorstepsEditField.Position = [191 90 55 22];
            app.nomotorstepsEditField.Value = 400;

            % Create ApproachModeCheckBox
            app.ApproachModeCheckBox = uicheckbox(app.ApproachSettingsPanel);
            app.ApproachModeCheckBox.ValueChangedFcn = createCallbackFcn(app, @ApproachModeCheckBoxValueChanged, true);
            app.ApproachModeCheckBox.Text = ' Approach Mode';
            app.ApproachModeCheckBox.FontSize = 16;
            app.ApproachModeCheckBox.FontWeight = 'bold';
            app.ApproachModeCheckBox.Position = [8 117 147 22];

            % Create Zencoded_Max_Box
            app.Zencoded_Max_Box = uieditfield(app.ApproachSettingsPanel, 'text');
            app.Zencoded_Max_Box.ValueChangedFcn = createCallbackFcn(app, @Zencoded_Max_BoxValueChanged, true);
            app.Zencoded_Max_Box.HorizontalAlignment = 'center';
            app.Zencoded_Max_Box.FontSize = 16;
            app.Zencoded_Max_Box.Position = [191 66 55 19];
            app.Zencoded_Max_Box.Value = '0';

            % Create Zenc_PauseStep_Box
            app.Zenc_PauseStep_Box = uieditfield(app.ApproachSettingsPanel, 'text');
            app.Zenc_PauseStep_Box.ValueChangedFcn = createCallbackFcn(app, @Zenc_PauseStep_BoxValueChanged, true);
            app.Zenc_PauseStep_Box.HorizontalAlignment = 'center';
            app.Zenc_PauseStep_Box.FontSize = 16;
            app.Zenc_PauseStep_Box.Position = [211 31 35 24];
            app.Zenc_PauseStep_Box.Value = '5';

            % Create Zs_PauseStep_Text
            app.Zs_PauseStep_Text = uilabel(app.ApproachSettingsPanel);
            app.Zs_PauseStep_Text.HorizontalAlignment = 'center';
            app.Zs_PauseStep_Text.FontSize = 16;
            app.Zs_PauseStep_Text.FontWeight = 'bold';
            app.Zs_PauseStep_Text.Position = [6 31 194 28];
            app.Zs_PauseStep_Text.Text = 'Pause after extention [S]';

            % Create TipSpeednmsSpinnerLabel_2
            app.TipSpeednmsSpinnerLabel_2 = uilabel(app.ApproachSettingsPanel);
            app.TipSpeednmsSpinnerLabel_2.HorizontalAlignment = 'right';
            app.TipSpeednmsSpinnerLabel_2.FontSize = 16;
            app.TipSpeednmsSpinnerLabel_2.FontWeight = 'bold';
            app.TipSpeednmsSpinnerLabel_2.Position = [13 64 164 22];
            app.TipSpeednmsSpinnerLabel_2.Text = 'Z-Encoder Max (um):';

            % Create MaxIterationsSpinnerLabel
            app.MaxIterationsSpinnerLabel = uilabel(app.ApproachSettingsPanel);
            app.MaxIterationsSpinnerLabel.HorizontalAlignment = 'right';
            app.MaxIterationsSpinnerLabel.Position = [176 117 81 22];
            app.MaxIterationsSpinnerLabel.Text = 'Max Iterations';

            % Create MaxIterationsSpinner
            app.MaxIterationsSpinner = uispinner(app.ApproachSettingsPanel);
            app.MaxIterationsSpinner.Limits = [0 Inf];
            app.MaxIterationsSpinner.ValueChangedFcn = createCallbackFcn(app, @MaxIterationsSpinnerValueChanged, true);
            app.MaxIterationsSpinner.Position = [271 117 100 22];
            app.MaxIterationsSpinner.Value = Inf;

            % Create IterationscompletedEditFieldLabel
            app.IterationscompletedEditFieldLabel = uilabel(app.UIFigure);
            app.IterationscompletedEditFieldLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.IterationscompletedEditFieldLabel.HorizontalAlignment = 'right';
            app.IterationscompletedEditFieldLabel.Position = [299 192 114 22];
            app.IterationscompletedEditFieldLabel.Text = 'Iterations completed';

            % Create IterationscompletedEditField
            app.IterationscompletedEditField = uieditfield(app.UIFigure, 'numeric');
            app.IterationscompletedEditField.Editable = 'off';
            app.IterationscompletedEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.IterationscompletedEditField.Position = [437 194 32 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Alt_Approach20_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end