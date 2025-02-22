package illogical

import "core:strings"
import "core:fmt"

DEFAULT_OPERATOR_MAP :: proc() -> map[Kind]string {
    m := make(map[Kind]string)

    m[.And]     = "AND"
    m[.Or]      = "OR"
    m[.Nor]     = "NOR"
    m[.Xor]     = "XOR"
    m[.Not]     = "NOT"
    m[.Eq]      = "=="
    m[.Ne]      = "!="
    m[.Gt]      = ">"
    m[.Ge]      = ">="
    m[.Lt]      = "<"
    m[.Le]      = "<="
    m[.None]    = "NONE"
    m[.Present] = "PRESENT"
    m[.In]      = "IN"
    m[.Not_In]  = "NOT IN"
    m[.Overlap] = "OVERLAP"
    m[.Prefix]  = "PREFIX"
    m[.Suffix]  = "SUFFIX"

    return m
}

Expression_Factory :: struct {
    operator: string,
    operator_not: string,
    operator_nor: string,
    factory_unary: proc(string, Evaluable) -> Evaluable,
    factory_binary: proc(string, Evaluable, Evaluable) -> Evaluable,
    factory_many: union{
        proc(string, ..Evaluable) -> (Evaluable, Error),
        proc(string, string, ..Evaluable) -> (Evaluable, Error),
        proc(string, string, string, ..Evaluable) -> (Evaluable, Error),
    },
}

Operator_Expression_Factory :: map[string]Expression_Factory

Parser :: struct {
    operator_expression_factory: Operator_Expression_Factory,
    serialize_options_reference: Serialize_Options_Reference,
    serialize_options_collection: Serialize_Options_Collection,
    simplify_options_reference: Simplify_Options_Reference,
}

new_parser :: proc(
    operator_map: ^map[Kind]string = nil,
) -> Parser {
    operator_map := operator_map != nil ? operator_map^ : DEFAULT_OPERATOR_MAP()
    defer delete(operator_map)

    escaped_operators := make(map[string]bool, len(operator_map))
    defer delete(escaped_operators)

    for _, v in operator_map {
        escaped_operators[v] = true
    }

    return Parser{
        operator_expression_factory = create_operator_expression_factory(&operator_map),
        serialize_options_reference = default_serialize_options_reference(),
        serialize_options_collection = Serialize_Options_Collection{
            escape_character = "\\",
            escaped_operators = escaped_operators,
        },
    }
}

with_serialize_options_reference :: proc(parser: ^Parser, options: Serialize_Options_Reference) -> ^Parser {
    parser.serialize_options_reference = options
    return parser
}

with_serialize_options_collection :: proc(parser: ^Parser, options: Serialize_Options_Collection) -> ^Parser {
    parser.serialize_options_collection = options
    return parser
}

with_simplify_options_reference :: proc(parser: ^Parser, options: Simplify_Options_Reference) -> ^Parser {
    parser.simplify_options_reference = options
    return parser
}

parse :: proc(parser: ^Parser, input: Primitive) -> (Evaluable, Error) {
    if input == nil {
		return nil, .Unexpected_Input
	}

    array, ok := input.(Array)
    if !ok {
        return create_operand(parser, input)
    }
    defer delete(array)

    if len(array) < 2 {
        return create_operand(parser, input)
    }

    operator, is_operator := array[0].(string)
    if is_operator && is_escaped(operator, parser.serialize_options_collection.escape_character) {
        escaped_array := make([dynamic]Primitive, len(array))
        defer delete(escaped_array)
        
        escaped_array[0] = operator[1:]
        for v, i in array[1:] {
            escaped_array[i+1] = v
        }

        return create_operand(parser, escaped_array)
    }

    expression, err := create_expression(parser, array)
    if err != nil {
        return create_operand(parser, input)
    }

    return expression, nil
}

