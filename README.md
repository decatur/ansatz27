A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

The JSON schema specification http://json-schema.org/ is used to map between JSON and MATLABs data types and to validate data.

# Requirements
GNU Octave version minimum 4.0 or MATLAB about version 2006 (verified for 2013b).
There are no dependencies.

# Related Work

# JSON Schema and Type Coersion

For all use cases of ansatz27, schemas are optional. However, their use is strongly encouraged.

Without schemas, roundtripping may break structure, for example

|     JSON   ->  |     MATLAB   ->  |   JSON       |
|----------------|------------------|--------------|
| { "foo": [1] } | struct('foo', 1) | { "foo": 1 } |


JSON Schema is itself defined in JSON and can be parsed into a MATLAB structure.

# Usage

[//]: # "Comment"

```MATLAB
addpath('lib', 'test')

schema = struct('type', 'object')

[obj, errors] = JSON.parse('file:document.json', 'file:schema.json')
[obj, errors] = JSON.parse('{"foo": 1, "bar": 2}', schema)

obj = struct('foo', 1, 'bar', 2)
[json, errors] = JSON.stringify(obj, 'file:schema.json')
[json, errors] = JSON.stringify(obj, schema)

```

## Mapping

### Key mapping

Object keys which are not valid MATLAB variable names are mapped, for example `$ref -> x_ref` or `He@@o -> He__o`.

# Formatter

Formatters allow to make custom transformations. A typical candidate are dates and their mapping bewteen
string representation and MATLABs numerical representation. A formatter is invoked on an element if
the value of the format property (if any) is the name of a registered formatter. 

```MATLAB
stringifier = JSON_Stringifier()
stringifier.formatters('date') = @(x) JSON_Handler.datenum2string(x)
stringifier.formatters('date-time') = @(x) JSON_Handler.datetimenum2string(x)
```

On parse, formatters are applied *after* all parse, validation steps have been performed.
On stringify, formatters are performed *before* all validation and stringifying takes place.

There are two predefined formatters

## date

| JSON       | MATLAB    |
|------------|-----------|
| string     | numerical |
| 2016-02-08 | 736368    |

## datetime

| JSON                  | MATLAB    |
|-----------------------|-----------|
| string                | numerical |
| 2016-02-08T12Z        | 736368.5  |
| 2016-02-08T12:00+0000 | 736368.5  |
| 2016-02-08T13:00+0100 | 736368.5  |
| 2016-02-08T12:30:30Z  | 736368.521181  |


# Array comprehensions

| Schema       | JSON     | MATLAB       | Motivation                 |
|--------------|----------|--------------|----------------------------|
| no schema    |  [...]   | cell array   | Array may be inhomogenious |
| items: [...] |  [...]   | cell array   | Array is inhomogenious     |
| items: {...} |  [...]   | struct array | Array is homogenious       |

# Defaults

A schema may specify a default value. On stringify, defaults are ignored.
On parse, default values are set for unspecified object properties, see test cases below.


# Roundtrip Test Cases

All entries are unit tests (:y: success, :x: failure).

[//]: # "ROUNDTRIP"

<table><tbody valign="top">
<tr><th>MATLAB</th><th>Schema</th><th>JSON</th></tr>
<tr><td span="3">(Pass) Comprehensive</td></tr>
<tr><td><pre>a = struct('id', '4711');
a.portfolio.index = 3;
a.portfolio.value = 4.32;
a.deals = struct( ...
  'name', {'DEAL-A' 'DEAL-B'}, ...
  'value', {13.13 42.42});
a.dealValues = [13.13 42.42];</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "id": {
      "type": "string"
    },
    "portfolio": {
      "type": "object",
      "properties": {
        "index": {
          "type": "integer",
          "minimum": 1
        },
        "value": {
          "type": "number"
        }
      }
    },
    "deals": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "name": {
            "type": "string",
            "pattern": "^DEAL-\\w+$"
          },
          "value": {
            "type": "number",
            "minimum": 0
          }
        }
      }
    }
  }
}</pre></td><td><pre>{
  "id": "4711",
  "portfolio": {
    "index": 3,
    "value": 4.32
  },
  "deals": [
    {
      "name": "DEAL-A",
      "value": 13.13
    },
    {
      "name": "DEAL-B",
      "value": 42.42
    }
  ],
  "dealValues": [
    13.13,
    42.42
  ]
}</pre></td></tr>
<tr><td span="3">(Pass) AllOf</td></tr>
<tr><td><pre>struct( ...
  'id', '4711', ...
  'foo', 2, ...
  'bar', 'DEF_VAL')</pre></td><td><pre>{
  "allOf": [
    {
      "$ref": "schema2.json"
    },
    {
      "type": "object",
      "required": ["id"],
      "properties": {
        "id": {
          "type": "string"
        },
        "foo": {
          "type": "number"
        }
      }
    }
  ]
}</pre></td><td><pre>{
  "id":"4711",
  "foo":2,
  "bar":"DEF_VAL"
}</pre></td></tr>
<tr><td span="3">(Pass) Cell array</td></tr>
<tr><td><pre>{struct('foo', 1) struct('bar', 2)}</pre></td><td><pre>{
  "type": "array",
  "items": {
    "type": "object"
  }
}</pre></td><td><pre>[{"foo":1},{"bar":2}]</pre></td></tr>
<tr><td span="3">(Pass) Structure array</td></tr>
<tr><td><pre>struct('foo', {1 2}, 'bar', {3 4})</pre></td><td><pre>{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "foo": {},
      "bar": {}
    },
    "additionalProperties": false
  }
}</pre></td><td><pre>[
  {"foo":1,"bar":3},
  {"foo":2,"bar":4}
]</pre></td></tr>
<tr><td span="3">(Pass) Array of strings</td></tr>
<tr><td><pre>{'foo'}</pre></td><td><pre></pre></td><td><pre>["foo"]</pre></td></tr>
<tr><td span="3">(Pass) Scalar number</td></tr>
<tr><td><pre>1</pre></td><td><pre>{
  "type": "number",
  "enum": [1, 2]
}</pre></td><td><pre>1</pre></td></tr>
<tr><td span="3">(Pass) Scalar boolean</td></tr>
<tr><td><pre>true</pre></td><td><pre>{
  "type": "boolean"
}</pre></td><td><pre>true</pre></td></tr>
<tr><td span="3">(Pass) Null or NaN</td></tr>
<tr><td><pre>NaN</pre></td><td><pre>{
  "type": "null"
}</pre></td><td><pre>null</pre></td></tr>
<tr><td span="3">(Pass) Single string with enumeration</td></tr>
<tr><td><pre>'foo'</pre></td><td><pre>{
  "type": "string",
  "enum": ["bar", "foo"]
}</pre></td><td><pre>"foo"</pre></td></tr>
<tr><td span="3">(Pass) Row vector</td></tr>
<tr><td><pre>[1 2]</pre></td><td><pre></pre></td><td><pre>[1,2]</pre></td></tr>
<tr><td span="3">(Pass) Mixed array</td></tr>
<tr><td><pre>{1, struct(), 2}</pre></td><td><pre>{
  "type": "array",
  "items": {"type": ["number", "object"]}
}</pre></td><td><pre>[1,{},2]</pre></td></tr>
<tr><td span="3">(Pass) Row vector with NaN</td></tr>
<tr><td><pre>[1 NaN 2]</pre></td><td><pre>{
  "type": "array",
  "items": {
    "type": ["number", "null"]
  }
}</pre></td><td><pre>[1,null,2]</pre></td></tr>
<tr><td span="3">(Pass) Matrix</td></tr>
<tr><td><pre>[ [1 2 NaN]; [4 -5 6] ]</pre></td><td><pre>{
  "type": "array",
  "items": {
    "type": "array",
    "items": {
      "type": ["number", "null"]
    }
  }
}</pre></td><td><pre>[[1,2,null],[4,-5,6]]</pre></td></tr>
<tr><td span="3">(Pass) Simple object</td></tr>
<tr><td><pre>struct('foo', 'bar')</pre></td><td><pre></pre></td><td><pre>{"foo":"bar"}</pre></td></tr>
<tr><td span="3">(Pass) Empty object, no schema</td></tr>
<tr><td><pre>struct()</pre></td><td><pre></pre></td><td><pre>{}</pre></td></tr>
<tr><td span="3">(Pass) Empty object</td></tr>
<tr><td><pre>struct()</pre></td><td><pre>{ "type": "object", "properties": {} }</pre></td><td><pre>{}</pre></td></tr>
<tr><td span="3">(Pass) Cell array</td></tr>
<tr><td><pre>{
  struct('foo',1) ...
  struct('foo',2)
}</pre></td><td><pre></pre></td><td><pre>[{"foo":1},{"foo":2}]</pre></td></tr>
<tr><td span="3">(Pass) Row vector (Fragile)</td></tr>
<tr><td><pre>[1 2]</pre></td><td><pre></pre></td><td><pre>[1,2]</pre></td></tr>
<tr><td span="3">(Pass) Matrix 2x2 (Fragile)</td></tr>
<tr><td><pre>[1 2;3 4]</pre></td><td><pre></pre></td><td><pre>[[1,2],[3,4]]</pre></td></tr>
<tr><td span="3">(Pass) Column vector (Fragile)</td></tr>
<tr><td><pre>[1; 2]</pre></td><td><pre></pre></td><td><pre>[[1],[2]]</pre></td></tr>
<tr><td span="3">(Pass) Array of strings</td></tr>
<tr><td><pre>{'foo' 'bar'}</pre></td><td><pre></pre></td><td><pre>["foo","bar"]</pre></td></tr>
<tr><td span="3">(Pass) Single number</td></tr>
<tr><td><pre>1</pre></td><td><pre></pre></td><td><pre>1</pre></td></tr>
<tr><td span="3">(Pass) Single boolean</td></tr>
<tr><td><pre>true</pre></td><td><pre></pre></td><td><pre>true</pre></td></tr>
<tr><td span="3">(Pass) Single string</td></tr>
<tr><td><pre>'Hello-World'</pre></td><td><pre></pre></td><td><pre>"Hello-World"</pre></td></tr>
<tr><td span="3">(Pass) Single boolean</td></tr>
<tr><td><pre>true</pre></td><td><pre></pre></td><td><pre>true</pre></td></tr>
<tr><td span="3">(Pass) Single boolean</td></tr>
<tr><td><pre>false</pre></td><td><pre></pre></td><td><pre>false</pre></td></tr>
<tr><td span="3">(Pass) Boolean array (Fragile)</td></tr>
<tr><td><pre>[true false]</pre></td><td><pre></pre></td><td><pre>[true,false]</pre></td></tr>
<tr><td span="3">(Pass) Hint array</td></tr>
<tr><td><pre>1</pre></td><td><pre>{ "type": "array",
  "items": { "type": ["number", "null"] }
}</pre></td><td><pre>[1]</pre></td></tr>
<tr><td span="3">(Pass) Hint array of arrays</td></tr>
<tr><td><pre>1</pre></td><td><pre>{ 
  "type": "array",
  "items": {
  "type": "array",  
  "items": { "type": ["number", "null"] }
  }
}</pre></td><td><pre>[[1]]</pre></td></tr>
<tr><td span="3">(Pass) Foo</td></tr>
<tr><td><pre>[1 NaN 2]</pre></td><td><pre>{ "type": "array",
  "items": { "type": ["number", "null"] }
}</pre></td><td><pre>[1, null, 2]</pre></td></tr>
<tr><td span="3">(Pass) Empty array</td></tr>
<tr><td><pre>[]</pre></td><td><pre>{ "type": ["array", "null"] }</pre></td><td><pre>[]</pre></td></tr>
<tr><td span="3">(Pass) 3D matrix</td></tr>
<tr><td><pre>a = NaN(2,2,2);
a(1,:,:) = [1 2; 3 4];
a(2,:,:) = [5 6; 7 8];</pre></td><td><pre></pre></td><td><pre>[[[1,2],[3,4]],[[5,6],[7,8]]]</pre></td></tr>
<tr><td span="3">(Pass) Foo</td></tr>
<tr><td><pre>[1 NaN]</pre></td><td><pre>{
  "type": "array",
  "items": [{"type": "number"}, {"type": "null"}]
}</pre></td><td><pre>[1,null]</pre></td></tr>
<tr><td span="3">(Pass) From-till-value list</td></tr>
<tr><td><pre>[datenum("2016-01-01") datenum("2016-01-31") 13]</pre></td><td><pre>{
  "type": "array",
  "items": [
    {"type": "string", "format": "date"},
    {"type": "string", "format": "date"},
    {"type": ["number", "null"] }
  ]
}</pre></td><td><pre>["2016-01-01","2016-01-31",13]</pre></td></tr>
<tr><td span="3">(Pass) List of from-till-value lists</td></tr>
<tr><td><pre>[
  [datenum("2016-01-01") datenum("2016-01-31") 13.13]
  [datenum("2016-02-01") datenum("2016-02-29") 42.42]
]</pre></td><td><pre>{
  "type": "array",
  "items": {
    "type": "array",
    "items": [
      {"type": "string", "format": "date"},
      {"type": "string", "format": "date"},
      {"type": ["number", "null"] }
    ]
  }
}</pre></td><td><pre>[
  ["2016-01-01", "2016-01-31", 13.13],
  ["2016-02-01", "2016-02-29", 42.42]
]</pre></td></tr>
<tr><td span="3">(Pass) Foo1</td></tr>
<tr><td><pre>struct('foo', 1)</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "foo": { "type": "array" }
  }
}</pre></td><td><pre>{"foo":[1]}</pre></td></tr>
<tr><td span="3">(Pass) Foo</td></tr>
<tr><td><pre>'Hello'</pre></td><td><pre>{
  "type": "string",
  "pattern": "^\\w+$"
}</pre></td><td><pre>"Hello"</pre></td></tr>
<tr><td span="3">(Pass) Date formater</td></tr>
<tr><td><pre>struct( ...
  'myDate', 1+datenum('2016-01-02'), ...
  'myDateTime', 1.5+datenum('2016-01-02') ...
)</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "myDate": { 
      "type": "string",
      "format": "date"
    },
    "myDateTime": { 
      "type": "string",
      "format": "date-time"
    }
  }
}</pre></td><td><pre>{
  "myDate":"2016-01-03",
  "myDateTime":"2016-01-03T12:00:00+0100"
}</pre></td></tr>
</tbody></table>

