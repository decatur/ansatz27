% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Handler < handle

    properties (Constant)
        isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    end

    properties %(Access = private)
        errors
        schemaURL
        formatters
    end
    
    
    methods

        function this = JSON_Handler()
            if JSON_Handler.isoct
                this.formatters = ContainersMap();
            else
                this.formatters = containers.Map();
            end
        end

        function text = readFileToString(this, path, encoding )
            if JSON_Handler.isoct
                fid = fopen(path, 'r');
            else
                fid = fopen(path, 'r', 'l', encoding);
            end
            text = fscanf(fid, '%c');
            fclose(fid);
        end

        function [ schema, schemaURL ] = loadSchema(this, schema)
            schemaURL = [];

            if ischar(schema) && regexp(schema, '^file:')
                schemaURL = regexprep(schema, '^file:', '');
                schema = this.readFileToString(schemaURL, 'latin1');
                schema = JSON_Parser.parse(schema);
            else
                error('Illegal type for schema');
            end
        end

        function rootDir = getRootDir(this)
            if isempty(this.schemaURL)
                % TODO: We need a file url in order to load sub-schemas from the
                % same location!
                error('rootschema must be a url to a schema');
            end
            rootDir = fileparts(this.schemaURL);
        end

        function schema = normalizeSchema(this, schema)
        %normalizeSchema recursively descends the schema and resolves allOf references.
            
            if ~isstruct(schema)
                return
            end

            if isfield(schema, 'allOf')
                schema = this.mergeSchemas(schema);
            end

            if ~isfield(schema, 'type')
                return
            end

            if strcmp(schema.type, 'object') && isfield(schema, 'properties')
                props = schema.properties;
                pNames = fieldnames(props);
                for k=1:length(pNames)
                    schema.properties.(pNames{k}) = this.normalizeSchema(props.(pNames{k}));
                end
            elseif strcmp(schema.type, 'array') && isfield(schema, 'items') 
                if isstruct(schema.items)
                    schema.items = this.normalizeSchema(schema.items);
                elseif iscell(schema.items)
                    for k=1:length(schema.items)
                        schema.items{k} = this.normalizeSchema(schema.items{k});
                    end
                end
            end

        end

        function [ mergedSchema ] = mergeSchemas(this, schema)
            %MERGESCHEMAS Summary of this function goes here
            %   Detailed explanation goes here

            % Merge properties and required fields of all schemas.
            mergedSchema = struct;
            mergedSchema.type = 'object';
            mergedSchema.properties = struct;
            mergedSchema.required = {};

            rootDir = this.getRootDir();

            for k=1:length(schema.allOf)
                subSchema = schema.allOf{k};
                if isfield(subSchema, 'x_ref')
                    subSchema = JSON_Parser.parse(this.readFileToString( fullfile(rootDir, subSchema.x_ref), 'latin1' ));
                end
                
                keys = fieldnames(subSchema.properties);
                for l=1:length(keys)
                    key = keys{l};
                    mergedSchema.properties.(key) = subSchema.properties.(key);
                end

                if isfield(subSchema, 'required')
                    if isfield(mergedSchema, 'required')
                        mergedSchema.required = [mergedSchema.required subSchema.required];
                    else
                        mergedSchema.required = subSchema.required;
                    end
                end
            end
        end

    end

    methods (Static)

        function s = datenum2string(n)
            if ~isnumeric(n) || rem(n, 1) ~=0 
                s = n;
                return;
            end

            s = datestr(n, 'yyyy-mm-dd');
        end

        function s = datetimenum2string(n)
            if ~isnumeric(n)
                s = n;
                return;
            end

            s = datestr(n, 'yyyy-mm-ddTHH:MM:SSZ');
        end

        function d = datestring2num(s)
            % Parse date into a numerical date according MATLABs datenum().
            % The argument is returned if it is not a valid date.
            %
            % Example: '2016-01-26'

            m = regexp(s, '^(\d{4})-(\d{2})-(\d{2})$', 'tokens', 'once');

            if isempty(m)
                d = s;
                return
            end

            d = datenum(str2double(m{1}),str2double(m{2}),str2double(m{3}));
        end

        function d = datetimestring2num(s)
            % Parse date-time with timezone offset into a numerical date according MATLABs datenum().
            % Minutes and seconds are optional. Timezone offset is Z (meaning +0000) or of the form +-02:00 or +-0200.
            % The argument is returned if it is not a valid date-time.
            %
            % Example: '2016-02-02 12:30:35+02:00'
            
            %  y = 2016     m = 02     d = 02
            %  h = 12      mi = :30  sec = :35
            %  o = +02:00  oh = 02   omi = 00

            % Note: This regexp is tuned for some Octave bugs with named tokens!
            names = regexp(s, '^(?<y>\d{4})-(?<m>\d{2})-(?<d>\d{2})(T|\s)(?<h>\d{2})(?<mi>:\d{2})?(?<sec>:\d{2})?(?<o>(\+|-)(?<oh>\d{2}):?(?<omi>\d{2})|Z)$', 'names', 'once');


            if isempty(names.y)
                d = s;
                return
            end

            y = str2double(names.y);
            m = str2double(names.m);
            d = str2double(names.d);
            h = str2double(names.h);

            mi = 0;
            if ~isempty(names.mi)
                mi = str2double(names.mi(2:end));
            end

            sec = 0;
            if ~isempty(names.sec)
                sec = str2double(names.sec(2:end));
            end

            if names.o == 'Z'
                offset = 0;
            else
                % Offset from Z in minutes.
                offset = str2double(names.oh)*60+str2double(names.omi);
                if names.o(1) == '+'
                    % Note: Positive offset means point in time is earlier than Z.
                    offset = -offset;
                end
            end

            % Note: minutes in access to 60 are rolled over to hours by datenum().
            d = datenum(y, m, d, h, mi + offset, sec);
        end
        
    end
end

