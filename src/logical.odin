package illogical

import "core:fmt"

Logical :: struct {
	kind:     Primitive,
	operator: string,
    not_operator: string,
    nor_operator: string,
	operands: [dynamic]Evaluable,
	handler:  proc(ctx: ^FlattenContext, operands: []Evaluable) -> (Evaluated, Error),
    simplify_handler: simplify_handler,
}

simplify_handler_base :: proc(operator: string, ctx: ^FlattenContext, operands: []Evaluable) -> (Evaluated, Evaluable)
simplify_handler_with_not :: proc(operator: string, ctx: ^FlattenContext, operands: []Evaluable, not_operator: string) -> (Evaluated, Evaluable)
simplify_handler_with_not_nor :: proc(operator: string, ctx: ^FlattenContext, operands: []Evaluable, not_operator: string, nor_operator: string) -> (Evaluated, Evaluable)
simplify_handler :: union{ simplify_handler_base, simplify_handler_with_not, simplify_handler_with_not_nor }

new_logical :: proc(
    kind: string,
    operator: string,
    not_operator: string,
    nor_operator: string,
    handler: proc(ctx: ^FlattenContext, operands: []Evaluable) -> (Evaluated, Error),
    simplify_handler: simplify_handler,
    operands: ..Evaluable,
) -> Evaluable {
	l := Logical{
		kind=     kind,
		operator= operator,
		operands= make([dynamic]Evaluable, len(operands)),
		handler=  handler,
        simplify_handler= simplify_handler,
	}

	for item, i in operands {
		l.operands[i] = item
	}

	return l
}

evaluate_logical :: proc(logical: ^Logical, ctx: ^FlattenContext) -> (Evaluated, Error) {
	return logical.handler(ctx, logical.operands[:])
}

simplify_logical :: proc(logical: ^Logical, ctx: ^FlattenContext) -> (Evaluated, Evaluable) {
    switch simplify_handler in logical.simplify_handler {
        case simplify_handler_base:
            return simplify_handler(logical.operator, ctx, logical.operands[:])
        case simplify_handler_with_not:
            return simplify_handler(logical.operator, ctx, logical.operands[:], logical.not_operator)
        case simplify_handler_with_not_nor:
            return simplify_handler(logical.operator, ctx, logical.operands[:], logical.not_operator, logical.nor_operator)
        case:
            panic("Invalid simplify handler")
    }
}

serialize_logical :: proc(logical: ^Logical) -> Primitive {
	res := make(Array, len(logical.operands) + 1)
	res[0] = logical.kind
	for &e, i in logical.operands {
        res[i + 1] = serialize(&e)
	}
	return res
}

to_string_logical :: proc(logical: ^Logical) -> string {
	res := "("
    for &e, i in logical.operands {
        res = fmt.tprintf("%s%s", res, to_string(&e))
        if i < len(logical.operands) - 1 {
            res = fmt.tprintf("%s %s ", res, logical.operator)
        }
	}
    return fmt.tprintf("%s)", res)
}

evaluate_logical_operand :: proc(e: ^Evaluable, ctx: ^FlattenContext) -> (bool, Error) {
    res, err := evaluate(e, ctx)
    if err != nil {
        return false, err
    }
    if res, ok := res.(Primitive).(bool); ok {
        return res, nil
    }
    return false, .Invalid_Evaluated_Logical_Operand
}