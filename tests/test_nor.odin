#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_nor_new :: proc(t: ^testing.T) {
    _, err := illogical.new_nor("NOR", "NOT")

    testing.expectf(t, err == .Invalid_Logical_Expression, "input (%v): expected %v, got %v", []illogical.Evaluable{}, err)   
}

@test
test_nor_handler :: proc(t: ^testing.T) {
    ctx := illogical.Flatten_Context{
        "RefA" = 10,
    }
    defer delete(ctx)

	tests := []struct {
		operands: []illogical.Evaluable,
		expected: bool
	}{
		// Truthy
		{[]illogical.Evaluable{val(false), val(false)}, true},
		{[]illogical.Evaluable{val(false), val(false), val(false)}, true},
		// Falsy
		{[]illogical.Evaluable{val(true), val(false)}, false},
		{[]illogical.Evaluable{val(false), val(true)}, false},
		{[]illogical.Evaluable{val(true), val(true)}, false},
	}

	for test in tests {
		evaluated, err := illogical.handler_nor(&ctx, test.operands[:])

		testing.expectf(t, evaluated.(illogical.Primitive).(bool) == test.expected, "input (%v): expected %v, got %v", test.operands, test.expected, evaluated)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.operands, err)
	}

    errs := []struct {
		operands: []illogical.Evaluable,
		expected: illogical.Error,
	}{
		{[]illogical.Evaluable{val(false), ref("RefA.(Boolean)")}, .Invalid_Data_Type_Conversion},
		{[]illogical.Evaluable{val(false), val(1)}, .Invalid_Evaluated_Logical_Operand},
	}

	for test in errs {
		_, err := illogical.handler_nor(&ctx, test.operands[:])

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.operands, test.expected, err)
	}
}

@test
test_nor_simplify :: proc(t: ^testing.T) {
	ctx := illogical.Flatten_Context{
		"RefA" = true,
	}
	defer delete(ctx)

	tests := []struct {
		input: []illogical.Evaluable,
		value: illogical.Primitive,
		e:     illogical.Evaluable
	}{
		{[]illogical.Evaluable{val(false), val(false)}, true, nil},
		{[]illogical.Evaluable{val(true), val(true)}, false, nil},
		{[]illogical.Evaluable{val(true), val(false)}, false, nil},
		{[]illogical.Evaluable{ref("RefA"), val(false)}, false, nil},
		{[]illogical.Evaluable{ref("Missing"), val(true)}, false, nil},
		{[]illogical.Evaluable{ref("Missing"), val(false)}, nil, not(ref("Missing"))},
		{[]illogical.Evaluable{ref("Missing"), ref("Missing")}, nil, nor(ref("Missing"), ref("Missing"))},
	}

	for &test in tests {
        e := nor(..test.input)
		value, self := illogical.simplify(&e, &ctx)

		testing.expectf(t, matches_evaluated(value, test.value), "input (%v): expected %v, got %v", test.input, test.value, value)
		testing.expectf(t, fprint(self) == fprint(test.e), "input (%v): expected %v, got %v", test.input, test.e, self)

        illogical.destroy_evaluable(&e)
        illogical.destroy_evaluable(&self)
        illogical.destroy_evaluable(&test.e)
	}
}