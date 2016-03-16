% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

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
                names = fieldnames(val);
                for k=1:length(names)
                    this.value(index).(names{k}) = val.(names{k});
                end
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

