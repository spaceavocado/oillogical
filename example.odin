#+feature dynamic-literals

package main

import "illogical"
import "core:fmt"
import "core:encoding/json"
import "core:strings"
import "core:text/regex"

credit :: proc() {
    fmt.println("   _  __ __            _             __")
    fmt.println("  (_)/ // /___  ___ _ (_)____ ___ _ / /")
    fmt.println(" / // // // _ \\/ _ `// // __// _ `// / ")
    fmt.println("/_//_//_/ \\___/\\_, //_/ \\__/ \\_,_//_/  ")
    fmt.println("              /___/                    ")
    fmt.println("https://github.com/spaceavocado")
    fmt.println("<In Search of Greatness>")
    fmt.println()
}

basic_usage :: proc() {
    // Create a parser
	parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    // Parse an expression to evaluable
    evaluable, parse_err := illogical.parse(&parser, illogical.Array{"==", 1, 1})
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    // Evaluate the evaluable
    result, evaluate_err := illogical.evaluate(&evaluable)
    assert(evaluate_err == nil)
    defer illogical.destroy_evaluated(result)

    // Print the result
    fmt.printf("basic usage: %s, result: %v\n", illogical.to_string(&evaluable), result)
    fmt.println()
}

evaluate_comparison :: proc() {
	parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)
    
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "name"          = "peter",
        "options"       = illogical.Array{1, 2, 3},
        "active"        = true,
        "address"       = map[string]illogical.Primitive{
            "city"    = "Toronto",
            "country" = "Canada",
        },
    }
    defer delete(ctx)

    expressions := []illogical.Array{
        {"==", 5, 5},
        {"==", true, true},
        {"==", "$name", "peter"},
        {"==", "$missing", "peter"},
        {"!=", "circle", "square"},
        {">=", 10, "$options[0]"},
        {"<=", "$options[1]", 10},
        {">", 10, "$options[2]"},
        {"<", 5, 10},
        {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
        {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
        {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
        {"NONE", "$missing"},
        {"PRESENT", "$name"},
        {"PREFIX", "bo", "bogus"},
        {"SUFFIX", "bogus", "us"},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        result, evaluate_err := illogical.evaluate(&evaluable, ctx)
        assert(evaluate_err == nil)
        defer illogical.destroy_evaluated(result)
        fmt.printf("evaluate comparison: %s, result: %v\n", illogical.to_string(&evaluable), result)
    }
    fmt.println()
}

evaluate_logical :: proc() {
	parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)
    
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "active" = true,
        "enabled" = false,
    }
    defer delete(ctx)

    expressions := []illogical.Array{
        {"AND", true, true},
        {"AND", "$active", true},
        {"OR", true, "$enabled"},
        {"NOT", false},
        {"XOR", false, true, false},
        {"NOR", false, false},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        result, evaluate_err := illogical.evaluate(&evaluable, ctx)
        assert(evaluate_err == nil)
        defer illogical.destroy_evaluated(result)
        fmt.printf("evaluate logical: %s, result: %v\n", illogical.to_string(&evaluable), result)
    }
    fmt.println()
}

