#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_logical_evaluate :: proc(t: ^testing.T) {
    ctx := illogical.FlattenContext{
        "RefA" = 10,
    }
    defer delete(ctx)

	tests := []struct {
		operator:     string,
		operands: []illogical.Evaluable,
		expected: illogical.Primitive
	}{
		{"Unknown", []illogical.Evaluable{val(true), val(true)}, true},
		{"Unknown", []illogical.Evaluable{val(false), val(false)}, false},
	}

    handler := proc(ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Error) {
		return illogical.evaluate(&operands[0], ctx)
	}
	simplify_handler: illogical.simplify_handler_base = proc(operator: string, ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Evaluable) {
        return nil, nil
    }

	for test in tests {
		l := illogical.new_logical("Unknown", test.operator, "N/A", "N/A", handler, simplify_handler, ..test.operands)

		output, err := illogical.evaluate(&l, &ctx)

		testing.expectf(t, matches_primitive(output, test.expected), "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, output)
		testing.expectf(t, err == nil, "input (%v, %v): expected no error, got %v", test.operator, test.operands, err)

        illogical.destroy_evaluable(&l)
	}

	errs := []struct {
		operator:     string,
		operands: []illogical.Evaluable,
		expected: illogical.Error,
	}{
		{"Unknown", []illogical.Evaluable{ref("RefA.(Boolean)"), val(true)}, .Invalid_Data_Type_Conversion},
	}

	for test in errs {
		l := illogical.new_logical("Unknown", test.operator, "N/A", "N/A", handler, simplify_handler, ..test.operands)
		_, err := illogical.evaluate(&l, &ctx)

		testing.expectf(t, err == test.expected, "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, err)

        illogical.destroy_evaluable(&l)
	}
}

@test
test_logical_simplify :: proc(t: ^testing.T) {
    ctx := illogical.FlattenContext{}
    defer delete(ctx)

	tests := []struct {
		operator: string,
		operands: []illogical.Evaluable,
		expected: illogical.Primitive,
	}{
		{"Unknown", []illogical.Evaluable{val(true), val(true)}, true},
	}

	handler := proc(ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Error) {
		return true, nil
	}
	simplify_handler: illogical.simplify_handler_base = proc(operator: string, ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Evaluable) {
        return true, nil
    }

	for test in tests {
		l := illogical.new_logical("Unknown", test.operator, "N/A", "N/A", handler, simplify_handler, ..test.operands)
		evaluated, self := illogical.simplify(&l, &ctx)

		testing.expectf(t, matches_primitive(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, evaluated)
		testing.expectf(t, self == nil, "input (%v, %v): expected no self, got %v", test.operator, test.operands, self)

        illogical.destroy_evaluable(&l)
	}
}

@test
test_logical_serialize :: proc(t: ^testing.T) {
	tests := []struct {
		operator: string,
		operands: []illogical.Evaluable,
		expected: illogical.Array,
	}{
		{"->", []illogical.Evaluable{val("e1"), val("e2")}, illogical.Array{"->", "e1", "e2"}},
		{"X", []illogical.Evaluable{val("e1")}, illogical.Array{"X", "e1"}},
	}

    handler := proc(ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Error) {
		return true, nil
	}
	simplify_handler: illogical.simplify_handler_base = proc(operator: string, ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Evaluable) {
        return true, nil
    }

	for test in tests {
		l := illogical.new_logical(test.operator, "Unknown", "N/A", "N/A", handler, simplify_handler, ..test.operands)
		output := illogical.serialize(&l)

		testing.expectf(t, fprint(output) == fprint(test.expected), "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, output)

        illogical.destroy_evaluable(&l)

        delete(test.expected)
        delete(output.(illogical.Array))
	}
}

@test
test_logical_to_string :: proc(t: ^testing.T) {
	tests := []struct {
		operator: string,
		operands: []illogical.Evaluable,
		expected: string,
	}{
		{"AND", []illogical.Evaluable{val("e1"), val("e2")}, "(\"e1\" AND \"e2\")"},
		{"AND", []illogical.Evaluable{val("e1"), val("e2"), val("e1")}, "(\"e1\" AND \"e2\" AND \"e1\")"},
	}

    handler := proc(ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Error) {
		return true, nil
	}
	simplify_handler: illogical.simplify_handler_base = proc(operator: string, ctx: ^illogical.FlattenContext, operands: []illogical.Evaluable) -> (illogical.Evaluated, illogical.Evaluable) {
        return true, nil
    }

	for test in tests {
		l := illogical.new_logical("Unknown", test.operator, "N/A", "N/A", handler, simplify_handler, ..test.operands)
		output := illogical.to_string(&l)

		testing.expectf(t, output == test.expected, "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, output)

        illogical.destroy_evaluable(&l)
	}
}

@test
test_logical_evaluate_operand :: proc(t: ^testing.T) {
    ctx := illogical.FlattenContext{
        "RefA" = 10,
    }
    defer delete(ctx)

	tests := []struct {
		operator: string,
		operands: []illogical.Evaluable,
		expected: bool,
	}{
		{"Unknown", []illogical.Evaluable{val(true)}, true},
	}

	for test in tests {
        res, err := illogical.evaluate_logical_operand(&test.operands[0], &ctx)

        testing.expectf(t, res == test.expected, "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, res)
        testing.expectf(t, err == nil, "input (%v, %v): expected no error, got %v", test.operator, test.operands, err)
	}

    errs := []struct {
		operator: string,
		operands: []illogical.Evaluable,
		expected: illogical.Error,
	}{
		{"Unknown", []illogical.Evaluable{ref("RefA.(Boolean)")}, .Invalid_Data_Type_Conversion},
        {"Unknown", []illogical.Evaluable{val(1)}, .Invalid_Evaluated_Logical_Operand},
	}

	for test in errs {
        _, err := illogical.evaluate_logical_operand(&test.operands[0], &ctx)

        testing.expectf(t, err == test.expected, "input (%v, %v): expected %v, got %v", test.operator, test.operands, test.expected, err)
	}
}
