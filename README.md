A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

▲ - U+25B2 BLACK UP-POINTING TRIANGLE
▼ - U+25BC BLACK DOWN-POINTING TRIANGLEU+25C0
◀ ▶
⮰ ⮱ ⮲ ⮳ ⮴ ⮵ ⮶ ⮷
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

Each entry is a passed unit test.

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
    "city": "Washington",
    "state": "DC"
  },
    "billing_address": {
    "street_address": "1st Street SE",
    "city": "Washington",
    "state": "DC"
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
          "city":       { "type": "string" },
          "state":      { "type": "string" }
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
