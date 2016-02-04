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

        function b = subsref (a, s)
            if (isempty (s))
                error ("polynomial: missing index");
            end

            b = [];
            if strcmp(s(1).type, '()')
                ind = s(1).subs;
                b = ind;
            end
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
                
                keys = fieldnames(subSchema.properties)
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
            formatString = 'yyyy-MM-dd';

            if ( isnumeric(n) && rem(n, 1) ~=0 )
                formatString = [formatString '''T''HH:mmZ'];
            end

            if JSON_Handler.isoct
                format = javaObject('java.text.SimpleDateFormat' ,formatString);
            else
                format = java.text.SimpleDateFormat(formatString);
            end

            millisPerDay = 1000*60*60*24;

            d = javaObject('java.util.Date' , (n-719529)*millisPerDay);
            s = char(format.format(d));

        end

        function d = datestring2num(s)
            formatString = 'yyyy-MM-dd';

            if ( isempty(regexp(s, '^\d{4}-\d{2}-\d{2}$')) )
                formatString = [formatString '''T''HH:mmZ'];
            end

            if JSON_Handler.isoct
                format = javaObject('java.text.SimpleDateFormat' ,formatString);
            else
                format = java.text.SimpleDateFormat(formatString);
            end

            millisPerDay = 1000*60*60*24;
            d = 719529 + format.parse(s).getTime()/millisPerDay;
        end
        
    end
end

