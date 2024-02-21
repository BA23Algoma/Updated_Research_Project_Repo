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
        
        
        function obj = Calibrate(obj)
            
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
        
        function obj = Log(obj, command)
            
            line_com = strcat('<SET ID="USER_DATA" VALUE="', command,'" DUR="1"/>\r\n');
            
            pnet(obj.client, 'printf',line_com);
            
        end
        
        function obj = Close(obj)
            
            pnet('closeall');
            
        end
        
    end
        
end
