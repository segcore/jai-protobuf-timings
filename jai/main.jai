#import "Protobuf";
#import "Basic";

#insert #run generate_jai("../proto/sample.proto");

REPEAT_COUNT :: 5;
FIELD_COUNT :: 1_000_000;
MB :: 1024*1024;
GB :: 1024*1024*1024;

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

main :: () {
    context.print_style.default_format_float.width = 5;
    context.print_style.default_format_float.trailing_width = 3;
    context.print_style.default_format_float.zero_removal = .NO;

    results: [..]Timings;
    array_add(*results, time(#procedure_name(test_repeated_ints), test_repeated_ints));
    array_add(*results, time(#procedure_name(test_repeated_zigzag), test_repeated_zigzag));
    array_add(*results, time(#procedure_name(test_repeated_floats), test_repeated_floats));
    array_add(*results, time(#procedure_name(test_repeated_strings), test_repeated_strings));
    array_add(*results, time(#procedure_name(test_repeated_maps_ints), test_repeated_maps_ints));
    array_add(*results, time(#procedure_name(test_repeated_maps_with_strings), test_repeated_maps_with_strings));
    array_add(*results, time(#procedure_name(test_submessages), test_submessages));

    print("| Procedure | Create Object | Serialize | Deserialize | Cleanup | Total | Bytes |\n");
    print("| --- | --- | --- | --- | --- | --- | --- |\n");
    for results {
        print("| % | % | % (% Gb/s) | % (% Gb/s) | % | % | % (% Mb) |\n", it.procedure_name,
                it.create_object,
                it.serialize, it.byte_count/it.serialize/GB,
                it.deserialize, it.byte_count/it.deserialize/GB,
                it.cleanup,
                it.total,
                it.byte_count, formatFloat(1.0*it.byte_count/MB, trailing_width=1)
        );
    }
}

time :: (name: string, fn: () -> Timings) -> Timings {
    best: Timings;
    best = fn();
    for 2..REPEAT_COUNT {
        this_run := fn();
        best.create_object = min(best.create_object, this_run.create_object);
        best.serialize = min(best.serialize, this_run.serialize);
        best.deserialize = min(best.deserialize, this_run.deserialize);
        best.cleanup = min(best.cleanup, this_run.cleanup);
    }
    best.procedure_name = name;
    best.total = best.create_object + best.serialize + best.deserialize + best.cleanup;
    print("=== % ===\n", name);
    print(" create object: %s\n", best.create_object);
    print(" serialize:     %s (% Gb/s) % bytes (% Mb)\n", best.serialize, best.byte_count/best.serialize/GB, best.byte_count, formatFloat(1.0*best.byte_count/MB, trailing_width=1));
    print(" deserialize:   %s (% Gb/s)\n", best.deserialize, best.byte_count/best.deserialize/GB);
    print(" cleanup:       %s\n", best.cleanup);
    print("total:          %s (% Gb/s)\n\n", best.total, best.byte_count/best.total/GB);

    return best;
}

test_repeated_ints :: () -> Timings {
    timings: Timings;

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
    return timings;
}

test_repeated_zigzag :: () -> Timings {
    timings: Timings;

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
    return timings;
}

test_repeated_floats :: () -> Timings {
    timings: Timings;

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
    return timings;
}

test_repeated_strings :: () -> Timings {
    timings: Timings;

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
    return timings;
}

test_repeated_maps_ints :: () -> Timings {
    timings: Timings;

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
    return timings;
}

test_repeated_maps_with_strings :: () -> Timings {
    timings: Timings;

    timings.create_object -= get_time();
    message: Maps;
    decoded: Maps;
    for i: 1..FIELD_COUNT {
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
    return timings;
}

test_submessages :: () -> Timings {
    timings: Timings;

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
    return timings;
}


string_with_length :: (length: int) -> string {
    arr := NewArray(length, u8, initialized=false,, temp);
    for i: 0..length-1 {
        arr[i] = #char "A";
    }
    return xx arr;
}
