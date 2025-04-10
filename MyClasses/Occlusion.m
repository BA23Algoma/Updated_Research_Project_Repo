classdef Occlusion
    
    properties
        
        
    end
    
    methods
        
    end
    
    methods(Static)
        
        function blocked = IsMoonBlocked(player, distallPos, normalWalls, playerHeight, distallHeight, wallHeight)
            
            % Check if the view to the object is obstructed by wall
            %  Line connecting from player to object
            lineOfSight(1) = distallPos(1);
            lineOfSight(2) = distallPos(2);
            lineOfSight(3) = player.previousPos(1);
            lineOfSight(4) = player.previousPos(2);
            
            % Find set of wall between player and distall queue
            closestIntersect= -1;
            minDistance = Inf;
%            intersectWall = -1;
            
            for wallIndex = 1:numel(normalWalls)
                
                %Check each wall for intersection with lineOfSight
                [intersect, intersectionPoint] = Occlusion.DoLineSegmentsIntersect(lineOfSight, normalWalls(wallIndex));
                                
                if intersect
                    
                    playerPos = [lineOfSight(3),  lineOfSight(4)];
                    
                    distance = norm(playerPos - intersectionPoint);
                    
                    % Find closet intersect distance
                    if distance < minDistance
                        
                        minDistance = distance;
                        closestIntersect = intersectionPoint;
%                        intersectWall = wallIndex;
                        
                    end
                    
                else
                    
                    % Do nothing
                    
                end
                
            end
            
            if ~exist('playerPos', 'var')
                
                blocked = false;
                return;

            end
                        
            % Claculate distance to closest wall
            distanceToWall = Occlusion.CalculateDistianceToWall(playerPos, ...
                distallPos, closestIntersect);
            
            % Calculate height at which line of sight between player and
            % distall cue intersect closest wall
            intersectHeight = Occlusion.CalculateIntersectionHeight(playerPos, ...
                playerHeight, distallPos, distallHeight, distanceToWall);
                        
%            wallPos = [normalWalls(intersectWall).p1, normalWalls(intersectWall).p2];
            
            if 0 < intersectHeight && intersectHeight < wallHeight
                
                blocked = true;
  %              disp('blocked');

            else
                
                blocked = false;
   %             disp('viewable');
                
            end                
            
        end
        
        function [intersects, intersectionPoint] = DoLineSegmentsIntersect(segment, wall)
            % Perform line segment intersect test
            % Return true if the segment intersects, else false

            x1 = segment(1);
            y1 = segment(2);
            x2 = segment(3);
            y2 = segment(4);
            x3 = wall.p1(1);
            y3 = wall.p1(2);
            x4 = wall.p2(1);
            y4 = wall.p2(2);

            %Calcualte the vecors for the two line segments
            u = [x2 - x1, y2 - y1];
            v = [x4 - x3, y4 - y3];

            %Calculate the cross prodcut
            crossProduct = u(1) * v(2) - u(2) * v(1);

            % Check if lines are parrallel
            if abs(crossProduct) < 1e-6
                intersects = false; % Lines are parrallel
                intersectionPoint = [];

                return;
            end

            % Calculate the parameters for the line segments
            t1 = ((x3 - x1) * v(2) - (y3 - y1) * v(1))/ crossProduct;
            t2 = ((x3 - x1) * u(2) - (y3 - y1) * u(1))/ crossProduct;

            % Check if the intersection point lies on the line segments
            if (t1 >= 0) && (t1 <= 1) && (t2 >= 0) && (t2 <=1)
                intersects = true;
                intersectionPoint = [x1 + t1 * u(1), y1 + t1 * u(2)];
            else
                intersects = false;
                intersectionPoint = [];
            end

        end
        
        
        
        function distanceToWall = CalculateDistianceToWall(playerPos, distallPos, intersectionPoint)
            
            % Calculate vector from player to moon
            playerToDistall = distallPos - playerPos;
            
            % Normalize the vector
            playerToDistallNorm = playerToDistall / norm(playerToDistall);
            
            playerToIntersect = intersectionPoint - playerPos;
            
            % Project playerToIntersect onto playerToDistallNorm
            distanceToWall = abs(dot(playerToIntersect, playerToDistallNorm));
            
        end
        
        function intersectHeight = CalculateIntersectionHeight(playerPos, playerHeight, distallPos, distallHeight, distanceToWall)
            
            % Find distance from player to distal
            pathDistance = norm(distallPos - playerPos);
            
            HeightDifference = norm(distallHeight - playerHeight);
            
            elevationAngle = atan2(HeightDifference, pathDistance);
            
            playerToIntersectHeight = tan(elevationAngle) * distanceToWall;
   
            intersectHeight = playerToIntersectHeight + abs(playerHeight);
            
        end

    end
    
end