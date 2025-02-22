#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"
import "core:log"

import illogical "../src"

@test
test_parse_value :: proc(t: ^testing.T) {
	parser := illogical.new_parser()
	defer illogical.destroy_parser(&parser)
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Evaluable
	}{
		{1, val(1)},
		{1.1, val(1.1)},
		{"val", val("val")},
		{true, val(true)},
	}

	for test in tests {
		output, err := illogical.parse(&parser, test.input)

		testing.expectf(t, fprint(output) == fprint(test.expected), "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected %v, got %v", test.input, nil, err)
	}
}

@test
test_parse_reference :: proc(t: ^testing.T) {
	parser := illogical.new_parser()
	defer illogical.destroy_parser(&parser)
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Evaluable
	}{
		{addr("path", &parser.serialize_options_reference), ref("path")},
	}

	for test in tests {
		output, err := illogical.parse(&parser, test.input)

		testing.expectf(t, fprint(output) == fprint(test.expected), "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected %v, got %v", test.input, nil, err)
	}
}

@test
test_parse_collection :: proc(t: ^testing.T) {
    operator_map := illogical.create_default_operator_map()
	parser := illogical.new_parser(&operator_map)
	defer illogical.destroy_parser(&parser)
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Evaluable
	}{
		{illogical.Array{1}, col(val(1))},
		{illogical.Array{"val"}, col(val("val"))},
		{illogical.Array{"val1", "val2"}, col(val("val1"), val("val2"))},
		{illogical.Array{true}, col(val(true))},
		{illogical.Array{addr("ref", &parser.serialize_options_reference)}, col(ref("ref"))},
		{illogical.Array{1, "val", true, addr("ref", &parser.serialize_options_reference)}, col(val(1), val("val"), val(true), ref("ref"))},
		// escaped
		{illogical.Array{fmt.tprintf("%s%s", parser.serialize_options_collection.escape_character, operator_map[.Eq]), 1}, col(val(operator_map[.Eq]), val(1))},
	}

	for &test in tests {
		output, err := illogical.parse(&parser, test.input)

		testing.expectf(t, fprint(output) == fprint(test.expected), "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected %v, got %v", test.input, nil, err)

        illogical.destroy_evaluable(&output)
        illogical.destroy_evaluable(&test.expected)
	}
}

@test
test_parse_comparison :: proc(t: ^testing.T) {
    operator_map := illogical.create_default_operator_map()
	parser := illogical.new_parser(&operator_map)
	defer illogical.destroy_parser(&parser)

	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Evaluable
	}{
		{illogical.Array{operator_map[.Eq], 1, 1}, illogical.new_eq(operator_map[.Eq], val(1), val(1))},
		{illogical.Array{operator_map[.Ne], 1, 1}, illogical.new_ne(operator_map[.Ne], val(1), val(1))},
		{illogical.Array{operator_map[.Gt], 1, 1}, illogical.new_gt(operator_map[.Gt], val(1), val(1))},
		{illogical.Array{operator_map[.Ge], 1, 1}, illogical.new_ge(operator_map[.Ge], val(1), val(1))},
		{illogical.Array{operator_map[.Lt], 1, 1}, illogical.new_lt(operator_map[.Lt], val(1), val(1))},
		{illogical.Array{operator_map[.Le], 1, 1}, illogical.new_le(operator_map[.Le], val(1), val(1))},
		{illogical.Array{operator_map[.In], illogical.Array{1}, 1}, illogical.new_in(operator_map[.In], col(val(1)), val(1))},
		{illogical.Array{operator_map[.Not_In], illogical.Array{1}, 1}, illogical.new_not_in(operator_map[.Not_In], col(val(1)), val(1))},
		{illogical.Array{operator_map[.None], 1}, illogical.new_nil(operator_map[.None], val(1))},
		{illogical.Array{operator_map[.Present], 1}, illogical.new_present(operator_map[.Present], val(1))},
		{illogical.Array{operator_map[.Suffix], "suffix", "ix"}, illogical.new_suffix(operator_map[.Suffix], val("suffix"), val("ix"))},
		{illogical.Array{operator_map[.Prefix], "bo", "bogus"}, illogical.new_prefix(operator_map[.Prefix], val("bo"), val("bogus"))},
	}

	for &test, i in tests {
		output, err := illogical.parse(&parser, test.input)

		testing.expectf(t, fprint(output) == fprint(test.expected), "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected %v, got %v", test.input, nil, err)

        illogical.destroy_evaluable(&output)
        illogical.destroy_evaluable(&test.expected)
	}
}

@test
test_parse_logical :: proc(t: ^testing.T) {
	operator_map := illogical.create_default_operator_map()
	parser := illogical.new_parser(&operator_map)
	defer illogical.destroy_parser(&parser)

	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Evaluable
	}{
		{illogical.Array{operator_map[.And], true, true}, and(val(true), val(true), operator=operator_map[.And])},
		{illogical.Array{operator_map[.Or], true, true}, or(val(true), val(true), operator=operator_map[.Or])},
		{illogical.Array{operator_map[.Nor], true, true}, nor(val(true), val(true), operator=operator_map[.Nor])},
		{illogical.Array{operator_map[.Xor], true, true}, xor(val(true), val(true), operator=operator_map[.Xor])},
		{illogical.Array{operator_map[.Not], true}, not(val(true), operator=operator_map[.Not])},
	}

	for &test in tests {
		output, err := illogical.parse(&parser, test.input)

		testing.expectf(t, fprint(output) == fprint(test.expected), "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected %v, got %v", test.input, nil, err)

        illogical.destroy_evaluable(&output)
        illogical.destroy_evaluable(&test.expected)
	}
}

@test
test_parse_invalid :: proc(t: ^testing.T) {
	opts := illogical.create_default_operator_map()
	parser := illogical.new_parser(&opts)
	defer illogical.destroy_parser(&parser)

	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Error
	}{
		{nil, .Unexpected_Input},
		{illogical.Array{}, .Invalid_Undefined_Operand},
	}

	for &test in tests {
		output, err := illogical.parse(&parser, test.input)

		testing.expectf(t, output == nil, "input (%v): expected %v, got %v", test.input, nil, output)
		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}

@test
test_is_escaped :: proc(t: ^testing.T) {
	tests := []struct {
		input:           string,
		escape_character: string,
		expected:        bool,
	}{
		{"\\expected", "\\", true},
		{"unexpected", "\\", false},
		{"\\expected", "", false},
	}

	for test in tests {
		output := illogical.is_escaped(test.input, test.escape_character)

		testing.expectf(t, output == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, output)
	}
}

@test
test_to_reference_addr :: proc(t: ^testing.T) {
	opts := illogical.Serialize_Options_Reference{
        from = proc(val: string) -> (string, illogical.Error) {
            if val == "expected" {
                return val, nil
            }
            return "", .Unexpected_Input
        },
        to = proc(val: string) -> string {
            return ""
        },
	}

	tests := []struct {
		input:    illogical.Primitive,
		expected: string
	}{
		{"expected", "expected"},
	}

	for test in tests {
		output, err := illogical.to_reference_addr(test.input, &opts)

		testing.expectf(t, output == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected %v, got %v", test.input, nil, err)
	}

	errs := []struct {
		input:    illogical.Primitive,
		expected: illogical.Error
	}{
		{"unexpected", .Unexpected_Input},
		{1, .Invalid_Data_Type},
	}

	for test in errs {
		output, err := illogical.to_reference_addr(test.input, &opts)

		testing.expectf(t, output == "", "input (%v): expected %v, got %v", test.input, "", output)
		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}