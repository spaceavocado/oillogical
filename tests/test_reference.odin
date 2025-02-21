#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:text/regex"
import "core:fmt"

import illogical "../src"

@test
test_reference_new :: proc(t: ^testing.T) {
	errs := []struct {
		input:    string,
		expected: illogical.Error
	}{
		{"ref.(Invalid)", .Invalid_Data_Type},
	}

	for test in errs {
		_, err := illogical.new_reference(test.input)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}

@test
test_reference_default_serialization_options :: proc(t: ^testing.T) {
	e, _ := illogical.new_reference("ref")
    reference := e.(illogical.Reference)

	tests := []struct {
		input:    string,
		expected: string
	}{
		{"$ref", "ref"},
	}

	for test in tests {
		output, err := reference.serialize_options.from(test.input)

		testing.expectf(t, output == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}

	errs := []struct {
		input:    string,
		expected: illogical.Error
	}{
		{"", .Invalid_Operand},
		{"$", .Invalid_Operand},
		{"r$ef", .Invalid_Operand},
	}

	for test in errs {
		_, err := reference.serialize_options.from(test.input)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}

	tests = []struct {
		input:    string,
		expected: string
	}{
		{"ref", "$ref"},
	}

	for test in tests {
		output := reference.serialize_options.to(test.input)

		testing.expectf(t, output == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, output)
	}
}

@test
test_reference_evaluate :: proc(t: ^testing.T) {
	ctx := illogical.FlattenContext{
        "refA" = 1,
		"refB.refB1" = 2,
		"refB.refB2" = "refB1",
		"refB.refB3" = true,
		"refC" = "refB1",
		"refD" = "refB2",
		"refE[0]" = 1,
		"refE[1][0]" = 2,
		"refE[1][1]" = 3,
		"refE[1][2]" = 4,
		"refF" = nil,
		"refG" = "1",
		"refH" = "1.1",
    }
    defer delete(ctx)

	tests := []struct {
		path:      string,
		data_type: illogical.Data_Type,
		expected:  illogical.Primitive,
	}{
		{"refA", .Integer, 1},
		{"refA", .String, "1"},
		{"refG", .Number, 1},
		{"refH", .Float, 1.1},
		{"refB.refB3", .String, "true"},
		{"refB.refB3", .Boolean, true},
		{"refB.refB3", .Number, 1},
		{"refJ", .Undefined, nil},
	}

	for test in tests {
		_, _, value, err := illogical._evaluate_reference(&ctx, test.path, test.data_type)

        testing.expectf(t, matches_primitive(value, test.expected), "input (%v, %v): expected %v, got %v", test.path, test.data_type, test.expected, value)
        testing.expectf(t, err == nil, "input (%v, %v): expected no error, got %v", test.path, test.data_type, err)
	}

	tests2 := []struct {
		addr:   string,
		expected: illogical.Primitive,
	}{
		{"refA", 1},
	}
	for test in tests2 {
		reference, _ := illogical.new_reference(test.addr)
		evaluated, err := illogical.evaluate(&reference, &ctx)

		testing.expectf(t, matches_primitive(evaluated, test.expected), "input (%v): expected %v, got %v", test.addr, test.expected, evaluated)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.addr, err)
	}
}

@test
test_reference_simplify :: proc(t: ^testing.T) {
    rx, _ := regex.create_by_user("/^refC/")
	simplify_options := illogical.Simplify_Options_Reference{
		ignored_paths = [dynamic]string{"ignored"},
		ignored_paths_rx = [dynamic]regex.Regular_Expression{rx},
	}

    defer delete(simplify_options.ignored_paths)
    defer delete(simplify_options.ignored_paths_rx)
    defer regex.destroy_regex(rx)

    ctx := illogical.FlattenContext{
        "refA" = 1,
		"refB.refB1" = 2,
		"refB.refB2" = "refB1",
		"refB.refB3" = true,
		"refC" = "refB1",
		"refD" = "refB2",
		"refE[0]" = 1,
		"refE[1][0]" = 2,
		"refE[1][1]" = 3,
		"refE[1][2]" = 4,
		"refF" = nil,
		"refG" = "1",
		"refH" = "1.1",
    }
    defer delete(ctx)

	tests := []struct {
		input: string,
		expected: illogical.Primitive,
		e:     illogical.Evaluable,
	}{
		{"refA", 1, nil},
		{"ignored", nil, ref("ignored")},
		{"refC.refB1", nil, ref("refC.refB1")},
		{"ref", nil, ref("ref")},
	}

	for test in tests {
		e, _ := illogical.new_reference(test.input, nil, &simplify_options)
        value, self := illogical.simplify(&e, ctx)

        testing.expectf(t, matches_evaluated(value, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)
        testing.expectf(t, fprint(self) == fprint(test.e), "input (%v): expected %v, got %v", test.input, test.e, self)
	}
}

@test
test_reference_serialize :: proc(t: ^testing.T) {
	tests := []struct {
		input: string,
		expected: illogical.Primitive
	}{
		{"refA", "$refA"},
		{"refA.(Number)", "$refA.(Number)"},
	}

    for test in tests {
		reference, _ := illogical.new_reference(test.input)
        serialized := illogical.serialize(&reference)

        testing.expectf(t, matches_primitive(serialized, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, serialized)
	}
}

@test
test_reference_to_string :: proc(t: ^testing.T) {
	tests := []struct {
		input: string,
		expected: string
	}{
		{"refA", "{refA}"},
		{"refA.(Number)", "{refA.(Number)}"},
	}

	for test in tests {
		reference, _ := illogical.new_reference(test.input)
        value := illogical.to_string(&reference)

        testing.expectf(t, value == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, value)
	}
}

@test
test_reference_data_type_to_number :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive
	}{
		{1, 1},
		{1.1, 1.1},
		{-1.1, -1.1},
		{"1", 1},
		{"-1", -1},
		{"1.1", 1.1},
		{"1.9", 1.9},
		{"-1.9", -1.9},
		{true, 1},
		{false, 0},
	}

	for test in tests {
        value, err := illogical._to_number(test.input)

		testing.expectf(t, matches_primitive(value, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}

    errors := []struct {
		input:    illogical.Primitive,
		expected: illogical.Error,
	}{
		{"1,1", .Invalid_Data_Type_Conversion},
        {nil, .Invalid_Data_Type_Conversion},
	}

	for test in errors {
        _, err := illogical._to_number(test.input)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}

@test
test_reference_data_type_to_integer :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive
	}{
		{1, 1},
		{1.1, 1},
		{-1.1, -1},
		{"1", 1},
		{"-1", -1},
		{"1.1", 1},
		{"1.9", 1},
		{"-1.9", -1},
		{true, 1},
		{false, 0},
	}

	for test in tests {
        value, err := illogical._to_integer(test.input)

		testing.expectf(t, matches_primitive(value, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}

    errors := []struct {
		input:    illogical.Primitive,
		expected: illogical.Error,
	}{
		{"1,1", .Invalid_Data_Type_Conversion},
        {nil, .Invalid_Data_Type_Conversion},
	}

	for test in errors {
        _, err := illogical._to_integer(test.input)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}

@test
test_reference_data_type_to_float :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive
	}{
		{1, 1.0},
		{1.1, 1.1},
		{"1", 1.0},
		{"-1", -1.0},
		{"1.1", 1.1},
		{"1.9", 1.9},
		{"-1.9", -1.9},
	}

	for test in tests {
        value, err := illogical._to_float(test.input)

		testing.expectf(t, matches_primitive(value, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}

    errors := []struct {
		input:    illogical.Primitive,
		expected: illogical.Error,
	}{
		{"1,1", .Invalid_Data_Type_Conversion},
		{true, .Invalid_Data_Type_Conversion},
        {nil, .Invalid_Data_Type_Conversion},
	}

	for test in errors {
        _, err := illogical._to_float(test.input)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}

@test
test_reference_data_type_to_boolean :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive
	}{
		{true, true},
		{false, false},
		{"true", true},
		{"false", false},
		{" True ", true},
		{" False ", false},
		{"1", true},
		{"0", false},
		{1, true},
		{0, false},
	}

	for test in tests {
        value, err := illogical._to_boolean(test.input)

		testing.expectf(t, matches_primitive(value, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}

    errors := []struct {
		input:    illogical.Primitive,
		expected: illogical.Error,
	}{
		{"yes", .Invalid_Data_Type_Conversion},
		{"bogus", .Invalid_Data_Type_Conversion},
		{2, .Invalid_Data_Type_Conversion},
		{1.1, .Invalid_Data_Type_Conversion},
        {nil, .Invalid_Data_Type_Conversion},
	}

	for test in errors {
        _, err := illogical._to_boolean(test.input)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)
	}
}

@test
test_reference_data_type_to_string :: proc(t: ^testing.T) {
	tests := []struct {
		input:    illogical.Primitive,
		expected: illogical.Primitive
	}{
		{1, "1"},
		{1.1, "1.100"},
		{-1.1, "-1.100"},
		{"1", "1"},
		{true, "true"},
		{false, "false"},
	}

	for test in tests {
        value, err := illogical._to_string(test.input)

		testing.expectf(t, matches_primitive(value, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.input, err)
	}
}

@test
test_reference_context_lookup :: proc(t: ^testing.T) {
	ctx := illogical.FlattenContext{
        "refA" = 1,
		"refB.refB1" = 2,
		"refB.refB2" = "refB1",
		"refB.refB3" = true,
		"refC" = "refB1",
		"refD" = "refB2",
		"refE[0]" = 1,
		"refE[1][0]" = 2,
		"refE[1][1]" = 3,
		"refE[1][2]" = 4,
		"refF" = "A",
		"refG" = "1",
		"refH" = "1.1",
    }
    defer delete(ctx)

	tests := []struct {
		input: string,
		found: bool,
		path:  string,
		value: illogical.Primitive,
	}{
		{"UNDEFINED", false, "UNDEFINED", nil},
		{"refA", true, "refA", 1},
		{"refB.refB1", true, "refB.refB1", 2},
		{"refB.{refC}", true, "refB.refB1", 2},
		{"refB.{UNDEFINED}", false, "refB.{UNDEFINED}", nil},
		{"refB.{refB.refB2}", true, "refB.refB1", 2},
		{"refB.{refB.{refD}}", true, "refB.refB1", 2},
		{"refE[0]", true, "refE[0]", 1},
		{"refE[2]", false, "refE[2]", nil},
		{"refE[1][0]", true, "refE[1][0]", 2},
		{"refE[1][3]", false, "refE[1][3]", nil},
		{"refE[{refA}][0]", true, "refE[1][0]", 2},
		{"refE[{refA}][{refB.refB1}]", true, "refE[1][2]", 4},
		{"ref{refF}", true, "refA", 1},
		{"ref{UNDEFINED}", false, "ref{UNDEFINED}", nil},
	}

	for test in tests {
		found, path, value := illogical._context_lookup(test.input, &ctx)

		testing.expectf(t, found == test.found, "input (%v): expected %v, got %v", test.input, test.found, found)
		testing.expectf(t, path == test.path, "input (%v): expected %v, got %v", test.input, test.path, path)
		testing.expectf(t, matches_primitive(value, test.value), "input (%v): expected %v, got %v", test.input, test.value, value)
	}
}

@test
test_reference_get_data_type :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: illogical.Data_Type
	}{
		{"ref", .Undefined},
		{"ref.(X)", .Undefined},
		{"ref.(Bogus)", .Unsupported},
		{"ref.(String)", .String},
		{"ref.(Number)", .Number},
		{"ref.(Integer)", .Integer},
		{"ref.(Float)", .Float},
		{"ref.(Boolean)", .Boolean},
	}

	for test in tests {
		output, _ := illogical._get_data_type(test.input)

		testing.expectf(t, output == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, output)
	}

	input := "ref.(Struct)"
    expected := illogical.Error.Invalid_Data_Type
	output, err := illogical._get_data_type(input)

	testing.expectf(t, err == expected, "input (%v): expected %v, got %v", input, expected, output)
}

@test
test_reference_trim_data_type :: proc(t: ^testing.T) {
	tests := []struct {
		input:    string,
		expected: string
	}{
		{"ref", "ref"},
		{"ref.(X)", "ref.(X)"},
		{"ref.(String)", "ref"},
	}

	for test in tests {
        output := illogical._trim_data_type(test.input)

		testing.expectf(t, output == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, output)
	}
}

@test
test_reference_is_ignored_path :: proc(t: ^testing.T) {
	rx, _ := regex.create_by_user("/^refC/")
	simplify_options := illogical.Simplify_Options_Reference{
		ignored_paths = [dynamic]string{"ignored"},
		ignored_paths_rx = [dynamic]regex.Regular_Expression{rx},
	}

    defer delete(simplify_options.ignored_paths)
    defer delete(simplify_options.ignored_paths_rx)
    defer regex.destroy_regex(rx)

	tests := []struct {
		input:    string,
		expected: bool,
	}{
		{"ignored", true},
		{"not", false},
		{"refC", true},
		{"refC.(Number)", true},
	}

	for test in tests {
        result := illogical._is_ignored_path(test.input, &simplify_options)
		
        testing.expectf(t, result == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, result)
    }
}
