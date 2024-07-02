classdef BoundingBox
    
    properties
        
        BoundingBoxProperties;
        minMax;
        Cue;
        scale;
        render;
        
    end
    
    methods
        
        function obj = BoundingBox(render, Cue, scale)
            
            if nargin < 3
                
                error('Invalid number of inputs');
                
            else
                
                obj.Cue = Cue;
                obj.scale = scale;
                obj.render = render;
        
            end
            
        end
        
        function [BoundingBox, minMax] = BoundBoxInitialize(obj)
            
            % Accumulate translation
            % Initialize local transformation matrix as an identity matrix
            obj.Cue.localTransform = eye(4);
            translationVector = [0, 0, 0];
            translationMatrix = makehgtform('translate', translationVector);
            obj.Cue.localTransform = obj.Cue.localTransform * translationMatrix;

            % Assume obj is your 3D object structure with fields like cueProperties, localTransform, etc.
            vertices = obj.Cue.vertices * obj.scale;

            %Global Transform
            globaltranslationVector = [0, 0, 0];
            rotationAngles = [0, 0, 0]; % Angles in degrees
            
            % Create translation matrix
            T = eye(4);
            T(1:3, 4) = globaltranslationVector;
            
            % Create rotation matrix (assuming rotation is around the origin)
            R = euler2rotmat(obj, rotationAngles);

            % Combine translation and rotation
            globalTransform = T * R;

            % Call the bounding box function
            boundingBox = CalculateBoundingBox(obj, vertices, ...
                obj.Cue.localTransform, globalTransform);
            
            BoundingBox = boundingBox;
            
            % Retrieve matrix values
            modelViewMatrix = glGetDoublev(obj.render.GL.MODELVIEW_MATRIX);
            projectionMatrix2D = glGetDoublev(obj.render.GL.PROJECTION_MATRIX);
            viewport = glGetIntegerv(obj.render.GL.VIEWPORT);
            
            % Initalize matrices to zero
            X = zeros(1,size(boundingBox, 2));
            Y = zeros(1,size(boundingBox, 2));
            Z = zeros(1,size(boundingBox, 2));
            
            % Find (X,Y, Z) projected coordinates of bounding box vertices
             for i = 1:size(boundingBox, 2)
                 
                 [X(i), Y(i), Z(i)] = gluProject(boundingBox(1,i), boundingBox(2,i), boundingBox(3,i),...
                     modelViewMatrix, projectionMatrix2D, viewport);
                
             end
             
             % Find max and min values
             xMin = min(X);
             yMin = min(Y);
             xMax = max(X);
             yMax = max(Y);
             zMax = max(Z);
            
            % Adjust Y to match OpenGL coordinate system
            yMin = double(viewport(4)) - yMin;
            yMax = double(viewport(4)) - yMax;
            
            % Normailize values for gazepoint ((0,0) Top left, (1,1) Bottom
            % right)            
            xMin = xMin / double(viewport(3));
            xMax = xMax / double(viewport(3));
            
            % Because of caretian plan. Y min is max while Y max is min
            tempyMin = yMin;
            yMin = yMax / double(viewport(4));
            yMax = tempyMin / double(viewport(4));
            
            minMax = [xMin xMax yMin yMax zMax];
            %disp(minMax);  
            
        end
        
        function boundingBox = CalculateBoundingBox(~, vertices, localTransform, globalTransform)

            %globalTransform = [globalTransform, 1];
            %globalTransform = reshape(globalTransform, 4, 1);

            vertices = [vertices; ones(1, size(vertices, 2))];

            combineTransform = globalTransform * localTransform;

            % Apply local and global transformations to vertices    
            transformedVertices = combineTransform * vertices;

            %-------------------Box Formating------------------

            % Calculate min and max along each axis
            minCoords = min(transformedVertices(1:3, :), [], 2);
            maxCoords = max(transformedVertices(1:3, :), [], 2);

            % Construct the bounding box vertices
            boundingBox = [
                minCoords(1), minCoords(2), minCoords(3);
                minCoords(1), minCoords(2), maxCoords(3);
                minCoords(1), maxCoords(2), minCoords(3);
                minCoords(1), maxCoords(2), maxCoords(3);
                maxCoords(1), minCoords(2), minCoords(3);
                maxCoords(1), minCoords(2), maxCoords(3);
                maxCoords(1), maxCoords(2), minCoords(3);
                maxCoords(1), maxCoords(2), maxCoords(3);
            ]';
        end
        
        function [onScreen, minMax] = IsBoundingBoxVisible(~, normalWalls, xCueLocation, yCueLocation, player, minReq, minMax)
            % First input paramter is obj, removed to get get rid warning
            % but need to display mouse position for testing
            
            xMin = minMax(1);
            xMax = minMax(2);
            yMin = minMax(3);
            yMax = minMax(4);
            zMax = minMax(5);
            
            % Mouse to check values
 %            viewport = glGetIntegerv(obj.render.GL.VIEWPORT);
 %            [Xmouse, Ymouse, ~] = GetMouse(obj.render.viewportPtr);
 %            Xmouse = Xmouse / double(viewport(3));
 %            Ymouse = Ymouse / double(viewport(4));
             
 %           disp([Xmouse Ymouse]);
            
            % Check if the view to the object is obstructed by wall
            %  Line connecting from player to object
            lineOfSight(1) = xCueLocation;
            lineOfSight(2) = yCueLocation;
            lineOfSight(3) = player.previousPos(1);
            lineOfSight(4) = player.previousPos(2);
            
            % Check if view is blocked by wall
            viewBlocked = false;
            
            for wallIndex = 1:numel(normalWalls)
                
                %Check each wall for intersection with lineOfSight
                if Occlusion.DoLineSegmentsIntersect(lineOfSight, normalWalls(wallIndex))
                    
                    viewBlocked = true;

                    break;
                    
                end
                
            end
            
            % Check if queue is on screen (viewable)
            onScreen = false;
            
            xDif = xMax - xMin;
            yDif = yMax - yMin;
            
            boudingboxArea = xDif * yDif; 
            
            minVisibility = (boudingboxArea * minReq);
             
            queueRect = [xMin yMin xDif yDif];
            
            screenRect = [0 0 1 1];
            
            intersect = rectint(queueRect, screenRect);
            
            if minVisibility < intersect && intersect < 1 && zMax < 1.0 && ~viewBlocked
                
                onScreen = true;
                
            end
            
            
