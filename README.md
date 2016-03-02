A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

The well established JSON schema specification http://json-schema.org/ is used to validate data and to map between JSON and MATLABs data types.
For all use cases of ansatz27, schemas are optional. However, their use is strongly encouraged.

Without schemas, roundtripping may break structure, for example

|     JSON   ->  |     MATLAB   ->  |   JSON       |
|----------------|------------------|--------------|
| { "foo": [1] } | struct('foo', 1) | { "foo": 1 } |

# Requirements
GNU Octave version minimum 4.0 or MATLAB about version 2006 (verified for 2013b).

# Dependencies
There are no dependencies.

# Related Work

# Parser

## Usage

[//]: # "Comment"
```
[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json')
[obj, errors] = JSON_Parser.parse('{"foo": 1, "bar: 2"}', 'file:schema.json')
```
## Mapping

### Key mapping

Object keys which are not valid MATLAB variable names are mapped, for example $ref -> x_ref.


# Stringifier

## Usage
```
[obj, errors] = JSON_Parser.parse('{"foo": 1, "bar: 2"}', '{ "type": "object" }')
[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json')

```

# Formatter

Formatters allow to make custom transformations. A typical candidate are dates and their mapping bewteen
string representation and MATLABs numerical representation. A formatter is invoked on an element if
the value of the format property (if any) is the name of a registered formatter. 
```
{
    "type": "string",
    "format": "date"
}
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

In each schema you may specify a default value.
```
{
    "type": "object",
    "properties": {
        "foo": { "type": "string", "default": "bar" }
    }
}
```

| JSON              | MATLAB    |
|-------------------|-----------|
| {}                | struct('foo', 'bar') |

Defaults are ignored when stringifying.

# Schema

JSON Schema is itself defined in JSON and can be parsed into a MATLAB structure.
```
schema = JSON_Parser.parse('file:schema.json')
```

# Roundtrip

[//]: # "ROUNDTRIP"

| MATLAB | Schema | JSON |
|--------|--------|------|
| Comprehensive |
| a = struct('id', '4711');<br/>a.portfolio.index = 3;<br/>a.portfolio.value = 4.32;<br/>a.deals = struct('name', {'DEAL-A' 'DEAL-B'}, 'value', {13.13 42.42});<br/>a.dealValues = [13.13 42.42]; | {<br/>"type": "object",<br/>"properties": {<br/>"id": {<br/>"type": "string"<br/>},<br/>"portfolio": {<br/>"type": "object",<br/>"properties": {<br/>"index": {<br/>"type": "integer",<br/>"minimum": 1<br/>},<br/>"value": {<br/>"type": "number"<br/>}<br/>}<br/>},<br/>"deals": {<br/>"type": "array",<br/>"items": {<br/>"type": "object",<br/>"additionalProperties": false,<br/>"properties": {<br/>"name": {<br/>"type": "string",<br/>"pattern": "^DEAL-\\w+$"<br/>},<br/>"value": {<br/>"type": "number",<br/>"minimum": 0<br/>}<br/>}<br/>}<br/>}<br/>}<br/>} | {"id":"4711","portfolio":{"index":3,"value":4.32},"deals":[{"name":"DEAL-A","value":13.13},{"name":"DEAL-B","value":42.42}],"dealValues":[13.13,42.42]} |
| AllOf |
| struct('id', '4711', 'foo', 2, 'bar', 'DEF_VAL') | {<br/>"allOf": [<br/>{<br/>"$ref": "schema2.json"<br/>},<br/>{<br/>"type": "object",<br/>"required": ["id"],<br/>"properties": {<br/>"id": {<br/>"type": "string"<br/>},<br/>"foo": {<br/>"type": "number"<br/>}<br/>}<br/>}<br/>]<br/>} | {"id":"4711","foo":2,"bar":"DEF_VAL"} |
| Cell array |
| {struct('foo', 1) struct('bar', 2)} | {<br/>"type": "array",<br/>"items": {<br/>"type": "object"<br/>}<br/>} | [{"foo":1},{"bar":2}] |
| Structure array |
| struct('foo', {1 2}, 'bar', {3 4}) | {<br/>"type": "array",<br/>"items": {<br/>"type": "object",<br/>"additionalProperties": false<br/>}<br/>} | [{"foo":1,"bar":3},{"foo":2,"bar":4}] |
| Array of strings |
| {'foo'} |  | ["foo"] |
| Scalar number |
| 1 | {<br/>"type": "number",<br/>"enum": [1, 2]<br/>} | 1 |
| Scalar boolean |
| true | {<br/>"type": "boolean"<br/>} | true |
| Null or NaN |
| NaN | {<br/>"type": "null"<br/>} | null |
| Single string with enumeration |
| 'foo' | {<br/>"type": "string",<br/>"enum": ["bar", "foo"]<br/>} | "foo" |
| Row vector |
| [1 2] |  | [1,2] |
| Mixed array |
| {1, struct(), 2} | {<br/>"type": "array",<br/>"items": {"type": ["number", "object"]}<br/>} | [1,{},2] |
| Row vector with NaN |
| [1 NaN 2] | {<br/>"type": "array",<br/>"items": {<br/>"type": ["number", "null"]<br/>}<br/>} | [1,null,2] |
| Matrix |
| [ [1 2 NaN]; [4 -5 6] ] | {<br/>"type": "array",<br/>"items": {<br/>"type": "array",<br/>"items": {<br/>"type": ["number", "null"]<br/>}<br/>}<br/>} | [[1,2,null],[4,-5,6]] |
| Simple object |
| struct('foo', 'bar') |  | {"foo":"bar"} |
| Empty object, no schema |
| struct() |  | {} |
| Empty object |
| struct() | { "type": "object", "properties": {} } | {} |
| Cell array |
| {struct('foo',1) struct('foo',2)} |  | [{"foo":1},{"foo":2}] |
| Row vector (Fragile) |
| [1 2] |  | [1,2] |
| Matrix 2x2 (Fragile) |
| [1 2;3 4] |  | [[1,2],[3,4]] |
| :x: Column vector (Fragile) |
| [1; 2] |  | [[1],[2]] |
| Array of strings |
| {'foo' 'bar'} |  | ["foo","bar"] |
| Single number |
| 1 |  | 1 |
| Single boolean |
| true |  | true |
| Single string |
| 'Hello-World' |  | "Hello-World" |
| Single boolean |
| true |  | true |
| Single boolean |
| false |  | false |
| :x: Boolean array (Fragile) |
| [true false] |  | [true,false] |
| Hint array |
| 1 | { "type": "array",<br/>"items": { "type": ["number", "null"] }<br/>} | [1] |
| Hint array of arrays |
| 1 | { <br/>"type": "array",<br/>"items": {<br/>"type": "array",  <br/>"items": { "type": ["number", "null"] }<br/>}<br/>} | [[1]] |
| Foo |
| [1 NaN 2] | { "type": "array",<br/>"items": { "type": ["number", "null"] }<br/>} | [1,null,2] |
| Empty array |
| [] | { "type": ["array", "null"] } | [] |
| :x: 3D matrix |
| a = NaN(2,2,2);<br/>a(1,:,:) = [1 2; 3 4];<br/>a(2,:,:) = [5 6; 7 8]; |  | [[[1,2],[3,4]],[[5,6],[7,8]]] |
| Foo |
| [1 NaN] | {<br/>"type": "array",<br/>"items": [{"type": "number"}, {"type": "null"}]<br/>} | [1,null] |
| From-till-value list |
| [datenum("2016-01-01") datenum("2016-01-31") 13] | {<br/>"type": "array",<br/>"items": [<br/>{"type": "string", "format": "date"},<br/>{"type": "string", "format": "date"},<br/>{"type": ["number", "null"] }<br/>]<br/>} | ["2016-01-01","2016-01-31",13] |
| List of from-till-value lists |
| [<br/>[datenum("2016-01-01") datenum("2016-01-31") 13.13]<br/>[datenum("2016-02-01") datenum("2016-02-29") 42.42]<br/>] | {<br/>"type": "array",<br/>"items": {<br/>"type": "array",<br/>"items": [<br/>{"type": "string", "format": "date"},<br/>{"type": "string", "format": "date"},<br/>{"type": ["number", "null"] }<br/>]<br/>}<br/>} | [["2016-01-01","2016-01-31",13.13],["2016-02-01","2016-02-29",42.42]] |
| Foo |
| struct('foo', 1) | {<br/>"type": "object",<br/>"properties": {<br/>"foo": { "type": "array" }<br/>}<br/>} | {"foo":[1]} |
| Foo |
| 'Hello' | {<br/>"type": "string",<br/>"pattern": "^\\w+$"<br/>} | "Hello" |
| Date formater |
| struct('myDate', 1+datenum('2016-01-02'), 'myDateTime', 1.5+datenum('2016-01-02')) | {<br/>"type": "object",<br/>"properties": {<br/>"myDate": { <br/>"type": "string",<br/>"format": "date"<br/>},<br/>"myDateTime": { <br/>"type": "string",<br/>"format": "date-time"<br/>}<br/>}<br/>} | {"myDate":"2016-01-03","myDateTime":"2016-01-03T12:00:00+0100"} |


[//]: # "ROUNDTRIP"


# Validation

[//]: # "VALIDATION"

| MATLAB |  JSON  | Schema | Errors |
|--------|--------|--------|--------|
| Array with one string |
| {'foo'} | ["foo"] | { "type": "object" } | {'/' 'does not match type object' '[array]'} |
| Row vector with NaNs |
| [NaN 1] | [null,1] | { "type": "array",<br/>    "items": [<br/>      { "type": "number" },<br/>      { "type": "null"}]<br/>  } | {'/1/' 'does not match type number' 'NaN'}<br/>  {'/2/' 'does not match type null' '1'} |
| Foo1 |
| struct('foo', 1) | {"foo":1} | {<br/>      "type": "object",<br/>      "required": ["bar"]<br/>  } | {'/' 'is missing required field bar' '{object}'} |
| Foo2 |
| [1 2] | [1, 2] | {<br/>      "type": "object"<br/>  } | {'/' 'does not match type object' '1  2'} |
| Foo3 |
| 'foo' | "foo" | {<br/>      "type": "number"<br/>  } | {'/' 'does not match type number' 'foo'} |
| Foo4 |
| true | true | {<br/>      "type": "number"<br/>  } | {'/' 'does not match type number' 'true'} |
| Foo4 |
| {'foo'} | ["foo"] | {<br/>      "type": "object"<br/>  } | {'/' 'does not match type object' '[array]'} |
| Foo6 |
| 'Hello World' | "Hello World" | {<br/>      "type": "string",<br/>      "pattern": "^\\w+$"<br/>  } | {'/' 'does not match pattern ^\w+$' 'Hello World'} |
| Foo6 |
| 'Hello World' | "Hello World" | {<br/>      "type": "string",<br/>      "enum": ["foo", "bar"]<br/>  } | {'/' 'is not contained in enumeration' 'Hello World'} |
| Foo6 |
| 4711 | 4711 | {<br/>      "type": "integer",<br/>      "enum": [1, 2, 3, 4]<br/>  } | {'/' 'is not contained in enumeration' '4711'} |
| External Schema |
| struct('id', '4711', 'bar', 2) | {<br/>      "id":"4711",<br/>      "bar":2<br/>  } | {<br/>      "$ref": "schema2.json"<br/>  } | {'/bar/' 'does not match type string' '2'} |


[//]: # "VALIDATION"

# Parse

[//]: # "PARSE"

| MATLAB <-|<- Schema <-|<- JSON |
|--------|--------|------|
| Structure array |
| {'foo'} |  | ["foo"] |
| AllOf |
| struct('id', '4711', 'foo', 2, 'bar', 'DEF_VAL') | {<br/>"$ref": "schema2.json"<br/>} | {<br/>"id":"4711",<br/>"foo":2<br/>} |


[//]: # "PARSE"

# Stringify

[//]: # "STRINGIFY"

| MATLAB | Schema | JSON |
|--------|--------|------|
| Structure array |
| struct('foo', {1 2}) |  | [{"foo":1},{"foo":2}] |
| Treatment of Inf |
| Inf |  | null |
| Treatment of special numbers |
| [1 Inf -Inf NaN 2] |  | [1,null,null,null,2] |
| Foo |
| [1 NaN Inf -Inf 2] | { "type": "array",<br/>"items": { "type": ["number", "null"] }<br/>} | [1,null,null,null,2] |
| Fixed precision |
| pi | {<br/>"type": "number",<br/>"fixedPrecision": 2<br/>} | 3.14 |
| Array of arrays with fixed precision |
| pi | { <br/>"type": "array",<br/>"items": {<br/>"type": "array",  <br/>"items": {<br/>"type": ["number", "null"], <br/>"fixedPrecision": 2<br/>}<br/>}<br/>} | [[3.14]] |


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
