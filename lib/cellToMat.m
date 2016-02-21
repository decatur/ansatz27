function m = cellToMat(c)
%cellToMat converts a uniform cell array into a matrix if possible.
%
% Usage:
%   cellToMat({{1 2},{[] 4}})
%   ans 1   2
%       NaN 4
%

if ~iscell(c)
    m = c;
    return;
end

m = [];
itemSize = [];

for k=1:length(c)
    mm = cellToMat(c{k});
    
    if isempty(mm)
        mm = NaN;
    end
    
    if isnumeric(mm) && (k == 1 || isequal(itemSize, size(mm)))
        if numel(mm) > 1
            dim = 1;
        else
            dim = 2;
        end

        m = cat(dim, m, mm);
        itemSize = size(mm);

    else
        m = c;
        return;
    end

end

end