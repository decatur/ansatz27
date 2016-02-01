% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

classdef JSON_Handler < handle

    properties %(Access = private)
        errors
        schemaURL
        isoct
        formatters
    end
    
    
    methods

        function this = JSON_Handler()
            this.isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
            if this.isoct
                this.formatters = ContainersMap();
            else
                this.formatters = containers.Map();
            end
            this.formatters('date') = @datetime;
            this.formatters('date-time') = this.formatters('date');
        end

        function text = readFileToString(this, path, encoding )
            if this.isoct
                fid = fopen(path, 'r');
            else
                fid = fopen(path, 'r', 'l', encoding);
            end
            text = fscanf(fid, '%c');
            fclose(fid);
        end

        function [ schema, schemaURL ] = loadSchema(this, schema)
            schemaURL = [];

            if isempty(schema) || isstruct(schema)
                return;
            elseif ischar(schema) && regexp(schema, '^file:')
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

        function [ date_num ] = datetime(this, date_str)
            if regexp(date_str, '^\d{4}-\d{2}-\d{2}$')
                format = java.text.SimpleDateFormat('yyyy-MM-dd');
            else
                format = java.text.SimpleDateFormat('yyyy-MM-dd''T''HH:mmZ');
            end

            date_num = 719529 + format.parse(date_str).getTime()/1000/60/60/24;
        end

        function [ mergedSchema ] = mergeSchemas(this, schema)
            %MERGESCHEMAS Summary of this function goes here
            %   Detailed explanation goes here

            if ~isfield(schema, 'allOf')
                mergedSchema = schema;
                return
            end

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
end

