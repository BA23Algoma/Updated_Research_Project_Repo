

function MazeExp                    
                                                                     
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
    %     p.perspectiveAngle             = 45;
     
    
    %     p.eyeLevel                      = -0.55;
    %     p.coo rdPollInterval            = 0.1; 
    %     p.coordPollTimeLimit            = 240;
    %     p.praticePollTimeLimit          = 60;
    %     p.cue                           = 1; % Proximal
    %     p.gazePoint                     = 0;

    Randomizer();
    
    filePath = ExpPath();
    
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
    p.dataPath                      = filePath.dataPath;
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
    render = render.InitMazeWindow(p.perspectiveAngle, p.eyeLevel, p.viewPoint, p.cue, p.dynamicFOV);
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
        
        % Close any previously left open conections
        pnet('closeall');
        
        % 127.0.0.1
        ipClient = GazePoint(p.ipAddress, 4242);
        
        WaitSecs(0.5);
        
        initCalibration = 1;
        
        % Calibrate eyetracker
        ipClient.Calibrate(render, inputDevice, initCalibration);
        
        % Initialize retrieving POG data from gazepoint
        ipClient.EnableSendingPOG();
        
        % Send experiment condition to Gazepoint
        if  ipClient.client ~= -1
            
            % Clear data in space
            ipClient.Log('','Marker', '');
            WaitSecs(0.1);
            
