% obj = GazePont([IP Address], [Port Number])

classdef GazePoint
    
    properties
        
        ipAddress           = '127.0.0.1';
        portNum             = 4242;
        client;
        gazePointSTR;
        names;
        
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

            obj.names = {
                    'XMin', 'XMax','YMin', 'YMax',...
                    'CueOneXMin', 'CueOneXMax'...
                    'CueOneYMin', 'CueOneYMax'...
                    'CueTwoXMin', 'CueTwoXMax'...
                    'CueTwoYMin', 'CueTwoYMax'...
                    'DistalXMin', 'DistalXMax'...
                    'DistalYMin', 'DistalYMax'...
                    'EyeLoc', 'Loc'...
                    };
                    
                for index = 1:numel(obj.names)
                    obj.gazePointSTR.(obj.names{index}) = '';
                end
                
                obj.gazePointSTR.XMin   = 'X1:';
                obj.gazePointSTR.XMax   = 'X2:';
                obj.gazePointSTR.YMin   = 'Y1:';
                obj.gazePointSTR.YMax   = 'Y2:';
                obj.gazePointSTR.EyeLoc = 'LOC: ';

        end
        
        function Calibrate(obj, render, inputDevice, initCalibration)

            % initialize standy and standbyBig
            % Standby
            standby = Standby;

            % Standby Big Numbers
            standbyBigNumber = StandbyBigNumber;
            
            % init respresents the first calibration of experiement
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
            
            % On screen countdown instructions leading to calibration 
            for j = 3:-1:1
                
                standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'Calibration starting in.....', j, ' ', 1, 0);

            end
            
            % tempory holder for render values to recreate render
            % window based on p constructor
            tempValues = [render.newWidth render.newHeight...
                render.newHz render.scaleRatio render.perspectiveAngle...
                render.eyeLevel render.viewPoint render.perCueFlag...
                render.initFOV(1)...
                ];
            
            tempNames = {'screenWidth', 'screenHeight', 'frameRate',...
                'scaleRatio', 'perspectiveAngle', 'eyeLevel',... 
                'viewPoint', 'cue', 'dynamicFOV',...
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
            render = render.InitMazeWindow(temp.perspectiveAngle, temp.eyeLevel, temp.viewPoint, temp.cue, temp.dynamicFOV);
            
            % Ensure that the calibration is valid
            obj.ValidCalibration(render, inputDevice, standby);
            
            % Rebuild rating selection
            rating = Rating(150, 'Textures');
            rating.Load(render);
            
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
                    pause(0.5);
                end
                
            end
            
             
        end
        
        % Ensure calibration completed successfully
        function obj = ValidCalibration(obj, render, inputDevice, standby)
            
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
        
        function obj = EnableSendingPOG(obj)
            
            % Configure data server to send eye coordinates
            pnet(obj.client, 'printf', '<SET ID="ENABLE_SEND_POG_FIX" STATE="1" /\r\n>');
                
            % Start sendind data from server (gazepoint) to client
            % (matlab)
            pnet(obj.client, 'printf', '<SET ID="ENABLE_SEND_DATA" STATE="1" /\r\n>');
            
        end
        
         % Read data for the X & Y real time eye cooridnates
         function FPOG = EyeCoordinates(obj)
             
             % Read the connection
             record = pnet(obj.client, 'read', 'noblock');

             % Setup the regulare expression patterns for the X & Y
             FPOGXexpr = 'FPOGX="([^"]+)"';
             FPOGYexpr = 'FPOGY="([^"]+)"';
            
             % Check if the read data contains the rec block
             if contains(record, '<REC')

                 % Extract the FPOG X & Y values
                 FPOGMatchX = regexp(record,FPOGXexpr,'tokens');
                 FPOGMatchY = regexp(record,FPOGYexpr,'tokens');

                 % Set X & Y values for the function
                 FPOGX = str2double(FPOGMatchX{1}{1});
                 
                 % Invert Y values to flip gazepoint convention
                 FPOGY = str2double(FPOGMatchY{1}{1});
                 FPOGY = 1 - FPOGY;
                 
                 FPOG = [FPOGX, FPOGY];

             else
                 
                 FPOG = [-1, -1];
                 
             end  
             
         end
        
        % Functions sends data from matlab to gazepoint user column
        function obj = Log(obj, command, type, switchCode)
            
            switch type
                
                case 'Data'
            
                    line_com = strcat('<SET ID="USER_DATA" VALUE="', command,'" />\r\n');
            
                case 'Marker'

                    code = switchCode;
                    
                    switch code
                        
                        case 'userID'
                            
                            lineCommand = strcat('USER ID-', command);
                            
                        case 'CueList'
                            
                            lineCommand = strcat('OBJECT CUES:', command);
                            
                        case 'Condition'
                            
                            lineCommand = command;

                        case 'Beginning'
                            
                            lineCommand = strcat('BEGINNING OF BLOCK-', command);

                        case 'StartPractice'
                            
                            lineCommand = strcat('START PRACTICE BLOCK RUN-',command,'-PRACTICEMAZE');

                        case 'EndPractice'
                            
                            lineCommand = strcat('END PRACTICE BLOCK RUN-', command,'-PRACTICEMAZE');

                        case 'StartLearning'
                            
                            lineCommand = strcat('START LEARNING BLOCK NUMBER-', command);

                        case 'EndLearning'
                            
                            lineCommand = strcat('END LEARNING BLOCK NUMBER-', command);
                            
                        case 'StartPerformance'
                            
                            lineCommand = strcat('START EXPERIMENT BLOCK NUMBER-', command);

                        case 'EndPerformance'
                            
                            lineCommand = strcat('END EXPERIMENT BLOCK NUMBER-', command);

                        case 'PreHesitancy'
                            
                            lineCommand = strcat('PRE-TRIAL HESITANCY TIME OF-', command);
                            
                        case 'PostHesitancy'
                            
                            lineCommand = strcat('FINAL HESITANCY TIME OF-', command);
                            
                        otherwise
                            
                            lineCommand = command;

                    end
                    
                    line_com = strcat('<SET ID="USER_DATA" VALUE="', lineCommand,'" DUR="1"/>\r\n');
                    
            end
            
            pnet(obj.client, 'printf',line_com);
            
            % Send marker again to ensure data is not lost
%            if strcmp(type, 'Marker')
%                pause(0.1);
%                pnet(obj.client, 'printf',line_com);
%            end
            
        end
        
        % Close the tcp connection
        function obj = Close(obj)
            
            % Blank Gazepoint to ensure data is not continuously being
            % logged
            obj.Log('', 'Marker', '');
            pnet('closeall');
            
        end
        
    end
        
end
