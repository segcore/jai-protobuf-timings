#import "Protobuf";
#import "Basic"()(ENABLE_ASSERT=true);
#import "String";
#import "Flat_Pool";

#insert #run generate_jai("../proto/sample.proto");

REPEAT_COUNT :: 15;
FIELD_COUNT :: 1_000_000;
MB :: 1024*1024;
GB :: 1024*1024*1024;
MEMCOPY_SIZE :: 4*MB;

Timings :: struct {
    procedure_name: string;
    create_object: float64;
    serialize: float64;
    deserialize: float64;
    cleanup: float64;
    total: float64;
    byte_count: s64;
}

get_time :: () -> float64 {
    time := current_time_monotonic();
    return to_float64_seconds(time);
}

pool: Flat_Pool;
main :: () {
    context.print_style.default_format_float.width = 5;
    context.print_style.default_format_float.trailing_width = 1;
    context.print_style.default_format_float.zero_removal = .NO;

    results: [..]Timings;
    results.allocator = context.default_allocator;

    init(*pool, 4*GB);

    time(*results, test_memcopy);
    time(*results, test_repeated_ints);
    time(*results, test_repeated_zigzag);
    time(*results, test_repeated_floats);
    time(*results, test_repeated_strings);
    time(*results, test_repeated_maps_ints);
    time(*results, test_repeated_maps_with_strings);
    time(*results, test_submessages);

    print("| Procedure | Create Object | Serialize | Deserialize | Cleanup | Total | Bytes |\n");
    print("| --- | --- | --- | --- | --- | --- | --- |\n");
    for results {
        print("| %0%0 | % | % (% Gb/s) | % (% Gb/s) | % | % (% Gb/s) | % (% Mb) |\n", it.procedure_name, pad(it.procedure_name, 39),
                1000*it.create_object,
                1000*it.serialize, format_gbps(it.byte_count/it.serialize/GB),
                1000*it.deserialize, format_gbps(it.byte_count/it.deserialize/GB),
                1000*it.cleanup,
                1000*it.total, format_gbps(it.byte_count/it.total/GB),
                it.byte_count, formatFloat(1.0*it.byte_count/MB, trailing_width=1, zero_removal=.NO)
        );
    }
}

time :: (results: *[..]Timings, $function: Code) {
    procedure_name :: #procedure_name(#insert function);
    fn :: #insert function;
    for use_arena: 0..1 {
        name := procedure_name;
        if use_arena {
            name = sprint("% (Arena)", procedure_name,, context.default_allocator);
            context.allocator = .{flat_pool_allocator_proc, *pool};
        } else {
            context.allocator = context.default_allocator;
        }

        best: Timings;
        for 1..REPEAT_COUNT {
            this_run := fn();
            if it == 1 {
                best = this_run;
            } else {
                best.create_object = min(best.create_object, this_run.create_object);
                best.serialize = min(best.serialize, this_run.serialize);
                best.deserialize = min(best.deserialize, this_run.deserialize);
                best.cleanup = min(best.cleanup, this_run.cleanup);
                best.total = min(best.total, this_run.total);
            }
            reset(*pool);
        }
        best.procedure_name = name;
        print("=== % ===\n", name);
        print(" create object: %ms\n", 1000*best.create_object);
        print(" serialize:     %ms (% Gb/s) % bytes (% Mb)\n", 1000*best.serialize, format_gbps(best.byte_count/best.serialize/GB), best.byte_count, formatFloat(1.0*best.byte_count/MB, trailing_width=1));
        print(" deserialize:   %ms (% Gb/s)\n", 1000*best.deserialize, format_gbps(best.byte_count/best.deserialize/GB));
        print(" cleanup:       %ms\n", 1000*best.cleanup);
        print("total:          %ms (% Gb/s)\n\n", 1000*best.total, format_gbps(best.byte_count/best.total/GB));

        array_add(results, best);
    }
}