%            userID = strcat('USER ID-', num2str(p.participantId));
            ipClient.Log(num2str(p.participantId),'Marker', 'userID');
            WaitSecs(0.1);
            
            if p.cue
                
                strGP = 'Proximal and Distal';
                
            else
                
                strGP = 'Distal';
                
            end
          
            ipClient.Log(strGP, 'Marker', 'Condition');
            WaitSecs(0.1);
            
        end
        
    else
        
        ipClient.client = -1;
        
    end
     

    
    % -----------------------
    % Pre-PHASE 1 (SELECT MAZE RUN)`
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
        render = render.loadPerCue(filePath.objectPath, filePath.objTextPath, maze.perCue);
        
        ShowCursor;
        
        [coordPoll, isCompleteFlag, stats, ~] = maze.Explore(render, player, inputDevice, 1000, p.coordPollInterval, p.nowNum, ipClient);

        coordPoll.SaveToFile(p.dataPath, p.participantId, maze.filePrefix, 'SingleMaze');
        
        if  ipClient.client ~= -1
            
            strGPEnd = strcat('End of', strcat(' ', mazeFileName));
            ipClient.Log(strGPEnd, 'Marker', '');
            WaitSecs(0.1);
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
            render = render.loadPerCue(filePath.objectPath, filePath.objTextPath, maze.perCue);

            standby.ShowStandby(render, inputDevice, ipClient, 'Hit ENTER when ready', 'Get Ready for Practice Tour');
            
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
            render = render.loadPerCue(filePath.objectPath, filePath.objTextPath, maze.perCue);
 
            standby.ShowStandby(render, inputDevice, ipClient, 'Hit ENTER when ready.','Get Ready For Maze Tour');
            
            maze.Tour(mazeTour, render, player, inputDevice);
            
            WaitSecs(.25);
            eolRating = rating.RatingSelect(render, inputDevice, 'EOL');
            expSchedule.trials(trialIndex, Schedule.COL.EOL_RATING) = eolRating;
            
        end
           
        message1Str = 'You may take a short break.';
        message2Str = 'Please stay seated and do not disturb others.';
        message3Str = 'Hit ENTER to begin next phase.';
        standby.ShowStandby(render, inputDevice, ipClient, message1Str, message2Str, message3Str);
        clc
        
    end
    
      
    % -----------------------
    % PHASE 3 PRACTICE (JOLs and RCJs)
    
     % Main Experiment Instructions
    
    if p.blockPracticeFlag
        
        % Set the practice Maze file title
        practiceMaze = 'PracticeMaze';
        
        if  ipClient.client ~= -1
 
%            strGP = strcat('Start Practice Block Run Experiment', strcat('-', practiceMaze));
            ipClient.Log(practiceMaze, 'Marker', 'Beginning');
            WaitSecs(0.1);
        end
        
        splashScreen.ShowSplashScreen(render, inputDevice, 'Enter_ExpInstructions1.jpg', 'Textures');
        
        schedule = Schedule(p.participantId, 'PRACTICE', p.nPracticeTrials, p.tourHand);
        splashScreen.ShowSplashScreen(render, inputDevice, 'Enter_ExpInstructions2.jpg', 'Textures', ipClient, Standby);
        
        for trialIndex = 1:schedule.nTrials
            
            % Load maze
            mazeFileIndex = schedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
            mazeFileName = schedule.mazeFileNames{mazeFileIndex};
            maze = Maze(mazeFileName, p.checkCollisionFlag);

            
            count = 3;
            
            % Maze Practice Maze Run
            if p.pracRun              
                
                splashScreen.ShowSplashScreen(render, inputDevice, 'Enter_ExpInstructions3.jpg', 'Textures', ipClient, Standby);
                
                for i = count:-1:1

                    standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'LEARNING PHASE begins in:', i, 'Next is the performance phase.', 1, 0);

                end
                
                % Notify start of practice block to gazepoint
                if  ipClient.client ~= -1
                    
       %             strGP = strcat('Learning', strcat('-', practiceMaze));
                    ipClient.Log('Learning', 'Marker', 'StartPractice');
                    WaitSecs(0.1);
                end

                [~, ~, ~, hesitantTime] = maze.Explore(render, player, inputDevice, p.praticePollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
                
                % Notify end of practice block to gazepoint
                if  ipClient.client ~= -1
 
%                    strGP = strcat('Learning', strcat('-', practiceMaze), 'EndPractice');
                    ipClient.Log('Learning', 'Marker', 'EndPractice');
                    WaitSecs(.1);
%                    strHesTime = strcat('Pre-Trial hesitancy time of', strcat('-', num2str(hesitantTime))); 
                    ipClient.Log(num2str(hesitantTime), 'Marker', 'PreHesitancy');
                    WaitSecs(0.1);
                end
                              
                % WaitSecs(.25);
                rating.RatingSelect(render, inputDevice, 'RCJ'); 
            end

            
            % Maze run 
            
            if  ipClient.client ~= -1
 
                % Notify end of run to gazepoint
%                strGP = strcat('Start Practice Block Run Experiment', strcat('-', practiceMaze));
%                strGP = strcat('Experiment', strcat('-', practiceMaze));
                ipClient.Log('Experiment', 'Marker', 'StartPractice');
                WaitSecs(0.1);
            end
            
            splashScreen.ShowSplashScreen(render, inputDevice, 'Enter_ExpInstructions4.jpg', 'Textures', ipClient, Standby);

                            
            for j = count:-1:1
                
                standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'PERFORMANCE PHASE begins in:', j, 'End of current block.', 1, 0);

            end
            
            [~, ~, ~, hesitantTime] = maze.Explore(render, player, inputDevice, p.coordPollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
            
            if  ipClient.client ~= -1
 
                % Notify end of run to gazepoint
 %               strGP = strcat('End Practice Block Run Experiment', strcat('-', practiceMaze));
                ipClient.Log('Experiment', 'Marker', 'EndPractice');
                WaitSecs(.1);
%                strHesTime = strcat('Final hesitancy time of', strcat('-', num2str(hesitantTime)));
                ipClient.Log(num2str(hesitantTime),  'Marker', 'PostHesitancy');
                WaitSecs(0.1);
            end
            
            %         WaitSecs(.25);    
            rating.RatingSelect(render, inputDevice, 'RCJ');
            
        end
        
    elseif ~p.singleMaze
        
         splashScreen.ShowSplashScreen(render, inputDevice, 'Enter_ExpInstructions1.jpg', 'Textures');
         
    end
    
    % -----------------------
    % PHASE 4 EXPERIMENT (JOLs and RCJs)
    
    expSchedule = expSchedule.Randomize();
    
    mazeNum = 0;
    
    if ~p.singleMaze
        
         splashScreen.ShowSplashScreen(render, inputDevice, 'Enter_ExpInstructions5.jpg', 'Textures');
    
        for blockIndex = 1:expSchedule.nBlocks

            message1Str = sprintf('Block %i', blockIndex);
            standby.ShowStandby(render, inputDevice, ipClient, 'Hit ENTER when ready.',  message1Str);

            if  ipClient.client ~= -1
 
%            strGP = strcat('Start Practice Block Run Experiment', strcat('-', practiceMaze));
            ipClient.Log(num2str(blockIndex), 'Marker', 'Beginning');
            WaitSecs(0.1);
            end
        
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

                        standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'Hit ENTER when ready.', labelIndex, 'Get Ready For Maze Tour:', 0, 0);

                    end

                    % Load Peripheral cues 
                    render = render.loadPerCue(filePath.objectPath, filePath.objTextPath, maze.perCue);
                    
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
                
                % Number of mazes between each break
                breakNum = ceil(expSchedule.nMazes / 3);

                for labelIndex = randperm(expSchedule.nMazesPerBlock)

                    mazeNum = mazeNum + 1;

                    trialIndex = labelIndex + (blockIndex-1) * expSchedule.nMazesPerBlock;

                    % Load maze
                    mazeFileIndex = expSchedule.trials(trialIndex, Schedule.COL.MAZE_FILE_INDEX);
                    mazeFileName = expSchedule.mazeFileNames{mazeFileIndex};

                    maze = Maze(mazeFileName, p.checkCollisionFlag);
                    
                    if (rem(mazeNum,breakNum) == 0) &&  ipClient.client ~= -1
                        
                        % Big break before continuing experiment
                        % splashScreen.ShowSplashScreen(render, inputDevice, 'Instructions1.jpg', 'Textures');
                        initCalibration = 0;
                        
                        % Calibrate eyetracker
                        ipClient.Calibrate(render, inputDevice, initCalibration);

                    end

                    % Load Peripheral cues 
                    render = render.loadPerCue(filePath.objectPath, filePath.objTextPath, maze.perCue);  
                    
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
                            
%                            strGP = strcat('Start Learning Block Number', strcat(' ', num2str(mazeNum)), '-', mazeFileName);
                            ipClient.Log(strcat(num2str(mazeNum), '-', mazeFileName), 'Marker', 'StartLearning');
                            WaitSecs(0.1);
                        end
        
                        for i = count:-1:1

                            standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'LEARNING PHASE begins in:', i, 'Next is the performance phase.', 1, 0);

                        end

                        [~, ~, ~, hesitantTime] = maze.Explore(render, player, inputDevice, p.praticePollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
                        
                        % WaitSecs(.25);
                        rating.RatingSelect(render, inputDevice, 'RCJ');
                        
                        if  ipClient.client ~= -1

                            % Notify end of run to gazepoint
%                            strGP = strcat('End Learning Block Number', strcat(' ', num2str(mazeNum)), '-', mazeFileName);
                            ipClient.Log(strcat(' ', num2str(mazeNum), '-', mazeFileName),  'Marker', 'EndLearning');
                            WaitSecs(.1);
%                            strHesTime = strcat('Pre-Trial hesitancy time of', strcat('-', num2str(hesitantTime))); 
                            ipClient.Log(num2str(hesitantTime),  'Marker', 'PreHesitancy');
                            WaitSecs(0.1);
                            
                        end
                                         
                    end

                    % message1Str = sprintf('Get Ready To Run Test Maze');
                    % standby.ShowStandby(render, inputDevice, message1Str, 'Hit ENTER when ready.');

                    for j = count:-1:1

                        standbyBigNumber.ShowStandbyBigNumber(render, inputDevice, 'PERFORMANCE PHASE begins in:', j, 'End of current block.', 1, 0);

                    end
                    
                    % Send experiment start note information to Gazepoint
                    if  ipClient.client ~= -1
                            
%                        strGP = strcat('Start Experiment Block Number', strcat(' ', num2str(mazeNum)), '-', mazeFileName);
%                        strCue = strcat('Object cues: ', strcat(' ',maze.perCue.obj),' &', strcat(' ',maze.perCue.objTwo));
                        strGP = strcat(' ', num2str(mazeNum), '-', mazeFileName);
                        strCue = strcat(strcat(' ',maze.perCue.obj),' &', strcat(' ',maze.perCue.objTwo));
                        ipClient.Log(strGP, 'Marker', 'StartPerformance');
                        WaitSecs(0.1);
                        ipClient.Log(strCue, 'Marker', 'CueList');
                        WaitSecs(0.1);  
                             
                    end

                    [coordPoll, isCompleteFlag, stats, hesitantTime] = maze.Explore(render, player, inputDevice, p.coordPollTimeLimit, p.coordPollInterval, p.nowNum, ipClient);
                    
                    % Send experiment end note information to Gazepoint
                    if  ipClient.client ~= -1
                            
%                        strGP = strcat('End Experiment Block Number', strcat(' ', num2str(mazeNum)), '-', mazeFileName);
                        strGP = strcat(' ', num2str(mazeNum), '-', mazeFileName);
                        ipClient.Log(strGP, 'Marker', 'EndPerformance');
                        WaitSecs(.1);
%                        strHesTime = strcat('Final hesitancy time of', strcat('-', num2str(hesitantTime))); 
                        ipClient.Log(num2str(hesitantTime), 'Marker', 'PostHesitancy');
                        WaitSecs(0.1);
                    end
                    
                    coordPoll.SaveToFile(p.dataPath, p.participantId, maze.filePrefix, 'user');

                    expSchedule.trials(trialIndex, Schedule.COL.IS_COMPLETE) = isCompleteFlag;
                    expSchedule.trials(trialIndex, Schedule.COL.DELTA_TIME) = stats(1);
                    expSchedule.trials(trialIndex, Schedule.COL.N_ERRORS) = stats(2);

                    WaitSecs(.25);        
                    rcjRating = rating.RatingSelect(render, inputDevice, 'RCJ');
                    expSchedule.trials(trialIndex, Schedule.COL.RCJ_RATING) = rcjRating;
                    
                    % Save data to user summary file
                    expSchedule.SaveToFile(p, mazeNum);

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
          
    splashScreen.ShowSplashScreen(render, inputDevice, 'Debriefing.jpg', 'Textures');
    
    if  ipClient.client ~= -1
   
        % Close eyetracker connection
        ipClient.Close;
        
    end
    
    Render.Close();
    
