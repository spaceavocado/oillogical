# (Odin)illogical

A micro conditional engine used to parse the logical and comparison expressions, evaluate an expression in data context, and provide access to a text form of the given expression.

> Revision: Feb 24, 2025.

Other implementations:
- [TS/JS](https://github.com/spaceavocado/illogical)
- [GO](https://github.com/spaceavocado/goillogical)
- [Python](https://github.com/spaceavocado/pyillogical)
- [Java](https://github.com/spaceavocado/jillogical)
- [C#](https://github.com/spaceavocado/cillogical)

## About

This project has been developed to provide Odin implementation of [spaceavocado/illogical](https://github.com/spaceavocado/illogical).

## Getting Started

> Example usage could be found in the [example.odin](example.odin) file.

**Table of Content**

---

- [(Odin)illogical](#odinillogical)
  - [About](#about)
  - [Getting Started](#getting-started)
  - [Basic Usage](#basic-usage)
    - [Evaluate Comparison Expression](#evaluate-comparison-expression)
    - [Evaluate Logical Expression](#evaluate-logical-expression)
    - [Serialize Comparison Expression](#serialize-comparison-expression)
    - [Serialize Logical Expression](#serialize-logical-expression)
    - [Get Comparison Expression String Representation](#get-comparison-expression-string-representation)
    - [Get Logical Expression String Representation](#get-logical-expression-string-representation)
    - [Simplify Comparison Expression](#simplify-comparison-expression)
    - [Simplify Logical Expression](#simplify-logical-expression)
  - [Working with Expressions](#working-with-expressions)
    - [Evaluation Data Context](#evaluation-data-context)
      - [Accessing Array Element:](#accessing-array-element)
      - [Accessing Array Element via Reference:](#accessing-array-element-via-reference)
      - [Nested Referencing](#nested-referencing)
      - [Composite Reference Key](#composite-reference-key)
      - [Data Type Casting](#data-type-casting)
    - [Operand Types](#operand-types)
      - [Value](#value)
      - [Reference](#reference)
      - [Collection](#collection)
    - [Comparison Expressions](#comparison-expressions)
      - [Equal](#equal)
      - [Not Equal](#not-equal)
      - [Greater Than](#greater-than)
      - [Greater Than or Equal](#greater-than-or-equal)
      - [Less Than](#less-than)
      - [Less Than or Equal](#less-than-or-equal)
      - [In](#in)
      - [Not In](#not-in)
      - [Prefix](#prefix)
      - [Suffix](#suffix)
      - [Overlap](#overlap)
      - [Nil / Null](#nil--null)
      - [Present](#present)
    - [Logical Expressions](#logical-expressions)
      - [And](#and)
      - [Or](#or)
      - [Nor](#nor)
      - [Xor](#xor)
      - [Not](#not)
  - [Parser Options](#parser-options)
    - [Reference Serialize Options](#reference-serialize-options)
      - [From](#from)
      - [To](#to)
    - [Collection Serialize Options](#collection-serialize-options)
      - [Escape Character](#escape-character)
    - [ReferenceSimplify Options](#referencesimplify-options)
      - [Ignored Paths](#ignored-paths)
      - [Ignored Paths RegEx](#ignored-paths-regex)
    - [Operator Mapping](#operator-mapping)
- [Contributing](#contributing)
- [License](#license)

---

## Basic Usage

```odin
import "illogical"

// Create a parser
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Parse an expression to evaluable
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"==", 1, 1})
assert(parse_err == nil)
defer illogical.destroy_evaluable(&evaluable)

// Evaluate the evaluable
result, evaluate_err := illogical.evaluate(&evaluable)
assert(evaluate_err == nil)
defer illogical.destroy_evaluated(result)

// Print the result
fmt.printf("basic usage: %s, result: %v\n", illogical.to_string(&evaluable), result)
fmt.println()
```

### Evaluate Comparison Expression

```odin
// Create a parser
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Create evaluation context
ctx := map[string]illogical.Primitive{
    "name"          = "peter",
    "options"       = illogical.Array{1, 2, 3},
    "active"        = true,
    "address"       = map[string]illogical.Primitive{
        "city"    = "Toronto",
        "country" = "Canada",
    },
}
defer delete(ctx)

// Comparison expression
expressions := []illogical.Array{
    {"==", 5, 5},
    {"==", true, true},
    {"==", "$name", "peter"},
    {"==", "$missing", "peter"},
    {"!=", "circle", "square"},
    {">=", 10, "$options[0]"},
    {"<=", "$options[1]", 10},
    {">", 10, "$options[2]"},
    {"<", 5, 10},
    {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
    {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
    {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
    {"NONE", "$missing"},
    {"PRESENT", "$name"},
    {"PREFIX", "bo", "bogus"},
    {"SUFFIX", "bogus", "us"},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    result, evaluate_err := illogical.evaluate(&evaluable, ctx)
    assert(evaluate_err == nil)
    defer illogical.destroy_evaluated(result)
    fmt.printf("evaluate comparison: %s, result: %v\n", illogical.to_string(&evaluable), result)
}
```

### Evaluate Logical Expression

```odin
// Create a parser
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Create evaluation context
ctx := map[string]illogical.Primitive{
    "active" = true,
    "enabled" = false,
}
defer delete(ctx)

expressions := []illogical.Array{
    {"AND", true, true},
    {"AND", "$active", true},
    {"OR", true, "$enabled"},
    {"NOT", false},
    {"XOR", false, true, false},
    {"NOR", false, false},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    result, evaluate_err := illogical.evaluate(&evaluable, ctx)
    assert(evaluate_err == nil)
    defer illogical.destroy_evaluated(result)
    fmt.printf("evaluate logical: %s, result: %v\n", illogical.to_string(&evaluable), result)
}
```

### Serialize Comparison Expression

```odin
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

expressions := []illogical.Array{
    {"==", 5, 5},
    {"==", true, true},
    {"==", "$name", "peter"},
    {"==", "$missing", "peter"},
    {"!=", "circle", "square"},
    {">=", 10, "$options[0]"},
    {"<=", "$options[1]", 10},
    {">", 10, "$options[2]"},
    {"<", 5, 10},
    {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
    {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
    {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
    {"NONE", "$missing"},
    {"PRESENT", "$name"},
    {"PREFIX", "bo", "bogus"},
    {"SUFFIX", "bogus", "us"},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    serialized := illogical.serialize(&evaluable)
    fmt.printf("serialize comparison: %s, result: %v\n", illogical.to_string(&evaluable), serialized)
}
```

### Serialize Logical Expression

```odin
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

expressions := []illogical.Array{
    {"AND", "$active", true},
    {"OR", true, "$enabled"},
    {"NOT", false},
    {"XOR", false, true, false},
    {"NOR", false, false},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    serialized := illogical.serialize(&evaluable)
    fmt.printf("serialize logical: %s, result: %v\n", illogical.to_string(&evaluable), serialized)
}
```

### Get Comparison Expression String Representation

```odin
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

expressions := []illogical.Array{
    {"==", 5, 5},
    {"==", true, true},
    {"==", "$name", "peter"},
    {"==", "$missing", "peter"},
    {"!=", "circle", "square"},
    {">=", 10, "$options[0]"},
    {"<=", "$options[1]", 10},
    {">", 10, "$options[2]"},
    {"<", 5, 10},
    {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
    {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
    {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
    {"NONE", "$missing"},
    {"PRESENT", "$name"},
    {"PREFIX", "bo", "bogus"},
    {"SUFFIX", "bogus", "us"},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    serialized := illogical.serialize(&evaluable)
    fmt.printf("to string comparison: %v, result: %s\n", serialized, illogical.to_string(&evaluable))
}
```

### Get Logical Expression String Representation

```odin
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

expressions := []illogical.Array{
    {"AND", "$active", true},
    {"OR", true, "$enabled"},
    {"NOT", false},
    {"XOR", false, true, false},
    {"NOR", false, false},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    serialized := illogical.serialize(&evaluable)
    fmt.printf("to string logical: %v, result: %s\n", serialized, illogical.to_string(&evaluable))
}
```

### Simplify Comparison Expression

Simplifies an expression with a given context. This is useful when you already have some of the properties of context and wants to try to evaluate the expression.

```odin
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Create evaluation context
ctx := map[string]illogical.Primitive{
    "name"          = "peter",
    "options"       = illogical.Array{1, 2, 3},
    "active"        = true,
    "address"       = map[string]illogical.Primitive{
        "country" = "Canada",
    },
}
defer delete(ctx)

expressions := []illogical.Array{
    {"==", "$missing", "peter"},
    {"!=", "$name", "john"},
    {">=", 10, "$options[0]"},
    {"<=", "$options[1]", 10},
    {">", 10, "$options[2]"},
    {"<", 5, 10},
    {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
    {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
    {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
    {"NONE", "$missing"},
    {"PRESENT", "$name"},
    {"PREFIX", "bo", "bogus"},
    {"SUFFIX", "bogus", "uus"},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    simplified_value, simplified_evaluable := illogical.simplify(&evaluable, ctx)
    assert(simplified_value != nil || simplified_evaluable != nil)

    defer illogical.destroy_evaluable(&simplified_evaluable)

    if simplified_evaluable != nil {
        fmt.printf("simplify comparison: %s, simplified evaluable: %s\n", illogical.to_string(&evaluable), illogical.to_string(&simplified_evaluable))
    } else {
        fmt.printf("simplify comparison: %s, simplified value: %v\n", illogical.to_string(&evaluable), simplified_value)
    }
}
```

> Values not found in the context will cause the parent operand not to be evaluated and returned as part of the simplified expression.

### Simplify Logical Expression

Simplifies an expression with a given context. This is useful when you already have some of the properties of context and wants to try to evaluate the expression.

```odin
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Create evaluation context
ctx := map[string]illogical.Primitive{
    "name"          = "peter",
    "options"       = illogical.Array{1, 2, 3},
    "active"        = true,
    "address"       = map[string]illogical.Primitive{
        "country" = "Canada",
    },
}
defer delete(ctx)

expressions := []illogical.Array{
    {"AND", illogical.Array{"==", "$missing", "peter"}, true},
    {"OR", illogical.Array{"==", "$name", "peter"}, "$enabled"},
    {"NOT", false},
    {"XOR", "$missing", "$enabled", true},
    {"NOR", false, "$missing"},
}

for expression in expressions {
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    simplified_value, simplified_evaluable := illogical.simplify(&evaluable, ctx)
    assert(simplified_value != nil || simplified_evaluable != nil)

    defer illogical.destroy_evaluable(&simplified_evaluable)

    if simplified_evaluable != nil {
        fmt.printf("simplify logical: %s, simplified evaluable: %s\n", illogical.to_string(&evaluable), illogical.to_string(&simplified_evaluable))
    } else {
        fmt.printf("simplify logical: %s, simplified value: %v\n", illogical.to_string(&evaluable), simplified_value)
    }
}
```

> Values not found in the context will cause the parent operand not to be evaluated and returned as part of the simplified expression.


## Working with Expressions

### Evaluation Data Context

The evaluation data context is used to provide the expression with variable references, i.e. this allows for the dynamic expressions. The data context is object with properties used as the references keys, and its values as reference values.

> Valid reference values:
> - Primitive: i64, f64, bool, string, Array, Object
> - Array: [dynamic]Primitive
> - Object: map[string]Primitive

To reference the nested reference, please use "." delimiter, e.g.: `$address.city`

#### Accessing Array Element:

`$options[1]`

#### Accessing Array Element via Reference:

`$options[{index}]`

- The **index** reference is resolved within the data context as an array index.

#### Nested Referencing

`$address.{segment}`

- The **segment** reference is resolved within the data context as a property key.

#### Composite Reference Key

`$shape{shapeType}`

- The **shapeType** reference is resolved within the data context, and inserted into the outer reference key.
- E.g. **shapeType** is resolved as "**B**" and would compose the **$shapeB** outer reference.
- This resolution could be n-nested.

#### Data Type Casting

`$payment.amount.(Type)`

Cast the given data context into the desired data type before being used as an operand in the evaluation.

> Note: If the conversion is invalid, then a warning message is being logged.

Supported data type conversions:

- .(String): cast a given reference to String.
- .(Number): cast a given reference to Number.
- .(Integer): cast a given reference to Integer.
- .(Float): cast a given reference to Float.
- .(Boolean): cast a given reference to Boolean.

**Example**

```odin
// Data context
ctx := map[string]illogical.Primitive{
  "name"        = "peter",
  "country"     = "canada",
  "age"         = 21,
  "options"     = illogical.Array{1, 2, 3},
  "address"     = map[string]illogical.Primitive{
    "city"      = "Toronto",
    "country"   = "Canada",
  },
  "index"       = 2,
  "segment"     = "city",
  "shapeA"      = "box",
  "shapeB"      = "circle",
  "shapeType"   = "B",
}

// Evaluate an expression in the given data context
evaluable, _ := illogical.parse(&parser, illogical.Array{">", "$age", 20})
illogical.evaluate(&evaluable, ctx) // true

// Evaluate an expression in the given data context
evaluable, _ := illogical.parse(&parser, illogical.Array{"==", "$address.city", "Toronto"})
illogical.evaluate(&evaluable, ctx) // true

// Accessing Array Element
evaluable, _ := illogical.parse(&parser, illogical.Array{"==", "$options[1]", 2})
illogical.evaluate(&evaluable, ctx) // true

// Accessing Array Element via Reference
evaluable, _ := illogical.parse(&parser, illogical.Array{"==", "$options[{index}]", 3})
illogical.evaluate(&evaluable, ctx) // true

// Nested Referencing
evaluable, _ := illogical.parse(&parser, illogical.Array{"==", "$address.{segment}", "Toronto"})
illogical.evaluate(&evaluable, ctx) // true

// Composite Reference Key
evaluable, _ := illogical.parse(&parser, illogical.Array{"==", "$shape{shapeType}", "circle"})
illogical.evaluate(&evaluable, ctx) // true

// Data Type Casting
evaluable, _ := illogical.parse(&parser, illogical.Array{"==", "$age.(String)", "21"})
illogical.evaluate(&evaluable, ctx) // true
```

### Operand Types

#### Value

Simple value types: string, number, float, boolean.

**Example**

```odin
val1: illogical.Primitive = 5
var2: illogical.Primitive = "circle"
var3: illogical.Primitive = true

evaluable, parse_err := illogical.parse(
    &parser,
    illogical.Array{"AND", illogical.Array{"==", val1, var2}, illogical.Array{"==", var3, var3}}
)
```

#### Reference

The reference operand value is resolved from the [Evaluation Data Context](#evaluation-data-context), where the the operands name is used as key in the context.

The reference operand must be prefixed with `$` symbol, e.g.: `$name`. This might be customized via [Reference Predicate Parser Option](#reference-predicate).

**Example**

| Expression                    | Data Context      |
| ----------------------------- | ----------------- |
| `["==", "$age", 21]`          | `{age: 21}`       |
| `["==", "circle", "$shape"] ` | `{shape: "circle"}` |
| `["==", "$visible", true]`    | `{visible: true}` |

#### Collection

The operand could be an array mixed from [Value](#value) and [Reference](#reference).

**Example**

| Expression                               | Data Context                        |
| ---------------------------------------- | ----------------------------------- |
| `["IN", [1, 2], 1]`                      | `{}`                                |
| `["IN", "circle", ["$shapeA", "$shapeB"] ` | `{shapeA: "circle", shapeB: "box"}` |
| `["IN", ["$number", 5], 5]`                | `{number: 3}`                       |

### Comparison Expressions

#### Equal

Expression format: `["==", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: string, number, boolean.

```json
["==", 5, 5]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"==", 5, 5})
```

#### Not Equal

Expression format: `["!=", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: string, number, boolean.

```json
["!=", "circle", "square"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"!=", "circle", "square"})
```

#### Greater Than

Expression format: `[">", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: number.

```json
[">", 10, 5]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{">", 10, 5})
```

#### Greater Than or Equal

Expression format: `[">=", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: number.

```json
[">=", 5, 5]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{">=", 5, 5})
```

#### Less Than

Expression format: `["<", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: number.

```json
["<", 5, 10]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"<", 5, 10})
```

#### Less Than or Equal

Expression format: `["<=", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: number.

```json
["<=", 5, 5]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"<=", 5, 5})
```

#### In

Expression format: `["IN", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: number and number[] or string and string[].

```json
["IN", 5, [1, 2, 3, 4, 5]]
["IN", ["circle", "square", "triangle"], "square"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"IN", 5, illogical.Array{1, 2, 3, 4, 5}})

evaluable, parse_err := illogical.parse(&parser, illogical.Array{"IN", illogical.Array{"circle", "square", "triangle"}, "square"}, "box")
```

#### Not In

Expression format: `["NOT IN", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: number and number[] or string and string[].

```json
["IN", 10, [1, 2, 3, 4, 5]]
["IN", ["circle", "square", "triangle"], "oval"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"NOT IN", 10, illogical.Array{1, 2, 3, 4, 5}})

evaluable, parse_err := illogical.parse(&parser, illogical.Array{"NOT IN", illogical.Array{"circle", "square", "triangle"}, "oval"})
```

#### Prefix

Expression format: `["PREFIX", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: string.

- Left operand is the PREFIX term.
- Right operand is the tested word.

```json
["PREFIX", "hemi", "hemisphere"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"PREFIX", "hemi", "hemisphere"})

evaluable, parse_err := illogical.parse(&parser, illogical.Array{"PREFIX", "hemi", "sphere"})
```

#### Suffix

Expression format: `["SUFFIX", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types: string.

- Left operand is the tested word.
- Right operand is the SUFFIX term.

```json
["SUFFIX", "establishment", "ment"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"SUFFIX", "establishment", "ment"})

evaluable, parse_err := illogical.parse(&parser, illogical.Array{"SUFFIX", "establish", "ment"})
```

#### Overlap

Expression format: `["OVERLAP", `[Left Operand](#operand-types), [Right Operand](#operand-types)`]`.

> Valid operand types number[] or string[].

```json
["OVERLAP", [1, 2], [1, 2, 3, 4, 5]]
["OVERLAP", ["circle", "square", "triangle"], ["square"]]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"OVERLAP", illogical.Array{1, 2, 6}, illogical.Array{1, 2, 3, 4, 5}})

evaluable, parse_err := illogical.parse(&parser, illogical.Array{"OVERLAP", illogical.Array{"circle", "square", "triangle"}, illogical.Array{"square", "oval"}})
```

#### Nil / Null

Expression format: `["NONE", `[Reference Operand](#reference)`]`.

```json
["NONE", "$RefA"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"NONE", "$RefA"})
```

#### Present

Evaluates as FALSE when the operand is UNDEFINED or NULL.

Expression format: `["PRESENT", `[Reference Operand](#reference)`]`.

```json
["PRESENT", "$RefA"]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"PRESENT", "$RefA"})
```

### Logical Expressions

#### And

The logical AND operator (&&) returns the boolean value TRUE if both operands are TRUE and returns FALSE otherwise.

Expression format: `["AND", Left Operand 1, Right Operand 2, ... , Right Operand N]`.

> Valid operand types: [Comparison Expression](#comparison-expressions) or [Nested Logical Expression](#logical-expressions).

```json
["AND", ["==", 5, 5], ["==", 10, 10]]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"AND", illogical.Array{"==", 5, 5}, illogical.Array{"==", 10, 10}})
```

#### Or

The logical OR operator (||) returns the boolean value TRUE if either or both operands is TRUE and returns FALSE otherwise.

Expression format: `["OR", Left Operand 1, Right Operand 2, ... , Right Operand N]`.

> Valid operand types: [Comparison Expression](#comparison-expressions) or [Nested Logical Expression](#logical-expressions).

```json
["OR", ["==", 5, 5], ["==", 10, 5]]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"OR", illogical.Array{"==", 5, 5}, illogical.Array{"==", 10, 5}})
```

#### Nor

The logical NOR operator returns the boolean value TRUE if both operands are FALSE and returns FALSE otherwise.

Expression format: `["NOR", Left Operand 1, Right Operand 2, ... , Right Operand N]`

> Valid operand types: [Comparison Expression](#comparison-expressions) or [Nested Logical Expression](#logical-expressions).

```json
["NOR", ["==", 5, 1], ["==", 10, 5]]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"NOR", illogical.Array{"==", 5, 1}, illogical.Array{"==", 10, 5}})
```

#### Xor

The logical NOR operator returns the boolean value TRUE if both operands are FALSE and returns FALSE otherwise.

Expression format: `["XOR", Left Operand 1, Right Operand 2, ... , Right Operand N]`

> Valid operand types: [Comparison Expression](#comparison-expressions) or [Nested Logical Expression](#logical-expressions).

```json
["XOR", ["==", 5, 5], ["==", 10, 5]]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"XOR", illogical.Array{"==", 5, 5}, illogical.Array{"==", 10, 5}})
```

#### Not

The logical NOT operator returns the boolean value TRUE if the operand is FALSE, TRUE otherwise.

Expression format: `["NOT", Operand]`

> Valid operand types: [Comparison Expression](#comparison-expressions) or [Nested Logical Expression](#logical-expressions).

```json
["NOT", ["==", 5, 5]]
```

```odin
evaluable, parse_err := illogical.parse(&parser, illogical.Array{"NOT", illogical.Array{"==", 5, 5}})
```

## Parser Options

### Reference Serialize Options

**Usage**

```odin
// Create a serialize options reference
serialize_options_reference := illogical.Serialize_Options_Reference{
    from = proc(operand: string) -> (string, illogical.Error) {
        if len(operand) > 2 && strings.has_prefix(operand, "__") {
            return operand[2:], .None
        }
        return "", .Invalid_Operand
    },
    to = proc(operand: string) -> string {
        return fmt.tprintf("__%s", operand)
    },
}

// Create a parser
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Apply the serialize options reference to the parser
parser = illogical.with_serialize_options_reference(&parser, serialize_options_reference)^
```

#### From

A function used to determine if the operand is a reference type, otherwise evaluated as a static value.

```odin
proc(operand: string) -> (address: string, error: illogical.Error)
```

**Return value:**

- `address` = resolved address of the reference (e.g., `$state` -> `state`)
- `error` = `.None` when the operand is a reference type, otherwise `.Invalid_Operand`.

**Default reference predicate:**

> The `$` symbol at the begging of the operand is used to predicate the reference type., E.g. `$State`, `$Country`.

#### To

A function used to transform the operand into the reference annotation stripped form. I.e. remove any annotation used to detect the reference type. E.g. "$Reference" => "Reference".

```odin
proc(operand: string) -> string
```

> **Default reference transform:**
> It removes the `$` symbol at the begging of the operand name.

### Collection Serialize Options

**Usage**

```odin
// Create a parser
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Apply the serialize options collection to the parser
escape_character := "~"
parser = illogical.with_serialize_options_collection(&parser, escape_character)^
```

#### Escape Character

Charter used to escape fist value within a collection, if the value contains operator value.

**Example**
- `["==", 1, 1]` // interpreted as EQ expression
- `["\==", 1, 1]` // interpreted as a collection

> **Default escape character:**
> `\`

### ReferenceSimplify Options

Options applied while an expression is being simplified.

**Usage**

```odin
// Create a simplify options reference
yearly_income_key_rx, _ := regex.create_by_user("/_income$/g")
simplify_options_reference := illogical.Simplify_Options_Reference{
    ignored_paths = [dynamic]string{"firstname"},
    ignored_paths_rx = [dynamic]regex.Regular_Expression{
        yearly_income_key_rx,
    },
}
defer illogical.destroy_simplify_options_reference(&simplify_options_reference)
defer regex.destroy(yearly_income_key_rx)

// Create a parser
parser := illogical.new_parser()
defer illogical.destroy_parser(&parser)

// Apply the serialize options reference to the parser
parser = illogical.with_simplify_options_reference(&parser, simplify_options_reference)^
```

#### Ignored Paths

Reference paths which should be ignored while simplification is applied. Must be an exact match.

```odin
ignored_paths = [dynamic]string
```

#### Ignored Paths RegEx

Reference paths which should be ignored while simplification is applied. Matching regular expression patterns.

```odin
ignored_paths_rx = [dynamic]regex.Regular_Expression
```

### Operator Mapping

Mapping of the operators. The key is unique operator key, and the value is the key used to represent the given operator in the raw expression.

**Usage**

```odin
// Create a custom operator map
operator_map := map[illogical.Kind]string {
    .Eq      = "<eq>",
    .Ne      = "<ne>",
    .Gt      = "<gt>",
    .Ge      = "<ge>",
    .Lt      = "<lt>",
    .Le      = "<le>",
    .In      = "<in>",
    .Not_In  = "<not in>",
    .Overlap = "<overlap>",
    .None    = "<none>",
    .Present = "<present>",
    .Prefix  = "<prefix>",
    .Suffix  = "<suffix>",
    .And     = "<and>",
    .Or      = "<or>",
    .Not     = "<not>",
    .Xor     = "<xor>",
    .Nor     = "<nor>",
}
defer delete(operator_map)

// Create a parser with the custom operator map
parser := illogical.new_parser(&operator_map)
defer illogical.destroy_parser(&parser)
```

**Default operator mapping:**

```odin
.And     = "AND"
.Or      = "OR"
.Nor     = "NOR"
.Xor     = "XOR"
.Not     = "NOT"
.Eq      = "=="
.Ne      = "!="
.Gt      = ">"
.Ge      = ">="
.Lt      = "<"
.Le      = "<="
.None    = "NONE"
.Present = "PRESENT"
.In      = "IN"
.Not_In  = "NOT IN"
.Overlap = "OVERLAP"
.Prefix  = "PREFIX"
.Suffix  = "SUFFIX"
```

---

# Contributing

See [contributing.md](https://github.com/spaceavocado/pyillogical/blob/master/contributing.md).

# License

Illogical is released under the MIT license. See [license.md](https://github.com/spaceavocado/pyillogical/blob/master/license.md).
