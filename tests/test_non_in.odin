#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_non_in_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Evaluated,
		right:    illogical.Evaluated,
		expected: illogical.Primitive,
	}{
		// Truthy
		{illogical.new_primitive(0), illogical.Array{1}, true},
		{illogical.Array{1}, illogical.new_primitive(0), true},
		{illogical.new_primitive("0"), illogical.Array{"1"}, true},
		{illogical.new_primitive(false), illogical.Array{true}, true},
		{illogical.new_primitive(1.0), illogical.Array{1.1}, true},
		{illogical.Array{1}, illogical.Array{1}, true},
		// Falsy
		{illogical.Array{1}, illogical.new_primitive(1), false},
		{illogical.new_primitive(1), illogical.Array{1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_not_in(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        illogical.destroy_evaluated(test.left)
		illogical.destroy_evaluated(test.right)
	}
}