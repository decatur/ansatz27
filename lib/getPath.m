% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function obj = getPath(obj, path)
%GETPATH Returns the value under the path or empty if the path does not exist.
% Example:
%    obj = struct('foo', struct('bar', 13))
%    getPath(obj, 'foo/bar') -> 13

parts = strsplit(path, '/');
for k=1:length(parts)
    if isfield(obj, parts{k})
        obj = obj.(parts{k});
    else
        obj = [];
        return
    end
end

end