[//]: # "ROUNDTRIP"


# Validation Test Cases

[//]: # "VALIDATION"

<table><tbody valign="top">
<tr><th>MATLAB</th><th>JSON</th><th>Schema</th><th>Errors</th></tr>
<tr><td span="4">Array with one string</td></tr>
<tr><td><pre>{'foo'}</pre></td><td><pre>["foo"]</pre></td><td><pre>{ "type": "object" }</pre></td><td><pre>{'' 'does not match type object' '[array]'}</pre></td></tr>
<tr><td span="4">Row vector with NaNs</td></tr>
<tr><td><pre>[NaN 1]</pre></td><td><pre>[null,1]</pre></td><td><pre>{ "type": "array",
  "items": [
  { "type": "number" },
  { "type": "null"}]
}</pre></td><td><pre>{'/1' 'does not match type number' 'NaN'}
{'/2' 'does not match type null' '1'}</pre></td></tr>
<tr><td span="4">Foo1</td></tr>
<tr><td><pre>struct('foo', 1)</pre></td><td><pre>{"foo":1}</pre></td><td><pre>{
  "type": "object",
  "required": ["bar"]
}</pre></td><td><pre>{'' 'is missing required field bar' '{object}'}</pre></td></tr>
<tr><td span="4">Foo2</td></tr>
<tr><td><pre>[1 2]</pre></td><td><pre>[1, 2]</pre></td><td><pre>{
  "type": "object"
}</pre></td><td><pre>{'' 'does not match type object' '1  2'}</pre></td></tr>
<tr><td span="4">Foo3</td></tr>
<tr><td><pre>'foo'</pre></td><td><pre>"foo"</pre></td><td><pre>{
  "type": "number"
}</pre></td><td><pre>{'' 'does not match type number' 'foo'}</pre></td></tr>
<tr><td span="4">Foo4</td></tr>
<tr><td><pre>true</pre></td><td><pre>true</pre></td><td><pre>{
  "type": "number"
}</pre></td><td><pre>{'' 'does not match type number' 'true'}</pre></td></tr>
<tr><td span="4">Foo4</td></tr>
<tr><td><pre>{'foo'}</pre></td><td><pre>["foo"]</pre></td><td><pre>{
  "type": "object"
}</pre></td><td><pre>{'' 'does not match type object' '[array]'}</pre></td></tr>
<tr><td span="4">Foo6</td></tr>
<tr><td><pre>'Hello World'</pre></td><td><pre>"Hello World"</pre></td><td><pre>{
  "type": "string",
  "pattern": "^\\w+$"
}</pre></td><td><pre>{'' 'does not match pattern ^\w+$' 'Hello World'}</pre></td></tr>
<tr><td span="4">Foo6</td></tr>
<tr><td><pre>'Hello World'</pre></td><td><pre>"Hello World"</pre></td><td><pre>{
  "type": "string",
  "enum": ["foo", "bar"]
}</pre></td><td><pre>{'' 'is not contained in enumeration' 'Hello World'}</pre></td></tr>
<tr><td span="4">Foo6</td></tr>
<tr><td><pre>4711</pre></td><td><pre>4711</pre></td><td><pre>{
  "type": "integer",
  "enum": [1, 2, 3, 4]
}</pre></td><td><pre>{'' 'is not contained in enumeration' '4711'}</pre></td></tr>
<tr><td span="4">External Schema</td></tr>
<tr><td><pre>struct('id', '4711', 'bar', 2)</pre></td><td><pre>{
  "id":"4711",
  "bar":2
}</pre></td><td><pre>{
  "$ref": "schema2.json"
}</pre></td><td><pre>{'/bar' 'does not match type string' '2'}</pre></td></tr>
<tr><td span="4">Internal Schema</td></tr>
<tr><td><pre>struct('id', '4711', 'bar', 2)</pre></td><td><pre>{
  "id": "4711",
  "bar": 2
}</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "bar": { "$ref": "#/definitions/bar" }
  },
  "additionalProperties": false,
  "definitions": {
    "bar": { "type": "string" }
  }
}</pre></td><td><pre>{'/bar' 'does not match type string' '2'}</pre></td></tr>
<tr><td span="4">additionalProperties</td></tr>
<tr><td><pre>{
  struct('id', '4711', 'bar', 2)
  struct('id', '4711', 'bar', 2, 'foo', 'Hello')
}</pre></td><td><pre>[
  {
    "id":"4711",
    "bar":2
  },
  {
    "id":"4711",
    "bar":2,
    "foo": "Hello"
  }
]</pre></td><td><pre>{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": { "type": "string" },
      "bar": { "type": "number" }
    },
    "additionalProperties": false
  }
}</pre></td><td><pre>{'/2' 'contains additional properties' '{object}'}</pre></td></tr>
<tr><td span="4">Invalid Reference</td></tr>
<tr><td><pre>struct('id', '4711', 'bar', 2)</pre></td><td><pre>{
  "id": "4711",
  "bar": 2
}</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "bar": { "$ref": "#/definitions/BAR" }
  },
  "definitions": {
    "bar": { }
  }
}</pre></td><td><pre>{[] 'Invalid $ref at /properties/bar -> #/definitions/BAR' ''}</pre></td></tr>
<tr><td span="4">Invalid Reference</td></tr>
<tr><td><pre>struct('id', '4711', 'bar', 2)</pre></td><td><pre>{
  "id": "4711",
  "bar": 2
}</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "bar": { "$ref": 4711 }
  }
}</pre></td><td><pre>{[] 'Invalid $ref at /properties/bar' ''}</pre></td></tr>
<tr><td span="4">Cyclic Schema References</td></tr>
<tr><td><pre>struct('id', '4711', 'bar', 2)</pre></td><td><pre>{
  "id": "4711",
  "bar": 2
}</pre></td><td><pre>{
  "type": "object",
  "properties": {
    "id": { "type": "string" },
    "bar": { "$ref": "#/definitions/barType" }
  },
  "additionalProperties": false,
  "definitions": {
    "barType": { "$ref": "#/properties/bar" }
  }
}</pre></td><td><pre>{[] 'Cyclic references /properties/bar -> #/definitions/barType -> #/properties/bar' ''}</pre></td></tr>
</tbody></table>

