% User_Data_Class

classdef user_data
    
    properties
        saveAsName;
        dataSet;
        sumFixation;
        outputTable;
        finalTable;
        tableIndex;
        nMazes;

        TIME;
        FPOGX;
        FPOGY;
        FPOGS;
        FPOGD;
        FPOGID;
        FPOGV;
        USER;
        GSR;
        GSRV;
        HR;
        HRV;
        Var13;
        maze;
        OBJECT_1;
        OBJECT_2;
        DISTAL;
        fixation;
        condition;
        particpantID;
        LOC;
        insideAOI;
        insidescreenHalf;
        cue             = {'OBJECT_1', 'OBJECT_2', 'DISTAL'};
        limits          = {'xMin', 'xMax', 'yMin', 'yMax'};
        screenHalfs     = ["SKY", "GROUND"];

    end
    
     properties (Constant = true)
    
        fileNameSuffix = '.summaryFile.csv';
        dataPath       = 'GazePoint User Data';
        proccessed     = 'ProcessedData';
        gazePointstring = '_all_gaze';
        fileTypeSufix  = '.csv';
        
    end
    
   methods
       
       function obj = user_data()
       
           % Retreive path to data and fixation files
%           rawData = FindFiles(obj, 'Raw Data');
%           fixData = FindFiles('Fixation Data');
           
%           rawData = 'GazePoint User Data\Sample Data\367259_all_gaze_edited.csv';
%           fixData = 'GazePoint User Data\Sample Data\367259_fixations.csv';
           
           % Test raw data
%           rawData = 'GazePoint User Data\Sample Data\User 22_all_gaze.csv';
           
           % Readtable to collect the data file information
%           obj.dataSet = obj.OpenFiles(rawData);
%           obj.sumFixation = obj.OpenFiles(fixData);
%           obj.sumFixation = readtable(fixData, 'PreserveVariableNames', true);

           % Preallocate array values
