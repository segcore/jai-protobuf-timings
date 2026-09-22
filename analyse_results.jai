#import "Basic";
#import "File";
#import,dir "jai/modules/Protobuf";

#insert #run generate_jai("./proto/test_results.proto");

INPUT_PATHS :: string.["jai/results.pb", "jai/results-no-assert.pb", "cpp/results.pb"];

main :: () {
    print("------------------------------\n");
    all_sources: [..]TestResults;

    for path: INPUT_PATHS {
        data_string, ok := read_entire_file(path);
        // Do not free, the protobuf points into the bytes
        if !ok {
            print("Warning: failed to read file path '%'\n", path, to_standard_error=true);
            continue;
        }
        data: []u8 = xx data_string;

        this_result: TestResults;
        if !Deserialize(*this_result, data) {
            print("Error: failed to deserialize the bytes of '%'\n", path, to_standard_error=true);
            continue;
        }
        print("Read '%'\n", path, to_standard_error=true);

        array_add(*all_sources, this_result);
    }

    // Gather the names of the test cases, so we can compare all sources for each test case
    test_names: [..]string;
    for source : all_sources {
        for test_case : source.results {
            if test_case.name == "test_memcopy" continue;
            if !array_find(test_names, test_case.name) {
                array_add(*test_names, test_case.name);
            }
        }
    }

    format2(all_sources, test_names);
}


// --------------------------------------------------
format1 :: (all_sources: []TestResults, test_names: []string) {
OUTPUT_FORMAT :: #string,\% END
    section %1
        \%\% Create object :done,   %2a, 0, %3s
        Serialize     :active, %2b, 0, %4s
        Deserialize   :        %2c, 0, %5s
        \%\% Cleanup       :crit,   %2d, 0, %6s
END

    for test_name : test_names {
        print(#string,\% END
```mermaid
gantt
    title %
    dateFormat  S
    axisFormat \%S
END, test_name);
        for source : all_sources {
            for testcase : source.results {
                if testcase.name == test_name {
                    plot := testcase.Avg;
                    section := tprint("% %", source.source, testcase.test_type);
                    print(OUTPUT_FORMAT, section, tprint("a%_", it_index),
                        1000*plot.create_object, 1000*plot.serialize, 1000*plot.deserialize, 1000*plot.cleanup);
                }
            }
        }
        write_string("```\n\n");
    }
}

// --------------------------------------------------
format2 :: (all_sources: []TestResults, test_names: []string) {
    TimeType :: enum {
        Serialize;
        Deserialize;
        CreateObject;
        Cleanup;
    }

    formatting_options :: string.[
        "",
        "active,",
        "done,",
        "crit,",
    ];

    for test_name : test_names {
        print(#string,\% END
```mermaid
gantt
    title %
    dateFormat x
    axisFormat \%s.\%L ms
END, test_name);
        for time_type : enum_values_as_enum(TimeType) {
            if time_type == .CreateObject then continue; // skip this for now
            print("    section %\n", time_type);
            for source, format_index : all_sources {
                for testcase : source.results {
                    if testcase.name == test_name {
                        plot := testcase.Avg;
                        source_and_type := tprint("% %", source.source, testcase.test_type);
                        time: float64;
                        if #complete time_type == {
                        case .Serialize; time = 1000*plot.serialize;
                        case .Deserialize; time = 1000*plot.deserialize;
                        case .CreateObject; time = 1000*plot.create_object; if testcase.test_type != .Default then continue;
                        case .Cleanup; time = 1000*plot.cleanup; if testcase.test_type != .Default then continue;
                        }
                        format := formatting_options[format_index % formatting_options.count];
                        print("        % :% 0, %s\n", source_and_type, format, time);
                    }
                }
            }

        }
        write_string("    section Markers\n        10ms : milestone, m1, 0, 20s\n");
        write_string("```\n\n");
    }
}
