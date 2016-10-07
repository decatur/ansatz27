Parser and Stringifier for GNU Octave and MATLAB®.

![Roundtrip MATLAB to JSON](/docs/roundtrip.png?raw=true)

ansatz27 lets you
* read and write JSON streams with a predictable behavior,
* make JSON Schemas part of your public API, and
* avoid boilerplate code to validate that input data is correct.

There is no one-to-one correspondence between JSON and MATLAB data types.
Even the number `1` is a 2-dimensional matrix in MATLAB, and could translate to a JSON type of `number`, `array of number` or `array of array of number`.
ansatz27 uses [JSON Schema](http://json-schema.org) to coerce JSON and MATLAB data types consistently and to validate the data.

# Requirements
Version GNU Octave ≥4.0 or MATLAB ≥2013b.
There are no dependencies.

# Related Work

[Understanding JSON Schema](http://spacetelescope.github.io/understanding-json-schema/)

You can validated JSON by JSON Schema online with [jsonschemalint](http://jsonschemalint.com/draft4)

# Usage

[//]: # "testUsage.m"
```MATLAB
jsonOrFilepath = 'document.json';
[obj, errors] = JSON.parse(jsonOrFilepath, 'schema.json');

obj = containers.Map();
obj('foo') = struct('bar', 13);
obj('bar') = {'foo' 'bar'};

json = JSON.stringify(obj);
[json, errors] = JSON.stringify(obj, 'schema.json');
```
[//]: #

# Conformance with JSON Schema Specification

<table>
    <tr><th>Feature</th><th>Description</th></tr>
    <tr>
        <td>type</td>
        <td>All primitive types (array, boolean, integer,  number, null, object, string) are supported; `type` keyword is string or list, i.e.  `"type": ["number", "null"]` meaning numeric or null</td>
    </tr>
    <tr><td colspan="2">object validation keywords</td></tr>
    <tr>
        <td>properties, patternProperties, maxProperties, minProperties</td>
        <td>Fully supported</td>
    </tr>
    <tr>
        <td>additionalProperties</td>
        <td>Supports only `true` and `false`</td>
    </tr>
    <tr><td colspan="2">array validation keywords</td></tr>
    <tr>
        <td>maxItems, minItems</td>
        <td>Fully supported</td>
    </tr>
    <tr>
        <td>additionalItems</td>
        <td>Supports only `true` and `false`</td>
    </tr>
    <tr><td colspan="2">string validation keywords</td></tr>
    <tr>
        <td>pattern</td>
        <td>Supports valid MATLAB/Octave regular expressions. On Octave not supported from the V4 Spec are lazy quantifiers ("+?", "*?", "??")</td>
    </tr>
    <tr>
        <td>maxLength, minLength</td>
        <td>Do not always work correctly because the *overestimating* length(char) function is used, i.e. `length('®')==2`</td>
    </tr>
    <tr><td colspan="2">number validation keywords</td></tr>
    <tr>
        <td>minimum, exclusiveMinimum, maximum, exclusiveMaximum, multipleOf</td>
        <td>Fully supported</td>
    </tr>
    <tr>
        <td>$ref</td>
        <td>Internal and external referencing fully supported</td>
    </tr>
    <tr>
        <td>definitions</td>
        <td>Fully supported</td>
    </tr>
    <tr>
        <td>default</td>
        <td>See <a href="#defaults">Defaults</a></td>
    </tr>
    <tr>
        <td>format</td>
        <td>Validates `date-time`, and adds `date`, `structured-array`, `cell-array` and `Map`</td>
    </tr>
    <tr>
        <td>enum</td>
        <td>Only supportes uniform arrays of either strings, numbers or booleans</td>
    </tr>
    <tr>
        <td>$schema</td>
        <td>Fully supported, which means ignored</td>
    </tr>
    <tr>
        <td>id</td>
        <td>
            Scope resolution alteration is fully supported, see <a href="#uri-resolution">URI Resolution</a>.
            Note: ansatz27 does not use inline dereferencing.
        </td>
    </tr>
    <tr>
        <td>uniqueItems</td>
        <td>Not supported</td>
    </tr>
    <tr>
        <td>dependencies</td>
        <td>Not supported</td>
    </tr>
    <tr>
        <td>allOf</td>
        <td>
            Deprecated. Supported only in top level schema. Use it as a poor man's schema inheritance.
            Best practise is to flatten the hierarchy by listing all properties and to use schema references.  
        </td>
    </tr>
    <tr>
        <td>anyOf</td>
        <td>
            Fully supported. Coersion is according the first validating schema.
            A back-tracking algorithm on the schema array is used, so performance may be poor.
        </td>
    </tr>
    <tr>
        <td>oneOf</td>
        <td>
            Fully supported. Coersion is according the single validating schema.
            Best practise is to use `anyOf` as it performs better.
        </td>
    </tr>
    <tr>
        <td>not</td>
        <td>Not supported</td>
    </tr>
</table>

# Comprehensive Example

*MATLAB*
[//]: # "roundtrip/Comprehensive_Example/payload.m"
```MATLAB
a = struct('id', '4711');
a.portfolio.index = 3;
a.portfolio.value = 4.32;
a.deals = struct( 'name', {'DEAL-A' 'DEAL-B'}, 'value', {13.13 42.42} );
a.dealValues = [13.13 42.42];
a;
```
[//]: #

*JSON*
[//]: # "roundtrip/Comprehensive_Example/payload.json"
```JSON
{
    "id": "4711",
    "portfolio": {
        "index": 3,
        "value": 4.32
    },
    "deals": [
        { "name": "DEAL-A", "value": 13.13 },
        { "name": "DEAL-B", "value": 42.42 }
    ],
    "dealValues": [ 13.13, 42.42 ]
}
```
[//]: #

*Schema*
[//]: # "roundtrip/Comprehensive_Example/schema.json"
```JSON
{
    "type": "object",
    "properties": {
        "id": {
            "type": "string"
        },
        "portfolio": {
            "type": "object",
            "properties": {
                "index": { "type": "integer", "minimum": 1 },
                "value": { "type": "number" }
            }
        },
        "deals": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": false,
                "properties": {
                    "name":  { "type": "string", "pattern": "^DEAL-\\w+$" },
                    "value": { "type": "number", "minimum": 0 }
                }
            }
        }
    }
}
```
[//]: #

# Type Coersion

## Type Coersion on Parse

|     JSON          |     Schema                    |      MATLAB               |
|-------------------|-------------------------------|---------------------------|
| number/integer    | none \| type=number\|integer  | 1x1 numeric matrix        |
| string            | format=date(-time)            | datetime           |
| string            | other formats                 | char array                |
| boolean           | none \| type=boolean          | 1x1 boolean matrix        |
| object            | format=struct (default)       | struct                    |
| object            | format=Map                    | containers.Map            |
| array             | format=structured-array and item type=object | structured-array |
| array             | array is uniform (hypercube) and all leafs are numeric | numeric matrix |
| array             | otherwise                     | cell array                |
| null              | none \| type=null             | 1x1 NaN                   |

Note: The coersion to struct will simply drop all properties with invalid field names.
The coersion to Map will retain all properties. 

*JSON*
[//]: # "parse/Non_MATLAB_Keys/payload.json"
```JSON
{ "Hello": "World", "$ref": 2 }
```
[//]: #

*MATLAB*
[//]: # "parse/Non_MATLAB_Keys/payload.m"
```MATLAB
struct('Hello', 'World')
```
[//]: #

## Type Coersion on Stringify

|     MATLAB            |     Schema                            |   JSON            |
|-----------------------|---------------------------------------|-------------------|
| 1x1 numeric matrix    | none \| type=number\|integer          | number/integer    |
| datetime              | type=string and format=date(-time)    | string            |
| numeric matrix        | none \| type=array                    | array             |
| char array            | none \| string                        | string            |
| 1x1 boolean matrix    | none \| type=boolean                  | boolean           |
| boolean matrix        | none \| type=array                    | array             |
| struct                | none \| type=object                   | object            |
| containers.Map        | none \| type=object                   | object            |
| NaN                   | none \| type=null                     | null              |


# URI Resolution

With ansatz27, you may reference a JSON or schema resource with a [Uniform Resource Identifier (URI)](https://tools.ietf.org/html/rfc3986).
This is either direcly when calling `JSON.parse()` or `JSON.stringify`, or indirectly
through the `$ref` keyword in schema documents.

All relative (i.e. having no scheme like `file:` or `http:`) URIs are resolved against the current resolution scope
as defined by the JSON Schema Specs.

There is one exception: If the schema was not loaded  base URI of the JSON class.

The default base URI of the JSON class is either `pwd()` or `ctfroot` with a `file` scheme.
You can change this value with
```MATLAB
    JSON.setBaseURI('THE_BASE_URI')
```

Be aware how URI resolution works. You probably want the base URI ending in a slash (/), for example
```MATLAB
    JSON.parse('{...}', 'test/schema.json')
    JSON.getBaseURI() ->  /home/decatur/ansatz27/
```
the resolved URI is `file:/home/decatur/ansatz27/test/schema.json`.

After resolution the resource is loaded with the Octave/MATLAB `urlread()` function.

In a standalone MATLAB application, be sure to include all schemas relative to your application into the CTF archive with [mcc](http://www.mathworks.com/access/helpdesk/help/toolbox/compiler/mcc.html)'s -a (add) flag.

# Formatter

Formatters allow to make custom transformations. A typical candidate is the mapping of dates between
string representation and MATLABs numerical representation. A formatter is invoked on an element if
the value of the format property (if any) is the name of a registered formatter.

On parse, formatters are applied *after* all parseing and validation steps have been performed.
On stringify, formatters are performed *before* all validation and stringifying takes place.

There are two predefined formatters `date` and `date-time`, see [Date Coercion](#date-coercion).

# Array Type Coercion

JSON arrays are converted to cell arrays with the exception of structured arrays and numeric matrices.

## Structured Array Coercion

A JSON array is coerced to a structured array if

1. there is a schema,
2. and `/items` is an object
3. and `/items/type` is `'object'`
4. and the *default* value of `/format` is `'structured-array'`

*MATLAB*
[//]: # "roundtrip/Roundtrip_Structured_Array/payload.m"
```MATLAB
struct('foo', {1 2}, 'bar', {3 4})
```
[//]: #

*Schema*
[//]: # "roundtrip/Roundtrip_Structured_Array/schema.json"
```JSON
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "foo": {},
            "bar": {}
        }
    }
}
```
[//]: #

*JSON*
[//]: # "roundtrip/Roundtrip_Structured_Array/payload.json"
```JSON
[
    {"foo":1,"bar":3},
    {"foo":2,"bar":4}
]
```
[//]: #

## Numeric Matrix Coercion

A JSON array is coerced to a numeric matrix if 
1. at each level the sub-arrays have the same length,
2. and if *all* items at the lowest level are numbers or null.

*MATLAB*
[//]: # "roundtrip/Roundtrip_Numeric_Matrix/payload.m"
```MATLAB
[ [1 2 NaN]; [4 -5 6] ]
```
[//]: #

*Schema*
[//]: # "roundtrip/Roundtrip_Numeric_Matrix/schema.json"
```JSON
{
    "type": "array",
    "items": {
        "type": "array",
        "items": {
            "type": ["number", "null"]
        }
    }
}
```
[//]: #

*JSON*
[//]: # "roundtrip/Roundtrip_Numeric_Matrix/payload.json"
```JSON
[[1,2,null],[4,-5,6]]
```
[//]: #

*MATLAB*
[//]: # "roundtrip/Roundtrip_3D_Matrix/payload.m"
```MATLAB
a = NaN(2,2,2);
a(1,:,:) = [1 2; 3 4];
a(2,:,:) = [5 6; 7 8];
a;
```
[//]: #

*JSON*
[//]: # "roundtrip/Roundtrip_3D_Matrix/payload.json"
```JSON
[
    [ [1,2], [3,4] ],
    [ [5,6], [7,8] ]
]
```
[//]: #

# Date Coercion

The two predefined formatters `date` and `date-time` coerce ISO8601 date string to datetime objects.


*MATLAB*
[//]: # "roundtrip/Roundtrip_Date_Formater/payload.m"
```MATLAB
struct( ...
    'myDate', 1+datetime('2016-01-02'), ...
    'myDateTime', 1.5+datetime('2016-01-02', 'TimeZone', 'Europe/Berlin') ...
)
```
[//]: #

*Schema*
[//]: # "roundtrip/Roundtrip_Date_Formater/schema.json"
```JSON
{
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
}
```
[//]: #

*JSON*
[//]: # "roundtrip/Roundtrip_Date_Formater/payload.json"
```JSON
{
    "myDate":"2016-01-03",
    "myDateTime":"2016-01-03T12:00:00+0100"
}
```
[//]: #

# Defaults

A schema may specify a default value. On stringify, defaults are ignored. In particular, values which are equals to defaults are not removed.

On parse, default values are set for unspecified object properties.

*MATLAB*
[//]: # "parse/Structured_Array_with_Defaults/payload.m"
```MATLAB
struct('foo', {1 2}, 'bar', {3 4})
```
[//]: #

*JSON*
[//]: # "parse/Structured_Array_with_Defaults/payload.json"
```JSON
[ { "foo": 1 }, { "foo": 2, "bar": 4 } ]
```
[//]: #

*Schema*
[//]: # "parse/Structured_Array_with_Defaults/schema.json"
```JSON
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "foo": {},
            "bar": { "type": "number", "default": 3 }
        }
    }
}
```
[//]: #

# Typical Use Cases

## List of From-Fill-Value Tripples

*MATLAB*
[//]: # "roundtrip/List_of_From-Fill-Value_Tripples/payload.m"
```MATLAB
{
    {datetime('2016-01-01') datetime('2016-01-31') 13.13}
    {datetime('2016-02-01') datetime('2016-02-29') 42.42}
}
```
[//]: #

*Schema*
[//]: # "roundtrip/List_of_From-Fill-Value_Tripples/schema.json"
```JSON
{
    "type": "array",
    "items": {
        "type": "array",
        "items": [
            {"type": "string", "format": "date"},
            {"type": "string", "format": "date"},
            {"type": ["number", "null"] }
        ]
    }
}
```
[//]: #

*JSON*
[//]: # "roundtrip/List_of_From-Fill-Value_Tripples/payload.json"
```JSON
[
    ["2016-01-01", "2016-01-31", 13.13],
    ["2016-02-01", "2016-02-29", 42.42]
]
```
[//]: #

## Reuse with Schema References

*MATLAB*
[//]: # "roundtrip/Reuse_with_Schema_References/payload.m"
```MATLAB
struct( ...
    'shipping_address', ...
        struct('street_address', '1600 Penn Ave NW', 'city', 'Washington', 'state', 'DC'), ...
    'billing_address', ...
        struct('street_address', '1st Street SE', 'city', 'Washington', 'state', 'DC'))
```
[//]: #

*Schema*
[//]: # "roundtrip/Reuse_with_Schema_References/schema.json"
```JSON
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "definitions": {
        "address": {
            "type": "object",
            "properties": {
                "street_address": { "type": "string" },
                "city":           { "type": "string" },
                "state":          { "type": "string" }
            },
            "required": ["street_address", "city", "state"]
        }
    },
    "type": "object",
    "properties": {
        "billing_address":  { "$ref": "#/definitions/address" },
        "shipping_address": { "$ref": "#/definitions/address" }
    }
}
```
[//]: #

*JSON*
[//]: # "roundtrip/Reuse_with_Schema_References/payload.json"
```JSON
{
    "shipping_address": {
        "street_address": "1600 Penn Ave NW",
        "city":           "Washington",
        "state":          "DC"
    },
    "billing_address": {
        "street_address": "1st Street SE",
        "city":           "Washington",
        "state":          "DC"
    }
}
```
[//]: #

## Schema Inheritance with allOf

*MATLAB*
[//]: # "roundtrip/Schema_Inheritance_with_allOf/payload.m"
```MATLAB
struct( ...
    'id', '4711', ...
    'foo', 2, ...
    'bar', 'DEF_VAL')
```
[//]: #

*Schema*
[//]: # "roundtrip/Schema_Inheritance_with_allOf/schema.json"
```JSON
{
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
}
```
[//]: #

*JSON*
[//]: # "roundtrip/Schema_Inheritance_with_allOf/payload.json"
```JSON
{
    "id":"4711",
    "foo":2,
    "bar":"DEF_VAL"
}
```
[//]: #

## Dictionary

Sometimes an object is used for arbitrary key-value mapping, also called a dictonary or a map.
In practice you should consider not to use dictionaries, use arrays and some extra lookup logic instead.

*MATLAB*
[//]: # "roundtrip/Dictionary/payload.m"
```MATLAB
a = containers.Map();
a('DEAL-A')  = struct('start', datetime('2016-03-20'), 'value', 1);
a('DEAL-XY') = struct('start', datetime('2016-03-21'), 'value', 2);
a('DEAL-Z')  = struct('start', datetime('2016-03-22'), 'value', 3);
a;
```
[//]: #

*Schema*
[//]: # "roundtrip/Dictionary/schema.json"
```JSON
{
    "type": "object",
    "format": "Map",
    "patternProperties": {
        "^DEAL-[A-Z]+$": { 
            "type": "object",
            "properties": {
                "start": { "type": "string", "format": "date" }
            }
        }
    }
}
```
[//]: #

*JSON*
[//]: # "roundtrip/Dictionary/payload.json"
```JSON
{
    "DEAL-A" : { "start": "2016-03-20", "value": 1 },
    "DEAL-XY": { "start": "2016-03-21", "value": 2 },
    "DEAL-Z" : { "start": "2016-03-22", "value": 3 }
}
```
[//]: #

# Validation by Schema

Appart from type coercion, schemas are used to validate the input to `parse` or `stringify`.
Validation errors are returned by these methods, see [Usage](#usage).

## Expected Errors
All errors related to input data are reported in the second return value of `JSON.parse()` and `JSON.stringify()`.
These include
* parse errors in the JSON data or JSON schema
* schema invalid against the specification 
* JSON data invalid against the schema

*Note*: The persistent schema cache is only written after schemas are successfully resolved. Therefore the cache will only hold valid schemas.

It is best practise to *always* check for errors and to discard the input if errors have occured:

[//]: # "testErrorHandling.m"
```MATLAB
[obj, errors] = JSON.parse('{"foo": 1, "bar": 2}', 'schema.json');
if ~isempty(errors)
    % Report errors and stop processing
end
```
[//]: #

For each validation error one item in the `errors` cell array is generated:

*Schema*
[//]: # "validation/Format_Validation_on_Parse/schema.json"
```JSON
{
    "type": "object",
    "properties": {
        "a": { "type": "string", "format": "date" },
        "b": { "type": "string", "format": "date" },
        "c": { "type": "string", "format": "date-time" },
        "d": { "type": "string", "format": "date-time" }
    }
}
```
[//]: #

*JSON*
[//]: # "validation/Format_Validation_on_Parse/payload.json"
```JSON
{
    "a": "2016-01-01",
    "b": "2016-01-01T12:00:00Z",
    "c": "2016-01-01T12:00:00Z",
    "d": "2016-01-01T12:00:00Y"
}
```
[//]: #

*Errors*
[//]: # "validation/Format_Validation_on_Parse/errors.m"
```MATLAB
{
{'/b' 'is not a valid date' '2016-01-01T12:00:00Z'}
{'/b' 'is not a valid date' '2016-01-01T12:00:00Z'}
{'/d' 'is not a valid date-time' '2016-01-01T12:00:00Y'}
}
```
[//]: #

## Unhandled Errors
Both `JSON.parse()` and `JSON.stringify()` may throw an error. This is the case when
the method is called with an invalid argument type such as `JSON.parse(struct())`.

In all other cases an unhandled error is *always* a bug in ansatz27. Please report it!


# Utilities

## JSON.getPath

Retrieve a value inside an object given its [JSON Pointer](See https://tools.ietf.org/html/rfc6901).
The object may be one of `struct`, `cell array` or `containers.Map`.

```MATLAB
obj = getPath(obj, pointer, default)
%GETPATH Returns the value under the pointer.
% The pointer must be a JSON pointer, so each reference token must be
% prefixed by / and numerical tokens referencing an array are zero-based.
% Returns default or empty if the pointer does not resolve.
```

Example

```MATLAB
obj = containers.Map();
obj('foo') = struct('bar', 13);
obj('bar') = {'foo' 'bar'};
obj('foo/bar') = 42;                % Not recommended!

JSON.getPath(obj, '/foo/bar')       % -> 13
JSON.getPath(obj, '/bar/1')         % -> 'bar'
JSON.getPath(obj, 'foo~1bar')       % -> 42
JSON.getPath(obj, 'foobar', 4711)   % -> 4711
```

# Security Considerations

The parse time of a JSON-document is proportional to its size. There is the possibility
of a DoS with a mild amplification factor.

You must trust the schema creator.
A schema can reference another external schema. This is then fetched by `urlread()` if network settings allow it.
The fetched document could contain malicious code, which (although not executed by ansatz27) may reside somewhere in storage.
Additionally, one can create an effient DoS with many, possibly huge, external schemas.

# Building

1. Execute `tests.m` and fix all errors.
2. Execute `build.py` will replace all code fragments in `README.md`.

# Design Decisions

* We do not use functions in private directories. Octave Version 4.0 cannot resolve those from class member functions.
* Local functions cannot call private class member functions in Octave.

# Improvements by Priority

- [ ] Resolve TODOs
- [ ] Check enum values for uniquness
- [ ] Support mixed type enum
- [ ] Describe Best Practises
- [ ] Usage with webread() introduced in R2014b, via weboptions('ContentReader', @handler)
- [ ] ThingSpeak?
- [ ] Validate keyword multipleOf (integer>0)
- [ ] Validate exclusiveMinimum/Maximum (min/max must exist)
