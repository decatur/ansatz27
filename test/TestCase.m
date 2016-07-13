% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef TestCase < handle
    
    properties
        errorCount
    end
    
    methods (Access=public)

        function this = TestCase()
            this.errorCount = 0;
        end

        function assertEqual(this, actual, expected)
            % Important: We do not use Octaves recursive isequal because it does not use overloaded isequal on objects!
            
            if isempty(expected)
                if ~isempty(actual)
                    fprintf(1, 'Error: Expected empty, found %s\n', TestCase.toString(actual));
                end
            elseif ischar(expected)
                if ~ischar(actual) || ~strcmp(actual, expected)
                    this.err('Error: Expected %s, found %s\n', expected, TestCase.toString(actual));
                end
            elseif isnumeric(expected)
                if ~isnumeric(actual) || ~isequaln(actual, expected)
                    fprintf(1, 'Error: Expected %g, found %s\n', expected, TestCase.toString(actual));
                end
            elseif islogical(expected)
                if ~islogical(actual) || ~isequal(actual, expected)
                    fprintf(1, 'Error: Expected %s, found %s\n', expected, TestCase.toString(actual));
                end
            elseif iscell(expected)
                if ~iscell(actual)
                    fprintf(1, 'Error: Expected cell, found %s\n', TestCase.toString(actual));
                elseif ~iscell(actual) || length(expected) ~= length(actual)
                    fprintf(1, 'Error: Expected cell of length %u, found length %u\n', length(expected), length(actual));
                end
                for k=1:length(expected)
                    this.assertEqual(actual{k}, expected{k})
                end
            elseif isstruct(expected)
                if ~isstruct(actual)
                    fprintf(1, 'Error: Expected struct, found %s\n', TestCase.toString(actual));
                end
                
                expectedNames = sort(fieldnames(expected));
                actualNames = sort(fieldnames(actual));
                
                if length(expected) ~= length(actual) || length(expectedNames) ~= length(actualNames)
                    fprintf(1, 'Error: Mismatch in field names. Expected %s, found %s', expectedNames{:}, actualNames{:});
                end
                
                for m=1:length(expected)
                    for k=1:length(expectedNames)
                        if ~strcmp(expectedNames{k}, actualNames{k})
                            fprintf(1, 'Error: Expected field name %s, found %s\n', expectedNames{k}, actualNames{k});
                        end
                        this.assertEqual(actual(m).(actualNames{k}), expected(m).(expectedNames{k}));
                    end
                end
            elseif isa(expected, 'Map') || isa(expected, 'containers.Map')
                if ~( isa(actual, 'Map') || isa(actual, 'containers.Map') )
                    fprintf(1, 'Error: Expected map, found %s\n', actual);
                end

                expectedNames = sort(expected.keys());
                actualNames = sort(actual.keys());
                
                if length(expectedNames) ~= length(actualNames)
                    fprintf(1, 'Error: Mismatch in field names. Expected %s, found %s', expectedNames{:}, actualNames{:});
                end
                
                for k=1:length(expectedNames)
                    if ~strcmp(expectedNames{k}, actualNames{k})
                         fprintf(1, 'Error: Expected field name %s, found %s\n', expectedNames{k}, actualNames{k});
                    end
                    this.assertEqual(actual(actualNames{k}), expected(expectedNames{k}));
                end
            elseif isa(expected, 'datetime')
                if ~isobject(actual) || ~isequal(expected, actual)
                    fprintf(1, 'Error: Expected datetime %s, found %s\n', toString(expected), TestCase.toString(actual));
                end
            else
                fprintf(1, 'Error: Cannot compare type %s', class(expected));
            end
        end

        function assertEmpty(this, actual)
            if ~isempty(actual)
                fprintf(1, 'Error: Unexpected\n');
                celldisp(actual);
            end
        end
        
        function err(this, varargin)
            c = varargin(2:end);
            fprintf(1, varargin{1}, c{:});
            this.errorCount = this.errorCount + 1;
        end
        
    end % methods

    methods (Static)
        function s = toString(obj)
            if ischar(obj)
                s = obj;
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
    end
end
