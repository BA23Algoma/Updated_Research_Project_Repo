% ProcessData

% Determine number of fixation to process/split data
fixSize = numel(ans.fixation.ID);

% Initialize object data by preallocating
Object_1.ID = ans.fixation.ID;
Object_1.x = zeros(fixSize, 1);
Object_1.y = zeros(fixSize, 1);

% arbitrariy selected, need reference for when cue is on screen
object = ans.Object_1.xMin;

FPOGX = ans.FPOGX;
FPOGY = ans.FPOGY;

% Loop average fixations
for i = 2:fixSize
    
    % Create variables for the start and end of fixation in array
    start = ans.fixation.start(i);
    stop = ans.fixation.end(i);
    duration = stop - start;
    
    
    % Allocate for object based on fixation duration
    temp = object(start:stop);
    disp(temp);
    
    % Ensure object appeared on screen for sufficient peroid of time
    [~,~,nonZeros] = find(temp);
    
    
    % Needed percentage to qualify as fixation
    p = 0.75;
    
    % If number of fixations is insuffecient move to next fixation
    if numel(nonZeros) < (p * (duration))
        
        continue;
        
    end
    
    
    tempx = mean(FPOGX(start:end));
    tempy = mean(FPOGY(start:end));
    
    Object_1.x(i) = mean(tempx);
    Object_1.y(i) = mean(tempy);
    disp(i);
    disp(Object_1.x(i));
    
end

