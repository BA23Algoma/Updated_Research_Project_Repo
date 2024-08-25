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

            % Initialize an array to hold the new wall values
            obj.nWalls = numWalls;
            
        end
        
        function Gaze = EyeFocus(obj, viewportMatrix, modelviewMatrix, projectionMatrix, maze, wallHeight, FPOG)
            
        Gaze = 'Sky;';    
            
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
        obj.X = obj.X / double(viewportMatrix(3));
        
        % Because of caretian plan. Y min is max while Y max is min
        obj.Y = obj.Y / double(viewportMatrix(4));
  
        % Set value to have intersect line segment will run vertically
        top = 1;
        bottom = 0;
        
        % Define the two vertex edges
        first = 1;
        second = 2;
        
        for index = 1:obj.nWalls
 
            if obj.Z(index, first) < 1 || obj.Z(index, second) < 1
                
                lineSegment(1) = FPOG(1);
                lineSegment(2) = top;
                lineSegment(3) = FPOG(1);
                lineSegment(4) = bottom;

                vertexFirst = [obj.X(index, first), obj.Y(index, first)];
                vertexSecond = [obj.X(index, second), obj.Y(index, second)];

                wall = Line(vertexFirst, vertexSecond);

                [intersects, intersectionPoint] = Occlusion.DoLineSegmentsIntersect(lineSegment, wall);
                
                if intersects
                    
                    if FPOG(2) < intersectionPoint(2) 
                        Gaze = 'Ground;';
                    end
                    
                end

            end
                
                
        end
               
        end
        

    end
    
end