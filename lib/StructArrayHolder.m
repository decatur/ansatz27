classdef StructArrayHolder < handle
    %StructArrayHolder Summary of this class goes here
    
    properties
        value
    end
    
    methods
        function this = StructArrayHolder(t)
            this.value = struct([]);
        end
        
        function setVal(this, index, key, val)
            if isempty(key)
                this.value(index) = val;
            else
                this.value(index).(key) = val;
            end
        end
        
        function val = getVal(this, index, key)
            if isempty(key)
                val = this.value(index);
            else
                val = this.value(index).(key);
            end
        end
        
    end
    
end