create_operator_expression_factory :: proc(operator_map: ^map[Kind]string) -> Operator_Expression_Factory {
    operator_handler := make(Operator_Expression_Factory, len(Kind))
    // defer delete(operator_handler)

    // Logical
    operator_handler[operator_map[.And]]        = Expression_Factory{operator=operator_map[.And],       factory_many=new_and}
	operator_handler[operator_map[.Or]]         = Expression_Factory{operator=operator_map[.Or],        factory_many=new_or}
	operator_handler[operator_map[.Nor]]        = Expression_Factory{operator=operator_map[.Nor],       factory_many=new_nor}
    operator_handler[operator_map[.Xor]]        = Expression_Factory{operator=operator_map[.Xor],       factory_many=new_xor}
    operator_handler[operator_map[.Not]]        = Expression_Factory{operator=operator_map[.Not],       factory_unary=new_not}

    // Comparison
    operator_handler[operator_map[.Eq]]         = Expression_Factory{operator=operator_map[.Eq],        factory_binary=new_eq}
    operator_handler[operator_map[.Ne]]         = Expression_Factory{operator=operator_map[.Ne],        factory_binary=new_ne}
    operator_handler[operator_map[.Gt]]         = Expression_Factory{operator=operator_map[.Gt],        factory_binary=new_gt}
    operator_handler[operator_map[.Ge]]         = Expression_Factory{operator=operator_map[.Ge],        factory_binary=new_ge}
    operator_handler[operator_map[.Lt]]         = Expression_Factory{operator=operator_map[.Lt],        factory_binary=new_lt}
    operator_handler[operator_map[.Le]]         = Expression_Factory{operator=operator_map[.Le],        factory_binary=new_le}
    operator_handler[operator_map[.In]]         = Expression_Factory{operator=operator_map[.In],        factory_binary=new_in}
    operator_handler[operator_map[.Not_In]]     = Expression_Factory{operator=operator_map[.Not_In],    factory_binary=new_not_in}
    operator_handler[operator_map[.Overlap]]    = Expression_Factory{operator=operator_map[.Overlap],   factory_binary=new_overlap}
    operator_handler[operator_map[.None]]       = Expression_Factory{operator=operator_map[.None],      factory_unary=new_nil}
    operator_handler[operator_map[.Present]]    = Expression_Factory{operator=operator_map[.Present],   factory_unary=new_present}
    operator_handler[operator_map[.Suffix]]     = Expression_Factory{operator=operator_map[.Suffix],    factory_binary=new_suffix}
    operator_handler[operator_map[.Prefix]]     = Expression_Factory{operator=operator_map[.Prefix],    factory_binary=new_prefix}

    return operator_handler
}

build_expression_unary :: proc(exp: ^Expression_Factory, operands: []Evaluable) -> (Evaluable, Error) {
    return exp.factory_unary(exp.operator, operands[0]), nil
}

build_expression_binary :: proc(exp: ^Expression_Factory, operands: []Evaluable) -> (Evaluable, Error) {
    return exp.factory_binary(exp.operator, operands[0], operands[1]), nil
}

build_expression_many :: proc(exp: ^Expression_Factory, operands: []Evaluable) -> (Evaluable, Error) {
    switch v in exp.factory_many {
        case proc(string, ..Evaluable) -> (Evaluable, Error):
            return v(exp.operator, ..operands)
        case proc(string, string, ..Evaluable) -> (Evaluable, Error):
            return v(exp.operator, exp.operator_not, ..operands)
        case proc(string, string, string, ..Evaluable) -> (Evaluable, Error):
            return v(exp.operator, exp.operator_not, exp.operator_nor, ..operands)
        case:
            panic("Invalid factory many")
    }
}

create_operand :: proc(parser: ^Parser, input: Primitive) -> (Evaluable, Error) {
    if array, ok := input.(Array); ok {
        if len(array) == 0 {
            return nil, .Invalid_Undefined_Operand
        }

        operands := make([dynamic]Evaluable, len(array))
        defer delete(operands)

        for v, i in array {
            operand, err := parse(parser, v)
            if err != nil {
                return nil, err
            }
            operands[i] = operand
        }

        return new_collection(..operands[:], options=&parser.serialize_options_collection)
    }

    addr, err := to_reference_addr(input, &parser.serialize_options_reference)
    if err == nil {
		return new_reference(addr, &parser.serialize_options_reference, &parser.simplify_options_reference)
	}

    return new_value(input), nil
}

create_expression :: proc(parser: ^Parser, input: Array) -> (Evaluable, Error) {
    operator := input[0]
    operands := input[1:]

    if _, ok := operator.(string); !ok {
        return nil, .Unexpected_Logical_Expression
    }

    factory, ok := parser.operator_expression_factory[operator.(string)]
    if !ok {
        return nil, .Unexpected_Logical_Expression
    }

    ops := make([]Evaluable, len(operands))
    defer delete(ops)

    for operand, i in operands {
        e, err := parse(parser, operand)
        if err != nil {
            return nil, err
        }
        ops[i] = e
    }

    if factory.factory_unary != nil {
        return factory.factory_unary(factory.operator, ops[0]), nil
    }

    if factory.factory_binary != nil {
        return factory.factory_binary(factory.operator, ops[0], ops[1]), nil
    }

    switch many in factory.factory_many {
        case proc(string, ..Evaluable) -> (Evaluable, Error):
            return many(factory.operator, ..ops)
        case proc(string, string, ..Evaluable) -> (Evaluable, Error):
            return many(factory.operator, factory.operator_not, ..ops)
        case proc(string, string, string, ..Evaluable) -> (Evaluable, Error):
            return many(factory.operator, factory.operator_not, factory.operator_nor, ..ops)
        case:
            panic("Invalid factory many")
    }
}

is_escaped :: proc(value: string, escape_character: string) -> bool {
	return escape_character != "" && strings.has_prefix(value, escape_character)
}

to_reference_addr :: proc(input: Primitive, options: ^Serialize_Options_Reference) -> (string, Error) {
    #partial switch typed in input {
	case string:
		return options.from(typed)
	case:
		return "", .Invalid_Data_Type
	}
}

destroy_parser :: proc(parser: ^Parser) {
    delete(parser.operator_expression_factory)
    // delete(parser.serialize_options_collection)
    // delete(parser.serialize_options_reference)
    // delete(parser.simplify_options_reference)
}