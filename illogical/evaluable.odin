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

// Operator mapping represents a map between an expression kind and the actual
// text literal denoting an expression.
// 
// 	Example:
// 		["==", 1, 1] to be mapped as EQ expression would be represented as:
// 
// 		map[Kind]string{ Eq: "==" }
OperatorMapping :: map[Kind]string

Integer :: i64
Float   :: f64
Boolean :: bool
String  :: string
Array   :: [dynamic]Primitive
Object  :: map[string]Primitive

Primitive :: union{
    Integer,
    Float,
    Boolean,
    String,
	Array,
	Object,
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

evaluate_with_no_context :: proc(evaluable: ^Evaluable) -> (Evaluated, Error) {
	return evaluate_with_flatten_context(evaluable, nil)
}

evaluate :: proc{ evaluate_with_context, evaluate_with_any_context, evaluate_with_flatten_context, evaluate_with_no_context }

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
		fmt.printfln("%v", e)
		panic("Unsupported evaluable type")
    }
}

// Free all data allocated by the evaluable
destroy_evaluable :: proc(evaluable: ^Evaluable) {
    #partial switch &e in evaluable {
	case Collection:
		// fmt.printf("destroy collection\n")
		for &item in e.data {
			// fmt.printf("destroy collection item\n")
			destroy_evaluable(&item)
		}
		// fmt.printf("destroy collection data, len: %d\n", len(e.data))
		delete(e.data)
		// fmt.printf("!!!!destroy collection done\n")
	case Comparison:
		// fmt.printf("destroy comparison\n")
		for &operand, i in e.operands {
			// fmt.printf("op: %d/%d\n", i, len(e.operands))
			// fmt.printf("destroy comparison operand\n")
			destroy_evaluable(&operand)
		}
		delete(e.operands)
		// fmt.printf("!!!!destroy comparison done\n")
	case Logical:
		for &operand in e.operands {
			destroy_evaluable(&operand)
		}
		delete(e.operands)
	case:
		// fmt.printf("--destroy evaluable\n")
    }
}

// Free all data allocated by the evaluated
destroy_evaluated :: proc(evaluated: Evaluated) {
	#partial switch t in evaluated {
	case Primitive:
		destroy_primitive(t)
	case Array:
		for item in t {
			destroy_primitive(item)
		}
		delete(t)
	}
}

// Free all data allocated by the primitive
destroy_primitive :: proc(primitive: Primitive) {
	#partial switch t in primitive {
	case Array:
		for item in t {
			destroy_primitive(item)
		}
		delete(t)
	case Object:
		for key, value in t {
			destroy_primitive(value)
		}
		delete(t)
	}
}

@(require_results)
clone_evaluable :: proc(evaluable: Evaluable) -> Evaluable {
	#partial switch &e in evaluable {
	case Collection:
		items := make([dynamic]Evaluable, len(e.data))
		defer delete(items)

		for item, i in e.data {
			items[i] = clone_evaluable(item)
		}

		collection, _ := new_collection(..items[:], options=&e.options)
		return collection
	case Comparison:
		operands := make([dynamic]Evaluable, len(e.operands))
		defer delete(operands)

		for operand, i in e.operands {
			operands[i] = clone_evaluable(operand)
		}

		return new_comparison(e.kind.(string), e.operator, e.handler, ..operands[:])
	case Logical:
		operands := make([dynamic]Evaluable, len(e.operands))
		defer delete(operands)

		for operand, i in e.operands {
			operands[i] = clone_evaluable(operand)
		}

		return new_logical(e.kind.(string), e.operator, e.not_operator, e.nor_operator, e.handler, e.simplify_handler, ..operands[:])
	case:
		return e
	}
}