test_repeated_ints :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    // message Integers {
    //   string id = 1;
    //   repeated int32 ints = 2;
    //   repeated sint32 zigzagged = 3;
    // }

    timings.create_object -= get_time();
    message: Integers;
    message.id = "Special Integers";
    for i: 1..FIELD_COUNT {
        array_add(*message.ints, cast(s32, i) * 10);
    }
    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    decoded: Integers;
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_zigzag :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Integers;
    decoded: Integers;
    message.id = "Special Integers";
    for i: 1..FIELD_COUNT {
        array_add(*message.zigzagged, cast(s32, i) * 10);
    }
    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_floats :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Floats;
    decoded: Floats;
    message.id = "Special Floats";
    for i: 1..FIELD_COUNT {
        array_add(*message.floats, cast(float32, i) * 10);
    }
    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_strings :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Strings;
    decoded: Strings;
    message.id = "Special strings";
    for i: 1..FIELD_COUNT {
        str := array_add(*message.strings);
        str.* = tprint("String with some characters: %", i);
    }
    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    reset_temporary_storage();
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_maps_ints :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Maps;
    decoded: Maps;

    for i: 1..FIELD_COUNT {
        table_set(*message.map_int_to_int, xx i, xx i);
    }

    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    reset_temporary_storage();
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_maps_with_strings :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Maps;
    decoded: Maps;
    for i: 1..FIELD_COUNT/10 {
        table_set(*message.map_int_to_string, xx i, string_with_length(i % 1000));
        table_set(*message.map_string_to_int, tprint("str%", i), xx i);
    }
    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    reset_temporary_storage();
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_submessages :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Messages;
    decoded: Messages;
    message.id = "Super message container!";
    for i: 1..FIELD_COUNT {
        // message Submessage {
        //   int32 i32a = 1;
        //   int32 i32b = 2;
        //   double f64a = 3;
        //   double f64b = 4;
        //   string text = 5;
        //   TheEnum the_enum = 6;
        //   bool the_bool = 7;
        //
        //   enum TheEnum {
        //     ENUM_NONE = 0;
        //     ENUM_A = 10;
        //     ENUM_B = 20;
        //   }
        // }
        submessage := array_add(*message.submessage);
        submessage.i32a = 4;
        submessage.i32b = 15152;
        submessage.f64a = 5.122;
        submessage.f64b = -3.14;
        submessage.text = "Text";
        submessage.the_enum = .ENUM_A;
        submessage.the_bool = true;
    }
    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes := Serialize(message);
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_memcopy :: () -> Timings {
    timings: Timings;
    timings.total -= get_time();

    // It would be nice to just do memcpy().
    // All this is to try and avoid the optimiser just removing everything.
    // There is most certainly a better way.
    timings.create_object -= get_time();
    message: Floats;
    decoded: Floats;
    message.id = "Special Floats";
    array_reserve(*message.floats, MEMCOPY_SIZE/size_of(float));
    memset(*message.floats, 1, message.floats.count * size_of(type_of(message.floats[0])));
    message.floats.count = message.floats.allocated;
    timings.create_object += get_time();

    bytes := Serialize(message);
    timings.byte_count = bytes.count;

    if (timings.byte_count < MEMCOPY_SIZE) {
        print("ERROR: Encoding too small. Test invalid. Got % but expect ~%\n", timings.byte_count, MEMCOPY_SIZE);
    }

    destination := NewArray(bytes.count, u8, initialized=false);

    timings.serialize -= get_time();
    memcpy(destination.data, bytes.data, destination.count);
    timings.serialize += get_time();

    bytes[0] = 10; // don't re-use this buffer secretly
    Deserialize(*decoded, destination);
    Serialize(bytes, bytes.count, decoded); // serialize into bytes

    timings.deserialize -= get_time();
    different := memcmp(bytes.data, destination.data, bytes.count);
    timings.deserialize += get_time();
    if different {
        print("ERROR: Serializations are different!\n");
    }

    timings.cleanup -= get_time();
    FreeContents(*message);
    FreeContents(*decoded);
    array_free(bytes);
    array_free(destination);
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}


string_with_length :: (length: int) -> string {
    arr := NewArray(length, u8, initialized=false,, temp);
    for i: 0..length-1 {
        arr[i] = #char "A";
    }
    return xx arr;
}

pad :: (s: string, length: int) -> string {
    spaces :: "                                                  ";
    if s.count < length return slice(spaces, 0, length - s.count);
    return "";
}

// #expand because formatInt takes the pointer to int, which would disappear in a regular function
format_gbps :: (value: float64) -> FormatFloat #expand {
    return formatFloat(value, width=4, trailing_width=2, zero_removal=.NO);
}