%            minMaxPost(1) = xMin;
%            minMaxPost(2) = xMax;
%            minMaxPost(3) = yMin;
%            minMaxPost(4) = yMax;           
%            disp([queueRect Xmouse Ymouse]);
%            disp(minMaxPost);
            
        end
        
        % Function to create a rotation matrix from Euler angles
        function R = euler2rotmat(~, angles)
            
            % Convert Euler angles to rotation matrix
            alpha = angles(1);
            beta = angles(2);
            gamma = angles(3);

            Rx = [1, 0, 0; 0, cosd(alpha), -sind(alpha); 0, sind(alpha), cosd(alpha)];
            Ry = [cosd(beta), 0, sind(beta); 0, 1, 0; -sind(beta), 0, cosd(beta)];
            Rz = [cosd(gamma), -sind(gamma), 0; sind(gamma), cosd(gamma), 0; 0, 0, 1];

            % Combine rotations about X, Y, and Z axes
            R = eye(4);
            R(1:3, 1:3) = Rz * Ry * Rx;

        end

        function matrix = perspectiveProjectionMatrix(fov, aspect, znear, zfar)
            
            f = 1 / tan((fov / 2) * (pi / 180));
            
            matrix = [f/aspect, 0, 0, 0; 0, f, 0, 0; 0, 0, (zfar + znear) / (znear - zfar), -1; 0, 0, 2*zfar*znear / (znear - zfar), 0];
            
        end
        
    end
    
end