function p = getBadPath(path, indices)
isVec = length(indices) > 1;
indices = find(indices);
if isempty(indices)
    p = [];
elseif isVec
    p = [path num2str(indices)];
else
    p = path;
end
end