serialize_comparison :: proc() {
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    expressions := []illogical.Array{
        {"==", 5, 5},
        {"==", true, true},
        {"==", "$name", "peter"},
        {"==", "$missing", "peter"},
        {"!=", "circle", "square"},
        {">=", 10, "$options[0]"},
        {"<=", "$options[1]", 10},
        {">", 10, "$options[2]"},
        {"<", 5, 10},
        {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
        {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
        {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
        {"NONE", "$missing"},
        {"PRESENT", "$name"},
        {"PREFIX", "bo", "bogus"},
        {"SUFFIX", "bogus", "us"},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        serialized := illogical.serialize(&evaluable)
        fmt.printf("serialize comparison: %s, result: %v\n", illogical.to_string(&evaluable), serialized)
    }
    fmt.println()
}

serialize_logical :: proc() {
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    expressions := []illogical.Array{
        {"AND", "$active", true},
        {"OR", true, "$enabled"},
        {"NOT", false},
        {"XOR", false, true, false},
        {"NOR", false, false},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        serialized := illogical.serialize(&evaluable)
        fmt.printf("serialize logical: %s, result: %v\n", illogical.to_string(&evaluable), serialized)
    }
    fmt.println()
}

to_string_comparison :: proc() {
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    expressions := []illogical.Array{
        {"==", 5, 5},
        {"==", true, true},
        {"==", "$name", "peter"},
        {"==", "$missing", "peter"},
        {"!=", "circle", "square"},
        {">=", 10, "$options[0]"},
        {"<=", "$options[1]", 10},
        {">", 10, "$options[2]"},
        {"<", 5, 10},
        {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
        {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
        {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
        {"NONE", "$missing"},
        {"PRESENT", "$name"},
        {"PREFIX", "bo", "bogus"},
        {"SUFFIX", "bogus", "us"},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        serialized := illogical.serialize(&evaluable)
        fmt.printf("to string comparison: %v, result: %s\n", serialized, illogical.to_string(&evaluable))
    }
    fmt.println()
}

to_string_logical :: proc() {
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    expressions := []illogical.Array{
        {"AND", "$active", true},
        {"OR", true, "$enabled"},
        {"NOT", false},
        {"XOR", false, true, false},
        {"NOR", false, false},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        serialized := illogical.serialize(&evaluable)
        fmt.printf("to string logical: %v, result: %s\n", serialized, illogical.to_string(&evaluable))
    }
    fmt.println()
}

simplify_comparison :: proc() {
	parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)
    
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "name"          = "peter",
        "options"       = illogical.Array{1, 2, 3},
        "active"        = true,
        "address"       = map[string]illogical.Primitive{
            "country" = "Canada",
        },
    }
    defer delete(ctx)

    expressions := []illogical.Array{
        {"==", "$missing", "peter"},
        {"!=", "$name", "john"},
        {">=", 10, "$options[0]"},
        {"<=", "$options[1]", 10},
        {">", 10, "$options[2]"},
        {"<", 5, 10},
        {"IN", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
        {"NOT IN", "$address.country", illogical.Array{"US", "Mexico"}},
        {"OVERLAP", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
        {"NONE", "$missing"},
        {"PRESENT", "$name"},
        {"PREFIX", "bo", "bogus"},
        {"SUFFIX", "bogus", "uus"},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        simplified_value, simplified_evaluable := illogical.simplify(&evaluable, ctx)
        assert(simplified_value != nil || simplified_evaluable != nil)

        defer illogical.destroy_evaluable(&simplified_evaluable)

        if simplified_evaluable != nil {
            fmt.printf("simplify comparison: %s, simplified evaluable: %s\n", illogical.to_string(&evaluable), illogical.to_string(&simplified_evaluable))
        } else {
            fmt.printf("simplify comparison: %s, simplified value: %v\n", illogical.to_string(&evaluable), simplified_value)
        }
    }
    fmt.println()
}

simplify_logical :: proc() {
	parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)
    
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "name"          = "peter",
        "options"       = illogical.Array{1, 2, 3},
        "active"        = true,
        "address"       = map[string]illogical.Primitive{
            "country" = "Canada",
        },
    }
    defer delete(ctx)

    expressions := []illogical.Array{
        {"AND", illogical.Array{"==", "$missing", "peter"}, true},
        {"OR", illogical.Array{"==", "$name", "peter"}, "$enabled"},
        {"NOT", false},
        {"XOR", "$missing", "$enabled", true},
        {"NOR", false, "$missing"},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        simplified_value, simplified_evaluable := illogical.simplify(&evaluable, ctx)
        assert(simplified_value != nil || simplified_evaluable != nil)

        defer illogical.destroy_evaluable(&simplified_evaluable)

        if simplified_evaluable != nil {
            fmt.printf("simplify logical: %s, simplified evaluable: %s\n", illogical.to_string(&evaluable), illogical.to_string(&simplified_evaluable))
        } else {
            fmt.printf("simplify logical: %s, simplified value: %v\n", illogical.to_string(&evaluable), simplified_value)
        }
    }
    fmt.println()
}

expression_and_context_from_json :: proc() {
    // Create a parser
	parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)
    
    // Example expression JSON string
    expression_json := `["AND", ["==", "$name", "peter"], ["!=", 1, false]]`
    // Example context JSON string
    ctx_json := `{"name": "peter", "options": [1, 2, 3], "active": true, "address": {"city": "Toronto", "country": "Canada"}}`

    // Parse the expression JSON string
    expression, parse_expression_err := json.parse_string(expression_json, parse_integers = true)
    assert(parse_expression_err == nil)
    fmt.printf("expression from json: %v\n", expression)

    // Parse the context JSON string
    ctx, parse_ctx_err := json.parse_string(ctx_json)
    assert(parse_ctx_err == nil)

    // Parse the expression
    evaluable, parse_err := illogical.parse(&parser, expression)
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)
    fmt.printf("evaluable from json: %s\n", illogical.to_string(&evaluable))

    // Evaluate the expression
    result, evaluate_err := illogical.evaluate(&evaluable, ctx)
    assert(evaluate_err == nil)
    defer illogical.destroy_evaluated(result)
    fmt.printf("evaluated from json: %v\n", result)
}

parser_options_custom_operator_map :: proc() {
    ctx := map[string]illogical.Primitive{}
    defer delete(ctx)

    // Create a custom operator map
    operator_map := map[illogical.Kind]string {
        .Eq      = "<eq>",
        .Ne      = "<ne>",
        .Gt      = "<gt>",
        .Ge      = "<ge>",
        .Lt      = "<lt>",
        .Le      = "<le>",
        .In      = "<in>",
        .Not_In  = "<not in>",
        .Overlap = "<overlap>",
        .None    = "<none>",
        .Present = "<present>",
        .Prefix  = "<prefix>",
        .Suffix  = "<suffix>",
        .And     = "<and>",
        .Or      = "<or>",
        .Not     = "<not>",
        .Xor     = "<xor>",
        .Nor     = "<nor>",
    }
    defer delete(operator_map)

    // Create a parser with the custom operator map
    parser := illogical.new_parser(&operator_map)
    defer illogical.destroy_parser(&parser)

    // Comparison expression
    expressions := []illogical.Array{
        {"<eq>", 5, 5},
        {"<ne>", "circle", "square"},
        {"<ge>", 10, "$options[0]"},
        {"<le>", "$options[1]", 10},
        {"<gt>", 10, "$options[2]"},
        {"<lt>", 5, 10},
        {"<in>", "$address.city", illogical.Array{"Toronto", "Vancouver", "Montreal"}},
        {"<not in>", "$address.country", illogical.Array{"US", "Mexico"}},
        {"<overlap>", illogical.Array{"1", 2, "3"}, illogical.Array{2, "3", "4"}},
        {"<none>", "$missing"},
        {"<present>", "$name"},
        {"<prefix>", "bo", "bogus"},
        {"<suffix>", "bogus", "us"},
    }
    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        result, evaluate_err := illogical.evaluate(&evaluable, ctx)
        assert(evaluate_err == nil)
        defer illogical.destroy_evaluated(result)
        fmt.printf("evaluate expression with custom operator map: %s, result: %v\n", illogical.to_string(&evaluable), result)
    }
    fmt.println()
}

parser_with_serialize_options_reference :: proc() {
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "name"          = "peter",
    }
    defer delete(ctx)

    // Create a serialize options reference
    serialize_options_reference := illogical.Serialize_Options_Reference{
        from = proc(operand: string) -> (string, illogical.Error) {
            if len(operand) > 2 && strings.has_prefix(operand, "__") {
                return operand[2:], .None
            }
            return "", .Invalid_Operand
        },
        to = proc(operand: string) -> string {
            return fmt.tprintf("__%s", operand)
        },
    }

    // Create a parser
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    // Apply the serialize options reference to the parser
    parser = illogical.with_serialize_options_reference(&parser, serialize_options_reference)^

    // Parse the expression
    evaluable, parse_err := illogical.parse(&parser, illogical.Array{"==", "__name", "peter"})
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    result, evaluate_err := illogical.evaluate(&evaluable, ctx)
    assert(evaluate_err == nil)
    defer illogical.destroy_evaluated(result)
    fmt.printf("parser with serialize options reference: %s, serialized: %s, result: %v\n", illogical.to_string(&evaluable), illogical.serialize(&evaluable), result)
    
    fmt.println()
}

