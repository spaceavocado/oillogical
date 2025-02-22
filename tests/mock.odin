package illogical_test

import "core:fmt"

import illogical "../src"

ref :: proc(address: string) -> illogical.Evaluable {
    e, _ := illogical.new_reference(address)
    return e
}

val :: proc(data: illogical.Primitive) -> illogical.Evaluable {
    e := illogical.new_value(data)
    return e
}

col :: proc(items: ..illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_collection(..items)
    return e
}

eq :: proc(left: illogical.Evaluable, right: illogical.Evaluable) -> illogical.Evaluable {
    return illogical.new_eq("==", left, right)
}

and := proc(operands: ..illogical.Evaluable, operator: string = "AND") -> illogical.Evaluable {
    e, _ := illogical.new_and(operator, ..operands)
    return e
}

or := proc(operands: ..illogical.Evaluable, operator: string = "OR") -> illogical.Evaluable {
    e, _ := illogical.new_or(operator, ..operands)
    return e
}

not := proc(operand: illogical.Evaluable, operator: string = "NOT") -> illogical.Evaluable {
    return illogical.new_not(operator, operand)
}

nor := proc(operands: ..illogical.Evaluable, operator: string = "NOR") -> illogical.Evaluable {
    e, _ := illogical.new_nor(operator, "NOT", ..operands)
    return e
}

xor := proc(operands: ..illogical.Evaluable, operator: string = "XOR") -> illogical.Evaluable {
    e, _ := illogical.new_xor(operator, "NOT", "NOR", ..operands)
    return e
}

addr :: proc(val: string, opts: ^illogical.Serialize_Options_Reference) -> string {
	return opts.to(val)
}
