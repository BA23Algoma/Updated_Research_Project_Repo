% obj = Maze([fileName], [checkCollisionFlag])
classdef Maze
    
    properties (GetAccess = public, SetAccess = protected)
        
        % User-defined objects
        checkCollisionFlag      = 1;
        normalWallArray;
        targetWallArray;
        tripWireArray;
        distalCue;
        perCue;
        
        % Built-in objects
        depth;
        fileName;
        isLoaded                = 0;
        isCompleteFlag          = 0;
        filePrefix;
        nWalls;
        nNormalWalls;
        pathName                = 'Mazes';
        nTargetWalls;
        nTripWires;
        tripCount;
        width;
        
    end
    
    
    properties (Constant)
        
        fileNameSuffix      = '.rev.txt';
        
    end
    
    methods
        
        function obj = Maze(varargin)
            
            if nargin > 0
                
                obj.fileName = varargin{1};
                
            end            
                        
            if ~isempty(obj.fileName)
                
                obj = Load(obj);
                
            end                       
            
            if nargin > 1
                
                obj.checkCollisionFlag = varargin{2};                
                
            end
            
        end
        
    end
    
    
    methods
        
        function [coordPoll, isCompleteFlag, stats] = Explore(obj, render, player, inputDevice, coordPollTimeLimit, coordPollInterval, nowNum, ipClient)
            
            coordPoll = CoordPoll(coordPollTimeLimit, coordPollInterval, nowNum);
            
            player.previousPos = [0 0];
            
            if ~obj.isLoaded
                
                error('Maze must be loaded before it can be explored');
                
            end
            
            t0 = GetSecs;
            tDelta = 0;
            coordPoll = coordPoll.Start();
            while 1
                                                
                coordPoll = coordPoll.Update(player, render);
                
                obj = TripWireCheck(obj, player);
                
                if coordPoll.timeoutFlag
                    
                    coordPoll = coordPoll.Stop();
                    
                    tripSum = sum( [obj.tripWireArray(:).tripCount] );
                    
                    stats = [tDelta tripSum];
                    
                    isCompleteFlag = 0;
                    
                    return;
                    
                else
                    
                    [proposedPosition, proposedHeading, quitCode] = inputDevice.PollPlayer(player, render, obj);
                    
                    if quitCode
                        
                        render.Close();
                        error('User terminated experiment');
                        
                    end
                    
                    player.proposedPos = proposedPosition;
                    player.heading = proposedHeading;
                    
                    if obj.checkCollisionFlag
                        
                        [collisionFlag, exitCode] = CollisionCheck(obj, player);
                        
                        if exitCode
                            
                            coordPoll = coordPoll.Stop();
                            
                            tripSum = sum( [obj.tripWireArray(:).tripCount] );
                            
                            stats = [tDelta tripSum];
                            
                            isCompleteFlag = 1;
                            
                            return;
                            
                        elseif collisionFlag
                            
                            player.proposedPos = player.previousPos;
                            
                        else
                            
                            player.proposedPos = proposedPosition;
                            
                        end
                        
                    end
                    
                    player.nextPos = player.proposedPos;
                    
                    player = player.UpdateState();
                                                            
                    render.UpdateDisplay(player, obj, ipClient);
                    
                    player.previousPos = player.nextPos;
                    
                    tDelta = GetSecs - t0;
                    
                end
                
            end
                        
        end
        
        
        function Tour(obj, mazeTour, render, player, inputDevice)
            
            for frameIndex = 1:mazeTour.nFrames
                
                [~, ~, quitCode] = inputDevice.PollPlayer(player, render, obj);
                
                if quitCode
                    
                    render.Close();
                    error('User terminated experiment');
                    
                end
                
                
                player.nextPos = mazeTour.coord(frameIndex, 1:2);
                player.heading = mazeTour.coord(frameIndex, 3);
                
                render.UpdateDisplay(player, obj);
                
            end
            
        end
        
        
        function Draw(obj)
            
            if ~isempty(obj.nWalls)
                
                for normalWallIndex = 1:obj.nNormalWalls
                    
                    line([-obj.normalWallArray(normalWallIndex).p1(1) -obj.normalWallArray(normalWallIndex).p2(1)], [obj.normalWallArray(normalWallIndex).p1(2) obj.normalWallArray(normalWallIndex).p2(2)], 'Color', 'k', 'LineWidth', 2);     
                end
                
                
                for targetWallIndex = 1:obj.nTargetWalls
                    
                    line([-obj.targetWallArray(targetWallIndex).p1(1) -obj.targetWallArray(targetWallIndex).p2(1)], [obj.targetWallArray(targetWallIndex).p1(2) obj.targetWallArray(targetWallIndex).p2(2)], 'Color', 'b', 'LineWidth', 2);

                end
                
                
                for tripWireIndex = 1:obj.nTripWires
                    
                    line([-obj.tripWireArray(tripWireIndex).p1(1) -obj.tripWireArray(tripWireIndex).p2(1)], [obj.tripWireArray(tripWireIndex).p1(2) obj.tripWireArray(tripWireIndex).p2(2)], 'Color', 'r', 'LineWidth', 1);
                    
                end
                
                for i = 1:numel(obj.distalCue.x)

                    radius = 0.15;
                    t = 0:pi/50:2*pi;
                    
                    %Draw distal cue
                      xDistal = radius*cos(t) - obj.distalCue.x(i);
                      yDistal = radius*sin(t) + obj.distalCue.y(i);
                     patch(xDistal, yDistal, 'red');

                end
                
                for i= 1:numel(obj.perCue.x)
                    
                    % Draw proximal cue
                    xPrxCue = radius*cos(t) - obj.perCue.x(i);
                    yPrxCue = radius*sin(t) + obj.perCue.y(i);
                    patch(xPrxCue, yPrxCue, 'blue');
                    
                end

                
            else
                
                figure;
                
            end
            
        end
        
        
