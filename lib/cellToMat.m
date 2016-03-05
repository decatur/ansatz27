function m=cellToMat(c)

assert(iscell(c));

if isempty(c)
    m = [];
    return;
end

cc = c;
dims = [];

while iscell(cc)
    dims = [dims length(cc)];
    if length(cc) > 0
        cc = cc{1};
    else
        break;
    end
end

if length(dims) == 1
    dims = [1 dims];
end

m = inf(dims(:));

hasLogical = false;
hasNumeric = false;
cc = c;
stack = {c};
ind = {1};

while true
    k = ind{end};
    if k<=length(stack{end})
        cc = stack{end}{k};
        if iscell(cc)
            stack{end+1} = cc;
            ind{end+1} = 1;
        elseif isnumeric(cc) || islogical(cc)
            if isempty(cc)
                cc = nan;
            end

            if islogical(cc)
                hasLogical = true;
            else
                hasNumeric = true;
            end
            
            indx = struct('type', '()');
            indx.subs = ind;
            m = subsasgn(m, indx, cc);
            ind{end} = 1+ind{end};
        else
            m = c;
            return;
        end
    else
        stack = stack(1:end-1);
        if isempty(stack)
            break;
        end
        ind = ind(1:end-1);
        ind{end} = 1 + ind{end};
    end
end

if any(isinf(m(:)))
   m = c;
elseif hasNumeric && hasLogical
    m=c 
elseif hasLogical
    l = true(dims(:));
    l(~m) = false;
    m = l;
end

end