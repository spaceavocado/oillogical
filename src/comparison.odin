package illogical

import "core:fmt"

Comparison :: struct {
	kind:     Primitive,
	operator: string,
	operands: [dynamic]Evaluable,
	handler:  proc([]Evaluated) -> Evaluated,
}

new_comparison :: proc(kind: string, operator: string, handler: proc([]Evaluated) -> Evaluated, operands: ..Evaluable) -> Evaluable {
	c := Comparison{
		kind=     kind,
		operator= operator,
		operands= make([dynamic]Evaluable, len(operands)),
		handler=  handler,
	}

	for item, i in operands {
		c.operands[i] = item
	}

	return c
}

evaluate_comparison :: proc(comparison: ^Comparison, ctx: ^FlattenContext) -> (Evaluated, Error) {
	evaluated := make([dynamic]Evaluated, len(comparison.operands))
    defer delete(evaluated)

	for &e, i in comparison.operands {
		val, err := evaluate(&e, ctx)
		if err != nil {
			return false, err
		}
		evaluated[i] = val
	}
	return comparison.handler(evaluated[:]), nil
}

simplify_comparison :: proc(comparison: ^Comparison, ctx: ^FlattenContext) -> (Evaluated, Evaluable) {
	res := make([dynamic]Evaluated, len(comparison.operands))
	defer delete(res)

	for &e, i in comparison.operands {
		val, e := simplify(&e, ctx)
		if e != nil {
			return {}, comparison^
		}
		res[i] = val
	}

	return comparison.handler(res[:]), nil
}

serialize_comparison :: proc(comparison: ^Comparison) -> Primitive {
	res := make(Array, len(comparison.operands) + 1)
	res[0] = comparison.kind
	for &e, i in comparison.operands {
        res[i + 1] = serialize(&e)
	}
	return res
}

to_string_comparison :: proc(comparison: ^Comparison) -> string {
	res := fmt.tprintf("(%s %s", to_string(&comparison.operands[0]), comparison.operator)
	if len(comparison.operands) > 1 {
        res = fmt.tprintf("%s %s", res, to_string(&comparison.operands[1]))
	}
    return fmt.tprintf("%s)", res)
}

compare_primitives :: proc(
    a: Evaluated, b: Evaluated,
    as_int: proc(int, int) -> Evaluated = nil,
    as_float: proc(f64, f64) -> Evaluated = nil,
    as_string: proc(string, string) -> Evaluated = nil,
    as_bool: proc(bool, bool) -> Evaluated = nil,
) -> Evaluated {
    if a, ok := a.(Primitive).(int); ok && as_int != nil {
        if b, ok := b.(Primitive).(int); ok {
            return as_int(a, b)
        }
        if b, ok := b.(Primitive).(f64); ok {
            return as_float(f64(a), b)
        }
    }
    if a, ok := a.(Primitive).(f64); ok && as_float != nil {
        if b, ok := b.(Primitive).(f64); ok {
            return as_float(a, b)
        }
        if b, ok := b.(Primitive).(int); ok {
            return as_float(a, f64(b))
        }
    }
	if a, ok := a.(Primitive).(string); ok && as_string != nil {
        if b, ok := b.(Primitive).(string); ok {
            return as_string(a, b)
        }
    }
	if a, ok := a.(Primitive).(bool); ok && as_bool != nil {
        if b, ok := b.(Primitive).(bool); ok {
            return as_bool(a, b)
        }
    }
    return false
}

as_equatable_primitive :: proc(p: Evaluated) -> (union{ Integer, Float, Boolean, String }, bool) {
	if p, ok := p.(Primitive); ok {
		#partial switch v in p {
		case Integer:
			return v, true
		case Float:
			return v, true
		case Boolean:
			return v, true
		case String:
			return v, true
		case:
			return nil, false
		}
	}
	return nil, p == nil
}
