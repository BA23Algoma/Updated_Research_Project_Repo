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
        completeWallArray;
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
        
        function [coordPoll, isCompleteFlag, stats, hesitantTime] = Explore(obj, render, player, inputDevice, coordPollTimeLimit, coordPollInterval, nowNum, ipClient)
            
            coordPoll = CoordPoll(coordPollTimeLimit, coordPollInterval, nowNum);
            
            player.previousPos = [0 0];
            
            if ~obj.isLoaded
                
                error('Maze must be loaded before it can be explored');
                
            end
            
            t0 = GetSecs;
            tDelta = 0;
            minTime = 1; % Minimum hesitation time
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
                    
                    [proposedPosition, proposedHeading, quitCode, skipEventCode, upKey, dwKey] = inputDevice.PollPlayer(player, render, obj);

                    if quitCode
                        
                        render.Close();
                        error('User terminated experiment');
                        
                    end
                    
                    if skipEventCode
                        
                        coordPoll = coordPoll.Stop();
                        
                        tripSum = sum( [obj.tripWireArray(:).tripCount] );
                        
                        stats = [tDelta tripSum];
                        
                        isCompleteFlag = 0;
                        
                        return;
                        
                   end
                    
                    player.proposedPos = proposedPosition;
                    player.heading = proposedHeading;
                    
                    if obj.checkCollisionFlag || skipEventCode
                        
                        [collisionFlag, exitCode, slideVector] = CollisionCheck(obj, player, upKey, dwKey);
                        
                        if exitCode || skipEventCode
                            
                            coordPoll = coordPoll.Stop();
                            
                            tripSum = sum( [obj.tripWireArray(:).tripCount] );
                            
                            stats = [tDelta tripSum];
                            
                            isCompleteFlag = 1;
                            
                            return;
                            
                        elseif collisionFlag
                            
                            player.proposedPos =  player.previousPos + slideVector;
                                 
                        else
                            
                            player.proposedPos = proposedPosition;
                            
                        end
                        
                    end
                    
                    % Check if the player is moving
                    hesitationFlag = player.IsPlayerHesitating();
               
                    if hesitationFlag && player.hesitantTimeStart == 0
                            
                        player.hesitantTimeStart = GetSecs;
                            
                    elseif ~hesitationFlag && player.hesitantTimeStart ~= 0
                        
                        hesitationTime = GetSecs - player.hesitantTimeStart;

                        if  minTime < hesitationTime
                       
                            player.hesitantTime =  player.hesitantTime + hesitationTime;
                        
                        else
                            
                            % Nothing
                            
                        end
                        
                        player.hesitantTimeStart = 0;
                        
                    else
                        
                        % Do nothing

                    end
                    
                    player.nextPos = player.proposedPos;
                    
                    player = player.UpdateState();
                                                            
                    render.UpdateDisplay(player, obj, ipClient);
                    
                    player.previousPos = player.nextPos;
                    
                    tDelta = GetSecs - t0;
                    
                    hesitantTime = player.hesitantTime;
                    
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
        
        
        function Draw(obj, drawDistal)
            
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

                      if drawDistal

                          patch(xDistal, yDistal, 'red');
                      
                      end
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
                obj.completeWallArray = Wall(obj.nWalls, 1);
                
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
                    
                    % Collect all the walls into 1 array
                    obj.completeWallArray(wallIndex) = thisWall;
                    
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
                 fgets(fid); % Skip Distal cue location line
                 %{
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
                 %}
                 
                 obj.distalCue.x(1) = -20.0;
                 obj.distalCue.y(1) = 8.0;
                 obj.distalCue.x(2) = -8.0;
                 obj.distalCue.y(2) = 20.0;
                 obj.distalCue.x(3) = -6.0;
                 obj.distalCue.y(3) = 20.0;
                 obj.distalCue.x(4) = -20.0;
                 obj.distalCue.y(4) = 6.0;

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
                 
                 %if numel(objStrCue) > 2
                     
                     %obj.perCue.normal = objStrCue{3};
                     
                 %end

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
                 
                 %if numel(objStrCue) > 2
                     
                     %obj.perCue.normalTwo = objStrCue{3};

                 %end
                
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
        
        
        function [collisionFlag, exitCode, slideVector] = CollisionCheck(obj, player, upKey, dwKey)

            exitCode = 0;
            
            % Normal walls
            collisionFlag = 0;
            
            % Set perimeter circular radius player radius * 2
            radius = player.bodyRadius;
            
            % Determine whether player is moving forward or backward
            if upKey
                inputMagnitude = player.maxVelocityPerFrame / 2;
            elseif dwKey
                 inputMagnitude = -player.maxVelocityPerFrame / 2;
            else
                inputMagnitude = 0;
            end

            % Determine the amount to slide along walls
            slideVector = [0, 0];
            orientationRadians = player.heading * (pi / 180);
            movementDirection = [-cos(orientationRadians), sin(orientationRadians)];
            movementVector = movementDirection * inputMagnitude;
            
            for wallIndex = 1:obj.nNormalWalls
                
                thisWall = obj.normalWallArray(wallIndex);
                
                x0 = thisWall.p1(1); x1 = thisWall.p2(1); z0 = thisWall.p1(2); z1 = thisWall.p2(2);
                
                % Check for collision              
               [isCollision, endPointCollision, endPoint] = Maze.normalWallCollisionDetect(x0, x1, z0, z1, player.proposedPos(1), player.proposedPos(2), player.bodyRadiusSquared);

                if isCollision 
                    
                    collisionFlag = 1;
                    
                    % Translate everything so that line segment start point to (0, 0)
        %            a = x1 - x0; % Line segment end point horizontal coordinate
        %            b = z1 - z0; % Line segment end point vertical coordinate
                    
                    % Determine normal wall vector
        %           normalWallVector = [-b, a];
        %           normalWallVector = normalWallVector / norm(normalWallVector);
                
                     % Calcualte slide vector for collision
       %             normalComponent = dot(movementVector, normalWallVector) * normalWallVector;
       
                    % function check
                    normalWallVector = thisWall.unitNormal;
                    
                    normalComponent = dot(movementVector, normalWallVector) * normalWallVector;
                    
        %            slideVector = movementVector - normalComponent;
        
                     slideVector = movementVector - normalComponent;
                    
                    % Ensure propsoed position does not pentrate wall
                    %minDistance = Maze.calculateMinDistanceToWall(x0, x1, z0, z1, (slideVector(1) + player.previousPos(1)), (slideVector(2) + player.previousPos(2)), player.bodyRadius);

                    if endPointCollision
                        
                        slideVector = Maze.handleEndPointCollision(endPoint, radius, (slideVector(1) + player.previousPos(1)), (slideVector(2) + player.previousPos(2)), player.bodyRadius, player.previousPos(1), player.previousPos(2));
                        
                    end
                    
                    movementVector = slideVector;
                    
                end
 
            end
            
            if collisionFlag
                
                slideVector = movementVector;

               return;
                
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
        
        
        function [collisionFlag, endPointCollisionFlag, endPoint] = normalWallCollisionDetect(x0, x1, y0, y1, px, py, rSqr)
            
            collisionFlag = 0;
            endPointCollisionFlag = 0;
            endPoint = [0,0];
            
            %{
            % First check collsion with edge buffers (circular buffers)
            
            distanceStart = sqrt((px - x0)^2 + (py - y0)^2);
            distanceEnd = sqrt((px - x1)^2 + (py - y1)^2);
            
            
            if distanceStart <= radius
                
                collisionFlag = 1;
                endPointCollisionFlag = 1;
                endPoint = [x0, y0];
                %return;
                
            elseif distanceEnd <= radius
                
                collisionFlag = 1;
                endPointCollisionFlag = 1;
                endPoint = [x1, y1];
                %return;
                
            end
            %}
            
            % Check if any collision is possible
            
            % Translate everything so that line segment start point to (0, 0)
            a = x1 - x0; % Line segment end point horizontal coordinate
            b = y1 - y0; % Line segment end point vertical coordinate
            c = px - x0; % Circle center horizontal coordinate
            d = py - y0; % Circle center vertical coordinate
                
            thisIndex = find((d.*a - c.*b).*(d.*a - c.*b) <= rSqr * (a.*a + b.*b));
            
            a = a(thisIndex);
            b = b(thisIndex);
            c = c(thisIndex);
            d = d(thisIndex);

            
            startInside = (c.*c + d.*d <= rSqr);
            % Line segment start point is inside the circle
            
            endInside = ((a-c).*(a-c) + (b-d).*(b-d) <= rSqr);
            
            middleInside = (~startInside & ~endInside & c.*a + d.*b >= 0 & c.*a + d.*b <= a.*a + b.*b);
            
            if any(startInside)
                
                collisionFlag = 1;
                endPointCollisionFlag = 1;
                endPoint = [x0, y0];
                
            elseif any(endInside)
                
                collisionFlag = 1;
                endPointCollisionFlag = 1;
                endPoint = [x1, y1];
                
            elseif any(middleInside)
                
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

        
        function movementVector = handleEndPointCollision(endPoint, radius, px, py, bodyRadius, prevX, prevY)
            
            playerPrev = [prevX, prevY];
            playerProposed = [px,py];
            
            collisionVector = playerProposed - endPoint;
            distance = norm(collisionVector);
            
            if distance == 0
                distance = 0.01;
            end
            
            normal = collisionVector / distance;
            
            % Determine player adjusment
            % shift = radius + bodyRadius + 0.01; % Ensures no overlap
            shift = 2 * bodyRadius + (bodyRadius * 0.01);
            playerX = endPoint(1) + normal(1) * shift;
            playerY = endPoint(2) + normal(2) * shift;
            playerTarget = [playerX, playerY];
            beta = 0.04;
            
            adjustedMovementVector = (1 - beta) * playerProposed + beta * playerTarget;
            
            % Attempt to find and use smallest beta for smoothest movements
            
            distance = sqrt((adjustedMovementVector(1) - endPoint(1))^2 + (adjustedMovementVector(2) - endPoint(2))^2);
            
            while distance <= (radius)
                
                beta = beta * 1.05;
                
                adjustedMovementVector = (1 - beta) * playerProposed + beta * playerTarget;
                
                distance = sqrt((adjustedMovementVector(1) - endPoint(1))^2 + (adjustedMovementVector(2) - endPoint(2))^2);
                
            end
            
            movementVector = adjustedMovementVector - playerPrev;
            
        end
        
        function minDitance = calculateMinDistanceToWall(x0, x1, y0, y1, px, py, bodyRadius)
            
            %Start of wall to end of wall
            wallVector = [x1 - x0, y1 - y0];
            
            %Start of wall to player
            wallToPlayer = [px - x0, py - y0];
            
            wallLengthSquared = dot(wallVector, wallVector);
            if wallLengthSquared == 0
                minDitance = norm(wallToPlayer);
                return;
            end
            
            projection = dot(wallToPlayer, wallVector) / wallLengthSquared;
            
            % Ensure projection is within the segment
            projection = max(0, min(1, projection));
            closestPoint = [x0, y0] + projection * wallVector;
            
            % Determine player adjusment
            distanceVector = [px, py] - closestPoint;
            
            minDitance = norm(distanceVector) - bodyRadius;
            
        end
        
    end
    
end
