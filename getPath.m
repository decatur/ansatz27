function obj = getPath(obj, path)
%GETPATH Liefert den Wert unterhalb des Pfades
% Beisiel:
%    obj = struct('foo', struct('bar', 13))
%    getPath(obj, 'foo/bar') -> 13
%
% Author: Wolfgang Kuehn
parts = strsplit(path, '/');
for k=1:length(parts)
    if isfield(obj, parts{k})
        obj = obj.(parts{k});
    else
        obj = [];
        return
    end
end
return
end
