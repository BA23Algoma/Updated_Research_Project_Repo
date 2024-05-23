classdef Keyboard < InputDevice
    
    properties
        
        leftArrowCode;
        rightArrowCode;
        upArrowCode;
        downArrowCode;
        escapeCode;
        spaceCode; % Previously used sapce bar
        enterCode;
        printScreen;
        skipEventCode;
        calibrate;
        
    end
    
    methods
        
        function obj = Keyboard()
            
            obj = obj@InputDevice('KEYBOARD');
                        
            try
                
                KbCheck;
                
            catch
                
                error('Use of keyboard requires PsychToolbox->KbCheck');
                
            end
            
%             KbName('UnifyKeyNames');
            
            if ispc
                
                obj.leftArrowCode   = 37;
                obj.rightArrowCode  = 39;
                obj.upArrowCode     = 38;
                obj.downArrowCode   = 40;
                obj.escapeCode      = 27;
                obj.spaceCode       = 32;
                obj.enterCode       = 13;
                obj.printScreen     = 80; % keycode p
                obj.skipEventCode   = 83; % key code s
                obj.calibrate       = 67; % key code c
                
            elseif ismac
                obj.leftArrowCode   = KbName('leftArrow');
                obj.rightArrowCode  = KbName('rightArrow');
                obj.upArrowCode     = KbName('upArrow');
                obj.downArrowCode   = KbName('downArrow');
                obj.escapeCode      = KbName('escape');
                obj.spaceCode       = KbName('space');
            end
%             ListenChar(2);
            
        end
        
        
        function [goFlag, calibrationFlag] = PollStandby(obj)
            
            goFlag = 0;
            calibrationFlag = 0;
            
            [keyIsDown, ~, keyCode, ~] = KbCheck();
            
            if keyIsDown
                                    
                if keyCode(obj.enterCode)
                    
                    goFlag = 1;
                    
                elseif keyCode(obj.calibrate)
                    
                    calibrationFlag = 1;
                   
                elseif  keyCode(obj.escapeCode)
                    
                    Render.Close();
                    
                else
                    
                    % do nothing
                end
                
            else
                
                % do nothing
                
            end
            
        end       
        
        function [xPosDelta, decisionFlag] = PollRating(obj)
            
            xPosDelta = 0;
            decisionFlag = 0;
            
            [keyIsDown, ~, keyCode, ~] = KbCheck();
            
            if keyIsDown
                
                if keyCode(obj.leftArrowCode)
                    
                    xPosDelta = -1;
                    
                elseif keyCode(obj.rightArrowCode)
                    
                    xPosDelta = 1;
                    
                elseif keyCode(obj.enterCode)
                    
                    decisionFlag = 1;
                    
                elseif keyCode(obj.escapeCode)
                    
                    Render.Close();
                    
                else
                    
                    % do nothing
                end
                
            else
                
                % do nothing
                
            end
            
        end
        
        
        function [proposedPosition, proposedHeading, quitCode, skipEventCode, upKey, dwKey] = PollPlayer(obj, player, render, maze)
            
            proposedPosition = player.previousPos;
            proposedHeading = player.heading;
            quitCode = 0;
            skipEventCode = 0;
            upKey = 0;
            dwKey = 0;
            
            [keyIsDown, ~, keyCode, ~] = KbCheck();
            
            if keyIsDown
                
                if keyCode(obj.rightArrowCode)
                    
                    proposedHeading = player.heading - player.maxDegreesPerFrame;
                    
                end
                
                if keyCode(obj.leftArrowCode)
                    
                    proposedHeading = player.heading + player.maxDegreesPerFrame;
                    
                end
                
                if keyCode(obj.downArrowCode)
                    
                    proposedPosition(1) = player.previousPos(1) + player.maxVelocityPerFrame * cos(proposedHeading * obj.piOver180);
                    proposedPosition(2) = player.previousPos(2) - player.maxVelocityPerFrame * sin(proposedHeading * obj.piOver180);
                    dwKey = 1;
                    
                end
                
                if keyCode(obj.upArrowCode)
                    
                    proposedPosition(1) = player.previousPos(1) - player.maxVelocityPerFrame * cos(proposedHeading * obj.piOver180);
                    proposedPosition(2) = player.previousPos(2) + player.maxVelocityPerFrame * sin(proposedHeading * obj.piOver180);
                    upKey = 1;
                     
                end
                
                % Print screen
                if keyCode(obj.printScreen)
                    
                    mazeNumber = maze.fileName;
                    
                    cue = 1;
 
                    current_display = Screen('GetImage', render.viewportPtr);
                    fileName = strcat('maze_screen_shot_', mazeNumber, num2str(cue),'.png'); 
                    file = fullfile('Objects\Screenshots', fileName);
                    
                     if exist(file, 'file')
                         
                        valid = false;

                        while ~valid

                           cue = cue + 1;
                           fileName = strcat('maze_screen_shot', mazeNumber, num2str(cue),'.png'); 
                           file = fullfile('Objects\Screenshots', fileName);

                           if ~exist(file, 'file')

                               valid = true;  

                           end



                        end
                    
                     end
                    
%                     if exist(file, 'file')
%                         
%                         cue = '2';
%                         fileName = strcat('maze_screen_shot', mazeNumber, cue,'.png'); 
%                         file = fullfile('Objects\Screenshots', fileName);
%                         
%                     end
                    
                    imwrite(current_display,file);

                end
                
                if keyCode(obj.skipEventCode)
                    
                    skipEventCode = 1;
                    
                end
                
                if keyCode(obj.escapeCode)
                    
                    Render.Close();
                    
                end
                
            end
            
        end
        
    end
    
end