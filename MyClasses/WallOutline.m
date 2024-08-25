classdef WallOutline
    
    properties
        
        X;
        Y;
        Z;
        nWalls;
        visible;
        
    end
    
    methods
        
        function obj = WallOutline(~, numWalls)
            
            % Initialize an array to hold the new wall values
            obj.nWalls = numWalls;
            
        end
        
        function Gaze = CreateLine(obj, viewportMatrix, modelviewMatrix, projectionMatrix, maze, wallHeight, FPOG)
            
        Gaze = 'Sky';    
            
        walls = maze.normalWallArray;
        vertexes = 2;
        
        % Initialize wall screen coordinate values
        obj.X = zeros(obj.nWalls, vertexes);
        obj.Y = zeros(obj.nWalls, vertexes);
        obj.Z = zeros(obj.nWalls, vertexes);

        % Loop through walls obtaining screen coordinates of edge points
        for wallIndex = 1:obj.nWalls
  
            thisWall = walls(wallIndex);
  
            xPoint = [thisWall.p1(1), thisWall.p2(1)];
            yPoint = [thisWall.p1(1), thisWall.p2(2)];
            zPoint = wallHeight;
  
            % Loop through both edges of wall
            for edge = 1:vertexes
  
                % Project 3d corrdinates to 2D screen coordiantes
                [obj.X(wallIndex, edge), obj.Y(wallIndex, edge), obj.Z(wallIndex, edge)] = gluProject(xPoint(edge), zPoint, yPoint(edge),...
                    modelviewMatrix, projectionMatrix, viewportMatrix);
             
            end
  
        end

        % Normailize values for gazepoint ((0,0) Top left, (1,1) Bottom
        % right)            
        obj.X = obj.X / double(obj.viewport(3));
        
        % Because of caretian plan. Y min is max while Y max is min
        obj.Y = obj.Y / double(obj.viewport(4));
  
        % Set value to have intersect line segment will run vertically
        top = 1;
        bottom = 0;
        
        % Define the two vertex edges
        first = 1;
        second = 2;
        
        for vertex = 1:obj.nWalls
 
            if  1 < obj.Z(vertex, first) && 1 < obj.Z(vertex, second)
                
                lineSegment(1) = FPOG(1);
                lineSegment(2) = top;
                lineSegment(3) = FPOG(2);
                lineSegment(4) = bottom;

                vertexFirst = [obj.X(vertex, first), obj.Y(vertex, first)];
                vertexSecond = [obj.X(vertex, second), obj.Y(vertex, second)];

                wall = Line(vertexFirst, vertexSecond);

                [intersects, intersectionPoint] = Occlusion.DoLineSegmentsIntersect(segment, wall);
                
                if intersects
                    
                    if FPOG(2) < intersectionPoint 
                        Gaze = 'Wall';                 
                    end
                    
                end

            end
                
                
        end
       
        % c = test(3 < test & test < 9);
        
        end
        

    end
    
end