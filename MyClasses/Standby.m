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
            
            if ischar(varargin{1})
                
                index = 1;
                disp('ischar');
                
            else
                
                ipClient = varargin{1};
                index = 2;

            end
            
            obj.printToScreen(render, index, varargin);
            
            goFlag = 0;
            
            while ~goFlag
            
                [goFlag, calibrationFlag] = inputDevice.PollStandby();
                
                if calibrationFlag && exist('ipClient', 'var')
                    
                    % reset flag and indicate not the first calibration for
                    % instructions
                    initCalibration = 0;
                    calibrationFlag = 0;
                    
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
                    
                    % initialize new big standy 
                    standbyBigNumber = StandbyBigNumber;
                    
                    ipClient.Calibrate(render, inputDevice, temp, obj, standbyBigNumber, initCalibration);
                    
                    index = 1;
                    
                    obj.printToScreen(render, index, 'Calibration complete', 'Hit ENTER to continue experiment' );
                                        
                end
                
            end
            
            Screen('Flip', render.viewportPtr);
            
        end
        
        function obj = printToScreen(obj, render, index, varargin)
            
            if ischar(varargin{1})
                   
                strings = varargin;
                disp(strings); 
                nVargin = numel(strings);
                
            else
                
                strings = varargin{:};
                nVargin = numel(strings);
                
            end
            
            normBoundsRect = Screen('TextBounds', render.viewportPtr, 'test');
            rectHeight = RectHeight(normBoundsRect);
            
            ySpace = render.scaleRatio * 2 * rectHeight * linspace(0, nVargin-1, nVargin) + render.y0;
            
            for textIndex = index:nVargin
                
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