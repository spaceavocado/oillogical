package illogical

import "core:fmt"
import "base:runtime"
import "core:reflect"

// Join path with a dot.
//      Example: joinPath("a", "b") -> "a.b"
joinPath :: proc(a, b: string) -> string {
    if len(a) == 0 {
        return b
    }

    return fmt.tprintf("%s.%s", a, b)
}

traverse_context :: proc(value: any, path: string, result: ^Flatten_Context) {
    ti := runtime.type_info_base(type_info_of(value.id))

    #partial switch info in ti.variant {
    case runtime.Type_Info_String:
        result[path] = value.(string)
    case runtime.Type_Info_Float:
        result[path] = value.(f64)
    case runtime.Type_Info_Integer:
        result[path] = value.(i64)
    case runtime.Type_Info_Boolean:
        result[path] = value.(bool)
    case runtime.Type_Info_Array, runtime.Type_Info_Dynamic_Array, runtime.Type_Info_Slice:
        from := 0
        for elem, i in reflect.iterate_array(value, &from) {
            traverse_context(elem, fmt.tprintf("%s[%d]", path, i), result)
        }
    case runtime.Type_Info_Map:
        from := 0
        for k, v in reflect.iterate_map(value, &from) {
            traverse_context(v, joinPath(path, fmt.tprintf("%v", k)), result)
        }
    case runtime.Type_Info_Union:
        tag_ptr := uintptr(value.data) + info.tag_offset
        tag_any := any{rawptr(tag_ptr), info.tag_type.id}

        tag: i64 = -1
        switch i in tag_any {
        case u8:   tag = i64(i)
        case i8:   tag = i64(i)
        case u16:  tag = i64(i)
        case i16:  tag = i64(i)
        case u32:  tag = i64(i)
        case i32:  tag = i64(i)
        case u64:  tag = i64(i)
        case i64:  tag = i64(i)
        case: panic("Invalid union tag type")
        }

        id := info.variants[tag-1].id
        traverse_context(any{value.data, id}, path, result)
    }
}

// Flatten context into a map of map[property path]value.
//
// Example:
// ctx := Flatten_Context{
//     "name"       = "peter",
//     "options"    = []int{1, 2, 3},
//     "address"    = struct {
//         city:    string,
//         country: string
//     }{
//         city     = "Toronto",
//         country  = "Canada",
//     },
// }
//
// flattened = flatten_context(ctx)
//
// flattened := Flatten_Context{
//     "name"               = "peter",
//     "options[0]"         = 1,
//     "options[1]"         = 2,
//     "options[2]"         = 3,
//     "address.city"       = "Toronto",
//     "address.country"    = "Canada",
// }
flatten_context :: proc(ctx: any) -> Flatten_Context {
    if ctx == nil {
        return nil
    }

    if ctx.id == Flatten_Context {
        return ctx.(Flatten_Context)
    }

    result := make(Flatten_Context)
    traverse_context(ctx, "", &result)

    return result
}