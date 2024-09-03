classdef GazeLocation
    
    properties
        
        X;
        Y;
        Z;
        nWalls;
        visible;
        
    end
    
    methods
        
        function obj = GazeLocation(numWalls)

            % Initialize total number f walls
            obj.nWalls = numWalls;
            
        end
        
        function Gaze = EyeFocus(obj, viewportMatrix, modelviewMatrix, projectionMatrix, maze, wallHeight, FPOG)

            Gaze = 'NA;';    

            walls = maze.completeWallArray;
            vertexes = 2;

            % Initialize wall screen coordinate values
            obj.X = zeros(1, vertexes);
            obj.Y = zeros(1, vertexes);
            obj.Z = zeros(1, vertexes);

            % Loop through walls obtaining screen coordinates of edge points
            for wallIndex = 1:obj.nWalls
                
                thisWall = walls(wallIndex);
                
                % Unnomamlize FPOG values 
                unNormX = FPOG(1) * double(viewportMatrix(3));
                unNormY = FPOG(2) * double(viewportMatrix(4));

                % Unproject FPOG values to the z depth of the frusturm to generate line of sight 
                [startX, ~, startY] = gluUnProject(unNormX, unNormY, 0, modelviewMatrix, projectionMatrix, viewportMatrix);
                [endX, ~, endY] = gluUnProject(unNormX, unNormY, 1, modelviewMatrix, projectionMatrix, viewportMatrix);

                % Convert point in line of sight
                lineOfSight(1) = startX;
                lineOfSight(2) = startY;
                lineOfSight(3) = endX;
                lineOfSight(4) = endY;

                % Check if the line of sight intersects wall
                [intersects, intersectPoint] = Occlusion.DoLineSegmentsIntersect(lineOfSight, thisWall);
             
                if intersects

                    % Project 3D corrdinates to 2D screen coordiantes
                    [~, screenY, ~] = gluProject(intersectPoint(1), wallHeight, intersectPoint(2),...
                            modelviewMatrix, projectionMatrix, viewportMatrix);

                    % Normailize value
                    screenY = screenY / double(viewportMatrix(4));
                    
                    if  FPOG(2) < screenY
                        Gaze = 'Ground;';
                        return;
                    else
                        Gaze = 'Sky;';
                    end
                    
                %{
                    xPoint = [thisWall.p1(1), thisWall.p2(1)];
                    yPoint = [thisWall.p1(2), thisWall.p2(2)];

                    % Loop through both edges of wall
                    for edge = 1:vertexes

                        % Project 3D corrdinates to 2D screen coordiantes
                        [obj.X(edge), obj.Y(edge), obj.Z(edge)] = gluProject(xPoint(edge), wallHeight, yPoint(edge),...
                            modelviewMatrix, projectionMatrix, viewportMatrix);

                    end
                
                     % Normailize values for gazepoint ((0,0) Top left, (1,1) Bottom right)            
                    obj.X = obj.X / double(viewportMatrix(3));
                    obj.Y = obj.Y / double(viewportMatrix(4));

                    % Set value to have line segment will run vertically at eye FPOGX
                    top = 1;
                    bottom = 0;

                    % Define the two vertex edges
                    first = 1;
                    second = 2;

                    % Create line segment for vertical intersecting wall
                    lineSegment(1) = FPOG(1);
                    lineSegment(2) = top;
                    lineSegment(3) = FPOG(1);
                    lineSegment(4) = bottom;

                    vertexFirst = [obj.X(first), obj.Y(first)];
                    vertexSecond = [obj.X(second), obj.Y(second)];

                    checkWall = Line(vertexFirst, vertexSecond);

                    [vertIntersects, vertIntersectionPoint] = Occlusion.DoLineSegmentsIntersect(lineSegment, checkWall);

                    disp([vertexFirst, vertexSecond]);
                     disp(FPOG(1));
                    if  FPOG(2) < vertIntersectionPoint(2)
                        Gaze = 'Ground;';
                        return;
                    else
                        Gaze = 'Sky;';
                        disp(vertIntersectionPoint(2));
                        disp(wallIndex);
                    end
                    %}
                end

            end
           
        end
        
    end
    
end