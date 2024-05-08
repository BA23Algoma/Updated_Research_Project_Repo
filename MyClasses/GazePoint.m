% obj = GazePont([IP Address], [Port Number])

classdef GazePoint
    
    properties
        
        ipAddress;
        portNum;
        client;
        
    end
    
    methods
        
        function obj = GazePoint(varargin)
            
            if nargin > 0
                
                obj.ipAddress = varargin{1};
                
            end
            
            if nargin > 1
                
                obj.portNum = varargin{2};
                
            end
            
            if ~isempty(obj.ipAddress) && ~isempty(obj.portNum)
                  
                obj.client = pnet('tcpconnect', obj.ipAddress, obj.portNum);
 
            end
            
        end
        
        function Calibrate(obj, render, inputDevice, p, standby, standbyBigNumber, initCalibration)

            if initCalibration
                
                cali1Str = 'We are going to calibrate eye tracker before starting experiment.';
                cali2Str = 'Ensure you are in an upright position.';
                cali3Str = 'Hit ENTER to begin calibration.';
                standby.ShowStandby(render, inputDevice, cali1Str, cali2Str, cali3Str);
                
            else
                
                cali1Str = 'We are going to re-calibrate eye tracker.'; 
                cali2Str = 'Hit ENTER when ready to begin calibration.';
                standby.ShowStandby(render, inputDevice, cali1Str, cali2Str);
                
            end
            
            for j = 3:-1:1
                
                standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'Calibration starting in.....', j, ' ', 1, 0);

            end

            %Close render window
            Render.CaliClose();

            WaitSecs(0.5);

            % Calibrate eyetracker
            obj.GazePointCalibrateInstr();

            % Rebuild and re-initialize render window
            render = Render([p.screenWidth p.screenHeight p.frameRate]);
            render = render.InitMazeWindow(p.perspectiveAngle, p.eyeLevel, p.viewPoint, p.cue);
            
            % Rebuild rating selection
            rating = Rating(150, 'Textures');
            rating = rating.Load(render);
            
        end
        
        
        function obj = GazePointCalibrateInstr(obj)
            
            WaitSecs(0.5);
            % Send command to remote gazepoint to display calibration
            % screen
            pnet(obj.client, 'printf', '<SET ID="CALIBRATE_SHOW" STATE="1" /\r\n>');
            WaitSecs(0.5);
            % Start calibration
            pnet(obj.client, 'printf', '<SET ID="CALIBRATE_START" STATE="1" />\r\n');
            calibration_complete = false;

            %check calibratoin
            while ~calibration_complete
                pnet(obj.client, 'printf', '<GET ID = "CALIBRATION_RESULT_PT" />\r\n');
                cali = pnet(obj.client, 'read', 'noblock');

                if contains(cali, '<CAL ID="CALIB_RESULT"')
                    calibration_complete = true;
                    % Close calibration screen
                    pnet(obj.client, 'printf', '<SET ID="CALIBRATE_SHOW" STATE="0" /\r\n>');
                    pause(3)
                    
                else
                    pause(2);
                end
                
            end
        
        end
        
         % Used to balance delimiters
         function obj = Blank(obj)
             
             emptySpace = ',,,,,,,,,,,,,,,,,,,,,,,';
             
             obj.Log(emptySpace);
         
         end
        
        
        function obj = Log(obj, command)
            
            line_com = strcat('<SET ID="USER_DATA" VALUE="', command,'" DUR="1"/>\r\n');
            
            pnet(obj.client, 'printf',line_com);
            
        end
        
        function obj = Close(obj)
            
            pnet('closeall');
            
        end
        
    end
        
end
