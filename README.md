A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

The well established JSON schema specification is used to validate data and to map between JSON and MATLABs data types.
For all use cases of ansatz27, schemas are optional. However, their use is strongly encouraged.

Without schemas, roundtripping may break structure, for example
```
    JSON                 MATLAB               JSON
{ "foo": [1] }  ->  struct('foo', 1)  ->  { "foo": 1 } 
```

# Requirements
GNU Octave version minimum 4.0 or MATLAB about version 2006 (verified for 2013b).

# Dependencies
There are no dependencies.

# Related Work

# Parser

## Examples
```
[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json')
[obj, errors] = JSON_Parser.parse('{"foo": 1, "bar: 2"}', 'file:schema.json')
```

# Stringifier

## Examples
```
[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json')
[obj, errors] = JSON_Parser.parse('{"foo": 1, "bar: 2"}', 'file:schema.json')
```
# Formatter

There are two predefined formatters

* date: Maps between JSON-string and MATLAB-double
* date-time: Maps between JSON-string and MATLAB-double

# Array comprehensions

* schemaless -> cell array
* items is array -> cell array
* items is object -> struct array

# Defaults

In each schema you may specify a default value.
```
{
    "type": "object",
    "properties": {
        "foo": { "type": "string", "default": "bar" }
    }
}

JSON               MATLAB
 {}    ->    struct('foo', 'bar')
```

Defaults are ignored when stringifying.


# Octave Limitations
Encoding of files

Design
We do not functions in private directories. Octave Version 4.0 cannot resolve those from a class member function.
