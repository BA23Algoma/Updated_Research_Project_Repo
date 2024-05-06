% User_Data_Class

classdef user_data
    
    properties
        dataSet;
        sumFixation;
        Time;
        FPOGX;
        FPOGY;
        FPOGS;
        FPOGD;
        FPOGID;
        FPOGV;
        maze;
        OBJECT_1;
        OBJECT_2;
        Distal;
        fixation;

    end
    
     properties (Constant = true)
    
        fileNameSuffix = '.summaryFile.txt';
        
        dataFileHeaders = strcat(...
            'ORDER\t',...
            'MAZE_NUMBER\t',...
            'PROXIMAL_CUE_1_TIME\t',...
            'PROXIMAL_CUE_1_TIME\t',...
            'DISTAL_CUE_1_TIME\t',...
            'NOW_NUM\n'...
            );
        
    end
    
   methods
       
       function obj = user_data()
       
           % Retreive path to data and fixation files
           %rawData = FindFiles('Raw Data');
           %fixData = FindFiles('Fixation Data');
           
           rawData = 'GazePoint User Data\Test Subject 2\result\User 2_all_gaze.csv';
           fixData = 'GazePoint User Data\Test Subject 2\result\User 2_fixations.csv';
           
           % Text scan the data files
           obj.dataSet = obj.OpenFiles(rawData);
           obj.sumFixation = obj.OpenFiles(fixData);
           
           % Preallocate array values
           obj = obj.Preallocate();
           
           % Parse raw and fixation data
           obj = obj.ParseFixations();
           obj = obj.ParseRawData();
           
           % Build summary data
           obj = obj.GazeDuration();
            
       end
       
        % Retrieve Data Path to File
       function [filePath] = FindFiles(type)
           
           % Build string for menu of graphical interface
           strInstr = strcat('Select ', type, ' file');
           [file, path] = uigetfile('', strInstr); % retrieve file
            
           
           % Return file path
           filePath = strcat(path, file);
           
       end
       
       % Open the file from the given data path
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
            obj.Time = zeros(dataSize, 1);
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
            obj.Distal.xMin = zeros(dataSize, 1);
            obj.Distal.xMax = zeros(dataSize, 1);
            obj.Distal.yMin = zeros(dataSize, 1);
            obj.Distal.yMax = zeros(dataSize, 1);

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
            userRow = 10; % Start of user row in data file

            % Parse fixation all gazes table, skip headers
            for j =2:numel(obj.dataSet)

                % Split data columns by delimiter ',', csv file
                 rowEntry = split(obj.dataSet(j), ',');
                 rowEntry = rowEntry.';

                 % Raw Data
                obj.Time(j) = str2double(rowEntry(3));
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
                    
                    if contains(rowEntry{10}, 'PRACTICE', 'IgnoreCase', true)
                        
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

                % First Cue
                if strcmp(tagX, rowEntry{userRow})

                    obj.OBJECT_1.xMin(j) = str2double(rowEntry(userRow + 1));
                    obj.OBJECT_1.xMax(j) = str2double(rowEntry(userRow + 3));
                    obj.OBJECT_1.yMin(j) = str2double(rowEntry(userRow + 5));
                    obj.OBJECT_1.yMax(j) = str2double(rowEntry(userRow + 7));

                end

                % Second Cue
                  if numel(rowEntry) > (userRow + 8) && strcmp(tagX, rowEntry{userRow + 8})

                    obj.OBJECT_2.xMin(j) = str2double(rowEntry(userRow + 9));
                    obj.OBJECT_2.xMax(j) = str2double(rowEntry(userRow + 11));
                    obj.OBJECT_2.yMin(j) = str2double(rowEntry(userRow + 13));
                    obj.OBJECT_2.yMax(j) = str2double(rowEntry(userRow + 15));

                  end

                % Distal Cue
                  if numel(rowEntry) > (userRow + 16) && strcmp(tagX, rowEntry{userRow + 16})

                    obj.Distal.xMin(j) = str2double(rowEntry(userRow + 17));
                    obj.Distal.xMax(j) = str2double(rowEntry(userRow + 19));
                    obj.Distal.yMin(j) = str2double(rowEntry(userRow + 21));
                    obj.Distal.yMax(j) = str2double(rowEntry(userRow + 23));

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
                   time = obj.Time(j) - obj.Time(j-1);
                   
                   % Check if gaze algins with objects
                   obj1 = obj.OBJECT_1;
                   obj2 = obj.OBJECT_2;
                   distal = obj.Distal;
                   x = obj.FPOGX;
                   y = obj.FPOGY;
                   tolX = 5 * eps(x); % Small comparison value for handling floating point cmoparision
                   tolY = 5 * eps(y);
                   
                   % Check if eye is gazing and update as needed
                   xMin = x - obj1.xMin(j);
                   xMax = obj1.xMax(j) - x;
                   yMin = y - obj1.yMin(j);
                   yMax = obj1.yMax(j) - y;
                   
                   disp(xMin)
                   
                   if  (0<xMin && xMin<1)
                       obj.maze{(i), 5} = time;
                       disp('first1');
                   end
                   
                   if  (x <= obj2.xMax(j))
                       obj.maze{(i), 5} = time;
                       disp('x');                       
                   end
                   
               end
               
           end
       end
       
       
       
   end
   
   
end




