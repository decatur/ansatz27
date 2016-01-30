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

        function [ schema, schemaURL ] = loadSchema(this, schemaURL )
            if ischar(schemaURL)
                if regexp(schemaURL, '^file:')
                    schemaURL = regexprep(schemaURL, '^file:', '');
                    schema = this.readFileToString(schemaURL, 'latin1');
                end
                schema = JSON_Parser.parse(schema);
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
        
    end
end

