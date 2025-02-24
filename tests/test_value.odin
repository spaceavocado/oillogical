package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_value_evaluate :: proc(t: ^testing.T) {
    ctx := illogical.Flatten_Context{}
    defer delete(ctx)

	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive,
	}{
		{1, 1},
		{1.1, 1.1},
		{"val", "val"},
		{true, true},
		{false, false},
        {nil, nil},
	}

	for test in tests {
		value := illogical.new_value(test.input)
		evaluated, err := illogical.evaluate(&value, &ctx)

		testing.expectf(t, matches_primitive(evaluated, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, evaluated)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}
}

@test
test_value_simplify :: proc(t: ^testing.T) {
    ctx := illogical.Flatten_Context{}
    defer delete(ctx)

	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive,
	}{
		{1, 1},
		{1.1, 1.1},
		{"val", "val"},
		{true, true},
		{false, false},
	}

	for test in tests {
		value := illogical.new_value(test.input)
		evaluated, evaluable := illogical.simplify(&value, &ctx)

		testing.expectf(t, matches_primitive(evaluated, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, evaluated)
		testing.expectf(t, evaluable == nil, "input (%v): expected no error, got %v", test.input, evaluable)
	}
}

@test
test_value_serialize :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive,
	}{
		{1, 1},
		{1.1, 1.1},
		{"val", "val"},
		{true, true},
		{false, false},
	}

	for test in tests {
		value := illogical.new_value(test.input)
		evaluated := illogical.serialize(&value)

		testing.expectf(t, matches_primitive(evaluated, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, evaluated)
	}
}

@test
test_value_to_string :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: string
	}{
		{1, "1"},
		{1.1, "1.1"},
		{"val", "\"val\""},
		{true, "true"},
		{false, "false"},
	}

	for test in tests {
		value := illogical.new_value(test.input)
		evaluated := illogical.to_string(&value)

		testing.expectf(t, evaluated == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, evaluated)
	}
}