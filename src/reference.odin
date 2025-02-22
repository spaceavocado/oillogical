package illogical

import "core:fmt"
import "core:text/regex"
import "core:strconv"
import "core:strings"

NESTED_REFERENCE_RX :: `/\{([^{}]+)\}/g`
DATA_TYPE_RX :: `/^.+\.\(([A-Z][a-z]+)\)$/`
DATA_TYPE_TRIM_RX :: `/\.\([A-Z][a-z]+\)$/g`

Data_Type :: enum {
    Undefined = 0,
    Unsupported,
    Number,
    Integer,
    Float,
    String,
    Boolean,
}

Reference :: struct {
    address: string,
    path: string,
    data_type: Data_Type,
    serialize_options: Serialize_Options_Reference,
    simplify_options: Simplify_Options_Reference,
}

Serialize_Options_Reference :: struct {
    from: proc(string) -> (string, Error),
    to: proc(string) -> string,
}

Simplify_Options_Reference :: struct {
    ignored_paths: [dynamic]string,
    ignored_paths_rx: [dynamic]regex.Regular_Expression,
}

new_reference :: proc(
    address: string,
    serialize_options: ^Serialize_Options_Reference = nil,
    simplify_options: ^Simplify_Options_Reference = nil,
) -> (Evaluable, Error) {
    data_type, err := get_data_type(address)
    if err != .None {
        return {}, err
    }
    
    r := Reference{
        address = address,
        path = trim_data_type(address),
        data_type = data_type,
        serialize_options = serialize_options^ if serialize_options != nil else create_default_serialize_options_reference(),
        simplify_options = simplify_options^ if simplify_options != nil else Simplify_Options_Reference{
            ignored_paths = make([dynamic]string),
            ignored_paths_rx = make([dynamic]regex.Regular_Expression),
        },
    }
    return r, .None
}

evaluate_reference :: proc(reference: ^Reference, ctx: ^Flatten_Context) -> (Primitive, Error) {
    if ctx == nil {
        return nil, .None
    }

    _, _, value, err := resolve_reference(ctx, reference.path, reference.data_type)
    return value, err
}

simplify_reference :: proc(reference: ^Reference, ctx: ^Flatten_Context) -> (Primitive, Evaluable) {
    if ctx == nil {
        return nil, reference^
    }

    found, path, value, _ := resolve_reference(ctx, reference.path, reference.data_type)
    if found && !is_ignored_path(path, &reference.simplify_options) {
        return value, {}
    }

    return nil, reference^
}

serialize_reference :: proc(reference: ^Reference) -> Primitive {
    path := reference.path

    if reference.data_type != .Undefined {
        path = fmt.tprintf("%s.(%s)", path, reference.data_type)
    }

    return reference.serialize_options.to(path)
}

to_string_reference :: proc(reference: ^Reference) -> string {
    return fmt.tprintf("{{%s}}", reference.address)
}

create_default_serialize_options_reference :: proc() -> Serialize_Options_Reference {
    return Serialize_Options_Reference{
        from = proc(operand: string) -> (string, Error) {
            if len(operand) > 1 && strings.has_prefix(operand, "$") {
                return operand[1:], .None
            }
            return "", .Invalid_Operand
        },
        to = proc(operand: string) -> string {
            return fmt.tprintf("$%s", operand)
        }
    }
}

resolve_reference :: proc(ctx: ^Flatten_Context, path: string, data_type: Data_Type) -> (bool, string, Primitive, Error) {
    found, resolved_path, value := context_lookup(path, ctx)
    if !found || value == nil {
        return found, resolved_path, nil, .None
    }

    #partial switch data_type {
    case .Number:
        val, err := as_number(value)
        return found, resolved_path, val, err
    case .Integer:
        val, err := as_integer(value)
        return found, resolved_path, val, err
    case .Float:
        val, err := as_float(value)
        return found, resolved_path, val, err
    case .Boolean:
        val, err := as_boolean(value)
        return found, resolved_path, val, err
    case .String:
        val, err := as_string(value)
        return found, resolved_path, val, err
    case:
        return found, resolved_path, value, .None
    }
}

as_number :: proc(value: Primitive) -> (Primitive, Error) { 
    switch v in value {
    case int, f64:
        return v, .None
    case string:
        if strings.contains(v, ".") {
            return as_float_from_string(v)
        }
        return as_int_from_string(v)
    case bool:
        return v ? 1 : 0, .None
    case Array:
        return nil, .Invalid_Data_Type_Conversion
    case:
        return nil, .Invalid_Data_Type_Conversion
    }
}

as_integer :: proc(value: Primitive) -> (Primitive, Error) {
    switch v in value {
    case int:
        return v, .None
    case f64:
        return int(v), .None
    case string:
        return as_int_from_string(v)
    case bool:
        return v ? 1 : 0, .None
    case Array:
        return nil, .Invalid_Data_Type_Conversion        
    case:
        return nil, .Invalid_Data_Type_Conversion
    }
}

