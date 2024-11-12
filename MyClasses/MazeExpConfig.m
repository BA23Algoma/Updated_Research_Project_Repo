classdef MazeExpConfig
    
    properties
        
        % GUI modifiable parameters
        participantId                 = 0;
        nBlocks                       = 20;
        nPracticeTrials               = 1;
        tourHand                      = 1;
        inputDevice                   = 1;
        playerBodyRadius              = 0.125;
        playerDeltaUnitPerFrame       = 0.075;
        playerDeltaDegPerFrame        = 3.0;
        tourDeltaUnitPerFrame         = 0.075;
        tourDeltaDegPerFrame          = 3.0;
        viewPoint                     = 1;
        frameRate                     = 60;
        perspectiveAngle              = 55;
        eyeLevel                      = -0.4;
        coordPollInterval             = 0.1;
        coordPollTimeLimit            = 240;
        screenWidth                   = 1920;
        screenHeight                  = 1080;
        praticePollTimeLimit          = 60;
        cue                           = 1;
        pracRun                       = 1;
        AITour                        = 0;
        singleMaze                    = 0;
        select                        = 0;
        gazePoint                     = 0;
        ipAddress                     = '127.0.0.1';
        dynamicFOV                    = 0;            
        
    end
    
    properties (Constant)
        
        configFileName = 'mazeExpConfig.txt';
        fieldNames = {...
            'participantId',...
            'nBlocks',...
            'nPracticeTrials',...
            'tourHand',...
            'inputDevice',...
            'playerBodyRadius',...
            'playerDeltaUnitPerFrame',...
            'playerDeltaDegPerFrame',...
            'tourDeltaUnitPerFrame',...
            'tourDeltaDegPerFrame',...
            'viewPoint',...
            'frameRate',...
            'perspectiveAngle',...
            'eyeLevel',...
            'coordPollInterval',...
            'coordPollTimeLimit',...
            'screenWidth',...
            'screenHeight'...
            'praticePollTimeLimit',...
            'cue',...
            'pracRun',...
            'AITour',...
            'singleMaze',...
            'gazePoint',...
            'ipAddress',...
            'dynamicFOV',... 
            };
        
    end
    
    methods
        
        function Make(obj)
            
            fid = fopen(obj.configFileName, 'wt');
            if (fid~=-1)
                
                fprintf(fid, '%i\t\t%s\n', obj.participantId, strcat('% participantId'));
                fprintf(fid, '%i\t\t%s\n', obj.nBlocks, strcat('% nBlocks'));
                fprintf(fid, '%i\t\t%s\n', obj.nPracticeTrials, strcat('% nPracticeTrials'));
                fprintf(fid, '%i\t\t%s\n', obj.tourHand, strcat('% tourHand (1 = LEFT HAND; 2 = RIGHT HAND)'));
                fprintf(fid, '%i\t\t%s\n', obj.inputDevice, strcat('% inputDevice (1 = KEYBOARD; 2 = JOYSTICK)'));
                fprintf(fid, '%f\t%s\n', obj.playerBodyRadius, strcat('% playerBodyRadius'));
                fprintf(fid, '%f\t%s\n', obj.playerDeltaUnitPerFrame, strcat('% playerDeltaUnitPerFrame'));
                fprintf(fid, '%f\t%s\n', obj.playerDeltaDegPerFrame, strcat('% playerDeltaDegPerFrame'));
                fprintf(fid, '%f\t%s\n', obj.tourDeltaUnitPerFrame, strcat('% tourDeltaUnitPerFrame'));
                fprintf(fid, '%f\t%s\n', obj.tourDeltaDegPerFrame, strcat('% tourDeltaDegPerFrame'));
                fprintf(fid, '%i\t\t%s\n', obj.viewPoint, strcat('% viewPoint (1 = FIRST PERSON; 2 = THIRD PERSON)'));
                fprintf(fid, '%f\t%s\n', obj.frameRate, strcat('% frameRate'));
                fprintf(fid, '%f\t%s\n', obj.perspectiveAngle, strcat('% perspectiveAngle'));
                fprintf(fid, '%f\t%s\n', obj.eyeLevel, strcat('% eyeLevel (-0.5 is a good number)'));
                fprintf(fid, '%f\t%s\n', obj.coordPollInterval, strcat('% coordPollInterval'));
                fprintf(fid, '%f\t%s\n', obj.coordPollTimeLimit, strcat('% coordPollTimeLimit'));
                fprintf(fid, '%i\t\t%s\n', obj.screenWidth, strcat('% screenWidth'));
                fprintf(fid, '%i\t\t%s\n', obj.screenHeight, strcat('% screenHeight'));
                fprintf(fid, '%f\t%s\n', obj.praticePollTimeLimit, strcat('% praticePollTimeLimit'));
                fprintf(fid, '%f\t%s\n', obj.cue, strcat('% cue'));
                fprintf(fid, '%f\t%s\n', obj.pracRun, strcat('% pracRun'));
                fprintf(fid, '%f\t%s\n', obj.AITour, strcat('% AITour'));
                fprintf(fid, '%f\t%s\n', obj.singleMaze, strcat('% singleMaze'));
                fprintf(fid, '%f\t%s\n', obj.select, strcat('% singleMaze'));
                fprintf(fid, '%f\t%s\n', obj.gazePoint, strcat('% gazePoint'));
                fprintf(fid, '%s\t%s\n', obj.ipAddress, strcat('% ipAddress')); 
                printf(fid, '%f\t%s\n', obj.dynamicFOV, strcat('% dynamicFOV')); 

            else
                
                error('Cannot open mazeExpConfig.txt');
            end
            
            fclose(fid);
            
        end
        
        function p = Read(obj)
            
            fid = fopen(obj.configFileName, 'rt');
            if (fid~=-1)
                
                a = cell(numel(obj.fieldNames), 1);
                for lineIndex = 1:numel(obj.fieldNames)
                   
                   t = fgetl(fid);

                   if startsWith(t, '''') % Check if the line contains letters
                       t = strtok(t, '%'); % Remove comment
                       t = strtrim(t); % Trim leading and trailing whitespaces
                       a{lineIndex} = t(2:end-1); % Remove quotes
                   else
                       a{lineIndex} = sscanf(t, '%f');    
                   end
                    
                end
                
                p = cell2struct(a, obj.fieldNames, 1);
                
                
            else
                
                error('Cannot open mazeExpConfig.txt');
                
            end

            
        end
        
    end
    
end

