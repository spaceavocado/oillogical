#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_collection_new :: proc(t: ^testing.T) {
	_, err := illogical.new_collection()

    expected := illogical.Error.Invalid_Collection
	testing.expectf(t, err == expected, "expected %v, got %v", expected, err)
}

@test
test_collection_evaluate :: proc(t: ^testing.T) {
    ctx := illogical.Flatten_Context{
        "RefA" = "A",
    }
    defer delete(ctx)
	
	tests := []struct {
		input:    []illogical.Evaluable,
		expected: illogical.Array
	}{
		{[]illogical.Evaluable{val(1)}, illogical.Array{1}},
		{[]illogical.Evaluable{val("1")}, illogical.Array{"1"}},
		{[]illogical.Evaluable{val(true)}, illogical.Array{true}},
		{[]illogical.Evaluable{ref("RefA")}, illogical.Array{"A"}},
		{[]illogical.Evaluable{val(1), ref("RefA")}, illogical.Array{1, "A"}},
		{[]illogical.Evaluable{eq(val(1), val(1)), ref("RefA")}, illogical.Array{true, "A"}},
	}

	for test in tests {
		c, _ := illogical.new_collection(..test.input)
		output, err := illogical.evaluate(&c, &ctx)

		testing.expectf(t, matches_evaluated(output, test.expected), "input (%v): expected %v, got %v", test.input, test.expected, output)
		testing.expectf(t, err == .None, "input (%v): expected no error, got %v", test.input, err)

        illogical.destroy_evaluable(&c)
        delete(test.expected)
        delete(output.(illogical.Array))
	}

	errs := []struct {
		input:    []illogical.Evaluable,
		expected: illogical.Error
	}{
		{[]illogical.Evaluable{ref("RefA.(Float)")}, .Invalid_Data_Type_Conversion},
	}

	for test in errs {
		c, _ := illogical.new_collection(..test.input)
		_, err := illogical.evaluate(&c, &ctx)

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, err)

        illogical.destroy_evaluable(&c)
	}
}

@test
test_collection_simplify :: proc(t: ^testing.T) {
    ctx := illogical.Flatten_Context{
        "RefA" = "A",
    }
    defer delete(ctx)

	tests := []struct {
		input: []illogical.Evaluable,
		value: illogical.Evaluated,
		e:     illogical.Evaluable,
	}{
		{[]illogical.Evaluable{ref("RefB")}, nil, col(ref("RefB"))},
		{[]illogical.Evaluable{ref("RefA")}, illogical.Array{"A"}, nil},
		{[]illogical.Evaluable{ref("RefA"), ref("RefB")}, nil, col(ref("RefA"), ref("RefB"))},
	}

	for &test in tests {
		e := col(..test.input)
		value, self := illogical.simplify(&e, &ctx)

		testing.expectf(t, matches_evaluated(value, test.value), "input (%v): expected %v, got %v", test.input, test.value, value)
        testing.expectf(t, fprint(self) == fprint(test.e), "input (%v): expected %v, got %v", test.input, test.e, self)

        illogical.destroy_evaluable(&e)
        illogical.destroy_evaluable(&test.e)

		illogical.destroy_evaluated(value)
		illogical.destroy_evaluated(test.value)
	}
}

@test
test_collection_serialize :: proc(t: ^testing.T) {
	options := illogical.Serialize_Options_Collection{
		escaped_operators= map[string]bool{"=="= true},
		escape_character=  "\\",
	}
    defer delete(options.escaped_operators)

	tests := []struct {
		input:    []illogical.Evaluable,
		expected: illogical.Array,
	}{
		{[]illogical.Evaluable{val(1)}, illogical.Array{1}},
		{[]illogical.Evaluable{val("1")}, illogical.Array{"1"}},
		{[]illogical.Evaluable{val(true)}, illogical.Array{true}},
		{[]illogical.Evaluable{ref("RefA")}, illogical.Array{"$RefA"}},
		{[]illogical.Evaluable{val(1), ref("RefA")}, illogical.Array{1, "$RefA"}},
		{[]illogical.Evaluable{eq(val(1), val(1)), ref("RefA")}, illogical.Array{illogical.Array{"==", 1, 1}, "$RefA"}},
		{[]illogical.Evaluable{val("=="), val(1), val(1)}, illogical.Array{"\\==", 1, 1}},
	}

	for test in tests {
		e, _ := illogical.new_collection(..test.input, options=&options)
		value := illogical.serialize(&e)

		testing.expectf(t, matches_evaluated(value.(illogical.Array), test.expected), "input (%v): expected %v, got %v", test.input, test.expected, value)

        illogical.destroy_evaluable(&e)
		illogical.destroy_primitive(value)
		illogical.destroy_primitive(test.expected)
	}
}

@test
test_collection_to_string :: proc(t: ^testing.T) {
	tests := []struct {
		input:    []illogical.Evaluable,
		expected: string
	}{
		{[]illogical.Evaluable{val(1)}, "[1]"},
		{[]illogical.Evaluable{val("1")}, "[\"1\"]"},
		{[]illogical.Evaluable{val(true)}, "[true]"},
		{[]illogical.Evaluable{ref("RefA")}, "[{RefA}]"},
		{[]illogical.Evaluable{val(1), ref("RefA")}, "[1, {RefA}]"},
		{[]illogical.Evaluable{eq(val(1), val(1)), ref("RefA")}, "[(1 == 1), {RefA}]"},
	}

	for test in tests {
		e, _ := illogical.new_collection(..test.input)
        result := illogical.to_string(&e)
        
		testing.expectf(t, result == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, result)

        illogical.destroy_evaluable(&e)
	}
}

@test
test_collection_should_be_escaped :: proc(t: ^testing.T) {
	options := illogical.Serialize_Options_Collection{
		escaped_operators= map[string]bool{"=="= true},
		escape_character=  "\\",
	}
    defer delete(options.escaped_operators)

	tests := []struct {
		input:    illogical.Primitive,
		expected: bool,
	}{
		{"==", true},
		{"!=", false},
		{nil, false},
		{true, false},
        {1, false},
        {1.1, false},
	}

	for test in tests {
		result := illogical.should_be_escaped(test.input, &options)

		testing.expectf(t, result == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, result)
	}
}

@test
test_collection_escape_operator :: proc(t: ^testing.T) {
	options := illogical.Serialize_Options_Collection{
		escaped_operators= map[string]bool{"=="= true},
		escape_character=  "*",
	}
    defer delete(options.escaped_operators)

	tests := []struct {
		input:    string,
		expected: string,
	}{
		{"==", "*=="},
	}

	for test in tests {
		result := illogical.escape_operator(test.input, &options)

		testing.expectf(t, result == test.expected, "input (%v): expected %v, got %v", test.input, test.expected, result)
	}
}