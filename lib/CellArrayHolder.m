% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef CellArrayHolder < handle
    %CellArrayHolder Summary of this class goes here
    
    properties
        value
    end
    
    methods
        function this = CellArrayHolder(t)
            this.value = cell(0);
        end
        
        function setVal(this, index, key, val)
            if isempty(key)
                this.value{index} = val;
            else
                this.value{index}.(key) = val;
            end
        end
        
        function val = getVal(this, index, key)
            if isempty(key)
                val = this.value{index};
            else
                val = this.value{index}.(key);
            end
        end
        
    end
    
end