%         function obj = VectorizeWalls(obj)
%             
%             obj.normalWallMatrix   = WallArray(obj.normalWallArray);
%             obj.targetWallMatrix   = WallArray(obj.targetWallArray);
%             obj.tripWireMatrix     = WallArray(obj.tripWireArray); 
%             
%         end
        
        
        function obj = Load(obj)
            
            obj.filePrefix = MazeFilePrefix(obj);
            
            fid = fopen(fullfile(obj.pathName, obj.fileName), 'rt');
            fprintf(obj.pathName);
             fprintf('\n');
            fprintf(obj.fileName);
            if (fid ~= -1)

                fgets(fid); % Skip comment line
                s = fgets(fid);
                a = sscanf(s, '%i');
                obj.width = a(1);
                obj.depth = a(2);
                obj.nWalls = a(4);
                obj.nTripWires = a(5);
                
                % Walls
                obj.nNormalWalls = obj.nWalls-3;
                obj.nTargetWalls = 3;
                obj.normalWallArray = Wall(obj.nNormalWalls, 1);
                obj.targetWallArray = Wall(obj.nTargetWalls, 1);
                
                normalWallIndex = 1;
                targetWallIndex = 1;
                fgets(fid); % Skip comment line

                for wallIndex = 1:obj.nWalls

                    
                    s = fgets(fid);
                    [vertices,~, ~, nextIndex]= sscanf(s, '%f');
                    
                    thisWall = Wall;
                    
                    thisWall.p1(1) = -vertices(1);
                    thisWall.p1(2) = vertices(2);
                    thisWall.p2(1) = -vertices(3);
                    thisWall.p2(2) = vertices(4);
                    
                    % thisWall = thisWall.UpdateWall();
                    
                    textureStr = strcat(s(nextIndex:end));                    
                    if strcmp(textureStr, 'Rock.bmp')
                        
                        thisWall.type = 'normal';
                        thisWall = thisWall.Precompute;
                        obj.normalWallArray(normalWallIndex, 1) = thisWall;
                        
                        normalWallIndex = normalWallIndex + 1;
                        
                    elseif strcmp(textureStr, 'Cheese.bmp')
                        
                        thisWall.type = 'target';
                        thisWall = thisWall.Precompute;
                        obj.targetWallArray(targetWallIndex, 1) = thisWall;
                        
                        targetWallIndex = targetWallIndex + 1;
                        
                        
                    else
                     
                        error('Undefined wall string');
                        
                    end
                    
                end
                
                % Trip Wires
                obj.tripWireArray = TripWire(obj.nTripWires, 1);
                
                fgets(fid); % Skip comment line

                for tripWireIndex = 1:obj.nTripWires
                    
                    s = fgets(fid);
                    vertices = sscanf(s, '%f');
                    
                    thisTripWire = TripWire;
                    
                    thisTripWire.p1(1) = -vertices(1);
                    thisTripWire.p1(2) = vertices(2);
                    thisTripWire.p2(1) = -vertices(3);
                    thisTripWire.p2(2) = vertices(4);
                    
                    thisTripWire = thisTripWire.Precompute;
                    
                    obj.tripWireArray(tripWireIndex) = thisTripWire;
                    
                end

                % Distal Queue Locations

                 fgets(fid); % Skip comment line
                 s = fgets(fid);
                 d = sscanf(s, '%f');
                 obj.distalCue.x(1) = d(1);
                 obj.distalCue.y(1) = d(2);
                 obj.distalCue.x(2) = d(3);
                 obj.distalCue.y(2) = d(4);
                 obj.distalCue.x(3) = d(5);
                 obj.distalCue.y(3) = d(6);
                 obj.distalCue.x(4) = d(7);
                 obj.distalCue.y(4) = d(8);

                 % Peripheral Queue Locations

                 % Peripheral Cue 1
                 fgets(fid); % Skip comment line
                 b = fgets(fid);
                 [cue,~, ~, nextIndex]= sscanf(b, '%f');
                 obj.perCue.x(1) = cue(1);
                 obj.perCue.y(1) = cue(2);
                 obj.perCue.scale(1) = cue(3);
                 obj.perCue.rot(1) = cue(4);

                 objStr = strcat(b(nextIndex:end));
                 objStrCue = split(objStr);
                 obj.perCue.obj = objStrCue{1};
                 obj.perCue.tex = objStrCue{2};

                 %Peripheral Cue 2
                 fgets(fid); % Skip comment line
                 c = fgets(fid);
                 [cue,~, ~, nextIndex]= sscanf(c, '%f');
                 obj.perCue.x(2) = cue(1);
                 obj.perCue.y(2) = cue(2);
                 obj.perCue.scale(2) = cue(3);
                 obj.perCue.rot(2) = cue(4);

                 objStr = strcat(c(nextIndex:end));
                 objStrCue = split(objStr);
                 obj.perCue.objTwo = objStrCue{1};
                 obj.perCue.texTwo = objStrCue{2};
                
                fclose(fid);
                
                %obj = VectorizeWalls(obj);
                
                obj.isLoaded = 1;
                
            else
                
                error('Cannot load maze file');
                
            end
            
        end
        
        function filePrefix = FilePrefix(obj)
            
            filePrefix = obj.fileName(1:strfind(obj.fileName, obj.fileNameSuffix)-1);
            
        end
        
        function obj = TripWireCheck(obj, player)
            
            for tripWireIndex = 1:obj.nTripWires
                
                thisTripWire = obj.tripWireArray(tripWireIndex);
                
                x0 = thisTripWire.p1(1); x1 = thisTripWire.p2(1); z0 = thisTripWire.p1(2); z1 = thisTripWire.p2(2);
                
                % Translate everything so that line segment start point to (0, 0)
                a = x1 - x0; % Line segment end point horizontal coordinate
                b = z1 - z0; % Line segment end point vertical coordinate
                
                % Criterion is that the player center (not the circle edge)
                % be on the tripwire, so we subtract proposed player position by R
                % which is the same as pushing back the tripwire by R
                proposedV = player.proposedPos - player.previousPos;
                
                if (player.norm ~= 0.0)

                    % Subtract the cosine residual of R from from velocity's deltaX
                    c = proposedV(1) * (1 - player.bodyRadius / player.norm);
                    
                    % Add back the reduced deltaX
                    c = player.previousPos(1) + c;
                    
                    % Translate to tripwire segment start point
                    c = c - x0;
                    
                    % Subtract the sine residual of R from from velocity's
                    % deltaY
                    d = proposedV(2) * (1 - player.bodyRadius / player.norm);
                    
                    % Add back the reduced deltaY
                    d = d + player.previousPos(2);
                    
                    % Translate to tripwire segment start point
                    d = d - z0;
                    
                else                    
                    
                    c = player.proposedPos(1) - x0; % Circle center horizontal coordinate
                    d = player.proposedPos(2) - z0; % Circle center vertical coordinate
                
                end
                
                isCollision = Maze.CollisionDetect(a, b, c, d, player.bodyRadiusSquared);
                
                if isCollision
                    
                    thisTripWire.collisionFlag = 1;
                    
                    if (thisTripWire.tripFlag == 0) && (thisTripWire.collisionFlag == 1)
                        
                        thisTripWire.tripFlag = 1;
                        thisTripWire.tripCount = thisTripWire.tripCount + 1;
                    end
                    
                else
                    
                    if (thisTripWire.tripFlag == 1) && (thisTripWire.collisionFlag == 0)
                    
                        thisTripWire.tripFlag = 0;
                        
                    end
                    
                end                    
                
                obj.tripWireArray(tripWireIndex) = thisTripWire;
                
            end
            
        end
        
        
        function [collisionFlag, exitCode] = CollisionCheck(obj, player)
            
            exitCode = 0;
             
            % Normal walls
            collisionFlag = 0;
            for wallIndex = 1:obj.nNormalWalls
                
                thisWall = obj.normalWallArray(wallIndex);
                
                x0 = thisWall.p1(1); x1 = thisWall.p2(1); z0 = thisWall.p1(2); z1 = thisWall.p2(2);
                
                % Translate everything so that line segment start point to (0, 0)
                a = x1 - x0; % Line segment end point horizontal coordinate
                b = z1 - z0; % Line segment end point vertical coordinate
                c = player.proposedPos(1) - x0; % Circle center horizontal coordinate
                d = player.proposedPos(2) - z0; % Circle center vertical coordinate
                
                isCollision = Maze.CollisionDetect(a, b, c, d, player.bodyRadiusSquared);
                
                if isCollision
                    
                    collisionFlag = 1;
                    return;
                    
                end
                
            end
            
            % Target walls
            for wallIndex = 1:obj.nTargetWalls
                
                thisWall = obj.targetWallArray(wallIndex);
                
                x0 = thisWall.p1(1); x1 = thisWall.p2(1); z0 = thisWall.p1(2); z1 = thisWall.p2(2);
                
                % Translate everything so that line segment start point to (0, 0)
                a = x1 - x0; % Line segment end point horizontal coordinate
                b = z1 - z0; % Line segment end point vertical coordinate
                c = player.proposedPos(1) - x0; % Circle center horizontal coordinate
                d = player.proposedPos(2) - z0; % Circle center vertical coordinate
                
                isCollision = Maze.CollisionDetect(a, b, c, d, player.bodyRadiusSquared);
                
                if isCollision
                    
                    collisionFlag = 1;
                    
                    if wallIndex == 2
                        
                        exitCode = 1;
                        
                    end
                    
                    return;
                    
                end
                
            end
            
            
        end
        
        
        function filePrefix = MazeFilePrefix(obj)
           
            endIndex = strfind(obj.fileName, obj.fileNameSuffix) - 1;
            filePrefix = obj.fileName(1:endIndex);
            
        end        
        
    end
    
    methods (Static)
        
        function collisionFlag = CollisionDetect(a, b, c, d, rSqr)
            
            collisionFlag = 0;
            
            %     % Optional orientation computation
            %     circleSideIsRight = 0;
            %     if (d*a - c*b < 0)
            %
            %         % Circle center is on left side looking from (x0, z0) to (x1, z1)
            %         circleSideIsRight = 1;
            %
            %     end
            
            % If collision is possible
            thisIndex = find((d.*a - c.*b).*(d.*a - c.*b) <= rSqr * (a.*a + b.*b));
            
            a = a(thisIndex);
            b = b(thisIndex);
            c = c(thisIndex);
            d = d(thisIndex);
            
            startInside = (c.*c + d.*d <= rSqr);
            
            % Line segment start point is inside the circle
            
            endInside = ((a-c).*(a-c) + (b-d).*(b-d) <= rSqr);
            
            middleInside = (~startInside & ~endInside & c.*a + d.*b >= 0 & c.*a + d.*b <= a.*a + b.*b);
            
            if any( [any(startInside) any(endInside) any(middleInside)] )
                
                collisionFlag = 1;
                
            end
            
        end
        
                
%         function collisionFlag = CollisionCheckVec(player, wallMatrix)
%             
%             collisionFlag = 0;
%             
%             x0 = wallMatrix.p1(:, 1);
%             x1 = wallMatrix.p2(:, 1);
%             z0 = wallMatrix.p1(:, 2);
%             z1 = wallMatrix.p2(:, 2);
%             
%             % Translate everything so that line segment start point to (0, 0)
%             a = x1 - x0; % Line segment end point horizontal coordinate
%             b = z1 - z0; % Line segment end point vertical coordinate
%             c = player.proposedPos(1) - x0; % Circle center horizontal coordinate
%             d = player.proposedPos(2) - z0; % Circle center vertical coordinate
%             
%             isCollision = CollisionDetect(a, b, c, d, player.bodyRadius);
%             
%             if isCollision
%                 
%                 collisionFlag = 1;
%                 
%             end
%             
%         end
        
    end
    
end
