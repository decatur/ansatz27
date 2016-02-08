A validating and roundtripping JSON Parser and Stringifier for GNU Octave and MATLAB®.

The well established JSON schema specification http://json-schema.org/ is used to validate data and to map between JSON and MATLABs data types.
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
## Mapping

### Key mapping

Object keys which are not valid MATLAB variable names are mapped, for example $ref -> x_ref.


# Stringifier

## Examples
```
[obj, errors] = JSON_Parser.parse('file:doc.json', 'file:schema.json')
[obj, errors] = JSON_Parser.parse('{"foo": 1, "bar: 2"}', 'file:schema.json')
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
| 2016-02-08T12:00Z     | 736368.5  |
| 2016-02-08T12:00+0000 | 736368.5  |
| 2016-02-08T13:00+0100 | 736368.5  |


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

# Schema


JSON Schema is itself defined in JSON and can be parsed into a MATLAB structure.
```
schema = JSON_Parser.parse('file:schema.json')
```

# Octave Limitations
Encoding of files

Design
We do not functions in private directories. Octave Version 4.0 cannot resolve those from a class member function.
