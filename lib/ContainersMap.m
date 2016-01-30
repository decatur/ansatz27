% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef ContainersMap < handle

    properties %(Access = private)
        s
    end
    
    
    methods

        function this = JSON_Handler()
            this.s = struct;
        end

        function name = makeName(this, key)
            name = ['a' sprintf('%x', uint8(key))];
        end

        function value = subsref(this, idx)
            if (isempty (idx))
                error ();
            end

            switch idx(1).type
                case '()'
                    key = idx(1).subs{1};
                    name = this.makeName(key);
                    if ~isfield(this.s, name)
                        error('Map has no field %s', key);
                    end
                    value = this.s.(name);
                    return;
                otherwise
                    %keyboard
                    % Enable dot notation for all properties and methods
                    [fName, args] = idx.subs;
                    if strcmp(fName, 'isKey')
                        value = isfield(this.s, this.makeName(args{1}));
                        return;
                    end
            end

            error('Invalid subscript call')
        end


        function this = subsasgn(this, idx, rhs)
            if (isempty (idx))
                error ();
            end

            if strcmp(idx(1).type, '()')
                key = idx(1).subs{1};
                name = this.makeName(key);
                ss = this.s;
                ss.(name) = rhs;
                this.s = ss;
            else
                error('Invalid subscript assignment')
            end
        end
        
    end
end

