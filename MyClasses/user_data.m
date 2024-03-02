% User_Data_Class


% Open Data File
fid = fopen('GazePoint User Data\Test Subject 2\result\User 2_all_gaze.csv');

% Write data from data file to dataSet
dataSet = textscan(fid, '%s', 'Delimiter', '\r');
dataSet = dataSet{1};
fclose(fid);

% Build cell array
size = numel(dataSet);

% Base Data
Time = zeros(size, 1);
FPOGX = zeros(size, 1);
FPOGY = zeros(size, 1);
FPOGS = zeros(size, 1);
FPOGD = zeros(size, 1);
FPOGID = zeros(size, 1);
FPOGV = zeros(size, 1);

% First Cue
Object_1.xMin = zeros(size, 1);
Object_1.xMax = zeros(size, 1);
Object_1.yMin = zeros(size, 1);
Object_1.yMax = zeros(size, 1);

% Second Cue
Object_2.xMin = zeros(size, 1);
Object_2.xMax = zeros(size, 1);
Object_2.yMin = zeros(size, 1);
Object_2.yMax = zeros(size, 1);

% Distal Cue
Distal.xMin = zeros(size, 1);
Distal.xMax = zeros(size, 1);
Distal.yMin = zeros(size, 1);
Distal.yMax = zeros(size, 1);

for i =2:size
     rowEntry = split(dataSet(i), ',');
     rowEntry = rowEntry.';
     
     % Base Data
    Time(i) = str2double(rowEntry(3));
    FPOGX(i) = str2double(rowEntry(4));
    FPOGY(i) = str2double(rowEntry(5));
    FPOGS(i) = str2double(rowEntry(6));
    FPOGD(i) = str2double(rowEntry(7));
    FPOGID(i) = str2double(rowEntry(8));
    FPOGV(i) = str2double(rowEntry(9));

    % First Cue
    if strcmp('X MIN', rowEntry{10})
        
        Object_1.xMin(i) = str2double(rowEntry(11));
        Object_1.xMAx(i) = str2double(rowEntry(13));
        Object_1.yMin(i) = str2double(rowEntry(15));
        Object_1.yMax(i) = str2double(rowEntry(17));
    
    end

    % Second Cue
      if numel(rowEntry) > 18 && strcmp('X MIN', rowEntry{18})
        
        Object_2.xMin(i) = str2double(rowEntry(19));
        Object_2.xMAx(i) = str2double(rowEntry(21));
        Object_2.yMin(i) = str2double(rowEntry(23));
        Object_2.yMax(i) = str2double(rowEntry(25));
    
      end

    % Distal Cue
      if numel(rowEntry) > 26 && strcmp('X MIN', rowEntry{26})
          
        Distal.xMin(i) = str2double(rowEntry(27));
        Distal.xMAx(i) = str2double(rowEntry(29));
        Distal.yMin(i) = str2double(rowEntry(31));
        Distal.yMax(i) = str2double(rowEntry(33));
    
      end
     

end

