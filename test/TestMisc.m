classdef TestMisc < TestCase

methods

    function this = TestMisc()
        this.name = 'Comprehensive Tests';
    end

    function _exec(this)

        [obj, errors] = JSON.parse('file:document.json', 'file:schema.json');

        m = JSON_Parser.cellToMat({1 2});
        assert(isequal(m, [1 2]));

        m = JSON_Parser.cellToMat({{1} {2}});
        assert(isequal(m, [1;2]));

        m = JSON_Parser.cellToMat({{1 2} {[] 4}});
        assert(isequaln(m, [1 2;NaN 4]));

        m = JSON_Parser.cellToMat({{{1 2} {3 4}} {{5 6} {7 8}}});
        assert(isequal(squeeze(m(1,:,:)), [1 2;3 4]));
        assert(isequal(squeeze(m(2,:,:)), [5 6; 7 8]));
        assert(isequal(m, permute(cat(3, [1 3;2 4], [5 7; 6 8]), [3 2 1])));

        m = JSON_Parser.cellToMat({1 NaN 3});
        assert(isequaln(m, [1 NaN 3]));

        % A JSON Schema is a JSON document, and that document MUST be an object
        [obj, errors] = JSON.parse('1', '2');
        assert(strcmp(errors{1}{2}, 'Could not resolve URI 2'));

        m = containers.Map();
        m('a') = 1;
        m('_*') = 2;
        assert(m('a') == 1);
        assert(m('_*') == 2);
        assert(all(ismember(m.keys(), {'a', '_*'})));
        assert(m.isKey('a'));
        assert(m.isKey('_*'));


        [json, errors] = JSON.parse(sprintf('{"f":12\n,}'));
        assert(strcmp(errors{1}{2}, 'tangling comma before line 2, column 2'));

        [json, errors] = JSON.parse('[1, 2,]');
        assert(strcmp(errors{1}{2}, 'tangling comma before line 1, column 7'));

        tc = TestCase();

        [obj, errors] = JSON.parse('a[1,2]');
        tc.assertEqual(errors{1}{2}(1:36), 'Could not resolve URI a[1,2] because');

        % Check for invalid chars in string "fo\x01o"
        [obj, errors] = JSON.parse(char([34  102  111 1 111 34]));
        tc.assertEqual(errors{1}{2}, 'Invalid char found in range #00-#1F at line 1, column 4');

        % Check that faulty schemas get reported
        [obj, errors] = JSON.parse('"foo"', '{sdsd=2}');
        assert(~isempty(errors));

        [obj, errors] = JSON.parse('"foo\tbar"');
        assert(isempty(errors));
        assert(strcmp(obj, sprintf('foo\tbar')));

        [obj, errors] =  JSON.parse(sprintf('"foo\tbar"'));
        assert(strcmp(errors{1}{2}, 'Invalid char found in range #00-#1F at line 1, column 5'));

        uriPrefix = ['file:///' strrep(pwd, '\', '/') '/'];

        [obj, errors] = JSON.parse([uriPrefix 'issue6/request.json'], [uriPrefix  'issue6/request_schema.json']);
        assert(isempty(errors));
        assert(isa(obj.start, 'datetime'));

        % [o, errors] = JSON.parse([uriPrefix 'bugreport3/Parameters.json'], [uriPrefix  'bugreport3/ParametersSchema.json']);
        % assert(isempty(errors));
        % assert(isfield(o, 'SEK'));
        % 
        % [o, errors] = JSON.parse([uriPrefix 'bugreport2/Parameters.json'], [uriPrefix  'bugreport2/ParametersSchema.json']);
        % assert(length(errors) == 1);
        % isequal(fieldnames(o) , {'SEK'; 'Signals'});
        % 
        % [o, errors] = JSON.parse([uriPrefix 'bugreport/testExample.json'], [uriPrefix  'bugreport/streamsContainer_schema.json']);
        % assert(isempty(errors));
        % assert(iscell(o) && length(o) == 1);

    end

end % methods
end % class
