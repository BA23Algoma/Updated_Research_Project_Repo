classdef Tracker
    
    
    properties
    
        fieldNames;
        value;

    end
    
    methods
        
        function obj = Tracker()
            
            obj.fieldNames = {
                    'XMin', 'XMax','YMin', 'YMax',...
                    'CueOneXMin', 'CueOneXMax'...
                    'CueOneYMin', 'CueOneYMax'...
                    'CueTwoXMin', 'CueTwoXMax'...
                    'CueTwoYMin', 'CueTwoYMax'...
                    'DistalXMin', 'DistalXMax'...
                    'DistalYMin', 'DistalYMax'...
                    'EyeLoc', 'Loc'...
                    };
                    
                for index = 1:numel(obj.fieldNames)
                    obj.value.(obj.fieldNames{index}) = '';
                end
                
                obj.value.XMin   = 'X1:';
                obj.value.XMax   = 'X2:';
                obj.value.YMin   = 'Y1:';
                obj.value.YMax   = 'Y2:';
                obj.value.EyeLoc = 'LOC: ';
            
        end
        
    end
    
end