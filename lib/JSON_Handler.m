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

            s = datestr(n, 'yyyy-mm-ddTHH:MMZ');
        end

        function d = datestring2num(s)
            % Example: s = '2016-01-26'

            m = regexp(s, '^(\d{4})-(\d{2})-(\d{2})$', 'tokens', 'once');

            if isempty(m)
                d = s;
                return
            end

            d = datenum(str2double(m{1}),str2double(m{2}),str2double(m{3}));
        end

        function d = datetimestring2num(s)
            % Example: s = '2016-01-26T00:00+0200'

            m = regexp(s, '^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})((\+|-)(\d{2})(\d{2})|Z)$', 'tokens', 'once');

            if isempty(m)
                d = s;
                return
            end

            minutes = str2double(m{5});

            if m{6} ~= 'Z'
                % Offset from UTC in minutes.
                offset = str2double(m{8})*60+str2double(m{9});
                if m{7} == '+'
                    % Note: Positive offset means point in time is earlier than UTC.
                    minutes = minutes - offset;
                else
                    minutes = minutes + offset;
                end
            end

            % Note: minutes in access to 60 are rolled over to hours by datenum().
            d = datenum(str2double(m{1}), str2double(m{2}), str2double(m{3}), str2double(m{4}), minutes, 0);
        end
        
    end
end

