classdef StandbyBigNumber
    
    properties
        
        
    end
    
    methods
        
        function obj = StandbyBigNumber
            
            
        end
        
        function obj = ShowStandbyBigNumber(obj, render, inputDevice, topMessageStr, mazeNumber, bottomMessageStr, pause, flip)
            
            WaitSecs(0.25);
            
            oldTextSize = Screen('TextSize', render.viewportPtr);
            
            Screen('TextSize', render.viewportPtr, oldTextSize);
            Screen('TextStyle', render.viewportPtr, 0);
            normBoundsRect1 = Screen('TextBounds', render.viewportPtr, topMessageStr);
            normBoundsRect1 = CenterRectOnPoint(normBoundsRect1, render.x0, render.y0 -  150);

            if contains(topMessageStr, 'PHASE')
                
                 if contains(topMessageStr, 'LEARNING')       
                        
                     textColor = [127 0 0]; % red
                        
                 elseif contains(topMessageStr, 'PERFORMANCE') 
                        
                     textColor = [0 127 0]; % green
                        
                 else
                     
                     textColor = [127 127 127]; % white
                     
                end
                
                phase = strfind(topMessageStr, 'PHASE');
                phase = phase + 5; % Include the word phaes
                
                strPhase = topMessageStr(1:phase);
                strEnd =  topMessageStr(phase: strlength(topMessageStr));
                
                strPhaseRect = Screen('TextBounds', render.viewportPtr, strPhase);
                strPhaseRect = AlignRect(strPhaseRect, normBoundsRect1, 'left', 'top');
                Screen('DrawText', render.viewportPtr, strPhase, strPhaseRect(RectLeft), strPhaseRect(RectTop), textColor, [0 0 0]);

                strEndRect = Screen('TextBounds', render.viewportPtr, strEnd);
                strEndRect = AlignRect(strEndRect, normBoundsRect1, 'right', 'top');
                Screen('DrawText', render.viewportPtr, strEnd, strEndRect(RectLeft), strEndRect(RectTop), [127 127 127], [0 0 0]);

            else
                
                Screen('DrawText', render.viewportPtr, topMessageStr, normBoundsRect1(RectLeft), normBoundsRect1(RectTop), [127 127 127], [0 0 0]);
                
            end          
                        
            Screen('TextSize', render.viewportPtr, 127);
            Screen('TextStyle', render.viewportPtr, 0);
            myText = sprintf('%i', mazeNumber);
            normBoundsRect2 = Screen('TextBounds', render.viewportPtr, myText);
            normBoundsRect2 = CenterRectOnPoint(normBoundsRect2, render.x0, render.y0);
            Screen('DrawText', render.viewportPtr, myText, normBoundsRect2(RectLeft), normBoundsRect2(RectTop), [127 127 127], [0 0 0]);
            
            Screen('TextSize', render.viewportPtr, oldTextSize);
            Screen('TextStyle', render.viewportPtr, 0);
            normBoundsRect3 = Screen('TextBounds', render.viewportPtr, bottomMessageStr);
            normBoundsRect3 = CenterRectOnPoint(normBoundsRect3, render.x0, render.y0 + 150);
            Screen('DrawText', render.viewportPtr, bottomMessageStr, normBoundsRect3(RectLeft), normBoundsRect3(RectTop), [127 127 127], [0 0 0]);
            
            Screen('Flip', render.viewportPtr);
            
            goFlag = 0;
            
            if pause ~= 0
                WaitSecs(pause);
            else
            
                while ~goFlag

                     [goFlag, ~] = inputDevice.PollStandby();

                end
            end
            
            if flip
                
                Screen('Flip', render.viewportPtr);
            
            end
            
        end
        
    end
    
end