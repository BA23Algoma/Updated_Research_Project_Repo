classdef SplashScreen
    
    properties
                
    end
    
    
    methods
        
        function obj = SplashScreen()
                        
        end

    end
    
    methods (Static)
        
        function ShowSplashScreen(render, inputDevice, imageFileName, imagePathName, varargin)
            
            imageMatrix = imread(fullfile(imagePathName, imageFileName));
            [nRows, nCols, ~] = size(imageMatrix);
            
            newCols = ceil(nCols * render.scaleRatio);
            %newRows = ceil(newCols * render.scaleRatio);
            newRows = ceil(nRows * render.scaleRatio);
            
            splashScreenRect = SetRect(0, 0, newCols, newRows);
            
            splashScreenRect = CenterRectOnPoint(splashScreenRect, render.x0, render.y0);
            splashTex = Screen('MakeTexture', render.viewportPtr, imageMatrix);
            Screen('DrawTexture', render.viewportPtr, splashTex, Screen('Rect', splashTex), splashScreenRect);
            Screen('Flip', render.viewportPtr);
            
            WaitSecs(0.25);
            
            goFlag = 0;
            
            while ~goFlag
                
                [goFlag, calibrationFlag] = inputDevice.PollStandby();
                
                if calibrationFlag && nargin > 4
                    
                    initCalibration = 0;
                    
                    ipClient = varargin{1};

                    ipClient.Calibrate(render, inputDevice, initCalibration);
                    
                    SplashScreen.ShowSplashScreen(render, inputDevice, imageFileName, imagePathName);
                    
                end
                
            end
            
            Screen('Flip', render.viewportPtr);            
            
        end
        
    end
    
end