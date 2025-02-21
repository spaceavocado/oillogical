#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_comparison_evaluate :: proc(t: ^testing.T) {
    ctx := illogical.FlattenContext{
        "RefA" = 10,
    }
    defer delete(ctx)

	tests := []struct {
		kind:     string,
		operands: []illogical.Evaluable,
		expected: illogical.Primitive
	}{
		{"==", []illogical.Evaluable{val(1), val(1)}, true},
		{"==", []illogical.Evaluable{val(1), val(2)}, false},
	}

	for test in tests {
		c := illogical.new_comparison(test.kind, test.kind, illogical.handler_eq, ..test.operands)

		output, err := illogical.evaluate(&c, &ctx)

		testing.expectf(t, matches_primitive(output, test.expected), "input (%v, %v): expected %v, got %v/%v", test.kind, test.operands, test.expected, output, err)
		testing.expectf(t, err == nil, "input (%v, %v): expected no error, got %v", test.kind, test.operands, err)

        illogical.destroy_evaluable(&c)
	}

	errs := []struct {
		kind:     string,
		operands: []illogical.Evaluable,
		expected: illogical.Error,
	}{
		{"==", []illogical.Evaluable{val(1), ref("RefA.(Boolean)")}, .Invalid_Data_Type_Conversion},
	}

	for test in errs {
		c := illogical.new_comparison(test.kind, test.kind, illogical.handler_eq, ..test.operands)
		_, err := illogical.evaluate(&c, &ctx)

		testing.expectf(t, err == test.expected, "input (%v, %v): expected %v, got %v", test.kind, test.operands, test.expected, err)

        illogical.destroy_evaluable(&c)
	}
}

@test
test_comparison_simplify :: proc(t: ^testing.T) {
	ctx := illogical.FlattenContext{
		"RefA" = "A",
	}
	defer delete(ctx)

	eq :: proc(operands: ..illogical.Evaluable) -> illogical.Evaluable {
		return illogical.new_comparison("==", "==", illogical.handler_eq, ..operands)
	}

	tests := []struct {
		input: []illogical.Evaluable,
		value: illogical.Primitive,
		e:     illogical.Evaluable,
	}{
		{[]illogical.Evaluable{val(0), ref("Missing")}, nil, eq(val(0), ref("Missing"))},
		{[]illogical.Evaluable{ref("Missing"), val(0)}, nil, eq(ref("Missing"), val(0))},
		{[]illogical.Evaluable{ref("Missing"), ref("Missing")}, nil, eq(ref("Missing"), ref("Missing"))},
		{[]illogical.Evaluable{val(0), val(0)}, true, nil},
		{[]illogical.Evaluable{val(0), val(1)}, false, nil},
		{[]illogical.Evaluable{val("A"), ref("RefA")}, true, nil},
	}

	for &test in tests {
		e := illogical.new_comparison("Unknown", "==", illogical.handler_eq, ..test.input)
		value, self := illogical.simplify(&e, &ctx)

		testing.expectf(t, matches_evaluated(value, test.value), "input (%v): expected %v (%v), got %v (%v)", test.input, typeid_of(type_of(test.value)), test.value == nil, typeid_of(type_of(value)))
        testing.expectf(t, fprint(self) == fprint(test.e), "input (%v): expected %v, got %v", test.input, test.e, self)

        illogical.destroy_evaluable(&e)
        illogical.destroy_evaluable(&test.e)
	}
}

@test
test_comparison_serialize :: proc(t: ^testing.T) {
	tests := []struct {
		kind:       string,
		operands: []illogical.Evaluable,
		expected: illogical.Array,
	}{
		{"->", []illogical.Evaluable{val(1), val(2)}, [dynamic]illogical.Primitive{"->", 1, 2}},
		{"X", []illogical.Evaluable{val(1)}, [dynamic]illogical.Primitive{"X", 1}},
	}

	for test in tests {
		c := illogical.new_comparison(test.kind, test.kind, illogical.handler_eq, ..test.operands)
		output := illogical.serialize(&c)

		testing.expectf(t, matches_evaluated(output.(illogical.Array), test.expected), "input (%v, %v): expected %v, got %v", test.kind, test.operands, test.expected, output)

        illogical.destroy_evaluable(&c)
        delete(output.(illogical.Array))
        delete(test.expected)
	}
}

