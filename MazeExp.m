        function       MazeExp                    
                                                                     
     %     %      GUI modifiable parameters                                  
    %     p .participantI d               = 0;      
    %     p.nBlocks                       = 4;  
    %     p.nPracticeTrials               = 1;              
    %     p.tourHand                      = 1;
    %     p.inputDevice                   = 1;    
    %     p.playerBodyRadius              = 0.125; 
    %     p.playerDeltaUnitPerFrame       = 0.075;    
    %     p.playerDeltaDegPer Frame       = 3.0;                       
    %     p.tourDeltaUnitPerFr ame        = 0.075; 
    %     p.tourDeltaDegPerFrame          = 3.0;    
    %     p.viewPoint                     = 1; 
    %     p.frameRate                     = 60;
    %     p.perspectiv eAngle             = 45;
     %    p.eyeLevel                      = -0.55;
    %     p.coo rdPollInterval            = 0.1; 
    %     p.coordPollTimeLimit            = 240;
     %    p.praticePollTimeLimit          = 60;
    %     p.cue                           = 1; % Proximal
    %     p.gazePoint                     = 0;
 
    %add 2007 file to path
    setPath = what('MatlabWindowsFilesR2007a');
    addpath(setPath.path);
    addpath(pathdef);
    
    Randomizer();
      
    mazeExpConfig = MazeExpConfig;
    p = mazeExpConfig.Read();
    p = MazeExpGUI(p);
    
    if p.isExit              
        
           error('User abort');
        
    end
    
    p.nowNum = now;  
    
    % Internal fixed param  eters
    p.checkCollisionFlag            = 1;
     
    % Path
    p.dataPath                      = 'Data';
    p.eolPracticeFlag               = 0;
    p.initialTourFlag               = 0;
    p.blockPracticeFlag             = 1;
    p.blockTourFlag                 = 0;    

    %Used to overwrite GUI
    % p.blockRunFlag                  = 1;
    % p.aiTour                        = 0; 
    % p.pracRun                       = 1;
    % p.singleMaze                    = 1;
    
    % Clears practice block run
    if p.singleMaze
        p.blockPracticeFlag             = 0;
    end
     
    if (exist(p.dataPath, 'dir')==7)
        
        %         do nothing
        
    else
        
        if ~mkdir(p.dataPath)
            
               error('Cannot create directory');
              
        end
          
    end
    
    % Input device (hack for now)
    if p.inputDevice == 1
            
        inputDevice = Keyboard();
        
    elseif p.inputDevice == 2
        
        if ismac
              
            inputDevice = JoystickMac(0.25);
                
        elseif ispc
            
            inputDevice = JoystickWin(0.25);
            
        else
            
            error('Invalid platform (not Mac and not PC)');
            
        end
        
    else
          
        error('Unknown input device');
        
    end
    
    %   Player
    player = Player(p.playerBodyRadius, p.playerDeltaDegPerFrame, p.playerDeltaUnitPerFrame);
       
    % Render
    render = Render([p.screenWidth p.screenHeight p.frameRate]);
    render = render.InitMazeWindow(p.perspectiveAngle, p.eyeLevel, p.viewPoint, p.cue);
    p.nRows = render.nRows;
    p.nCols = render.nCols;         
    
    % Rating
    rating = Rating(150, 'Textures');
    rating = rating.Load(render);
    
    % Standby
    standby = Standby;
    
    % Standby Big Numbers
    standbyBigNumber = StandbyBigNumber;
    
    % SplashScreen
    splashScreen = SplashScreen;
    
    % GazePoint (Eyetracker) TCP/IP remote initalization & Calibration
    if p.gazePoint
        
        ipClient = GazePoint(p.ipAddress, 4242);
        
        WaitSecs(0.5);
        
        initCalibration = 1;
        
        % Calibrate eyetracker
        ipClient.Calibrate(render, inputDevice, p, standby, standbyBigNumber, initCalibration);
        
    else
        
        ipClient.client = -1;
        
    end
    
    % -----------------------
    % Pre-PHASE 1 (SELECT MAZE RUN)
    if p.singleMaze
        
        WaitSecs(0.25);
        
        % Load maze file name and initalize experiment
        preExp = Schedule(p.participantId, 'EXPERIMENT', p.nBlocks, p.tourHand, 1); 
        splashScreen.ShowSplashScreen(render, inputDevice, 'Instructions1.jpg', 'Textures'); 
        
        % Load maze 
        mazeFileIndex = p.mazeRunFile;
        mazeFileName = preExp.mazeFileNames{mazeFileIndex};
        maze = Maze(mazeFileName, p.checkCollisionFlag);

        % Load Peripheral cues 
        render = render.loadPerCue('Objects\OBJ Textures', maze.perCue.obj, maze.perCue.tex, maze.perCue.objTwo, maze.perCue.texTwo, maze);
        
        if  ipClient.client ~= -1
            
            %initialize maze to send client values
            strGP = strcat('Beginning of,', mazeFileName);
            ipClient.Log(strGP);
            
        end
        
        ShowCursor;
        
        [coordPoll, isCompleteFlag, stats] = maze.Explore(render, player, inputDevice, 1000, p.coordPollInterval, p.nowNum, ipClient);

        coordPoll.SaveToFile(p.dataPath, p.participantId, maze.filePrefix, MazeTour.TourHandStr(p.tourHand));
        
        if  ipClient.client ~= -1
            
            strGPEnd = strcat('End of,', mazeFileName);
            ipClient.Log(strGPEnd);
            
        end

        preExp.trials(mazeFileIndex, Schedule.COL.IS_COMPLETE) = isCompleteFlag;
        preExp.trials(mazeFileIndex, Schedule.COL.DELTA_TIME) = stats(1);
        preExp.trials(mazeFileIndex, Schedule.COL.N_ERRORS) = stats(2);
        
        preExp.SaveToFile(p);
                  
    end
    % -----------------------
    % PHASE 1 (PRACTICE EOL)
    
    % Practice EOL
    if p.eolPracticeFlag
        
        splashScreen.ShowSplashScreen(render, inputDevice, 'Instructions1.jpg', 'Textures');
        
        schedule = Schedule(p.participantId, 'PRACTICE', p.nPracticeTrials, p.tourHand);
         
        for trialIndex = 1:schedule.nTrials
       
            % Load maze
            mazeFileIndex = schedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
            mazeFileName = schedule.mazeFileNames{mazeFileIndex};
            maze = Maze(mazeFileName, p.checkCollisionFlag);
            
            % Load Peripheral cues 
            render = render.loadPerCue('Objects\OBJ Textures', maze.perCue.obj, maze.perCue.tex, maze.perCue.objTwo, maze.perCue.texTwo);

            standby.ShowStandby(render, inputDevice, ipClient, 'Get Ready for Practice Tour', 'Hit ENTER when ready.');
            
            % Maze tour
            mazeTour = MazeTour(maze.FilePrefix, p.tourHand, maze.pathName, p.tourDeltaDegPerFrame, p.tourDeltaUnitPerFrame);
            maze.Tour(mazeTour, render, player, inputDevice);
            
            rating = rating.Load(render);
            rating.RatingSelect(render, inputDevice, 'EOL');
            
        end
        
    end 
     
    % -----------------------
    % PHASE 2 (EXPERIMENT EOL)
     
    expSchedule = Schedule(p.participantId, 'EXPERIMENT', p.nBlocks, p.tourHand);
    
    if p.initialTourFlag
        
        splashScreen.ShowSplashScreen(render, inputDevice, 'Instructions2.jpg', 'Textures');        
        
        for trialIndex = randperm(expSchedule.nTrials)        
            
            % Load maze
            mazeFileIndex = expSchedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
            mazeFileName = expSchedule.mazeFileNames{mazeFileIndex};
            tourHand = expSchedule.trials(trialIndex, Schedule.COL.TOUR_HAND);
            maze = Maze(mazeFileName, p.checkCollisionFlag);
            
            % Maze tour
            mazeTour = MazeTour(maze.FilePrefix, tourHand, maze.pathName, p.tourDeltaDegPerFrame, p.tourDeltaUnitPerFrame);

            % Load Peripheral cues 
            render = render.loadPerCue('Objects\OBJ Textures', maze.perCue.obj, maze.perCue.tex, maze.perCue.objTwo, maze.perCue.texTwo);

            standby.ShowStandby(render, inputDevice, ipClient, 'Get Ready For Maze Tour', 'Hit ENTER when ready.');
            
            maze.Tour(mazeTour, render, player, inputDevice);
            
            WaitSecs(.25);
            eolRating = rating.RatingSelect(render, inputDevice, 'EOL');
            expSchedule.trials(trialIndex, Schedule.COL.EOL_RATING) = eolRating;
            
        end
           
        message1Str = 'You may take a short break.';
        message2Str = 'Please stay seated and do not disturb others.';
        message3Str = 'Hit ENTER to begin next phase.';
        standby.ShowStandby(render, inputDevice, ipClient, message1Str, message2Str, message3Str);
        
    end
    
      
    % -----------------------
    % PHASE 3 PRACTICE (JOLs and RCJs)
    
    if p.blockPracticeFlag
        
        schedule = Schedule(p.participantId, 'PRACTICE', p.nPracticeTrials, p.tourHand);
        splashScreen.ShowSplashScreen(render, inputDevice, 'Instructions3.jpg', 'Textures');
        
        for trialIndex = 1:schedule.nTrials
            
            % Load maze
            mazeFileIndex = schedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
            mazeFileName = schedule.mazeFileNames{mazeFileIndex};
            maze = Maze(mazeFileName, p.checkCollisionFlag);
   
            % Load Peripheral cues 
            % render = render.loadPerCue('Objects\OBJ Textures', maze.perCue.obj, maze.perCue.tex, maze.perCue.objTwo, maze.perCue.texTwo);
 
            standby.ShowStandby(render, inputDevice, ipClient, 'Get Ready for Practice Block', 'Hit ENTER when ready.');
            
            count = 3;
            
            % Maze Practice Maze Run
            if p.pracRun

                for i = count:-1:1

                    standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'LEARNING PHASE begins in:', i, 'Next is the performance phase.', 1, 0);

                end

                maze.Explore(render, player, inputDevice, p.praticePollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
                % WaitSecs(.25);
                rating.RatingSelect(render, inputDevice, 'RCJ'); 
            end

            
            % Maze run  
            for j = count:-1:1
                
                standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'PERFOMANCE PHASE begins in:', j, 'End of current block.', 1, 0);

            end
            
            maze.Explore(render, player, inputDevice, p.coordPollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
            %         WaitSecs(.25);    
            rating.RatingSelect(render, inputDevice, 'RCJ');
            
        end
        
    end
    
    % -----------------------
    % PHASE 4 EXPERIMENT (JOLs and RCJs)
    
    splashScreen.ShowSplashScreen(render, inputDevice, 'Instructions4.jpg', 'Textures');
    
    expSchedule = expSchedule.Randomize();
    
    mazeNum = 0;
    
    if ~p.singleMaze
    
        for blockIndex = 1:expSchedule.nBlocks

            message1Str = sprintf('Block %i', blockIndex);
            standby.ShowStandby(render, inputDevice, ipClient, message1Str, 'Hit ENTER when ready.');

            %    -----------------------
            % JOL

            if p.blockTourFlag

                for labelIndex = 1:expSchedule.nMazesPerBlock

                    trialIndex = labelIndex + (blockIndex-1) * expSchedule.nMazesPerBlock;

                    % Load maze         
                    mazeFileIndex = expSchedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
                    mazeFileName = expSchedule.mazeFileNames{mazeFileIndex};

                    maze = Maze(mazeFileName, p.checkCollisionFlag);

                    % Maze tour
                    if expSchedule.nMazesPerBlock ~= 1

                        standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'Get Ready For Maze Tour:', labelIndex, 'Hit ENTER when ready.', 0, 0);

                    end

                    % Load Peripheral cues 
                    render = render.loadPerCue('Objects\OBJ Textures', maze.perCue.obj, maze.perCue.tex, maze.perCue.objTwo, maze.perCue.texTwo);
                    
                    mazeTour = MazeTour(maze.FilePrefix, p.tourHand, maze.pathName, p.tourDeltaDegPerFrame, p.tourDeltaUnitPerFrame);
                    maze.Tour(mazeTour, render, player, inputDevice);

                    WaitSecs(.25);
                    jolRating = rating.RatingSelect(render, inputDevice, 'JOL');
                    expSchedule.trials(trialIndex, Schedule.COL.JOL_RATING) = jolRating;
                end
            end

            % -----------------------
                % RCJ

            if p.blockRunFlag


                for labelIndex = randperm(expSchedule.nMazesPerBlock)

                    mazeNum = mazeNum + 1;

                    trialIndex = labelIndex + (blockIndex-1) * expSchedule.nMazesPerBlock;

                    % Load maze
                    mazeFileIndex = expSchedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
                    mazeFileName = expSchedule.mazeFileNames{mazeFileIndex};

                    maze = Maze(mazeFileName, p.checkCollisionFlag);
                    
                    if mazeNum == (expSchedule.nMazes / 2) &&  ipClient.client ~= -1
                        
                        initCalibration = 0;
                        
                        % Calibrate eyetracker
                        ipClient.Calibrate(render, inputDevice, p, rating, standby, standbyBigNumber, initCalibration);
            
                    end

                    % Load Peripheral cues 
                    render = render.loadPerCue('Objects\OBJ Textures', maze.perCue.obj, maze.perCue.tex, maze.perCue.objTwo, maze.perCue.texTwo, maze);  
                    
                    % if expSchedule.nMazesPerBlock ~= 1

                            standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'Get Ready To Run In Maze:', mazeNum, ' ', 2, 1);

                    % end
                    
                    count = 3;

                    if p.pracRun

                        % Practice Maze run      
                        %message1Str = sprintf('Get Ready To Run Practice Maze');
                        %standby.ShowStandby(render, inputDevice, ipClient, message1Str, 'Hit ENTER when ready.');

                        % Send practice note information to Gazepoint
                        if  ipClient.client ~= -1
                            
                            strGP = strcat('Start Practice ,', mazeFileName);
                            ipClient.Log(strGP);
                            
                        end
        
                        for i = count:-1:1

                            standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'LEARNING PHASE begins in:', i, 'Next is the performance phase.', 1, 0);

                        end

                        maze.Explore(render, player, inputDevice, p.praticePollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
                        % WaitSecs(.25);
                        rating.RatingSelect(render, inputDevice, 'RCJ');
                        
                        if  ipClient.client ~= -1
 
                            % Notify end of run to gazepoint
                            strGP = strcat('End Practice ,', mazeFileName);
                            ipClient.Log(strGP);
                             
                        end
                                         
                    end

                    % message1Str = sprintf('Get Ready To Run Test Maze');
                    % standby.ShowStandby(render, inputDevice, message1Str, 'Hit ENTER when ready.');

                    for j = count:-1:1

                        standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'PERFOMANCE PHASE begins in:', j, 'End of current block.', 1, 0);

                    end
                    
                    % Send experiment start note information to Gazepoint
                    if  ipClient.client ~= -1
                            
                        strGP = strcat('Start Experiment for,', num2str(mazeNum), ',', mazeFileName);
                           strCue = strcat(maze.perCue.obj,',,,,,,', maze.perCue.objTwo);
                        ipClient.Log(strGP);
                        WaitSecs(0.25);
                         ipClient.Log(strCue);
                        WaitSecs(0.25);  
                            
                    end

                    [coordPoll, isCompleteFlag, stats] = maze.Explore(render, player, inputDevice, p.coordPollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);

                    % Send experiment end note information to Gazepoint
                    if  ipClient.client ~= -1
                            
                        strGP = strcat('End Experiment ,', mazeFileName);
                        ipClient.Log(strGP);
                            
                    end
                    
                    coordPoll.SaveToFile(p.dataPath, p.participantId, maze.filePrefix, MazeTour.TourHandStr(p.tourHand));

                    expSchedule.trials(trialIndex, Schedule.COL.IS_COMPLETE) = isCompleteFlag;
                    expSchedule.trials(trialIndex, Schedule.COL.DELTA_TIME) = stats(1);
                    expSchedule.trials(trialIndex, Schedule.COL.N_ERRORS) = stats(2);

                    WaitSecs(.25);        
                    rcjRating = rating.RatingSelect(render, inputDevice, 'RCJ');
                    expSchedule.trials(trialIndex, Schedule.COL.RCJ_RATING) = rcjRating;

                end
                
                if mazeNum ~= expSchedule.nBlocks
                    message1Str = 'You may take a short break.';
                    message2Str = 'Please stay seated and do not disturb others.';
                    message3Str = 'Hit ENTER to begin next block.';
                    standby.ShowStandby(render, inputDevice, ipClient, message1Str, message2Str, message3Str);

                end
                

            end

        end
    end
    
    if ~p.singleMaze
        
        expSchedule.SaveToFile(p);
    
    end
          
    splashScreen.ShowSplashScreen(render, inputDevice, 'Debriefing.jpg', 'Textures');
    
    if  ipClient.client ~= -1
   
        % Close eyetracker connection
        ipClient.Close;
        
    end
    
    Render.Close();
    