parser_with_serialize_options_collection :: proc() {
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "name"          = "peter",
    }
    defer delete(ctx)

    // Create a parser
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    // Apply the serialize options collection to the parser
    escape_character := "~"
    parser = illogical.with_serialize_options_collection(&parser, escape_character)^

    // Parse the expression
    evaluable, parse_err := illogical.parse(&parser, illogical.Array{"~==", "$name", "peter"})
    assert(parse_err == nil)
    defer illogical.destroy_evaluable(&evaluable)

    result, evaluate_err := illogical.evaluate(&evaluable, ctx)
    assert(evaluate_err == nil)
    defer illogical.destroy_evaluated(result)
    fmt.printf("parser with serialize options collection: %s, serialized: %s, result: %v\n", illogical.to_string(&evaluable), illogical.serialize(&evaluable), result)
    
    fmt.println()
}

parser_with_simplify_options_reference :: proc() {
    // Create evaluation context
    ctx := map[string]illogical.Primitive{
        "firstname"     = "peter",
        "lastname"      = "parker",
        "yearly_income" = 100000,
    }
    defer delete(ctx)

    // Create a simplify options reference
    yearly_income_key_rx, _ := regex.create_by_user("/_income$/g")
    simplify_options_reference := illogical.Simplify_Options_Reference{
        ignored_paths = [dynamic]string{"firstname"},
        ignored_paths_rx = [dynamic]regex.Regular_Expression{
            yearly_income_key_rx,
        },
    }
    defer illogical.destroy_simplify_options_reference(&simplify_options_reference)
    defer regex.destroy(yearly_income_key_rx)

    // Create a parser
    parser := illogical.new_parser()
    defer illogical.destroy_parser(&parser)

    // Apply the serialize options reference to the parser
    parser = illogical.with_simplify_options_reference(&parser, simplify_options_reference)^

    expressions := []illogical.Array{
        {"==", "$firstname", "peter"},
        {"==", "$lastname", "parker"},
        {">", "$yearly_income", 0},
    }

    for expression in expressions {
        evaluable, parse_err := illogical.parse(&parser, expression)
        assert(parse_err == nil)
        defer illogical.destroy_evaluable(&evaluable)

        simplified_value, simplified_evaluable := illogical.simplify(&evaluable, ctx)
        assert(simplified_value != nil || simplified_evaluable != nil)

        defer illogical.destroy_evaluable(&simplified_evaluable)

        if simplified_evaluable != nil {
            fmt.printf("parser with simplify options reference: %s, simplified evaluable: %s\n", illogical.to_string(&evaluable), illogical.to_string(&simplified_evaluable))
        } else {
            fmt.printf("parser with simplify options reference: %s, simplified value: %v\n", illogical.to_string(&evaluable), simplified_value)
        }
    }
    fmt.println()
}

main :: proc() {
    credit()

	basic_usage()
    evaluate_comparison()
    evaluate_logical()
    serialize_comparison()
    serialize_logical()
    to_string_comparison()
    to_string_logical()
    simplify_comparison()
    simplify_logical()
    expression_and_context_from_json()
    parser_options_custom_operator_map()
    parser_with_serialize_options_reference()
    parser_with_serialize_options_collection()
    parser_with_simplify_options_reference()
}