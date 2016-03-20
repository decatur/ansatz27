A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

```
      ↱ MATLAB  ⬎
      ↑          ↓
      ↑← Schema →↓
      ↑          ↓
      ⬑  JSON   ↲
```

The [JSON schema specification](http://json-schema.org) is used to map between JSON and MATLABs data types and to validate data.

# Requirements
GNU Octave version minimum 4.0 or MATLAB about version 2006 (verified for 2013b).
There are no dependencies.

# Related Work

[Understanding JSON Schema](http://spacetelescope.github.io/understanding-json-schema/)

You can also validated JSON and JSON schema online with [jsonschemalint](http://jsonschemalint.com/draft4)


# JSON Schema and Type Coersion

For all use cases of ansatz27, schemas are optional. However, their use is strongly encouraged.

Without schemas, roundtripping may break structure, for example

|     JSON   ->  |     MATLAB   ->  |   JSON       |
|----------------|------------------|--------------|
| { "foo": [1] } | struct('foo', 1) | { "foo": 1 } |


JSON Schema is itself defined in JSON and can be parsed into a MATLAB structure.

# Usage

[//]: # "Usage"
*MATLAB*
```MATLAB

addpath('lib', 'test');

schema = struct('type', 'object');

[obj, errors] = JSON.parse('file:document.json', 'file:schema.json');
[obj, errors] = JSON.parse('{"foo": 1, "bar": 2}', schema);

obj = struct('foo', 1, 'bar', 2);
[json, errors] = JSON.stringify(obj, 'file:schema.json');
[json, errors] = JSON.stringify(obj, schema);
        
```

[//]: # "Usage"

# Conformance with JSON Schema Specification

## Supported Features

* Supports all primitive types array, boolean, integer, number, null, object and string 
* A type may be a list of primitive types, i.e. `"type": ["number", "null"]` meaning numeric or null
* Internal and external referencing with "$ref" keyword
* Keywords "minimum", "maximum", "pattern", "additionalItems", "additionalProperties", "properties", "patternProperties", "enum", "type", "allOf", "definitions", "default", "format"

## MUST keywords (yet) ignored
```
$schema, id (scope alteration), multipleOf, exclusiveMaximum, exclusiveMinimum,
maxLength, minLength, maxItems, minItems, uniqueItems, maxProperties, minProperties, dependencies, anyOf, oneOf, not
```

# Comprehensive Example

[//]: # "Comprehensive Roundtrip Example"
*MATLAB*
```MATLAB

            a = struct('id', '4711');
            a.portfolio.index = 3;
            a.portfolio.value = 4.32;
            a.deals = struct( 'name', {'DEAL-A' 'DEAL-B'}, 'value', {13.13 42.42} );
            a.dealValues = [13.13 42.42];
        
```
*JSON*
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
*Schema*
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

[//]: # "Comprehensive Roundtrip Example"

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
2. and `schema.items` is an object
3. and `schema.items.type` is `'object'`
4. and the *default* value of `schema.format` is `'structured-array'`

[//]: # "Roundtrip Structured Array"
*MATLAB*
```MATLAB
struct('foo', {1 2}, 'bar', {3 4})
```
*Schema*
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
*JSON*
```JSON

            [
                {"foo":1,"bar":3},
                {"foo":2,"bar":4}
            ]
        
```

[//]: # "Roundtrip Structured Array"

## Numeric Matrix Coercion

A JSON array is coerced to a numeric matrix if 
1. at each level the sub-arrays have the same length,
2. and if *all* items at the lowest level are numbers or null.

[//]: # "Roundtrip Numeric Matrix"
*MATLAB*
```MATLAB
[ [1 2 NaN]; [4 -5 6] ]
```
*Schema*
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
*JSON*
```JSON
[[1,2,null],[4,-5,6]]
```

[//]: # "Roundtrip Numeric Matrix"

[//]: # "Roundtrip 3D Matrix"
*MATLAB*
```MATLAB

            a = NaN(2,2,2);
            a(1,:,:) = [1 2; 3 4];
            a(2,:,:) = [5 6; 7 8];
        
```
*JSON*
```JSON

    [
        [ [1,2], [3,4] ],
        [ [5,6], [7,8] ]
    ]
        
```

[//]: # "Roundtrip 3D Matrix"

# Date Coercion

The two predefined formatters `date` and `date-time` coerce string dates to numeric values.

[//]: # "Roundtrip Date Formater"
*MATLAB*
```MATLAB

            struct( ...
                'myDate', 1+datenum('2016-01-02'), ...
                'myDateTime', 1.5+datenum('2016-01-02') ...
            )
        
```
*Schema*
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
*JSON*
```JSON

            {
                "myDate":"2016-01-03",
                "myDateTime":"2016-01-03T12:00:00+01:00"
            }
        
```

[//]: # "Roundtrip Date Formater"

# Defaults

A schema may specify a default value. On stringify, defaults are ignored. In particular, values which are equals to defaults are not removed.

On parse, default values are set for unspecified object properties.

[//]: # "Structured Array with Defaults"
*MATLAB*
```MATLAB
struct('foo', {1 2}, 'bar', {3 4})
```
*JSON*
```JSON

            [ { "foo": 1 }, { "foo": 2, "bar": 4 } ]
        
```
*Schema*
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

[//]: # "Structured Array with Defaults"

# Typical Use Cases

## List of From-Fill-Value Tripples
[//]: # "List of From-Fill-Value Tripples"
*MATLAB*
```MATLAB

            [
                [736330 736360 13.13]
                [736361 736389 42.42]
            ]
        
```
*Schema*
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
*JSON*
```JSON

            [
                ["2016-01-01", "2016-01-31", 13.13],
                ["2016-02-01", "2016-02-29", 42.42]
            ]
        
```

[//]: # "List of From-Fill-Value Tripples"

## Reuse with Schema References
[//]: # "Reuse with Schema References"
*MATLAB*
```MATLAB

                struct( ...
                    'shipping_address', ...
                        struct('street_address', '1600 Pennsylvania Avenue NW', 'city', 'Washington', 'state', 'DC'), ...
                    'billing_address', ...
                    struct('street_address', '1st Street SE', 'city', 'Washington', 'state', 'DC'))
        
```
*Schema*
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
*JSON*
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

[//]: # "Reuse with Schema References"

## Schema Inheritance with allOf
[//]: # "Schema Inheritance with allOf"
*MATLAB*
```MATLAB

            struct( ...
                'id', '4711', ...
                'foo', 2, ...
                'bar', 'DEF_VAL')
        
```
*Schema*
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
*JSON*
```JSON

            {
                "id":"4711",
                "foo":2,
                "bar":"DEF_VAL"
            }
        
```

[//]: # "Schema Inheritance with allOf"

# Validation by Schema

Appart from type coercion, schemas are used to validate the input to `parse` or `stringify`.
Validation errors are returned by these methods, see [Usage](#usage).
It is best practise to *always* check for errors and to discard the input if errors have occured:

[//]: # "Error Handling"
*MATLAB*
```MATLAB

[obj, errors] = JSON.parse('{"foo": 1, "bar": 2}', 'file:schema.json');
if ~isempty(errors)
    % Report errors and stop processing
end
        
```

[//]: # "Error Handling"

For each validation error one item in the errors cell array is generated:

[//]: # "Format Validation on Parse"
*Schema*
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
*JSON*
```JSON

            {
                "a": "2016-01-01",
                "b": "2016-01-01T12:00:00Z",
                "c": "2016-01-01T12:00:00Z",
                "d": "2016-01-01T12:00:00Y"
            }
        
```
```MATLAB

            {'/b' 'is not a date' '2016-01-01T12:00:00Z'}
            {'/b' 'is not a valid date' '2016-01-01T12:00:00Z'}
            {'/d' 'is not a valid date-time' '2016-01-01T12:00:00Y'}
        
```

[//]: # "Format Validation on Parse"

# Advanced Usage

## Key mapping

Object keys which are not valid MATLAB variable names are normalized, for example

[//]: # "Non-MATLAB Keys"
*JSON*
```JSON
{ "H@ll@": 1, "$ref": 2 }
```
*MATLAB*
```MATLAB
struct('x_48406c6c40', 1, 'x_24726566', 2)
```

[//]: # "Non-MATLAB Keys"

# Security Considerations

TODO: Do these apply
* DoS like [billion laughs](https://en.wikipedia.org/wiki/Billion_laughs)
* External entity expansion
* External schema resolution


# Validation Test Cases

[//]: # "VALIDATION"


[//]: # "VALIDATION"


# Building

1. Execute `tests.m` and fix all errors
2. Execute `build.py` will replace all code fragments in `README.md`.

# Octave Limitations

We do not use functions in private directories. Octave Version 4.0 cannot resolve those from class member functions.
