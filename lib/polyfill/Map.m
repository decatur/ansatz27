% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef Map < handle

    properties %(Access = private)
        s
    end
    
    
    methods

        function this = Map()
            this.s = struct;
        end

        function key = denormalizeKey(this, key)
            if length(key) >= 2 && isequal(key(1:2), 'x_')
                a = arrayfun(@(x) sscanf(x, '%x'), reshape(key(3:end), 2, []));
                key = char(16*a(1,:)+a(2,:));
            end
        end

        function key = normalizeKey(this, key)
            if isempty(key)
                key = 'x_';
                return
            end
            s = strrep(key, '_', 'A');
            if !(isalpha(s(1)) && all(isalnum(s)))
                key = ['x_' sprintf('%x', uint8(key))];
            end
        end

        function value = subsref(this, idx)
            if (isempty(idx))
                error('Must provide idx in call to subsref()');
            end

            switch idx(1).type
                case '()'
                    key = idx(1).subs{1};
                    name = this.normalizeKey(key);
                    if ~isfield(this.s, name)
                        error('Map has no field %s', key);
                    end
                    value = this.s.(name);
                otherwise
                    % Enable o.foo('bar'). We expect
                    %     idx = struct('type', { '.' '()' }, 'subs', { 'foo' {'bar'} })
                    if ~strcmp(cat(2, idx.type), '.()') 
                        error('Invalid subscript call');
                    end

                    [fName, args] = idx.subs;
                    if strcmp(fName, 'isKey')
                        value = isfield(this.s, this.normalizeKey(args{1}));
                    elseif strcmp(fName, 'remove')
                        value = [];
                        if ~isempty(args{1})
                            this.s = rmfield(this.s, this.normalizeKey(args{1}));
                        end
                    elseif strcmp(fName, 'keys')
                        normalizedNames = fieldnames(this.s);
                        value = cell(1, length(normalizedNames));
                        for k=1:length(normalizedNames)
                            value{k} = this.denormalizeKey(normalizedNames{k});
                        end
                    else
                        error('Invalid member %s', fName);
                    end
            end

        end


        function this = subsasgn(this, idx, rhs)
            if (isempty (idx))
                error('Must provide idx in call to subsasgn()');
            end

            if strcmp(idx(1).type, '()')
                key = idx(1).subs{1};
                name = this.normalizeKey(key);
                ss = this.s;
                ss.(name) = rhs;
                this.s = ss;
            else
                keyboard
                error('Invalid subscript assignment: %s', idx(1).type);
            end
        end

        function disp(this)
            disp(this.s) %JSON.stringify(this, [], 4));
        end
        
    end
end

