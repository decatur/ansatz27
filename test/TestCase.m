% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef TestCase < handle
    
    properties
        name
        errorCount
    end
    
    methods (Access=public)
        
        function this = TestCase()
            this.errorCount = 0;
        end
        
        function exec(this)
            fprintf(1, 'Running test %s\n', this.name);
            
            this.exec_();
            
            if this.errorCount > 0
                fprintf(1, '%s: There are %u errors\n', this.name, this.errorCount);
            else
                fprintf(1, '%s: No errors\n', this.name);
            end
        end
        
        function assertEqual(this, actual, expected)
            % Important: We do not use Octaves recursive isequal because it does not use overloaded isequal on objects!
            
            if isempty(expected)
                if ~isempty(actual)
                    this.err('Error: Expected empty, found %s', TestCase.toString(actual));
                end
            elseif ischar(expected)
                if ~ischar(actual) || ~strcmp(actual, expected)
                    this.err('Error: Expected %s, found %s', expected, TestCase.toString(actual));
                end
            elseif isnumeric(expected)
                if ~isnumeric(actual) || ~isequaln(actual, expected)
                    this.err('Error: Expected %g, found %s', expected, TestCase.toString(actual));
                end
            elseif islogical(expected)
                if ~islogical(actual) || ~isequal(actual, expected)
                    this.err('Error: Expected %s, found %s', expected, TestCase.toString(actual));
                end
            elseif iscell(expected)
                if ~iscell(actual)
                    this.err('Error: Expected cell, found %s', TestCase.toString(actual));
                    return;
                elseif ~iscell(actual) || length(expected) ~= length(actual)
                    this.err('Error: Expected cell of length %u, found length %u', length(expected), length(actual));
                    return;
                end
                for k=1:length(expected)
                    this.assertEqual(actual{k}, expected{k})
                end
            elseif isstruct(expected)
                if ~isstruct(actual)
                    this.err('Error: Expected struct, found %s', TestCase.toString(actual));
                    return;
                end
                
                expectedNames = sort(fieldnames(expected));
                actualNames = sort(fieldnames(actual));
                
                if length(expectedNames) ~= length(actualNames)
                    expectedNames = sprintf('%s, ', expectedNames{:});
                    actualNames = sprintf('%s, ', actualNames{:});
                    this.err('Error: Mismatch in field names: Expected [%s] actual [%s]', expectedNames, actualNames);
                    return;
                end
                
                for m=1:length(expected)
                    for k=1:length(expectedNames)
                        if ~strcmp(expectedNames{k}, actualNames{k})
                            this.err('Error: Expected field name %s, found %s', expectedNames{k}, actualNames{k});
                            return;
                        end
                        this.assertEqual(actual(m).(actualNames{k}), expected(m).(expectedNames{k}));
                    end
                end
            elseif isa(expected, 'Map') || isa(expected, 'containers.Map')
                if ~( isa(actual, 'Map') || isa(actual, 'containers.Map') )
                    this.err('Error: Expected map, found %s', class(actual));
                    return;
                end
                
                expectedNames = sort(expected.keys());
                actualNames = sort(actual.keys());
                
                if length(expectedNames) ~= length(actualNames)
                    this.err('Error: Mismatch in field names. Expected %s, found %s', expectedNames{:}, actualNames{:});
                    return;
                end
                
                for k=1:length(expectedNames)
                    if ~strcmp(expectedNames{k}, actualNames{k})
                        this.err('Error: Expected field name %s, found %s', expectedNames{k}, actualNames{k});
                        return;
                    end
                    this.assertEqual(actual(actualNames{k}), expected(expectedNames{k}));
                end
            elseif isa(expected, 'datetime')
                if ~isobject(actual) || ~isequal(expected, actual)
                    this.err('Error: Expected datetime %s, found %s', char(expected), TestCase.toString(actual));
                end
            else
                this.err('Error: Cannot compare type %s', class(expected));
            end
        end
        
        function assertEmpty(this, actual)
            if ~isempty(actual)
                this.err('Error: Expected empty, found ...');
                actual
            end
        end
        
        function err(this, varargin)
            c = varargin(2:end);
            fprintf(1, varargin{1}, c{:});
            fprintf(1, '\n');
            this.errorCount = this.errorCount + 1;
        end
        
    end % methods
    
    methods (Static)
        function s = toString(obj)
            if ischar(obj)
                s = ['(char) ' obj];
            elseif isnumeric(obj)
                s = num2str(obj);
            elseif islogical(obj)
                if obj
                    s = 'true';
                else
                    s = 'false';
                end
            else
                s = class(obj);
            end
        end
    end % methods
end
