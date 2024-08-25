% obj = Player([])
classdef Player
    
    properties
        
        % Static properties
        maxDegreesPerFrame  = 1.0;
        maxVelocityPerFrame = 0.0167;
        bodyRadius          = 0.125;
        bodyRadiusSquared;
        
        % Dynamic properties
        previousPos         = [0 0];
        proposedPos         = [0 0];
        nextPos             = [0 0];
        heading             = 45.0;        
        normal;
        unitNormal;
        v;
        norm;
        normSqr;
        hesitationFlag;
        hesitantTime        = 0;
        hesitantRaduis      = 0.0025;
        hesitantTimeStart   = 0;
        
    end
    
    
    methods
        
        % Constructor
        function obj = Player(varargin)
            
            if nargin > 0
                
                obj.bodyRadius = varargin{1};
                
            end
            
            if nargin > 1
                
                obj.maxDegreesPerFrame = varargin{2};
                
            end
            
            if nargin > 2
                
                obj.maxVelocityPerFrame = varargin{3};
                
            end                        
            
            obj.bodyRadiusSquared = obj.bodyRadius * obj.bodyRadius;
            
        end
        
        function obj = UpdateState(obj)
            
            obj.v = obj.proposedPos - obj.previousPos;
            obj.normSqr = obj.v * obj.v';
            obj.norm = realsqrt(obj.normSqr);
            obj.normal = [-obj.v(2) obj.v(1)];
            obj.unitNormal = obj.normal / obj.norm;
            
            %             obj.proposedPos = proposedPos;
%             
%             [~, next] = Collision.WallCollisionVec(obj, wallArray);
%             
%             obj.nextPos = next;
%             obj.heading = proposedHeading;

            
        end
        
        function obj = set.maxDegreesPerFrame(obj, MaxDegreesPerFrame)
            
            if isnumeric(MaxDegreesPerFrame)
                
                obj.maxDegreesPerFrame = MaxDegreesPerFrame;
                
            else
                
                error('MaxDegreesPerFrame must be numeric');
                
            end
            
        end
        
        
        function obj = set.maxVelocityPerFrame(obj, MaxVelocityPerFrame)
            
            if isnumeric(MaxVelocityPerFrame)
                
                obj.maxVelocityPerFrame = MaxVelocityPerFrame;
                
            else
                
                error('MaxVelocityPerFrame must be numeric');
                
            end
            
        end
        
        function hesitationFlag = IsPlayerHesitating(obj)
            
           hesitationFlag = 0;
           xDisplacement = abs(obj.proposedPos(1) - obj.previousPos(1));
           yDisplacement = abs(obj.proposedPos(2) - obj.previousPos(2));
           
           if (xDisplacement < obj.hesitantRaduis) && (yDisplacement < obj.hesitantRaduis)
               
               hesitationFlag = 1;
               
           end
            
        end
        
    end % methods
    
end
