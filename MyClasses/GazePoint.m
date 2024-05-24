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
        
        function Calibrate(obj, render, inputDevice, initCalibration)

            % initialize standy and standbyBig
            % Standby
            standby = Standby;

            % Standby Big Numbers
            standbyBigNumber = StandbyBigNumber;
            
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
            
            % tempory holder for render values to recreate render
            % window based on p constructor
            tempValues = [render.newWidth render.newHeight...
                render.newHz render.scaleRatio render.perspectiveAngle...
                render.eyeLevel render.viewPoint render.perCueFlag...
                ];

            tempNames = {'screenWidth', 'screenHeight', 'frameRate',...
                'scaleRatio', 'perspectiveAngle', 'eyeLevel',... 
                'viewPoint', 'cue', ...
                };

            for index = 1:numel(tempNames)
                temp.(tempNames{index}) = tempValues(index);
            end

            %Close render window
            Render.CaliClose();

            WaitSecs(0.5);

            % Calibrate eyetracker
            obj.GazePointCalibrateInstr();

            % Rebuild and re-initialize render window
            render = Render([temp.screenWidth temp.screenHeight temp.frameRate]);
            render = render.InitMazeWindow(temp.perspectiveAngle, temp.eyeLevel, temp.viewPoint, temp.cue);
            
            obj.ValidCalibration(render, inputDevice, standby, standbyBigNumber);
            
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
            calibComplete = false;

            %check calibratoin
            while ~calibComplete
                pnet(obj.client, 'printf', '<GET ID = "CALIB_RESULT" />\r\n');
                cali = pnet(obj.client, 'read', 'noblock');
              
                if contains(cali, '<CAL ID="CALIB_RESULT"')
                    calibComplete = true;
                    WaitSecs(0.5);
                    % Close calibration screen
                    pnet(obj.client, 'printf', '<SET ID="CALIBRATE_SHOW" STATE="0" /\r\n>');
                    pause(3)
                    
                else
                    pause(2);
                end
                
            end
            
             
        end
        
        % Ensure calibratino completed successfully
        function obj = ValidCalibration(obj, render, inputDevice, standby, standbyBigNumber)
            
            pnet(obj.client, 'printf', '<GET ID="CALIBRATE_RESULT_SUMMARY" /\r\n>');
            WaitSecs(0.5);
            summary = pnet(obj.client, 'read', 'noblock');
            
            expression = 'VALID_POINTS="(\d+)"';
            valid = regexp(summary,expression,'tokens');
            numValid = str2double(valid{1});
                 
            if numValid >= 4
                
                standby.ShowStandby(render, inputDevice, 'Calibration Successful', 'Hit ENTER to continue experiment' );
                
            else
                
                standby.ShowStandby(render, inputDevice, 'Calibration Unsuccessful', 'Hit ENTER to initialize calibration process' );
                obj.Calibrate(render, inputDevice, 0)
                
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
