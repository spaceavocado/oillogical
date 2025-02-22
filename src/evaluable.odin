package illogical

import "core:fmt"
import "core:reflect"
import "base:runtime"
import "core:mem"
import "core:log"
// Evaluation expression kind.
Kind :: enum {
    // Unknown,
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

// Operator mapping represents a map between an expression kind and the actual
// text literal denoting an expression.
//
// Example:
// ["==", 1, 1] to be mapped as EQ expression would be represented as:
//
// map[Kind]string{ Eq: "==" }
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

Context :: map[string]Primitive
FlattenContext :: distinct map[string]Primitive

Evaluated :: union{Primitive, Array}
Expression :: Evaluated
// Evaluated :: union{Primitive, Array}
// Expression :: [dynamic]Mixed
// Serialized :: union{Primitive, Expression}

Evaluable :: union {
	Value,
	Reference,
	Collection,
	Comparison,
	Logical,
}

_evaluate_with_context :: proc(evaluable: ^Evaluable, ctx: Context) -> (Evaluated, Error) {
	flatten := flattenContext(ctx)
	return _evaluate_with_flatten_context(evaluable, &flatten)
}

_evaluate_with_any_context :: proc(evaluable: ^Evaluable, ctx: any) -> (Evaluated, Error) {
	flatten := flattenContext(ctx)
	return _evaluate_with_flatten_context(evaluable, &flatten)
}

_evaluate_with_flatten_context :: proc(evaluable: ^Evaluable, ctx: ^FlattenContext) -> (Evaluated, Error) {
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

evaluate :: proc{ _evaluate_with_context, _evaluate_with_any_context, _evaluate_with_flatten_context }

simplify_with_context :: proc(evaluable: ^Evaluable, ctx: any) -> (Evaluated, Evaluable) {
	flatten := flattenContext(ctx)
    return simplify_with_flatten_context(evaluable, &flatten)
}

simplify_with_flatten_context :: proc(evaluable: ^Evaluable, ctx: ^FlattenContext) -> (Evaluated, Evaluable) {
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
		log.info(typeid_of(type_of(&e)))
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

new_primitive :: proc(a: Primitive) -> Primitive {
	return a
}
