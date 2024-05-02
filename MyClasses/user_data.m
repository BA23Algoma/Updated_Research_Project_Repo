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
        Object_1;
        Object_2;
        Distal;
        fixation;

    end
    
   methods
       
       function obj = user_data()
       
           % Retreive path to data and fixation files
           %rawData = findFiles('Raw Data');
           %fixData = findFiles('Fixation Data');
           
           rawData = 'GazePoint User Data\Test Subject 1\result\User 0_all_gaze.csv';
           fixData = 'GazePoint User Data\Test Subject 1\result\User 0_fixations.csv';
           
           % Text scan the data files
           obj.dataSet = obj.openFiles(rawData);
           obj.sumFixation = obj.openFiles(fixData);
           
           % Preallocate array values
           obj = obj.preallocate();
           
           % Parse raw and fixation data
           obj = obj.parseFix();
           obj =  obj.parseRawData();
            
            
       end
       
        % Retrieve Data Path to File
       function [filePath] = findFiles(type)
           
           % Build string for menu of graphical interface
           strInstr = strcat('Select ', type, ' file');
           [file, path] = uigetfile('', strInstr); % retrieve file
            
           
           % Return file path
           filePath = strcat(path, file);
           
       end
       
       % Open the file from the given data path
       function [InputData] = openFiles(~, path)
           
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
       function obj = preallocate(obj)
           
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
            obj.Object_1.xMin = zeros(dataSize, 1);
            obj.Object_1.xMax = zeros(dataSize, 1);
            obj.Object_1.yMin = zeros(dataSize, 1);
            obj.Object_1.yMax = zeros(dataSize, 1);

            % Second Cue
            obj.Object_2.xMin = zeros(dataSize, 1);
            obj.Object_2.xMax = zeros(dataSize, 1);
            obj.Object_2.yMin = zeros(dataSize, 1);
            obj.Object_2.yMax = zeros(dataSize, 1);

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
       function obj = parseFix(obj)
           
           % Parse fixation ID table, skip headers
            for i = 2:numel(obj.sumFixation)

                % Split data columns by delimiter ',', csv file
                fixationEntry = split(obj.sumFixation(i), ',');
                fixationEntry = fixationEntry.';

                % Build fixation struct
                obj.fixation.ID(i) =  str2double(fixationEntry(8));
                obj.fixation.duration(i) = str2double(fixationEntry(7));
            end
           
       end
       
       % Parse raw data into arays including fixation start and stop times
       function obj = parseRawData(obj)
           
           tag = 'X MIN'; % Tag used to track data entries

            id = 1;

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


                % First Cue
                if strcmp(tag, rowEntry{10})

                    obj.Object_1.xMin(j) = str2double(rowEntry(11));
                    obj.Object_1.xMax(j) = str2double(rowEntry(13));
                    obj.Object_1.yMin(j) = str2double(rowEntry(15));
                    obj.Object_1.yMax(j) = str2double(rowEntry(17));

                end

                % Second Cue
                  if numel(rowEntry) > 18 && strcmp(tag', rowEntry{18})

                    obj.Object_2.xMin(j) = str2double(rowEntry(19));
                    obj.Object_2.xMax(j) = str2double(rowEntry(21));
                    obj.Object_2.yMin(j) = str2double(rowEntry(23));
                    obj.Object_2.yMax(j) = str2double(rowEntry(25));

                  end

                % Distal Cue
                  if numel(rowEntry) > 26 && strcmp(tag, rowEntry{26})

                    obj.Distal.xMin(j) = str2double(rowEntry(27));
                    obj.Distal.xMax(j) = str2double(rowEntry(29));
                    obj.Distal.yMin(j) = str2double(rowEntry(31));
                    obj.Distal.yMax(j) = str2double(rowEntry(33));

                  end


            end
           
       end
       
       
   end
   
   
end




