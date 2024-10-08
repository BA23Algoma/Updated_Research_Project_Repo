classdef Standby
    
    properties
                
        
    end
    
    methods
        
        function obj = Standby
            
            
        end
        
    end
    
    methods
        
        function obj = ShowStandby(obj, render, inputDevice, varargin)
            
            WaitSecs(0.25);
           
           if ~ischar(varargin{1})
               
               ipClient = varargin{1};
               varargin = varargin(2:end);
               
           end
            
            obj.printToScreen(render, varargin);
            
            goFlag = 0;
            
            while ~goFlag
            
                [goFlag, calibrationFlag] = inputDevice.PollStandby();
                
                if calibrationFlag && exist('ipClient', 'var') && ipClient.client ~= -1
                    
                    % indicate not the first calibration
                    initCalibration = 0;

                    % run calibration
                    ipClient.Calibrate(render, inputDevice, initCalibration);
                    
                    % Re-initialize original window
                    %goFlag = 0;
                    obj.ShowStandby(render, inputDevice, varargin{:});
    
                    % reset flag 
                    calibrationFlag = 0;
                    
                end
                
            end
            
            Screen('Flip', render.viewportPtr);
            
        end
        
        function obj = printToScreen(obj, render, varargin)
                
            strings = varargin{:};
            nVargin = numel(strings);                
            
            normBoundsRect = Screen('TextBounds', render.viewportPtr, 'test');
            rectHeight = RectHeight(normBoundsRect);
            
            ySpace = render.scaleRatio * 2 * rectHeight * linspace(0, nVargin-1, nVargin) + render.y0;
            
            for textIndex = 1:nVargin
                
                if textIndex == 1
                    
                    Screen('TextStyle', render.viewportPtr, 1);
                    
                else
                    
                    Screen('TextStyle', render.viewportPtr, 0);
                    
                end

                normBoundsRect = Screen('TextBounds', render.viewportPtr, strings{textIndex});
                normBoundsRect = CenterRectOnPoint(normBoundsRect, render.x0, ySpace(textIndex));
                Screen('DrawText', render.viewportPtr, strings{textIndex}, normBoundsRect(RectLeft), normBoundsRect(RectTop));                
                
            end
            
            Screen('Flip', render.viewportPtr);
            
        end
        
    end
        
    
end