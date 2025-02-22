package illogical

import "core:fmt"
import "core:reflect"
import "base:runtime"
import "core:mem"

Kind :: enum {
	Value,
	Reference,
	Collection,
	And,
	Or,
	Nor,
	Xor,
	Not,
	Eq,
	Ne,
	Gt,
	Ge,
	Lt,
	Le,
	None,
	Present,
	In,
	Not_In,
	Overlap,
	Prefix,
	Suffix,
}

/*
	Operator mapping represents a map between an expression kind and the actual
	text literal denoting an expression.

	Example:
		["==", 1, 1] to be mapped as EQ expression would be represented as:

		map[Kind]string{ Eq: "==" }
*/
OperatorMapping :: map[Kind]string

Integer :: int
Float   :: f64
Boolean :: bool
String  :: string
Array   :: [dynamic]Primitive

Primitive :: union{
    Integer,
    Float,
    Boolean,
    String,
	Array,
}

Evaluated :: union{Primitive, Array}

Context :: map[string]Primitive
Flatten_Context :: distinct map[string]Primitive

Evaluable :: union {
	Value,
	Reference,
	Collection,
	Comparison,
	Logical,
}

evaluate_with_context :: proc(evaluable: ^Evaluable, ctx: Context) -> (Evaluated, Error) {
	flatten := flatten_context(ctx)
	return evaluate_with_flatten_context(evaluable, &flatten)
}

evaluate_with_any_context :: proc(evaluable: ^Evaluable, ctx: any) -> (Evaluated, Error) {
	flatten := flatten_context(ctx)
	return evaluate_with_flatten_context(evaluable, &flatten)
}

evaluate_with_flatten_context :: proc(evaluable: ^Evaluable, ctx: ^Flatten_Context) -> (Evaluated, Error) {
	#partial switch &e in evaluable {
	case Value:
		return evaluate_value(&e), .None
	case Collection:
		return evaluate_collection(&e, ctx)
	case Reference:
		return evaluate_reference(&e, ctx)
	case Comparison:
		return evaluate_comparison(&e, ctx)
	case Logical:
		return evaluate_logical(&e, ctx)
	case:
		panic("Unsupported evaluable type")
	}
}

evaluate :: proc{ evaluate_with_context, evaluate_with_any_context, evaluate_with_flatten_context }

simplify_with_context :: proc(evaluable: ^Evaluable, ctx: any) -> (Evaluated, Evaluable) {
	flatten := flatten_context(ctx)
    return simplify_with_flatten_context(evaluable, &flatten)
}

simplify_with_flatten_context :: proc(evaluable: ^Evaluable, ctx: ^Flatten_Context) -> (Evaluated, Evaluable) {
    #partial switch &e in evaluable {
    case Value:
        return simplify_value(&e), nil
    case Collection:
        return simplify_collection(&e, ctx)
	case Reference:		
		return simplify_reference(&e, ctx)
	case Comparison:
		return simplify_comparison(&e, ctx)
	case Logical:
		return simplify_logical(&e, ctx)
	case:
        panic("Unsupported evaluable type")
    }			
}

simplify :: proc{ simplify_with_context, simplify_with_flatten_context }

serialize :: proc(evaluable: ^Evaluable) -> Primitive {
    #partial switch &e in evaluable {
    case Value:
        return serialize_value(&e)
    case Collection:
        return serialize_collection(&e)
	case Reference:
		return serialize_reference(&e)
	case Comparison:
		return serialize_comparison(&e)
	case Logical:
		return serialize_logical(&e)
    case:
        panic("Unsupported evaluable type")
    }
}

to_string :: proc(evaluable: ^Evaluable) -> string {
    #partial switch &e in evaluable {
    case Value:
        return to_string_value(&e)
    case Collection:
        return to_string_collection(&e)
	case Reference:
		return to_string_reference(&e)
	case Comparison:
		return to_string_comparison(&e)
	case Logical:
		return to_string_logical(&e)
	case:
		panic("Unsupported evaluable type")
    }
}

/*
	Free all data allocated by the evaluable and its children.
*/
destroy_evaluable :: proc(evaluable: ^Evaluable) {
    #partial switch &e in evaluable {
	case Collection:
		for &item in e.data {
			destroy_evaluable(&item)
		}
		delete(e.data)
	case Comparison:
		for &operand in e.operands {
			destroy_evaluable(&operand)
		}
		delete(e.operands)
	case Logical:
		for &operand in e.operands {
			destroy_evaluable(&operand)
		}
		delete(e.operands)
    }	
}

destroy_evaluated :: proc(a: Evaluated) {
	if p, ok := a.(Primitive); ok {
		destroy_primitive(p)
	}
	if arr, ok := a.(Array); ok {
		for item in arr {
			destroy_primitive(item)
		}
		delete(arr)
	}
}

destroy_primitive :: proc(a: Primitive) {
	if arr, ok := a.(Array); ok {
		for item in arr {
			destroy_primitive(item)
		}
		delete(arr)
	}
}

new_primitive :: proc(a: Primitive) -> Primitive {
	return a
}
