% COPYRIGHT Wolfgang Kuehn 2016 under the MIT License (MIT).
% Origin is https://github.com/decatur/ansatz27.

function obj = getPath(obj, pointer, default)
%GETPATH Returns the value under the pointer or empty if the pointer does not exist.
% The pointer must be in JSON pointer syntax, so each component must be prefixed by /.
%
% Example:
%    obj = struct('foo', struct('bar', 13))
%    getPath(obj, '/foo/bar') -> 13

if isempty(pointer)
    if isempty(obj)
        obj = default;
    end
    return;
end


if pointer(1) ~= '/'
    error('Invalid pointer', pointer)
end

parts = strsplit(pointer, '/');

for k = 2:length(parts)
    if isfield(obj, parts{k})
        obj = obj.(parts{k});
    else
        if nargin >= 3
            obj = default;
        else
            obj = [];
        return
    end
end

end
