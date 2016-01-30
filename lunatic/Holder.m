classdef Holder < handle
    %Holder Summary of this class goes here
    
    properties
        type % one of structSingleton, structArray or cellArray
        value % struct, structured array or cell array
    end
    
    methods
        function this = Holder(t)
            if strcmp(t, 'structSingleton')
                this.value = struct();
            elseif strcmp(t, 'structArray')
                this.value = struct([]);
            elseif strcmp(t, 'cellArray')
                this.value = cell(0);
            else
                error('Invalid type %s', t)
            end
            this.type = t;
        end
        
        function setVal(this, index, key, val)
            if strcmp(this.type, 'cellArray')
                if isempty(key)
                    this.value{index} = val;
                else
                    this.value{index}.(key) = val;
                end
            elseif strcmp(this.type, 'structSingleton')
                this.value.(key) = val;
            else % structArray
                if isempty(key)
                    this.value(index) = val;
                else
                    this.value(index).(key) = val;
                end
                
            end
        end
        
        function val = getVal(this, index, key)
            if strcmp(this.type, 'cellArray')
                if isempty(key)
                    val = this.value{index};
                else
                    val = this.value{index}.(key);
                end
            elseif strcmp(this.type, 'structSingleton')
                val = this.value.(key);
            else % structArray
                if isempty(key)
                    val = this.value(index);
                else
                    val = this.value(index).(key);
                end
                
            end
        end
        
    end
    
end

