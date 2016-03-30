classdef TestBase < TestCase

properties
    fileName
    tests
    absdir
end

methods

function this = TestBase(fileName)
    this.fileName = fileName;
    this.absdir = fileparts(which(fileName));
    this.absdir = strrep(this.absdir, '\', '/');
end

function exec(this, description)
    document = xmlread(fullfile(this.absdir, this.fileName));
    tests = document.getDocumentElement().getElementsByTagName('test');
    for k=1:tests.getLength()
        test = tests.item(k-1);
        desc = this.getElementText(test, 'description');
        
        if nargin >= 2 && ~strcmp(desc, description)
            continue;
        end

        if strcmp(test.getAttribute('skip'), 'true')
            fprintf(1, '\t\tSkipping\n');
            continue;
        end

        fprintf(1, '%s ... ', desc);
        tic();
        this.execSingle(test);
        fprintf(1, 'OK in %g[sec]\n', toc());
    end
end

function text = getElementText(this, parentNode, tagName)
    nodeList = parentNode.getElementsByTagName(tagName);
    if nodeList.getLength() == 0
        text = '';
    else
        text = char(nodeList.item(0).getTextContent());
        %text = regexprep(text, '^[^\n]*\n', '');
        text = regexprep(text, '\s*$', '');
        [a indentLength] = regexp(text, '^\n\s*', 'once');
        text = regexprep(text, sprintf('\n\\s{%i}', indentLength-1), '\n');
        %text = regexprep(text, '    ', '  ');
        text = regexprep(text, '^\n', '');

        if strcmp(tagName, 'schema')
            text = strrep(text, 'BASE_URI', ['file:' this.absdir]);
        end
    end
end

end

end