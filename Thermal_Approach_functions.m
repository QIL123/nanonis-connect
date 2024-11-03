classdef Thermal_Approach_functions
    %THERMAL_APPROACH_FUNCTIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    
    methods(Static)
        function  Plot_ACDC(app)

            % Plot AC

            if  app.ACx>app.Frame_Val
                app.ClearplotButtonPushed(app)
            end

            % Plot AC
            app.ACx=app.ACx+1;   % Fix time

                      % Average?
%                       if toc(app.tictoc) > (1/10)
%                              channels = double(Nanonis.Gets([app.AC_Channel,app.DC_Channel]));
%                              app.ACy = channels(1);
%                               app.DCy = channels(2);
%                
%                      end 
                     channels = double(Nanonis.Gets([app.AC_Channel,app.DC_Channel]));
                     app.ACy = channels(1);
                     app.DCy = channels(2);
%                     app.ACy=double(Nanonis.Get(app.AC_Channel));
              
                                        % UD_Axis_Limit(app)

            % Plot DC

%             app.DCy=double(Nanonis.Get(app.DC_Channel));
%             tic

            % app.test_x(end+1) = app.ACx;
            % app.test_y(end+1) = app.ACy;
            % app.test_y2(end+1) = app.DCy;
            % 
%             if toc(app.tictoc) > (1/10)
%                 addpoints(app.AC_Animated,app.test_x,app.test_y);
%                 addpoints(app.DC_Animated,app.test_x,app.test_y2);
%                 app.test_x = [];
%                 app.test_y = [];
%                 app.test_y2 = [];
%             
%                 app.tictoc = tic;
%             end



            addpoints(app.AC_Animated,app.ACx,app.ACy);
            addpoints(app.DC_Animated,app.ACx,app.DCy);

