#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_or_new :: proc(t: ^testing.T) {
    _, err := illogical.new_or("OR")

    testing.expectf(t, err == .Invalid_Logical_Expression, "input (%v): expected %v, got %v", []illogical.Evaluable{}, err)   
}

@test
test_or_handler :: proc(t: ^testing.T) {
    ctx := illogical.FlattenContext{
        "RefA" = 10,
    }
    defer delete(ctx)

	tests := []struct {
		operands: []illogical.Evaluable,
		expected: bool
	}{
		// Truthy
		{[]illogical.Evaluable{val(true), val(false)}, true},
		{[]illogical.Evaluable{val(false), val(true)}, true},
		// Falsy
		{[]illogical.Evaluable{val(false), val(false)}, false},
	}

	for test in tests {
		evaluated, err := illogical.handler_or(&ctx, test.operands[:])

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
		_, err := illogical.handler_or(&ctx, test.operands[:])

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.operands, test.expected, err)
	}
}

@test
test_or_simplify :: proc(t: ^testing.T) {
	ctx := illogical.FlattenContext{
		"RefA" = true,
	}
	defer delete(ctx)

	tests := []struct {
		input: []illogical.Evaluable,
		value: illogical.Primitive,
		e:     illogical.Evaluable
	}{
		{[]illogical.Evaluable{val(true), val(true)}, true, nil},
		{[]illogical.Evaluable{val(true), val(false)}, true, nil},
		{[]illogical.Evaluable{val(false), val(false)}, false, nil},
		{[]illogical.Evaluable{ref("RefA"), val(false)}, true, nil},
		{[]illogical.Evaluable{ref("Missing"), val(false)}, nil, ref("Missing")},
		{[]illogical.Evaluable{ref("Missing"), ref("Missing")}, nil, or([]illogical.Evaluable{ref("Missing"), ref("Missing")})},
	}

	for &test in tests {
        e := or(test.input)
		value, self := illogical.simplify(&e, &ctx)

		testing.expectf(t, matches_evaluated(value, test.value), "input (%v): expected %v, got %v", test.input, test.value, value)
		testing.expectf(t, fprint(self) == fprint(test.e), "input (%v): expected %v, got %v", test.input, test.e, self)

        illogical.destroy_evaluable(&e)
        illogical.destroy_evaluable(&self)
        illogical.destroy_evaluable(&test.e)
	}
}