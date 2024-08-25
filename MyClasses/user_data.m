% User_Data_Class

classdef user_data
    
    properties
        dataSet;
        sumFixation;
        outputTable;
        finalTable;
        tableIndex;
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
        LOC;
        inside;
        cue             = {'OBJECT_1', 'OBJECT_2', 'DISTAL'};
        limits          = {'xMin', 'xMax', 'yMin', 'yMax'};
        screenHalfs     = ["SKY", "GROUND"];

    end
    
     properties (Constant = true)
    
        fileNameSuffix = '.summaryFile.csv';
        dataPath       = 'GazePoint User Data';
        proccessed     = 'ProcessedData';
        
    end
    
   methods
       
       function obj = user_data()
       
           % Retreive path to data and fixation files
%           rawData = FindFiles('Raw Data');
%           fixData = FindFiles('Fixation Data');
           
%           rawData = 'GazePoint User Data\Sample Data\367259_all_gaze_edited.csv';
           fixData = 'GazePoint User Data\Sample Data\367259_fixations.csv';
           
           % Test raw data
           rawData = 'GazePoint User Data\Sample Data\User 22_all_gaze.csv';
           
           % Readtable to collect the data file information
%           obj.dataSet = obj.OpenFiles(rawData);
%           obj.sumFixation = obj.OpenFiles(fixData);
           obj.dataSet = readtable(rawData, 'PreserveVariableNames', true);
           obj.sumFixation = readtable(fixData, 'PreserveVariableNames', true);
           
           % Preallocate array values
%           obj = obj.Preallocate();
           
           % Collect raw data variable names
           varNames = obj.dataSet.Properties.VariableNames;
           
           % Replace TIME header with a simplier header ('TIME')
           matches = regexp(varNames,'^.*TIME.*$', 'match');
           timeHeader = ~cellfun(@isempty, matches);
           varNames{timeHeader} = 'TIME';
           obj.dataSet.Properties.VariableNames{timeHeader} = 'TIME';
           
           % Determine dataset size
           numRows = size(obj.dataSet);
           
           % Preallocate raw data with zeros
           obj = PreallocateVectoriztion(obj, numRows(1), varNames);
           
           % Preallocate cue data for min/max with zeros
           obj = PreallocateVectoriztion(obj, numRows(1));
                      
           % Parse raw and fixation data
