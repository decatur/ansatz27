function text = getElementText(parentNode, tagName)
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
    end
end