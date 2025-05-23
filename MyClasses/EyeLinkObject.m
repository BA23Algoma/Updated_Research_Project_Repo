% obj = EyeLinkObject([screen], [IP Address], [Port Number])

classdef EyeLinkObject
    
    properties
        
        el                  % Eyelink Structure created by SR-Research
        ipAddress           = '127.0.0.1';
        portNum             = 4242;
        client;
        names;
        
    end
    
    methods
        
        % Main eyelink function containing initialization, data recording
        % and eyelink TCP communication  for initial testing
        function obj = EyeLinkObject()
            
            % Initialize EyeLink connection (dummymode = 0) or run in "Dummy Mode" without an EyeLink connection (dummymode = 1);
            dummymode = 0;
            
            EyelinkInit(dummymode); % Initialize EyeLink connection using provided dummy mode parameter
            
            % Run a error check to ensure if dummymode is set to 0, the
            % eyelink connection was established
            status = Eyelink('IsConnected');
            if status < 1 % If EyeLink not connected
                dummymode = 1; 
            end
            
            % Hardcoded test example for opening window
            screenNumber=max(Screen('Screens'));
            window=Screen('OpenWindow', screenNumber);
            Screen('Flip', window);

             if dummymode ==0 % If connected to EyeLink
                 
                 % Provide EyeLink with default information, which are returned in the structure "el".
                 obj.el = EyelinkInitDefaults(window);
                 
                 % You must call this function to apply the changes made to the el structure above 
                 EyelinkUpdateDefaults(obj.el);
                 
                 % Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
                 EyelinkDoTrackerSetup(obj.el);
                 
                 % Debugging marker for tracking process
                 disp('Completed tracker setup....\n');
            
                 % Open EDF file for recording data
                 fileName = 'test.edf'; % EDF is the file type used by eyelink
                 Eyelink('Openfile', fileName);
                 frpintf('Opened "%s" file ....\n', fileName);

                 % Start Recording on Host PC (Eyelink computer)
                 Eyelink ('StartRecording');
                 frpintf('Started recording ....\n', fileName);

                 % mark zero-plot time in data file
                 Eyelink('Message', 'SYNCTIME');
                 stopkey=KbName('space');
    
                 % Send message of start of test (Message sent over TCP to
                 % Eyelink
                 Eyelink('Message', 'Trial Start');

                 % Clear any existing areas of interest that may carry over from previous trials runs 
                 EyeLink('Command', 'clear_screen 0');
                 
                 
             
             end
    
             
             
             for timer = 3:-1:1
                 conClose = 'Connection closing in....';
                 str = [conClose, num2str(timer)];
                 disp(str);
                 WaitSecs(1);
             end
             
             % Shutdown Eyelink
             Eyelink('Shutdown');
             
             % Check if the eyelink is still connected
             connection = Eyelink('IsConnected');
             
              if connection ~= 0
                  obj.CloseProgram('Shutdown');
                  return;
              end
             
              disp('Eyelink has been shutdown succesfully....');
              disp('Terminating program....');
              
              % Try-Catch block for attempting to download the EDF data
              % file
              try
                  fprintf('Receiving data file ''%s''\n', fileName );
                  status=Eyelink('ReceiveFile');
                  if status > 0
                      fprintf('ReceiveFile status %d\n', status);
                  end
                  
                  if 2==exist(fileName, 'file')
                      fprintf('Data file ''%s'' can be found in ''%s''\n', fileName, pwd );
                  end
              catch rdf
                  fprintf('Problem receiving data file ''%s''\n', fileName );
                  rdf;
              end
              
              Eyelink('ReceiveFile', fileName, strcat('./', fileName));
              Screen('CloseAll');

        end
        
        % Calibrate Eyelink
        function result = Calibrate(type)
            
            % result variable output 0 if the calirbation failed, and 1 if
            % the calibration was successful
            % Setting the secondary input parameter to one calls the
            % do_tracker_setup() instead of the eyelink_start_seup()
            setupType = type;
            result = Eyelink('StartSetup', setupType);
            
        end
        
        % Validate Calibration
        function ValidateCali(InputParaemters)
            
            % Code
            
        end
        
        % Close Program
        function CloseProgram(~, code)

            error = {'Initialization', 'Calibration', 'Shutdown'};
              
              switch code
                  
                  case error(1)
                      
                      str = 'Eyelink failed to establish connection, program will be terminated....';
                      
                  case error(2)
                      
                      str = 'Eyelink failed to calibrate, program will be terminated....';
                      
                  case error(3)
                      
                      str = 'Eyelink was not shutdown correctly, program will now be focrefully terminated....';
                      
              end
              
              disp(str);
              o
              Screen('CloseAll');
              return;
              
        end
         
        
        % Code
        
    end
   
end