%           obj = obj.ParseFixations();
%           Data = obj.ParseRawData(obj.dataSet, Data, varNames);
           
           obj = ParseRawDataVectorization(obj, varNames);
           
           % Build gaze time summary data
           obj = GazeDurationVectorization(obj);
           
           % Output Sorted Data Table
           fileName = strcat('1345_processed_data', obj.fileNameSuffix);
           
           fid = fopen( fullfile(obj.dataPath, obj.proccessed, fileName), 'at');
           writetable(obj.outputTable, fullfile(obj.dataPath, obj.proccessed, fileName));
           fclose(fid);
            
       end
       
        % Retrieve Data Path to File
       function [filePath] = FindFiles(type)
           
           % Build string for menu of graphical interface
           strInstr = strcat('Select ', type, ' file');
           [file, path] = uigetfile('', strInstr); % retrieve file
            
           
           % Return file path
           filePath = strcat(path, file);
           
       end
       
       % Open the file from the given data path, for text scan
       function [InputData] = OpenFiles(~, path)
           
           InputData = {}; % Initialize incase a error occurs
           
           % Open file path
           fid = fopen(path);

           % Error check if the file was able to open
           if fid == -1

                disp('Error, unable to open data file, check file name and location');

           else
               
               temp = textscan(fid, '%s', 'Delimiter', '\r');
               temp = temp{1};
               InputData = temp;
               fclose(fid);

              
           end
           
       end
       
       % prallocate memeory to arrays
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
           obj.inside = zeros(1, length(obj.cue));
           
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
                         disp(n);
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
       
           % Parse raw data into arays including fixation start and stop times
       function obj = ParseRawDataVectorization(obj, varNames)
           
           % Set the tags to search in input data
           
           tag = struct(...
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

           % Set number of rows and columns of table
           obj.outputTable = table('Size', [100 29],...
               'VariableNames', ["OrderNumber", "MazeNumber", "Cue1"...
               "Cue2", "LearningStart", "LearningEnd"...
               "ExperimentStart", "ExperimentEnd", "ExperimentCondition",...
               "OBJECT_1_LearningGazeTime", "OBJECT_1_ExperimentGazeTime",...
               "OBJECT_2_LearningGazeTime", "OBJECT_2_ExperimentGazeTime",...
               "DISTAL_LearningGazeTime", "DISTAL_ExperimentGazeTime",...
               "HesitancyTimeLearning", "HesitancyTimeExperiment",...
               "SkyTimeLearning","SkyTimeExperiment",...
               "GroundTimeLearning","GroundTimeExperiment",...
               "OBJECT_1_LearnFixationCount","OBJECT_2_LearnFixationCount",...
               "DISTAL_LearnFixationCount","OBJECT_1_ExpFixationCount",...
               "OBJECT_2_ExpFixationCount","DISTAL_ExpFixationCount"...
               "TotalFixationLearning","TotalFixationExperiment"],...
               'VariableTypes',{'double';'double';'string';'string';...
               'double';'double';'double';'double';'string';'double';...
               'double';'double';'double';'double';'double';'double';...
               'double';'double';'double';'double';'double';'double';...
               'double';'double';'double';'double';'double';'double';...
               'double'});

     %{      
           obj.outputTable = table('Size', [41 15],...
               'VariableNames', ["ID", "Condition",...
               "Learning_vs._Testing", "MazeOrder",...
               "MazeIdentity", "AOI", "AOI_Time", "HesistencyTime"...
               "Cue2", "LearningStart", "LearningEnd"...
               "ExperimentStart", "ExperimentEnd",...
               "OBJECT_1_LearningGazeTime", "OBJECT_1_ExperimentGazeTime",...
               "OBJECT_2_LearningGazeTime", "OBJECT_2_ExperimentGazeTime",...
               "DISTAL_LearningGazeTime", "DISTAL_ExperimentGazeTime",],...
               'VariableTypes',{'double';'double';'string';'string';'double'...
               ;'double';'double';'double';'string';'double';'double'...
               ;'double';'double';'double';'double'});
           %}
 
           obj.tableIndex = 1;
                      
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

%                    disp(splitData{j});

                end
                    
                % Split data columns by delimiter ':', csv file
                if contains(splitData{j}, ':')

                    % Determine if the string is the objects or cue limit
                    if  contains(splitData{j}, tag.Cue)

                        rowEntry = split(splitData{j}, [":"; "&"]);
                        obj.outputTable.Cue1(obj.tableIndex) = rowEntry{2};
                        obj.outputTable.Cue2(obj.tableIndex) = rowEntry{3};
                        
                    else
                        
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
                elseif contains(splitData{j}, tag.Condition)
                    
                    obj.condition = splitData{j};
                    
                % Track start of mazes
                elseif contains(splitData{j}, tag.Start)

                    if contains(splitData{j}, tag.Experiment, 'IgnoreCase', true)
                        
                        % Set the start of the experiment phase
                        obj.outputTable.ExperimentStart(obj.tableIndex) = j;
 %                       disp(splitData{j});
                        
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
                            pattern = 'NUMBER(\d*)';
                            orderNum = regexp(splitString(1), pattern, 'tokens');
                            obj.outputTable.OrderNumber(obj.tableIndex) = str2double(orderNum{1}{1});
     %                      disp(splitData{j});

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
                    
 %                    disp(splitData{j});
                    % Retrieve the value of hesitancy time
                    hesiPattern = 'OF-(\d*\.?\d+)';
                    hesiTime = regexp(splitData{j}, hesiPattern, 'tokens');
  %                  disp(str2double(hesiTime{1}{1}));
                    
                    if contains(splitData{j}, tag.HesitancyLearning, 'IgnoreCase', true)
                        
  %                      disp(splitData{j});
  %                      disp(obj.tableIndex);
                        obj.outputTable.HesitancyTimeLearning(obj.tableIndex) = str2double(hesiTime{1}{1});
                        
                        
                    else
                        
                        obj.outputTable.HesitancyTimeExperiment(obj.tableIndex) = str2double(hesiTime{1}{1});

                        % Increment the table index 
                        obj.outputTable.ExperimentCondition(obj.tableIndex) = obj.condition;
                        obj.tableIndex = obj.tableIndex + 1;
                        
                    end
                   
                    
                else
                    
                    % Do nothing
                    
                end              

            end
           
           
       end
       
       function obj = GazeDurationVectorization(obj)

           index = 1;
           
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
                       
                       % Set the eye location to the most prominent
                       % condition
                       if totalskyMatches < totalgroundMatches
                           
                           groundfield = find(groundMatches);
                           eyeLoc = groundfield(1);
                           
                       else
                           
                           skyfield = find(skyMatches);
                           eyeLoc = skyfield(1);
                           
                       end
                       
                   end
                   
                   % Get the average FPOG X/Y for current ID
                   avgFPOGX = mean(obj.FPOGX(startingIdIndex:endingIdIndex));
                   avgFPOGY = mean(obj.FPOGY(startingIdIndex:endingIdIndex));
                   
                   % Preallocate rects based on cues
                   boundingBox = zeros(length(obj.cue), length(obj.limits));
                   
                   % Construct the rects based on the cue bounding boxes
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
                   
                   % Determine if the FPOG was within a bounding box, which
                   % which bounding box eye lie within
                   AOI = gazeInRect(obj, boundingBox, avgFPOGX, avgFPOGY);
                   
                   %  Collect the column name for setting the values
                   columnNames = obj.outputTable.Properties.VariableNames;

                   for block = 1:length(obj.outputTable.OrderNumber)
                   
                       % Initialize maze block indices
                       learningStart = obj.outputTable.LearningStart(block);
                       learningEnd = obj.outputTable.LearningEnd(block);
                       ExpStart = obj.outputTable.ExperimentStart(block);
                       ExpEnd = obj.outputTable.ExperimentEnd(block);
                           
                       % Allocating duration 
                       if learningStart <= startingIdIndex && endingIdIndex <= learningEnd

                           % Ensure the FPOG was within one of the the bounding boxes
                           if AOI ~= -1 

                               % Count if gaze is ener new AOI
                               if obj.inside(AOI) == 0
               
                                   obj.inside(AOI) = 1;
                                   count = 1;
           
                               else
                                   
                                  count = 0;
           
                               end
                       
                               % Building column names
                               learningGaze = strcat(obj.cue(AOI), '_LearningGazeTime');
                               fixationAOI = strcat(obj.cue(AOI), '_LearnFixationCount');

                               % Find column in table
                               columnGaze = contains(columnNames, learningGaze);
                               columnFixation = contains(columnNames, fixationAOI);
                               
                               % Add duration to time block
                               obj.outputTable.(columnNames{columnGaze})(block) = obj.outputTable.(columnNames{columnGaze})(block) + duration;

                               % Add to fixation count
                               obj.outputTable.(columnNames{columnFixation})(block) = obj.outputTable.(columnNames{columnFixation})(block) + count;
                               
                           elseif ~isempty(eyeLoc) 
                               
                               % Reset object
                               obj.inside = [0,0,0];
                       
                               % Set the eye location based on user data
                               eyeLoc = eyeGaze(1);
                               
                               % Building column name
                               eyeLoc = strcat(eyeLoc,'TimeLearning');
                               
                               % Find column in table
                               column = contains(columnNames, eyeLoc, 'IgnoreCase', true);
                               
                               % Add duration to time block
                               obj.outputTable.(columnNames{column})(block) = obj.outputTable.(columnNames{column})(block) + duration;
                               
                           else
                               
                               % Do nothing
                               
                           end

                           % Find total learning fixationa column in table
                           columnTotalFix = contains(columnNames, "TotalFixationLearning");
                           
                           % Add to total number of fixations
                           obj.outputTable.(columnNames{columnTotalFix})(block) = obj.outputTable.(columnNames{columnTotalFix})(block) + 1;
                               

                       elseif ExpStart <= startingIdIndex && endingIdIndex <= ExpEnd
%                               helperStr = strcat(obj.cue(gazeObject), '...........', string(obj.FPOGID(endingIdIndex)));
%                               disp(helperStr);

                           % Ensure the FPOG was within one of the the bounding boxes
                           if AOI ~= -1 

                               % Count if gaze is ener new AOI
                               if obj.inside(AOI) == 0
               
                                   obj.inside(AOI) = 1;
                                   count = 1;
           
                               else
                                   
                                  count = 0;
           
                               end
                               
                               % Building column names
                               expGaze = strcat(obj.cue(AOI), '_ExperimentGazeTime');
                               fixationAOI = strcat(obj.cue(AOI), '_ExpFixationCount');
                               
                               % Find column in table
                               columnGaze = contains(columnNames, expGaze);
                               columnFixation = contains(columnNames, fixationAOI);

                               % Add duration to time block
                               obj.outputTable.(columnNames{columnGaze})(block) = obj.outputTable.(columnNames{columnGaze})(block) + duration;

                               % Add duration to time block
                               obj.outputTable.(columnNames{columnFixation})(block) = obj.outputTable.(columnNames{columnFixation})(block) + count;
                               
                           elseif ~isempty(eyeLoc) % Set the eye  location to sky or ground
                               
                               % Reset object
                               obj.inside = [0,0,0];
                       
                                % Set the eye location based on user data
                               eyeLoc = eyeGaze(1);
                               
                               % Building column name
                               eyeLoc = strcat(eyeLoc,'TimeExperiment');
                               
                               % Find column in table
                               column = contains(columnNames, eyeLoc, 'IgnoreCase', true);
                               
                               % Add duration to time block
                               obj.outputTable.(columnNames{column})(block) = obj.outputTable.(columnNames{column})(block) + duration;
                               
                           else
                               
                               % Do Nothing
                               
                           end
                           
                           % Find total experiment fixationa column in table
                           columnTotalFix = contains(columnNames, "TotalFixationExperiment");
                           
                           % Add to total number of fixations
                           obj.outputTable.(columnNames{columnTotalFix})(block) = obj.outputTable.(columnNames{columnTotalFix})(block) + 1;
                           
                       else

                           % do nothing

                       end
                     
                   end
                   
               end
               
           end
           
       end
       
       function obj = ConstructfinalTable(obj)
           
           % Set number of rows and columns of table
           obj.outputTable = table('Size', [100 21],...
               'VariableNames', ["ID", "Condition", "Learning_vs.Performance"...
               "MazeOrder", "MazeIdentity", "AOI", "AOI_Time",...
               "HesistencyTime", "TotalTrialTime", "AverageHeartRate",...
               "AverageGalvanicSkinResponse",...
               "OBJECT_1_LearningGazeTime", "OBJECT_1_ExperimentGazeTime",...
               "OBJECT_2_LearningGazeTime", "OBJECT_2_ExperimentGazeTime",...
               "DISTAL_LearningGazeTime", "DISTAL_ExperimentGazeTime",...
               "HesitancyTimeLearning", "HesitancyTimeExperiment",...
               "SkyTimeLearning","SkyTimeExperiment",...
               "GroundTimeLearning","GroundTimeExperiment"],...
               'VariableTypes',{'double';'double';'string';'string';...
               'double';'double';'double';'double';'string';'double';...
               'double';'double';'double';'double';'double';'double';...
               'double';'double';'double'});

     %{      
           obj.outputTable = table('Size', [41 15],...
               'VariableNames', ["ID", "Condition",...
               "Learning_vs._Testing", "MazeOrder",...
               "MazeIdentity", "AOI", "AOI_Time", "HesistencyTime"...
               "Cue2", "LearningStart", "LearningEnd"...
               "ExperimentStart", "ExperimentEnd",...
               "OBJECT_1_LearningGazeTime", "OBJECT_1_ExperimentGazeTime",...
               "OBJECT_2_LearningGazeTime", "OBJECT_2_ExperimentGazeTime",...
               "DISTAL_LearningGazeTime", "DISTAL_ExperimentGazeTime",],...
               'VariableTypes',{'double';'double';'string';'string';'double'...
               ;'double';'double';'double';'string';'double';'double'...
               ;'double';'double';'double';'double'});
           %}
 
               
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
                   x =  obj.FPOGX;
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
               disp('first1');
           else
               MazeTime = mazeTime;
               
           end
           
       end
       
       
       
   end
   
   
end