[//]: # "VALIDATION"

# Parse Oneway Test Cases

[//]: # "PARSE"

<table><tbody valign="top">
<tr><th>MATLAB</th><th>Schema</th><th>JSON</th></tr>
<tr><td span="3">Structure array</td></tr>
<tr><td><pre>{'foo'}</pre></td><td><pre></pre></td><td><pre>["foo"]</pre></td></tr>
<tr><td span="3">AllOf</td></tr>
<tr><td><pre>struct('id', '4711', 'foo', 2, 'bar', 'DEF_VAL')</pre></td><td><pre>{
  "$ref": "schema2.json"
}</pre></td><td><pre>{
  "id":"4711",
  "foo":2
}</pre></td></tr>
</tbody></table>

[//]: # "PARSE"

# Stringify Oneway Test Cases

[//]: # "STRINGIFY"

<table><tbody valign="top">
<tr><th>MATLAB</th><th>Schema</th><th>JSON</th></tr>
<tr><td span="3">Structure array</td></tr>
<tr><td><pre>struct('foo', {1 2})</pre></td><td><pre></pre></td><td><pre>[{"foo":1},{"foo":2}]</pre></td></tr>
<tr><td span="3">Treatment of Inf</td></tr>
<tr><td><pre>Inf</pre></td><td><pre></pre></td><td><pre>null</pre></td></tr>
<tr><td span="3">Treatment of special numbers</td></tr>
<tr><td><pre>[1 Inf -Inf NaN 2]</pre></td><td><pre></pre></td><td><pre>[1,null,null,null,2]</pre></td></tr>
<tr><td span="3">Foo</td></tr>
<tr><td><pre>[1 NaN Inf -Inf 2]</pre></td><td><pre>{ "type": "array",
  "items": { "type": ["number", "null"] }
}</pre></td><td><pre>[1,null,null,null,2]</pre></td></tr>
<tr><td span="3">Fixed precision</td></tr>
<tr><td><pre>pi</pre></td><td><pre>{
  "type": "number",
  "fixedPrecision": 2
}</pre></td><td><pre>3.14</pre></td></tr>
<tr><td span="3">Array of arrays with fixed precision</td></tr>
<tr><td><pre>pi</pre></td><td><pre>{ 
  "type": "array",
  "items": {
    "type": "array",  
    "items": {
      "type": ["number", "null"], 
      "fixedPrecision": 2
    }
  }
}</pre></td><td><pre>[[3.14]]</pre></td></tr>
</tbody></table>

[//]: # "STRINGIFY"

# Building

1. Execute `tests.m`
2. Execute `build.py`
3. Copy `build/README.md` to `README.md`

# Octave Limitations
Encoding of files

Design
We do not functions in private directories. Octave Version 4.0 cannot resolve those from a class member function.

# Testing

The schemas and documents in the tests where validated with http://jsonschemalint.com/draft4/
