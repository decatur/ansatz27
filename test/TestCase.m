% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef TestCase < handle
    
    methods

        function this = TestCase()
        end

        function assertEqual(this, actual, expected)
            % Important: We do not use Octaves recursive isequal because it does not use overloaded isequal on objects!
            
            msg = 'TestCase failed';
            if isempty(expected)
                if ~isempty(actual)
                    error(msg);
                end
            elseif ischar(expected)
                if ~ischar(actual) || ~strcmp(actual, expected)
                    error(msg);
                end
            elseif isnumeric(expected)
                if ~isnumeric(actual) || ~isequaln(actual, expected)
                    error(msg);
                end
            elseif islogical(expected)
                if ~islogical(actual) || ~isequal(actual, expected)
                    error(msg);
                end
            elseif iscell(expected)
                if ~iscell(actual) || length(expected) ~= length(actual)
                    error(msg);
                end
                for k=1:length(expected)
                    this.assertEqual(actual{k}, expected{k})
                end
            elseif isstruct(expected)
                if ~isstruct(actual)
                    error(msg);
                end
                
                expectedNames = sort(fieldnames(expected));
                actualNames = sort(fieldnames(actual));
                
                if length(expected) ~= length(actual) || length(expectedNames) ~= length(actualNames)
                    error(msg);
                end
                
                for m=1:length(expected)
                    for k=1:length(expectedNames)
                        if ~strcmp(expectedNames{k}, actualNames{k})
                            error(msg);
                        end
                        this.assertEqual(actual(m).(actualNames{k}), expected(m).(expectedNames{k}));
                    end
                end
            elseif isa(expected, 'Map')
                if ~isa(actual, 'Map')
                    error(msg);
                end

                expectedNames = sort(expected.keys());
                actualNames = sort(actual.keys());
                
                if length(expectedNames) ~= length(actualNames)
                    error(msg);
                end
                
                for k=1:length(expectedNames)
                    if ~strcmp(expectedNames{k}, actualNames{k})
                        error(msg);
                    end
                    this.assertEqual(actual(actualNames{k}), expected(expectedNames{k}));
                end
            elseif isobject(expected)
                if ~isobject(actual) || ~expected.isequal(actual)
                    error(msg);
                end
            else
                error('Cannot compare type %s', class(expected));
            end
        end

        function assertEmpty(this, actual)
            msg = 'TestCase failed';
            if ~isempty(actual)
                error(msg);
            end
        end

        
    end

    methods (Static)
    end
end
