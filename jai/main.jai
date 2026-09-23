#import "Protobuf";
#import "Basic"()(ENABLE_ASSERT=true);
#import "String";
#import "Flat_Pool";
#import "File";

#insert #run generate_jai("../proto/sample.proto", "../proto/test_results.proto");

REPEAT_COUNT :: 15;
FIELD_COUNT :: 1_000_000;
MB :: 1024*1024;
GB :: 1024*1024*1024;
MEMCOPY_SIZE :: 4*MB;

Basic :: #import "Basic";
#if Basic.ENABLE_ASSERT {
    SOURCE_NAME :: "Jai";
    OUTPUT_PATH :: "results.pb";
} else {
    SOURCE_NAME :: "Jai (no asserts)";
    OUTPUT_PATH :: "results-no-assert.pb";
}

TestParams :: struct {
    test_type: TestType;
    preallocated_buffer: []u8;
}

TestFunction :: #type (preallocated_buffer: TestParams) -> Timing;

get_time :: () -> float64 {
    time := current_time_monotonic();
    return to_float64_seconds(time);
}

pool: Flat_Pool;
main :: () {
    context.print_style.default_format_float.width = 5;
    context.print_style.default_format_float.trailing_width = 1;
    context.print_style.default_format_float.zero_removal = .NO;

    test_results: TestResults;
    test_results.source = SOURCE_NAME;
    test_results.results.allocator = context.default_allocator;

    init(*pool, 4*GB);

    time(*test_results, test_memcopy);
    time(*test_results, test_repeated_ints);
    time(*test_results, test_repeated_zigzag);
    time(*test_results, test_repeated_floats);
    time(*test_results, test_repeated_strings);
    time(*test_results, test_repeated_maps_ints);
    time(*test_results, test_repeated_maps_with_strings);
    time(*test_results, test_submessages);

    print("| Procedure | Create Object | Serialize | Deserialize | Cleanup | Total | Bytes |\n");
    print("| --- | --- | --- | --- | --- | --- | --- |\n");
    for test_results.results {
        name := tprint("% (%)", it.name, it.test_type);
        b := it.Avg;
        print("| %0%0 | % | % (% GB/s) | % (% GB/s) | % | % (% GB/s) | % (% MB) |\n", name, pad(name, 41),
                1000*b.create_object,
                1000*b.serialize, format_gbps(b.byte_count/b.serialize/GB),
                1000*b.deserialize, format_gbps(b.byte_count/b.deserialize/GB),
                1000*b.cleanup,
                1000*b.total, format_gbps(b.byte_count/b.total/GB),
                b.byte_count, formatFloat(1.0*b.byte_count/MB, trailing_width=1, zero_removal=.NO)
        );
    }

    // Output to a machine-readable format for plotting
    result_bytes := Serialize(test_results);
    write_entire_file(OUTPUT_PATH, result_bytes.(string));
    print("Wrote % (% bytes)\n", OUTPUT_PATH, result_bytes.count);
}