as_float :: proc(value: Primitive) -> (Primitive, Error) {
    switch v in value {
    case f64:
        return v, .None
    case int:
        return f64(v), .None
    case string:
        return as_float_from_string(v)
    case bool:
        return nil, .Invalid_Data_Type_Conversion
    case Array:
        return nil, .Invalid_Data_Type_Conversion
    case:
        return nil, .Invalid_Data_Type_Conversion
    }
}

as_boolean :: proc(value: Primitive) -> (Primitive, Error) {
    switch v in value {
    case bool:
        return v, .None
    case int:
        if v == 0 {
            return false, .None
        } else if v == 1 {
            return true, .None
        }
        return nil, .Invalid_Data_Type_Conversion
    case string:
        term := strings.trim_space(v)
        term = strings.to_lower(term)
        defer delete(term)

        if term == "true" || term == "1" {
            return true, .None
        } else if term == "false" || term == "0" {
            return false, .None
        }
        return nil, .Invalid_Data_Type_Conversion
    case f64:
        return nil, .Invalid_Data_Type_Conversion
    case Array:
        return nil, .Invalid_Data_Type_Conversion
    case:
        return nil, .Invalid_Data_Type_Conversion
    }
}

as_string :: proc(value: Primitive) -> (Primitive, Error) {
    switch v in value {
    case string:
        return v, .None
    case int:
        return fmt.tprintf("%d", v), .None
    case f64:
        return fmt.tprintf("%f", v), .None
    case bool:
        return fmt.tprintf("%t", v), .None
    case Array:
        return nil, .Invalid_Data_Type_Conversion
    case:
        return fmt.tprintf("%v", v), .None
    }
}

as_int_from_string :: proc(value: string) -> (int, Error) {
    if len(value) == 0 {
        return 0, .Invalid_Data_Type_Conversion
    }

    sign := 1
    input := value
    if value[0] == '-' {
        sign = -1
        input = value[1:]
    }

    if f, ok := strconv.parse_f64(input); ok {
        return int(f) * sign, .None
    }

    if val, ok := strconv.parse_int(input); ok {
        return val * sign, .None
    }

    return 0, .Invalid_Data_Type_Conversion
}

as_float_from_string :: proc(value: string) -> (f64, Error) {
    if len(value) == 0 {
        return 0, .Invalid_Data_Type_Conversion
    }

    sign := 1.0
    input := value
    if value[0] == '-' {
        sign = -1.0
        input = value[1:]
    }

    if val, ok := strconv.parse_f64(input); ok {
        return val * sign, .None
    }
    return 0, .Invalid_Data_Type_Conversion
}

context_lookup :: proc(path: string, ctx: ^Flatten_Context, nested_reference_rx: string = NESTED_REFERENCE_RX) -> (bool, string, Primitive) {
    if (ctx == nil) {
        return false, path, nil
    }

    path := path

    re, err := regex.create_by_user(nested_reference_rx)
    defer regex.destroy(re)
    if err != nil {
        panic("Invalid nested reference regex")
    }

    capture, success := regex.match(re, path)
    for success {
        found, _, val := context_lookup(path[capture.pos[1][0]:capture.pos[1][1]], ctx)
        if !found {
            regex.destroy_capture(capture)
            return false, path, nil
        }

        path = fmt.tprintf("%s%v%s", path[0:capture.pos[0][0]], val, path[capture.pos[0][1]:])

        regex.destroy_capture(capture)
        capture, success = regex.match(re, path)
    }

    if value, ok := ctx[path]; ok {
        return true, path, value
    }
    
    return false, path, nil
}

get_data_type :: proc(path: string, data_type_rx: string = DATA_TYPE_RX) -> (Data_Type, Error) {
    re, err := regex.create_by_user(data_type_rx)
    defer regex.destroy(re)
    if err != nil {
        panic("Invalid data type regex")
    }

    capture, success := regex.match(re, path)
    defer if success {
        regex.destroy_capture(capture)
    }
    if !success || len(capture.groups) == 0 {
        return .Undefined, .None
    }

    switch capture.groups[1] {
    case "Number":
        return .Number, .None
    case "Integer":
        return .Integer, .None
    case "Float":
        return .Float, .None
    case "String":
        return .String, .None
    case "Boolean":
        return .Boolean, .None
    case:
        return .Unsupported, .Invalid_Data_Type
    }

    return .Undefined, .None
}

trim_data_type :: proc(path: string, data_type_trim_rx: string = DATA_TYPE_TRIM_RX) -> string {
    re, err := regex.create_by_user(data_type_trim_rx)
    defer regex.destroy(re)
    if err != nil {
        panic("Invalid data type regex")
    }

    capture, success := regex.match(re, path)
    if !success {
        return path
    }

    defer regex.destroy_capture(capture)
    return path[0:capture.pos[0][0]]
}

is_ignored_path :: proc(path: string, simplify_options: ^Simplify_Options_Reference) -> bool {
    for ignored_path in simplify_options.ignored_paths {
        if ignored_path == path {
            return true
        }
    }

    for rx in simplify_options.ignored_paths_rx {
        if capture, success := regex.match(rx, path); success {
            defer regex.destroy_capture(capture)
            return true
        }
    }

    return false
}
