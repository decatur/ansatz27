function appendRow(fid, format, varargin)
    fprintf(fid, ['<tr>' format '</tr>\n'], varargin{:});
end