%             toc
        end
        
        function Plot_ZpExe(app)
            % Plots by demends
            
            %X is The previus readout of Z scanner, Y is the thermal value
            app.Ratio_Vec(end+1)=app.Thermal_Ratio;
            app.Encoder_Vec(end+1)=app.Zpy;
            addpoints(app.Zp_Animated2,app.Encoder_Vec(end),app.Ratio_Vec(end));
        
            app.Zpx=app.Zpx+1;   % Fix time
            app.Zpy=Nanonis.Get_Encoder_Z();   % Value of Z scanner
            addpoints(app.Zp_Animated,app.Zpx,app.Zpy);
            drawnow
        end
        
        function UD_Axis_Limit(app)
            app.AC_Axes.YLim=[app.ACn_Box.Value app.ACp_Box.Value]+[-1 1].*app.ScaleY.Value;
            app.DC_Axes.YLim=[app.DCn_Box.Value app.DCp_Box.Value]+[-1 1].*app.ScaleY.Value;
        end
        
        function Set_Zs(app)
            
            % Cheack the limet of the extintion, if ok
            
            Con1=app.Zscanner_Val<=app.Zs_Limit; % Z scanner val is smaller then the limit
            if Con1
                % Sets the new value of Zs and update it value
                try
                    Nanonis.Set_Scanner_Z(app.Zscanner_Val);
                    % A solution to pause(0.03) which caused program
                    % runtime jumps due to OS issue
                        a = tic;
                        while toc(a) < 0.003
                        end
                    app.Zscanner_Val=double(Nanonis.Get_Scanner_Z());
                    
                    % Updates the box and slider values
                    
                    app.Zs_Val_Box.Value=round(app.Zscanner_Val,3);
                    app.Zs_ext_Slider.Value=app.Zscanner_Val;

                catch err
                    app.MessagesTextArea.Value = [err.message;app.MessagesTextArea.Value];
                end
                
            elseif app.Zscanner_Val-app.Zs_Step_Box.Value<=app.Zs_Limit
               
                % If the value of Zs - step size is smaller then the limit
                % but Zs is larger then the limit - go to the limit
                app.Zscanner_Val=app.Zs_Limit;
                Set_Zs(app);
            else
                
                app.Zscanner_Val=Nanonis.Get_Scanner_Z();
                
            end
           
        end
        
        function Timer_Fun(app,~,~)
       
            Plot_ACDC(app)
            if app.Run_Condition==1 % If ok to continiu in Z
                
                if  UD_Stop_Limit(app)  % If the value in threshold
                    
                    app.Zscanner_Val=app.Zscanner_Val+app.Zs_Step;
                    
                    Set_Zs(app)
                    
                    if app.Zscanner_Val==app.Zs_Extension
                       
                                
                                app.ACy = double(Nanonis.Get(app.AC_Channel));
                                app.Thermal_Ratio=app.ACy/app.Thermal_Initial.Value;
                                % Message
                                d=datestr(datetime);
                                Message=[d(13:end),' Thermal ratio is: ',num2str(app.Thermal_Ratio)];
                                app.MessagesTextArea.Value = [Message;app.MessagesTextArea.Value];
                                if app.Thermal_Ratio>app.Ratio_Box.Value
                                    
                                    d=datestr(datetime);
                                    Message=[d(13:end),' Thermal ratio condition reached, approach stoped!'];
                                    app.MessagesTextArea.Value = [Message;app.MessagesTextArea.Value];
                                    app.Retract_Button_Callback(app);
                                else 
                                    Propagate_Zmotor(app);
                                    
                                   
                                end
                                pause(1)
                     
                                app.Thermal_Initial.Value=double(Nanonis.Get_Average(app.AC_Channel,20));  % up date the thermal initial index
                                Thermal_InitialValueChanged(app);
                        
                    end 
                end 
            end
        end        
        
        function Con = UD_Stop_Limit(app)
            % Which condition
            Con=1;
            %             app.ACy=double(Nanonis.Get_Average(app.AC_Channel,app.Step_Average));
            Con1=app.ACy>app.ACp_Box.Value;
            Con2=app.ACy<app.ACn_Box.Value;
            Con3=app.DCy>app.DCp_Box.Value;
            Con4=app.DCy<app.DCn_Box.Value;
            
            if  Con1|| Con2||Con3||Con4
                
                % message
                d=datestr(datetime);
                
                switch  1
                    case Con1
                        Message=[d(13:end),' Threshold_AC+ = ',num2str(app.ACy),'[V], Z scan = ',num2str(app.Zscanner_Val),' [um]'];
                    case Con2
                        Message=[d(13:end),' Threshold_AC- = ',num2str(app.ACy),'[V], Z scan = ',num2str(app.Zscanner_Val),' [um]'];
                    case Con3
                        Message=[d(13:end),' Threshold_DC+ = ',num2str(app.DCy),'[V], Z scan = ',num2str(app.Zscanner_Val),' [um]'];
                    case Con4
                        Message=[d(13:end),' Threshold_DC- = ',num2str(app.DCy),'[V], Z scan = ',num2str(app.Zscanner_Val),' [um]'];
                end
                
                
                %   Retract if needed
                if app.Retract_Condition.Value
                    app.Zscanner_Val=app.Zscanner_Val-app.Retract_Condition_Val.Value;
                    Set_Zs(app);
                end
                
                % Stop moving
                if app.Start_Stop_Button.Value==1
                    app.Start_Stop_Button.Value=0;
                end
                Start_Stop_ButtonValueChanged(app);
                Con=0;
                
                app.MessagesTextArea.Value = [Message;app.MessagesTextArea.Value];  % Add message
                General.Beep()
                
            end
        end
        
        function Propagate_Zmotor(app)
            pause(1)
            app.Zscanner_Val=0; % Retract
            Set_Zs(app);
            pause(1)
            
            if Nanonis.Get_Encoder_Z()<str2double(app.Zencoded_Max_Box.Value)
                
                Nanonis.Motors_Move_Steps(str2double(app.Zenc_Steper_Box.Value),'z+');
                pause(str2double(app.Zenc_PauseStep_Box.Value))
                
                % Message
                d=datestr(datetime);
                Message=[d(13:end),'  Z motor moved, new val: ', num2str(Nanonis.Get_Encoder_Z())];
                app.MessagesTextArea.Value = [Message;app.MessagesTextArea.Value];
        else
               
                % Message
                d=datestr(datetime);
                Message= [d(13:end) ' Z motor is at the limit, motor didn''t move'];
                
                app.MessagesTextArea.Value = [Message;app.MessagesTextArea.Value];
            end
            Plot_ZpExe(app)
            
            if app.Blink.Value   % Blink if wish to
                try
                    DAC.Blink(app.Blink_Chan.Value)
                catch
                    warning('no DAC')
                end
               pause(1)
            end
            
        end
        
    end
    end