%           obj = obj.Preallocate();
           
            %add 2007 file to path
            setPath = what('MatlabWindowsFilesR2007a');
            addpath(setPath.path);
            addpath(pathdef);

           % Set the name of the file
           fileName = userDataGUI();
           obj.saveAsName = strcat(fileName, obj.fileNameSuffix);
           
           WaitSecs(0.5);
           
           % Retrieve gaze point files folder path
           path = uigetdir('', ' Select the folder containing Gaze Point data'); 

           % Collect file names from the folder
           fileNames = dir(path);
           fileNames = {fileNames(:).name};
           
           % Remove non gaze point all gaze files
           fileNameIndex = contains(fileNames(:), "_all_gaze.csv");
           fileNames = fileNames(fileNameIndex);

           % Transpose and set full file paths
           fileNames = {fileNames(:)}';
           fileNames = fullfile(path, fileNames{:});
           
           for user = 1:numel(fileNames)

               % Readtable to collect the data file information
               obj.dataSet = readtable(fileNames{user}, 'PreserveVariableNames', true);

               % Collect raw data variable names
               varNames = obj.dataSet.Properties.VariableNames;
               
               % Replace TIME header with a simplier header ('TIME')
               matches = regexp(varNames,'^.*TIME.*$', 'match');
               timeHeader = ~cellfun(@isempty, matches);
               varNames{timeHeader} = 'TIME';
               obj.dataSet.Properties.VariableNames{timeHeader} = 'TIME';

               % Determine dataset size
               numRows = size(obj.dataSet);

               % Preallocate raw data variable with zeros
               obj = PreallocateVectoriztion(obj, numRows(1), varNames);

               % Preallocate cue data for min/max with zeros
               obj = PreallocateVectoriztion(obj, numRows(1));

               obj = ParseRawDataVectorization(obj, varNames);

               % Build gaze time summary data
               obj = GazeDurationVectorization(obj);

               % Collect ID name for data file experiment
               
               curFileName = split(fileNames(user), "\");
 
               for i = 1:length(curFileName)

                   if contains(curFileName{i}, obj.gazePointstring)
                       userID = curFileName{i};
                   end

               end
               
               % Construct the final output table
               obj = ConstructfinalTable(obj, userID);

               % Add data to text and output file
               SaveToFile(obj);
               
               % Display completed data set to screen
               fprintf('Completed data for user %s, %i / %i\n', userID, user, numel(fileNames));
           
           end
            
       end
      
       % prallocate memeory to arrays
       function obj = PreallocateVectoriztion(varargin)
           
           obj = varargin{1};  
           numRows = varargin{2};  
     
           % Raw data set preallocation
           if nargin > 2
               
                varNames = varargin{3};
                
               
               for i  = 1:length(varNames)
                   obj.(varNames{i}) = zeros(numRows, 1);
               end  
            
           else % cue data set preallocation
           
               for i  = 1:length(obj.cue)

                   for j = 1:length(obj.limits)
                       obj.(obj.cue{i}).(obj.limits{j}) = zeros(numRows, 1);
                   end
                   
               end
           
           end
           
           % Allocate Screen half location
           obj.LOC = cell(numRows, 1);
           obj.LOC(:) = {''};
           
           % Allocate the gaze Object (AOI) inside check
           obj.insideAOI = zeros(1, length(obj.cue));
           obj.insidescreenHalf = [];
           
       end
       
       % Parse raw data into arays including fixation start and stop times
       function obj = ParseRawDataVectorization(obj, varNames)
           
           % Set the tags to search in input data
           
           tag = struct(...
            'BeginningBlock',        'BEGINNING',...
            'ParticipantID',         'USER',...
            'Condition',             'DISTAL',...
            'Start',                 'START',...
            'End',                   'END',...
            'Experiment',            'EXPERIMENT',...
            'Practice',              'PRACTICE',...
            'Learn',                 'LEARN',...
            'Cue',                   '.OBJ',...
            'Hesitancy',             'TIME',...
            'HesitancyLearning',     'PRE-TRIAL',...
            'HesitancyFinal',        'FINAL');
            
           % Raw Data
           
           % Asign values of table to data variable (Converting table to
           % matrix)
           for i  = 1:length(varNames)
               obj.(varNames{i}) = obj.dataSet.(varNames{i});
           end
           
           % Split user column based on delimiter ';'
           splitData = cellfun(@(x) split(x, ';'), obj.USER, 'UniformOutput', false);

           variableNamesTypes =...
               [["particpantID", "string"];...
               ["OrderNumber", "double"];...
               ["MazeNumber","double"];...
               ["Cue1", "string"];...
               ["Cue2", "string"];...
               ["LearningStart", "double"];...
               ["LearningEnd", "double"];...
               ["ExperimentStart", "double"];...
               ["ExperimentEnd", "double"];...
               ["ExperimentCondition", "string"];...
               ["OBJECT_1_LearningGazeTime", "double"];...
               ["OBJECT_1_ExperimentGazeTime", "double"];...
               ["OBJECT_2_LearningGazeTime", "double"];...
               ["OBJECT_2_ExperimentGazeTime", "double"];...
               ["SUM_OBJECT_LearningGazeTime", "double"];...
               ["SUM_OBJECT_ExperimentGazeTime", "double"];...
               ["DISTAL_LearningGazeTime", "double"];...
               ["DISTAL_ExperimentGazeTime", "double"];...
               ["HesitancyTimeLearning", "double"];...
               ["HesitancyTimeExperiment", "double"];...
               ["SkyTimeLearning", "double"];...
               ["SkyTimeExperiment", "double"];...
               ["GroundTimeLearning", "double"];...
               ["GroundTimeExperiment", "double"];...
               ["SKY_LearnLastInsideFixation", "double"];...
               ["SKY_LearnLastOutsideFixation", "double"];...
               ["SKY_ExpLastInsideFixation", "double"];...
               ["SKY_ExpLastOutsideFixation", "double"];...
               ["GROUND_LearnLastInsideFixation", "double"];...
               ["GROUND_LearnLastOutsideFixation", "double"];...
               ["GROUND_ExpLastInsideFixation", "double"];...
               ["GROUND_ExpLastOutsideFixation", "double"];...
               ["OBJECT_1_LearnLastInsideFixation", "double"];...
               ["OBJECT_1_LearnLastOutsideFixation", "double"];...
               ["OBJECT_1_ExpLastInsideFixation", "double"];...
               ["OBJECT_1_ExpLastOutsideFixation", "double"];...
               ["OBJECT_2_LearnLastInsideFixation", "double"];...
               ["OBJECT_2_LearnLastOutsideFixation", "double"];...
               ["OBJECT_2_ExpLastInsideFixation", "double"];...
               ["OBJECT_2_ExpLastOutsideFixation", "double"];...
               ["DISTAL_LearnLastInsideFixation", "double"];...
               ["DISTAL_LearnLastOutsideFixation", "double"];...
               ["DISTAL_ExpLastInsideFixation", "double"];...
               ["DISTAL_ExpLastOutsideFixation", "double"];...
               ["SUM_OBJECT_LearnLastInsideFixation", "double"];...
               ["SUM_OBJECT_LearnLastOutsideFixation", "double"];...
               ["SUM_OBJECT_ExpLastInsideFixation", "double"];...
               ["SUM_OBJECT_ExpLastOutsideFixation", "double"];...
               ["TotalFixationLearning", "double"];...
               ["TotalFixationExperiment", "double"];...
               ["AverageGalvanicSkinLearning", "double"];...
               ["AverageGalvanicSkinExperiment", "double"];...
               ["AverageHeartRateLearning", "double"];...
               ["AverageHeartRateExperiment", "double"]];

           obj.outputTable = table('Size', [100, size(variableNamesTypes, 1)],...
                'VariableNames',variableNamesTypes(:, 1),...
                'VariableTypes',variableNamesTypes(:, 2));
           
           obj.tableIndex = 0;
           obj.nMazes = 0;
           
           % Parse fixation all gazes table, skip headers
            for j =1:numel(splitData)
                
                if numel(splitData{j}) > 1   
                    
                    for i = 1:numel(splitData{j})
                        
                        % Determine the number of ':' in eah
                        delimeter = strfind(splitData{j}{i},':');
                        
                        if length(delimeter) > 1
                    
                            % Adjust the split row to the correct format
                            newRows = split(splitData{j}(i), ':');
                            temp = newRows(end);
                            newRows(end) = [];
                            newRows = strcat(newRows, ':');
                            newRows(end) = strcat(newRows{end}, temp);
                            
                            preRows = [];
                            
                            if i > 1
                                
                                preRows = splitData{j}(1:i-1);
                                
                            end
                            
                            splitData{j} = [preRows; newRows; splitData{j}(i+1:end)];
                            
                        end
                        
                        
                    end
                    
                    splitData{j} = splitData{j}(~cellfun('isempty', splitData{j}));

                end
                    
                % Split data columns by delimiter ':', csv file
                if contains(splitData{j}, ':') & obj.tableIndex ~= 0

                    % Determine if the string is the objects or cue limit
                    if  contains(splitData{j}, tag.Cue)

                        rowEntry = split(splitData{j}, [":"; "&"]);
                        obj.outputTable.Cue1(obj.tableIndex) = rowEntry{2};
                        obj.outputTable.Cue2(obj.tableIndex) = rowEntry{3};

                    else
%                        disp(splitData{j});
%                        splitData = splitData{j}(~cellfun('isempty', splitData{j}));
                        rowEntry = split(splitData{j}, ':');
%                        disp('Post removing last element');
%                        disp(rowEntry);

                        % Loop for each cue
                        for index  = 1:length(obj.cue)

                            %Parsing XMIN, XMAX, YMIN, YMAX values for all cues
                           for limitIndex = 1:length(obj.limits)

                               % Retrieve row value and convert to string
                              cueCheck = rowEntry((((index - 1) * numel(obj.limits)) + limitIndex), 2);

                              % Set the object cue value to the 
                              obj.(obj.cue{index}).(obj.limits{limitIndex})(j) = str2double(cueCheck);

                           end

                        end

 %                       obj.check = (splitData);
                        eyeLocation = numel(obj.cue) * numel(obj.limits);

                        if eyeLocation < numel(rowEntry(:, 2))

                            obj.LOC(j) = rowEntry((eyeLocation + 1), 2);

                        end

                    end

                    % Set condition
                elseif contains(splitData{j}, tag.BeginningBlock)

                    obj.tableIndex = obj.tableIndex + 1;
                    obj.nMazes = obj.nMazes + 1;

                % Set condition
                elseif contains(splitData{j}, tag.ParticipantID)

                    idColumn = split(splitData{j}, '-'); 
                    obj.particpantID = idColumn{2};

                % Set condition
                elseif contains(splitData{j}, tag.Condition)

                    obj.condition = splitData{j};

                % Track start of mazes
                elseif contains(splitData{j}, tag.Start)

                    if contains(splitData{j}, tag.Experiment, 'IgnoreCase', true)

                        % Set the start of the experiment phase
                        obj.outputTable.ExperimentStart(obj.tableIndex) = j;

                    else

                        % Set the strat of the learning phase
                        obj.outputTable.LearningStart(obj.tableIndex) = j;

                        if contains(splitData{j}, tag.Practice, 'IgnoreCase', true)

                            % Set the order number to zero
                            obj.outputTable.OrderNumber(obj.tableIndex) = 0;

                            obj.outputTable.MazeNumber(obj.tableIndex) =  0;

                        else

                            % Initialize table maze number index
                            splitString = split(splitData{j}, ["#", "."]);
                            obj.outputTable.MazeNumber(obj.tableIndex) =  str2double(splitString(2));

                            % Set the maze order number
                            pattern = 'NUMBER-(\d*)';
                            orderNum = regexp(splitString(1), pattern, 'tokens');
                            obj.outputTable.OrderNumber(obj.tableIndex) = str2double(orderNum{1}{1});

                        end

                    end

                % Track end of mazes
                elseif contains(splitData{j}, tag.End)

                    if contains(splitData{j}, tag.Experiment, 'IgnoreCase', true)

                        obj.outputTable.ExperimentEnd(obj.tableIndex) = j;


                    else

                        obj.outputTable.LearningEnd(obj.tableIndex) = j;

                    end

                elseif contains(splitData{j}, tag.Hesitancy)

                    % Retrieve the value of hesitancy time
                    hesiPattern = 'OF-(\d*\.?\d+)';
                    hesiTime = regexp(splitData{j}, hesiPattern, 'tokens');
  %                  disp(str2double(hesiTime{1}{1}));

                    if contains(splitData{j}, tag.HesitancyLearning, 'IgnoreCase', true)

                        obj.outputTable.HesitancyTimeLearning(obj.tableIndex) = str2double(hesiTime{1}{1});

                    else

                        obj.outputTable.HesitancyTimeExperiment(obj.tableIndex) = str2double(hesiTime{1}{1});
                        obj.outputTable.ExperimentCondition(obj.tableIndex) = obj.condition;
                        obj.outputTable.particpantID(obj.tableIndex) = obj.particpantID;

                    end


                else

                    % Do nothing

                end
                    

            end
           
           
       end
       
       function obj = GazeDurationVectorization(obj)

           OutsideFixCondition = [{'_LearnLastOutsideFixation'}, {'_ExpLastOutsideFixation'}];
           InsideFixCondition = [{'_LearnLastInsideFixation'}, {'_ExpLastInsideFixation'}];
           gazetimeCond = [{'_LearningGazeTime'}, {'_ExperimentGazeTime'}];
           totalFixCond = ["TotalFixationLearning", "TotalFixationExperiment"];                                  
           timingCondition = [{'TimeLearning'}, {'TimeExperiment'}];
           
           % Set the fixation increment count
           count = 1;
           index = 1;
           minValidEyeLoc = 0.7;
           
           % Gazes are broken into fixation ID's, where the duration of the
           % fixation is added to the individual cue gaze times

           while  index < numel(obj.FPOGID)
               
               % Find starting index of next FPOGID
               startingIdIndex = index;
               
               % Find ending index current FPOGID
               
               while obj.FPOGID(startingIdIndex) == obj.FPOGID(index)
                   
                   % Determine the final valid FPOG
                   if obj.FPOGV(index) == 1
                       
                       endingIdIndex = index;
                       
                   end
                   
                   if index < numel(obj.FPOGID)
                   
                       index = index + 1;
                   
                   elseif index == numel(obj.FPOGID)
                       
                       break;
                       
                   end
                   
               end
               
               % check to ensure that the FPOG is valid
               if obj.FPOGV(startingIdIndex) ~= 1
                  
                   continue;
                   
               else
                   
                   % Get the current ID gaze duration
                   duration = obj.FPOGD(endingIdIndex);
                   
                   % Get the index set for thr screen halfs
                   eyeGaze = obj.LOC(startingIdIndex:endingIdIndex);
                   
                   % Remove empty array fields
                   eyeGaze(eyeGaze == "") = [];
                   
                   
                   
                   % Ensure the remainging eyeGaze has values
                   if isempty(eyeGaze)

                       eyeLoc = [];
                       
                   else
                       
                       % Cross check for apperances of both conditions
                       skyMatches = matches(eyeGaze, obj.screenHalfs{1});
                       groundMatches = matches(eyeGaze, obj.screenHalfs{2});
                       
                       totalskyMatches = sum(skyMatches);
                       totalgroundMatches = sum(groundMatches);
                       
                       % Check to ensure values are an accuarat
                       % representation
                       setsize = endingIdIndex - startingIdIndex;
                   
                       % Set the eye location to the most prominent
                       % condition totalskyMatches
                       if totalgroundMatches < totalskyMatches && (setsize * minValidEyeLoc) < totalskyMatches 
                           
                           eyeLoc = obj.screenHalfs(1);
                           
                       elseif totalskyMatches < totalgroundMatches && (setsize * minValidEyeLoc) < totalgroundMatches
                           
                           eyeLoc = obj.screenHalfs(2);
                           
                       else
                           
                           eyeLoc = [];
                           
                       end
                       
                   end
                   
                   % Get the average FPOG X/Y for current ID
                   avgFPOGX = mean(obj.FPOGX(startingIdIndex:endingIdIndex));
                   avgFPOGY = mean(obj.FPOGY(startingIdIndex:endingIdIndex));
                   
                   % Preallocate rects based on cues
                   boundingBox = zeros(length(obj.cue), length(obj.limits));
                   
                   % Construct the rects based on the cue bounding boxes
                   % Distal, and proximal bounding boxes
                   for i  = 1:length(obj.cue)
                       
                       cueData = obj.(obj.cue{i});
                       
                       % Retrive bounding box values
                       xMin = cueData.xMin(startingIdIndex:endingIdIndex);
                       yMin = cueData.yMin(startingIdIndex:endingIdIndex);
                       xMax = cueData.xMax(startingIdIndex:endingIdIndex);
                       yMax = cueData.yMax(startingIdIndex:endingIdIndex);
                       
                       % remove zero entries
                       xMin(xMin==0)=[];
                       yMin(yMin==0)=[];
                       xMax(xMax==0)=[];
                       yMax(yMax==0)=[];
                       
                       % Get average values
                       avgXMIN = mean(xMin);
                       avgYMIN = mean(yMin);
                       avgXMAX = mean(xMax);
                       avgYMAX = mean(yMax);

                       boundingBox(i, :) = [avgXMIN, avgYMIN, avgXMAX, avgYMAX];
        
                   end
                   
                   % Determine if the FPOG was within a bounding box, if so
                   % return which bounding box eye gaze lied within
                   AOI = gazeInRect(obj, boundingBox, avgFPOGX, avgFPOGY);
                   
                   %  Collect the column name for setting the values
                   columnNames = obj.outputTable.Properties.VariableNames;
                                                      
                   for block = 1:obj.nMazes
                   
                       % Initialize maze block indices
                       learningStart = obj.outputTable.LearningStart(block);
                       learningEnd = obj.outputTable.LearningEnd(block);
                       ExpStart = obj.outputTable.ExperimentStart(block);
                       ExpEnd = obj.outputTable.ExperimentEnd(block);
                       
                       indexSet = [
                           learningStart, learningEnd;
                           ExpStart, ExpEnd
                           ];
                       
                       
                       % Determine the condition of the test
                       if learningStart <= startingIdIndex && endingIdIndex <= learningEnd
                           set = 1;
                       elseif ExpStart <= startingIdIndex && endingIdIndex <= ExpEnd
                           set = 2;
                       else
                           set = -1;
                       end
                       
                       if set ~= -1
                           
                           % Ensure the FPOG was within one of the the bounding boxes
                           if AOI ~= -1 

                               if ~isempty(obj.insidescreenHalf)
                                   
                                   % Reset AOI inside tracker
                                   obj.insidescreenHalf = [];
                               
                               end
           
                               % Set the AOI fixation cloumn
                               if obj.insideAOI(AOI) == 0
                                                                      
                                   obj.insideAOI(AOI) = 1;
                                   
                                   fixCondition = OutsideFixCondition{set};
                                   fixationAOI = strcat(convertCharsToStrings(obj.cue(AOI)), fixCondition);
           
                               else
                                   
                                   if strcmp(convertCharsToStrings(obj.cue(AOI)),"DISTAL")
                                       
                                   else
 %                                      disp(convertCharsToStrings(obj.cue(AOI)));
                                   end  
                                  fixCondition = InsideFixCondition{set};
                                  fixationAOI = strcat(obj.cue(AOI), fixCondition); 
           
                               end
                               
                               % Reset all other inside values to zero
                               obj.insideAOI(1:end ~= AOI) = 0;
               
                               % Building column names
                               learningGaze = strcat(obj.cue(AOI), gazetimeCond{set});

                               % Find gaze time and fixation column in table
                               columnGaze = contains(columnNames, learningGaze);
                               columnFixation = contains(columnNames, fixationAOI);
                               
                               % Add duration to time block
                               obj.outputTable.(columnNames{columnGaze})(block) = obj.outputTable.(columnNames{columnGaze})(block) + duration;

                               % Add to fixation count
                               obj.outputTable.(columnNames{columnFixation})(block) = obj.outputTable.(columnNames{columnFixation})(block) + count;
                               
                               % Add to the sum values in the tables
                               if  contains(columnNames{columnGaze}, "OBJECT")
                               
                                   sumFxtnAOI = strcat('SUM_OBJECT', fixCondition);
                                   obj.outputTable.(sumFxtnAOI)(block) = obj.outputTable.(sumFxtnAOI)(block) + count;

                               end
                               
                               % Find total learning fixationa column in table
                               columnTotalFix = contains(columnNames, totalFixCond{set});
                           
                               % Add to total number of fixations
                               obj.outputTable.(columnNames{columnTotalFix})(block) = obj.outputTable.(columnNames{columnTotalFix})(block) + count;
               
                           elseif ~isempty(eyeLoc) 
                               
                               % Reset AOI inside tracker
                               obj.insideAOI(:) = 0;
       
                               % Set the AOI fixation cloumn
                               if isempty(obj.insidescreenHalf) || ~strcmp(obj.insidescreenHalf, eyeLoc)
                                   
                                   obj.insidescreenHalf = eyeLoc;
                                   
                                   fixCondition = OutsideFixCondition{set};
                                   
                               else
                                  
                                  fixCondition = InsideFixCondition{set};
                                  
                               end
                               
                               % Building column name
                               timing = strcat(eyeLoc,timingCondition{set});

                               % Find column in table
                               column = contains(columnNames, timing, 'IgnoreCase', true);

                               % Add duration to time block
                               obj.outputTable.(columnNames{column})(block) = obj.outputTable.(columnNames{column})(block) + duration;
                               
                               % Add to fixation count
                               fixHalf = strcat(eyeLoc, fixCondition);
                               columnScreenHalf = contains(columnNames, fixHalf, 'IgnoreCase', true);
                               obj.outputTable.(columnNames{columnScreenHalf})(block) = obj.outputTable.(columnNames{columnScreenHalf})(block) + count;
                               
                               % Find total learning fixationa column in table
                               columnTotalFix = contains(columnNames, totalFixCond(set));
                           
                               % Add to total number of fixations
                               obj.outputTable.(columnNames{columnTotalFix})(block) = obj.outputTable.(columnNames{columnTotalFix})(block) + count;
                           
                           else
                               
                               % Reset inside screen half tracker
                               obj.insidescreenHalf = [];
                               
                               % Reset AOI inside tracker
                               obj.insideAOI(:) = 0;
                               
                           end
                           
                           % Set the average Galvanic Skin and Heart Rate
                           obj.outputTable.AverageGalvanicSkinLearning(block) = mean(obj.GSR(indexSet(set,1):indexSet(set,2)));
                           obj.outputTable.AverageHeartRateLearning(block) = mean(obj.HR(indexSet(set,1):indexSet(set,2)));
                           
                       end
                       
                   end
                   
               end
               
           end
           
       end
       
       function obj = ConstructfinalTable(obj, userID)
           
           pattern = strcat('(.*)', obj.gazePointstring);
           userID = regexp(userID, pattern, 'tokens');
        
           % Get the number of elements in the table
           userSize = obj.nMazes;
           
           % Reset table index for final table
           obj.tableIndex = 1;
           
           % Set number of rows and columns for table
           finalVariableNamesTypes =...
               [["PatricpantID", "string"];...
               ["RecordingGazePointID","string"];...
               ["Condition","string"];...
               ["LearningVsPerformance", "string"];...
               ["MazeOrder", "double"];...
               ["MazeIdentity", "double"];...
               ["AOI", "string"];...
               ["AOI_Time", "double"];...
               ["TotalTrialTime", "double"];...
               ["PercentageAOI_TIME", "double"];...
               ["HesistencyTime", "double"];...
               ["AverageHeartRate", "string"];...
               ["AverageGalvanicSkinResponse", "double"];...
               ["AOI_FixationLastInside", "double"];...
               ["AOI_FixationLastOutside", "double"];...
               ["TotalFixation", "double"];...
               ["AOI_AverageFixationLength", "double"];...
               ["TotalNumberMazes", "double"]];
           
           obj.finalTable = table('Size', [700, size(finalVariableNamesTypes, 1)],...
                'VariableNames',finalVariableNamesTypes(:, 1),...
                'VariableTypes',finalVariableNamesTypes(:, 2));
               
           gazetime = [...
               "SUM_OBJECT_LearningGazeTime", "DISTAL_LearningGazeTime", "SkyTimeLearning","GroundTimeLearning";...
               "SUM_OBJECT_ExperimentGazeTime", "DISTAL_ExperimentGazeTime", "SkyTimeExperiment", "GroundTimeExperiment"];
          
          AOIFixationLastInside = [...
               "SUM_OBJECT_LearnLastInsideFixation", "DISTAL_LearnLastInsideFixation", "SKY_LearnLastInsideFixation",  "GROUND_LearnLastInsideFixation";...
               "SUM_OBJECT_ExpLastInsideFixation", "DISTAL_ExpLastInsideFixation", "SKY_ExpLastInsideFixation",  "GROUND_ExpLastInsideFixation"...
               ];
          
          AOIFixationLastOutside = [...
               "SUM_OBJECT_LearnLastOutsideFixation", "DISTAL_LearnLastOutsideFixation", "SKY_LearnLastOutsideFixation", "GROUND_LearnLastOutsideFixation";...
               "SUM_OBJECT_ExpLastOutsideFixation", "DISTAL_ExpLastOutsideFixation", "SKY_ExpLastOutsideFixation",  "GROUND_ExpLastOutsideFixation"...
               ];
           
           totalFixationTime = ["TotalFixationLearning", "TotalFixationExperiment"];
           
           heartRate = ["AverageHeartRateLearning", "AverageHeartRateExperiment"];

           galvanicSkinRate = ["AverageGalvanicSkinLearning", "AverageGalvanicSkinExperiment"];
   
           hesitancyTime = ["HesitancyTimeLearning", "HesitancyTimeExperiment"];
           
           experimentPhase = ["Learning", "Performance"];
           
           AOISet = ["Proximal", "Distal", "Sky", "Lower"];
           
           % Avrage Fixation Length
           
           % Percentage AOI Dwell Time

           % Loop the the table loading data
           for index = 1:userSize
               
               % Loop between learning and performance phases
               for phase = 1:2
                   
                   for AOIid = 1:length(AOISet)
                   
                       % Get the experiment condition (Distal vs. Proximal
                       % and Distal)
                       expCondition = obj.outputTable.ExperimentCondition(index);
                       
                       % Skip Proximal if only distal condition
                       if ~contains(expCondition, "PROXIMAL") && strcmp(AOISet(AOIid),"Proximal")
                           
                           continue;
                           
                       end
                       
                       % Load the user name
                       obj.finalTable.PatricpantID(obj.tableIndex) = obj.outputTable.particpantID(index);
                       
                       % Load the user name
                       obj.finalTable.RecordingGazePointID(obj.tableIndex) = userID;

                       % Set the experiment condition
                       obj.finalTable.Condition(obj.tableIndex) = obj.outputTable.ExperimentCondition(index);

                       % Set the phase, whether learning or experiment
                       obj.finalTable.LearningVsPerformance(obj.tableIndex) = experimentPhase(phase);

                       % Set the maze order
                       obj.finalTable.MazeOrder(obj.tableIndex) = obj.outputTable.OrderNumber(index);

                       % Set the maze idenity
                       obj.finalTable.MazeIdentity(obj.tableIndex) = obj.outputTable.MazeNumber(index);
                   
                       % Set the AOI idenity
                       obj.finalTable.AOI(obj.tableIndex) = AOISet(AOIid);

                       % Set the AOI Gaze time
                       obj.finalTable.AOI_Time(obj.tableIndex) = obj.outputTable.(gazetime(phase, AOIid))(index);
                       timeAOI = obj.finalTable.AOI_Time(obj.tableIndex);
                       
                       % Sum the total
                       sumTime = 0;
                       for set = 1:length(gazetime(phase,:))

                           sumTime = obj.outputTable.(gazetime(phase, set))(index) + sumTime;

                       end
                       
                       % Set the total time
                       obj.finalTable.TotalTrialTime(obj.tableIndex) = sumTime;
                       
                        % Set the Precentage AOI time
                       obj.finalTable.PercentageAOI_TIME(obj.tableIndex) = (timeAOI / sumTime) * 100;
                       
                       % Set the hesitancy time
                       obj.finalTable.HesistencyTime(obj.tableIndex) = obj.outputTable.(hesitancyTime(phase))(index);
 
                       % Set the average heart rate
                       obj.finalTable.AverageHeartRate(obj.tableIndex) = obj.outputTable.(heartRate(phase))(index);

                       % Set the average galvanic skin rate
                       obj.finalTable.AverageGalvanicSkinResponse(obj.tableIndex) = obj.outputTable.(galvanicSkinRate(phase))(index);

                       % Set the inside AOI number of fixations for cues
                       obj.finalTable.AOI_FixationLastInside(obj.tableIndex) = obj.outputTable.(AOIFixationLastInside(phase, AOIid))(index);
                       InsideAOI = obj.finalTable.AOI_FixationLastInside(obj.tableIndex);
                       
                       % Set the outside AOI number of fixations for cues
                       obj.finalTable.AOI_FixationLastOutside(obj.tableIndex) = obj.outputTable.(AOIFixationLastOutside(phase, AOIid))(index);
                       OutsideAOI = obj.finalTable.AOI_FixationLastOutside(obj.tableIndex);
                       
                       % Set the total fixation
                       obj.finalTable.TotalFixation(obj.tableIndex) = obj.outputTable.(totalFixationTime(phase))(index);
                       
                       % Set the average fixation length
                       if timeAOI ~= 0
                           obj.finalTable.AOI_AverageFixationLength(obj.tableIndex) = timeAOI / (InsideAOI + OutsideAOI);
                       else
                           obj.finalTable.AOI_AverageFixationLength(obj.tableIndex) = 0;
                       end

                       % Set the number of mazes
                       obj.finalTable.TotalNumberMazes(obj.tableIndex) = obj.nMazes;
                       
                       obj.tableIndex = obj.tableIndex + 1;
                       
                   end
                   
               end
               
           end
 
               
       end
       
       function gazeObject = gazeInRect(~, rect, xPos, yPos)
           
           gazeObject = -1;
           
           for index = 1:length(rect(:, 1))
               
               % Initialize bounding box to current iteration of cue
               box = rect(index, :);
               
               % Set the corresponding X/Y vertices of the bounding box
               xVertices = [ box(1), box(1), box(3), box(3), box(1)];
               yVertices = [ box(2), box(4), box(4), box(2), box(2)];
               
               in = inpolygon(xPos, yPos, xVertices, yVertices);
               
               if in
                   
                   gazeObject = index;
                   
                   break;
                   
               end
               
           end
           
       end
       
       function SaveToFile(obj)
            
            % Save header
            if ~exist(fullfile(obj.dataPath, obj.proccessed, obj.saveAsName),'file')
            
                fid = fopen(fullfile(obj.dataPath, obj.proccessed, obj.saveAsName), 'at');
                
                if (fid == -1)
                    
                    error('Cannot open data file');
                    
                else
                    
                    obj.PrintHeader(fid);
                    fclose(fid);
                    
                end
                
            end
            
            % Save data
            fid = fopen(fullfile(obj.dataPath, obj.proccessed, obj.saveAsName), 'at');
            
            if (fid == -1)
                
                error('Cannot open data file');
                
            else
                
                obj.PrintData(fid);
                fclose(fid);
                
            end
            
        end
        
        
        function PrintHeader(~, fid)
           
            dataFileHeaders = strcat(...
                'PatricpantID,\t',...
                'RecordingGazePointID,\t',...
                'Condition,\t',...
                'LearningVsPerformance,\t',...
                'MazeOrder,\t',...
                'MazeIdentity,\t',...
                'AOI,\t',...
                'AOI_Time(s),\t',...
                'TotalTrialTime(s),\t',...
                'PercentageAOI_TIME(s),\t',...
                'HesistencyTime(s),\t',...
                'AverageHeartRate,\t',...
                'AverageGalvanicSkinResponse,\t',...
                'AOI_FixationLastInside,\t',...
                'AOI_FixationLastOutside,\t',...
                'TotalFixation,\t',...
                'AOI_AverageFixationLength,\t',...
                'TotalNumberMazes\n'...
                );
        
            fprintf(fid, dataFileHeaders);
            
        end
        
        function PrintData(obj, fid)
            
            tableSize = obj.tableIndex - 1;
            
            for trialIndex = 1:tableSize

                
                fprintf(fid, '%s,\t', obj.finalTable.PatricpantID(trialIndex));
                fprintf(fid, '%s,\t', obj.finalTable.RecordingGazePointID(trialIndex));
                fprintf(fid, '%s,\t', obj.finalTable.Condition(trialIndex));
                fprintf(fid, '%s,\t', obj.finalTable.LearningVsPerformance(trialIndex));
                fprintf(fid, '%i,\t', obj.finalTable.MazeOrder(trialIndex));
                fprintf(fid, '%i,\t', obj.finalTable.MazeIdentity(trialIndex));
                fprintf(fid, '%s,\t', obj.finalTable.AOI(trialIndex));
                fprintf(fid, '%3.4f,\t', obj.finalTable.AOI_Time(trialIndex));
                fprintf(fid, '%3.4f,\t', obj.finalTable.TotalTrialTime(trialIndex));
                fprintf(fid, '%4.2f,\t', obj.finalTable.PercentageAOI_TIME(trialIndex));
                fprintf(fid, '%3.4f,\t', obj.finalTable.HesistencyTime(trialIndex));
                fprintf(fid, '%3.4f,\t', obj.finalTable.AverageHeartRate(trialIndex));
                fprintf(fid, '%3.4f,\t', obj.finalTable.AverageGalvanicSkinResponse(trialIndex));
                fprintf(fid, '%i,\t', obj.finalTable.AOI_FixationLastInside(trialIndex));
                fprintf(fid, '%i,\t', obj.finalTable.AOI_FixationLastOutside(trialIndex));
                fprintf(fid, '%i,\t', obj.finalTable.TotalFixation(trialIndex));
                fprintf(fid, '%3.4f,\t', obj.finalTable.AOI_AverageFixationLength(trialIndex));
                fprintf(fid, '%i\n', obj.finalTable.TotalNumberMazes(trialIndex));
                
            end
            
        end
       
       %******************** OLD FUNCTIONS******************
       
      % preallocate memeory to arrays
       function obj = Preallocate(obj)
           
           % Build cell array
            dataSize = numel(obj.dataSet);
            numFixation = numel(obj.sumFixation);

            % Base Data
            obj.TIME = zeros(dataSize, 1);
            obj.FPOGX = zeros(dataSize, 1);
            obj.FPOGY = zeros(dataSize, 1);
            obj.FPOGS = zeros(dataSize, 1);
            obj.FPOGD = zeros(dataSize, 1);
            obj.FPOGID = zeros(dataSize, 1);
            obj.FPOGV = zeros(dataSize, 1);
            
            % First Cue
            obj.OBJECT_1.xMin = zeros(dataSize, 1);
            obj.OBJECT_1.xMax = zeros(dataSize, 1);
            obj.OBJECT_1.yMin = zeros(dataSize, 1);
            obj.OBJECT_1.yMax = zeros(dataSize, 1);

            % Second Cue
            obj.OBJECT_2.xMin = zeros(dataSize, 1);
            obj.OBJECT_2.xMax = zeros(dataSize, 1);
            obj.OBJECT_2.yMin = zeros(dataSize, 1);
            obj.OBJECT_2.yMax = zeros(dataSize, 1);

            % Distal Cue
            obj.DISTAL.xMin = zeros(dataSize, 1);
            obj.DISTAL.xMax = zeros(dataSize, 1);
            obj.DISTAL.yMin = zeros(dataSize, 1);
            obj.DISTAL.yMax = zeros(dataSize, 1);

            % Fixation IDs
            obj.fixation.ID = zeros(numFixation, 1);
            obj.fixation.duration = zeros(numFixation, 1);
            obj.fixation.start = zeros(numFixation, 1);
            obj.fixation.end = zeros(numFixation, 1);
           
       end
       
       % Parse the fixation data, ID's and duration
       function obj = ParseFixations(obj)
           
           % Parse fixation ID table, skip headers
            for i = 2:numel(obj.sumFixation)

                % Split data columns by delimiter ',', csv file
                fixationEntry = split(obj.sumFixation(i), ',');
                fixationEntry = fixationEntry.';

                % Build fixation struct
                obj.fixation.duration(i) = str2double(fixationEntry(7));
                obj.fixation.ID(i) =  str2double(fixationEntry(8));
            end
           
       end
       
       % Parse raw data into arays including fixation start and stop times
       function obj = ParseRawData(obj)
           
           tagX = 'X MIN'; % Tag used to track data entries
           tagStart = 'START'; % Search for beginning of maze
           tagEnd = 'END'; % Search for beginning of maze
           tagCue = '.OBJ'; % Track cues for each maze

            id = 1;
            userRow = find(contains(split(obj.dataSet(1), ','), 'USER')); % Find beginning of user data

            % Parse fixation all gazes table, skip headers
            for j =2:numel(obj.dataSet)

                % Split data columns by delimiter ',', csv file
                 rowEntry = split(obj.dataSet(j), ',');
                 rowEntry = rowEntry.';

                 % Raw Data
                obj.TIME(j) = str2double(rowEntry(3));
                obj.FPOGX(j) = str2double(rowEntry(4));
                obj.FPOGY(j) = str2double(rowEntry(5));
                obj.FPOGS(j) = str2double(rowEntry(6));
                obj.FPOGD(j) = str2double(rowEntry(7));
                obj.FPOGID(j) = str2double(rowEntry(8));
                obj.FPOGV(j) = str2double(rowEntry(9));

                % Fixation time stamps

                if obj.fixation.ID(id) ~= obj.FPOGID(j)

                    % Search for ID entry number
                    id = find(obj.fixation.ID == obj.FPOGID(j));

                end

                % Ensure the first entry is the first fixation from fixation data sheet
                if  obj.FPOGID(j) >= obj.fixation.ID(1)

                    % Initialize start value
                    if obj.fixation.start(id) == 0

                        obj.fixation.start(id) = j;

                    else

                        % Update end value
                        obj.fixation.end(id) = j;

                    end

                end
                
                % Track start of mazes
                if contains(rowEntry{userRow}, tagStart)
                    
                    if contains(rowEntry{userRow}, 'PRACTICE', 'IgnoreCase', true)
                        
                        obj.maze{(end + 1), 1} = strcat('PRACTICE -', rowEntry{userRow + 1});
                        
                    else
                        
                        obj.maze{(end + 1), 1} = strcat('EXPERIMENT -',rowEntry{userRow + 2});

                    end
                    
                    obj.maze{(end), 2} = j;
                    
                end
                
                % Track end of mazes
                if contains(rowEntry{userRow}, tagEnd)
                    
                    obj.maze{(end), 3} = j;
                    
                end
                
                % Track names of objects used in mazes
                if contains(rowEntry{userRow}, tagCue)
                    
                    obj.maze{(end), 4} = rowEntry{userRow};
                    obj.maze{(end), 5} = 0;
                    obj.maze{(end), 6} = rowEntry{userRow + 6};
                    obj.maze{(end), 7} = 0;
                    obj.maze{(end), 8} = 'DISTAL_CUE(MOON)';
                    obj.maze{(end), 9} = 0;
                    
                end
                
                %Parsing XMIN, XMAX, YMIN, YMAX values for all cues
                property = fieldnames(obj.OBJECT_1);
                numCols = numel(property) * 2;
                
                % First Cue
                if strcmp(tagX, rowEntry{userRow})
                    n = 1;
                    for index = 1:2:numCols
                        
                        obj.OBJECT_1.(property{n})(j) = str2double(rowEntry(index));
                        n = n + 1;
                    end

                end

                % Second Cue
                cueTwoStart = userRow + 8;
                  if numel(rowEntry) > (cueTwoStart) && strcmp(tagX, rowEntry{cueTwoStart})
                      n = 1;
                     for index = (cueTwoStart + 1):2:(cueTwoStart + numCols)

                        obj.OBJECT_2.(property{n})(j) = str2double(rowEntry(index));
                        
                        n = n + 1;

                    end

                  end

                % Distal Cue
                distalStart = userRow + 16;
                  if numel(rowEntry) > (distalStart) && strcmp(tagX, rowEntry{distalStart})
                      n = 1;
                    for index = (distalStart + 1):2:(distalStart + numCols)
                        
                        obj.DISTAL.(property{n})(j) = str2double(rowEntry(index));
                        
                        n = n + 1;
                        
                    end

                  end
                

            end
           
       end
       
       function obj = GazeDuration(obj)
           
           %{ 
            Note The time elapsed in seconds since the last system initialization or calibration. 
            The time stamp is recorded at the end of the transmission of the image from camera to computer. (Gazepoint API - 5.2 TIME)
            **There the current time to the most recent is used as the
            duration of individual gazes.
           %}

           for i = 1:numel(obj.maze(:,1))
               
               startMaze = obj.maze{i, 2};
               endMaze = obj.maze{i, 3};
               fprintf('start = %d\n', startMaze);

               for j = startMaze:endMaze
                   
                   % check gaze is valid and objects on screen
                   if obj.FPOGV(j) == 0
                       continue
                   end

                   % Duration
                   time = obj.TIME(j) - obj.TIME(j-1);
                   
                   for n = 5:2:9
                       
                       if isempty(obj.maze{(i), n})
                           obj.maze{(i), n} = 0;
                       end
                       
                   end
                   
                   initMazeTime = [obj.maze{(i), 5} obj.maze{(i), 7} obj.maze{(i), 9}];
                   object = [obj.OBJECT_1 obj.OBJECT_2 obj.DISTAL];
                   x = obj.FPOGX;
                   y = obj.FPOGY;
                   
                   mazeTime = Gazing(obj, object, initMazeTime, x, y, j, time);
                   
                   n = 1;
                   for index = 5:2:9
                       
                       obj.maze{(i), index} = mazeTime(n);
                       n = n + 1;
                       
                   end
                   
               end
               
           end
       end
       
       function [MazeTime] = Gazing(obj, object, initMazeTime, x, y, j, time)
           
           MazeTime = zeros(numel(object), 1);

           for i = 1:numel(MazeTime)
               
               MazeTime(i) = GazingHelper(obj, object(i), initMazeTime(i), x, y, j, time);
               
           end
           
       end
       
       function [MazeTime] = GazingHelper(~, object, mazeTime, x, y, j, time)
           
           if  ((object.xMin(j) < x(j) && x(j) < object.xMax(j)) && (object.yMin(j) < y(j) && y(j) < object.yMax(j)))
               MazeTime = mazeTime + time;
           else
               MazeTime = mazeTime;
               
           end
           
       end
       
       % Open the file from the given data path, for text scan
       function [InputData] = OpenFiles(~, path)
           
           InputData = {}; % Initialize incase a error occurs
           
           % Open file path
           fid = fopen(path);

           % Error check if the file was able to open
           if fid == -1

           else
               
               temp = textscan(fid, '%s', 'Delimiter', '\r');
               temp = temp{1};
               InputData = temp;
               fclose(fid);

              
           end
           
       end
       
   end
   
   
end