@test
test_comparison_string :: proc(t: ^testing.T) {
	tests := []struct {
		kind:       string,
		operands: []illogical.Evaluable,
		expected: string,
	}{
		{"==", []illogical.Evaluable{val(1), val(2)}, "(1 == 2)"},
		{"<nil>", []illogical.Evaluable{val(1)}, "(1 <nil>)"},
	}

	for test in tests {
		c := illogical.new_comparison(test.kind, test.kind, illogical.handler_eq, ..test.operands)
		output := illogical.to_string(&c)

		testing.expectf(t, output == test.expected, "input (%v, %v): expected %v, got %v", test.kind, test.operands, test.expected, output)

        illogical.destroy_evaluable(&c)
	}
}

@test
test_comparison_compare_primitives :: proc(t: ^testing.T) {
	compare_int := proc(a: int, b: int) -> illogical.Evaluated { return a == b }
    compare_float := proc(a: f64, b: f64) -> illogical.Evaluated { return a == b }
    compare_string := proc(a: string, b: string) -> illogical.Evaluated { return a == b }
    compare_bool := proc(a: bool, b: bool) -> illogical.Evaluated { return a == b }

	tests := []struct {
		a: illogical.Evaluated,
		b: illogical.Evaluated,
		expected: illogical.Evaluated,
	}{
		// Truthy
		{illogical.new_primitive(1), illogical.new_primitive(1), illogical.new_primitive(true)},
		{illogical.new_primitive(1.0), illogical.new_primitive(1.0), illogical.new_primitive(true)},
		{illogical.new_primitive(1.0), illogical.new_primitive(1), illogical.new_primitive(true)},
		{illogical.new_primitive(1), illogical.new_primitive(1.0), illogical.new_primitive(true)},
		{illogical.new_primitive(true), illogical.new_primitive(true), illogical.new_primitive(true)},
		{illogical.new_primitive(false), illogical.new_primitive(false), illogical.new_primitive(true)},
		{illogical.new_primitive("value"), illogical.new_primitive("value"), illogical.new_primitive(true)},		

		// Falsy
		{illogical.new_primitive(1), illogical.new_primitive(2), illogical.new_primitive(false)},
		{illogical.new_primitive(1.0), illogical.new_primitive(2.0), illogical.new_primitive(false)},
		{illogical.new_primitive(1.0), illogical.new_primitive(2), illogical.new_primitive(false)},
		{illogical.new_primitive(1), illogical.new_primitive(2.0), illogical.new_primitive(false)},
		{illogical.new_primitive(true), illogical.new_primitive(false), illogical.new_primitive(false)},
	}

	for test in tests {
		ok := illogical.compare_primitives(test.a, test.b, compare_int, compare_float, compare_string, compare_bool)

		testing.expectf(t, matches_evaluated(test.expected, ok), "input (%v, %v): expected %v, got %v", test.a, test.b, test.expected, ok)
	}
}

@test
test_comparison_as_equatable_primitive :: proc(t: ^testing.T) {
	tests := []struct {
		input: illogical.Primitive,
		ok: bool,
	}{
		{1, true},
		{1.0, true},
		{true, true},
		{false, true},
		{"Hello", true},
	}

	for test in tests {
		_, ok := illogical.as_equatable_primitive(test.input)
		testing.expectf(t, ok == test.ok, "input (%v): expected %v, got %v", test.input, test.ok, ok)
	}

    arr := [dynamic]illogical.Primitive{"A", 1}
    _, ok := illogical.as_equatable_primitive(arr)

    testing.expectf(t, !ok, "input (%v): expected %v, got %v", arr, false, ok)
    delete(arr)
}
