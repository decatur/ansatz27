A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

```
      ⮳ MATLAB  ⮷
      |          |
      |◀-Schema-▶|
      |          |
      ⮴  JSON   ⮰
```

The [JSON schema specification](http://json-schema.org) is used to map between JSON and MATLABs data types and to validate data.

# Requirements
GNU Octave version minimum 4.0 or MATLAB about version 2006 (verified for 2013b).
There are no dependencies.

# Related Work

[Understanding JSON Schema](http://spacetelescope.github.io/understanding-json-schema/)

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
TODO
```

On parse, formatters are applied *after* all parseing and validation steps have been performed.
On stringify, formatters are performed *before* all validation and stringifying takes place.

There are two predefined formatters `date` and `date-time`, see [some examples](#date-formater) below.

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

[//]: # "ROUNDTRIP"

### Comprehensive
MATLAB
```MATLAB
a = struct('id', '4711');
a.portfolio.index = 3;
a.portfolio.value = 4.32;
a.deals = struct( ...
    'name', {'DEAL-A' 'DEAL-B'}, ...
    'value', {13.13 42.42});
a.dealValues = [13.13 42.42];
```
JSON
```JSON
{
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
}
```

Schema
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
}
```
### AllOf
MATLAB
```MATLAB
struct( ...
    'id', '4711', ...
    'foo', 2, ...
    'bar', 'DEF_VAL')
```
JSON
```JSON
{
    "id":"4711",
    "foo":2,
    "bar":"DEF_VAL"
}
```

Schema
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
### Cell array
MATLAB
```MATLAB
{struct('foo', 1) struct('bar', 2)}
```
JSON
```JSON
[{"foo":1},{"bar":2}]
```

Schema
```JSON
{
    "type": "array",
    "items": {
        "type": "object"
    }
}
```
### Hint array of arrays
MATLAB
```MATLAB
1
```
JSON
```JSON
[[1]]
```

Schema
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
### 3D matrix
MATLAB
```MATLAB
a = NaN(2,2,2);
a(1,:,:) = [1 2; 3 4];
a(2,:,:) = [5 6; 7 8];
```
JSON
```JSON
[
    [
        [1,2],
        [3,4]
    ], [
        [5,6],
        [7,8]
    ]
]
```

Schema
```JSON

```
### List of from-till-value tripples
<a name="date-formater"></a>

MATLAB
```MATLAB
[
    [736330 736360 13.13]
    [736361 736389 42.42]
]
```
JSON
```JSON
[
    ["2016-01-01", "2016-01-31", 13.13],
    ["2016-02-01", "2016-02-29", 42.42]
]
```

Schema
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
### Date formater
MATLAB
```MATLAB
struct( ...
    'myDate', 1+datenum('2016-01-02'), ...
    'myDateTime', 1.5+datenum('2016-01-02') ...
)
```
JSON
```JSON
{
    "myDate":"2016-01-03",
    "myDateTime":"2016-01-03T12:00:00+0100"
}
```

Schema
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
### Reuse
MATLAB
```MATLAB
struct( ...
    'shipping_address', ...
        struct('street_address', '1600 Pennsylvania Avenue NW', 'city', 'Washington', 'state', 'DC'), ...
    'billing_address', ...
    struct('street_address', '1st Street SE', 'city', 'Washington', 'state', 'DC'))
```
JSON
```JSON
{
    "shipping_address": {
        "street_address": "1600 Pennsylvania Avenue NW",
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

Schema
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


[//]: # "ROUNDTRIP"


# Validation Test Cases

[//]: # "VALIDATION"

### Pattern
MATLAB
```MATLAB
'Hello World'
```
JSON
```JSON
"Hello World"
```

Schema
```JSON
{
    "type": "string",
    "pattern": "^\\w+$"
}
```
Errors
```MATLAB
{'' 'does not match pattern ^\w+$' 'Hello World'}
```
### Cyclic Schema References
MATLAB
```MATLAB
struct('id', '4711', 'bar', 2)
```
JSON
```JSON
{
    "id": "4711",
    "bar": 2
}
```

Schema
```JSON
{
    "type": "object",
    "properties": {
        "id": { "type": "string" },
        "bar": { "$ref": "#/definitions/barType" }
    },
    "additionalProperties": false,
    "definitions": {
        "barType": { "$ref": "#/properties/bar" }
    }
}
```
Errors
```MATLAB
{[] 'Cyclic references #/properties/bar -> #/definitions/barType -> #/properties/bar' ''}
```
### Format validation on stringify
MATLAB
```MATLAB
struct('a', 736330, 'b', 736330.5, 'c', 736330.5, 'd', 'i')
```
Schema
```JSON
{
    "type": "object",
    "properties": {
        "a": { "type": "string", "format": "date" },
        "b": { "$ref": "#/properties/a" },
        "c": { "type": "string", "format": "date-time" },
        "d": { "$ref": "#/properties/c" }
    }
}
```
Errors
```MATLAB
{'/b' 'must be an integer' '736330.5'}
{'/b' 'does not match type string' '736330.5'}
{'/d' 'must be a number' 'i'}
```
### Format validation on parse
JSON
```JSON
{
    "a": "2016-01-01",
    "b": "2016-01-01T12:00:00Z",
    "c": "2016-01-01T12:00:00Z",
    "d": "2016-01-01T12:00:00Zulu"
}
```

Schema
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
Errors
```MATLAB
{'/b' 'is not a valid date' '2016-01-01T12:00:00Z'}
{'/d' 'is not a valid date-time' '2016-01-01T12:00:00Zulu'}
```


[//]: # "VALIDATION"

# Parse Oneway Test Cases

[//]: # "PARSE"



[//]: # "PARSE"

# Stringify Oneway Test Cases

[//]: # "STRINGIFY"



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