time :: (results: *TestResults, $function: Code) {
    procedure_name :: #procedure_name(#insert function);
    fn : TestFunction : #insert function;

    preallocated_buffer := NewArray(GB, u8, initialized=false,, context.default_allocator);
    defer array_free(preallocated_buffer);

    for test_type_int : enum_values_as_s64(TestType) {
        test_type := cast(TestType, test_type_int);

        result : *TestResult = array_add(*results.results);
        result.name = procedure_name;
        result.test_type = test_type;

        params: TestParams;
        params.test_type = test_type;

        if test_type == {
            case .Default; context.allocator = context.default_allocator;
            case .Arena; context.allocator = .{flat_pool_allocator_proc, *pool};
            case .Buffer;
                // Can use any allocator, it will only affect the object itself
                // context.allocator = context.default_allocator;
                context.allocator = .{flat_pool_allocator_proc, *pool};
                params.preallocated_buffer = preallocated_buffer;
        }
        defer context.allocator = context.default_allocator;

        for 1..REPEAT_COUNT {
            this_run := fn(params);
            array_add(*result.runs, this_run,, context.default_allocator);
            if it == 1 {
                result.Max = this_run;
                result.Min = this_run;
                result.Total = this_run;
                result.byte_count = this_run.byte_count;
            } else {
                save :: (destination: *Timing, this_run: Timing, fn: (a: float64, b: float64) -> float64) {
                    destination.create_object = fn(destination.create_object, this_run.create_object);
                    destination.serialize = fn(destination.serialize, this_run.serialize);
                    destination.deserialize = fn(destination.deserialize, this_run.deserialize);
                    destination.cleanup = fn(destination.cleanup, this_run.cleanup);
                    destination.total = fn(destination.total, this_run.total);
                }
                save(*result.Total, this_run, (a, b) => a + b);
                save(*result.Min, this_run, min);
                save(*result.Max, this_run, max);
            }
            reset(*pool);
        }
        result.Avg = result.Total;
        result.Avg.create_object /= REPEAT_COUNT;
        result.Avg.serialize /= REPEAT_COUNT;
        result.Avg.deserialize /= REPEAT_COUNT;
        result.Avg.cleanup /= REPEAT_COUNT;
        result.Avg.total /= REPEAT_COUNT;

        b := result.Avg;
        print("=== % (%) ===\n", result.name, result.test_type);
        print(" create object: %ms\n", 1000*b.create_object);
        print(" serialize:     %ms (% GB/s) % bytes (% MB)\n", 1000*b.serialize, format_gbps(b.byte_count/b.serialize/GB), b.byte_count, formatFloat(1.0*b.byte_count/MB, trailing_width=1));
        print(" deserialize:   %ms (% GB/s)\n", 1000*b.deserialize, format_gbps(b.byte_count/b.deserialize/GB));
        print(" cleanup:       %ms\n", 1000*b.cleanup);
        print("total:          %ms (% GB/s)\n\n", 1000*b.total, format_gbps(b.byte_count/b.total/GB));
    }
}

test_repeated_ints :: (params: TestParams) -> Timing {
    timings: Timing;
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
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    decoded: Integers;
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_zigzag :: (params: TestParams) -> Timing {
    timings: Timing;
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
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_floats :: (params: TestParams) -> Timing {
    timings: Timing;
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
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_strings :: (params: TestParams) -> Timing {
    timings: Timing;
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
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    reset_temporary_storage();
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_maps_ints :: (params: TestParams) -> Timing {
    timings: Timing;
    timings.total -= get_time();

    timings.create_object -= get_time();
    message: Maps;
    decoded: Maps;

    for i: 1..FIELD_COUNT {
        table_set(*message.map_int_to_int, xx i, xx i);
    }

    timings.create_object += get_time();

    timings.serialize -= get_time();
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    reset_temporary_storage();
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_repeated_maps_with_strings :: (params: TestParams) -> Timing {
    timings: Timing;
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
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    reset_temporary_storage();
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_submessages :: (params: TestParams) -> Timing {
    timings: Timing;
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
    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
    timings.byte_count = bytes.count;
    timings.serialize += get_time();

    timings.deserialize -= get_time();
    Deserialize(*decoded, bytes);
    timings.deserialize += get_time();

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

test_memcopy :: (params: TestParams) -> Timing {
    timings: Timing;
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

    bytes: []u8;
    if params.preallocated_buffer {
        bytes = Serialize(message, params.preallocated_buffer);
    } else {
        bytes = Serialize(message);
    }
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
    Serialize(decoded, bytes); // serialize into bytes

    timings.deserialize -= get_time();
    different := memcmp(bytes.data, destination.data, bytes.count);
    timings.deserialize += get_time();
    if different {
        print("ERROR: Serializations are different!\n");
    }

    timings.cleanup -= get_time();
    if params.test_type == .Default {
        FreeContents(*message);
        FreeContents(*decoded);
        array_free(bytes);
    }
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
    return formatFloat(value, width=5, trailing_width=2, zero_removal=.NO);
}
