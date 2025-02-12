#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_nil_handler :: proc(t: ^testing.T) {
	tests := []struct {
		e:     illogical.Evaluated,
		expected: illogical.Primitive,
	}{
        // Truthy
		{nil, true},
        // Falsy
		{illogical.new_primitive(1), false},
		{illogical.new_primitive(1.1), false},
		{illogical.new_primitive("1"), false},
		{illogical.new_primitive(true), false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.e}
		evaluated := illogical.handler_nil(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v): expected %v, got %v", test.e, test.expected, evaluated)
	}
}