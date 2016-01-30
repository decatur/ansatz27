% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function [ mergedSchema ] = mergeSchemas( schema, rootDir )
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

for i=1:length(schema.allOf)
    subSchema = schema.allOf{i};
    if isfield(subSchema, 'x_ref')
        subSchema = JSON_parseValidate(readFileToString( fullfile(rootDir, subSchema.x_ref), 'latin1' ));
    end
    
    mergedSchema.properties = mixInStruct( mergedSchema.properties, subSchema.properties);
    mergedSchema.required = [mergedSchema.required subSchema.required];
end


end

