#include "google/protobuf/arena.h"
#include "sample.pb.h"
#include "test_results.pb.h"

#include <cassert>
#include <chrono>
#include <cstdio>
#include <fstream>
#include <string>
#include <string_view>

double get_time() {
    auto time = std::chrono::steady_clock::now().time_since_epoch();
    auto seconds = std::chrono::duration<double>(time).count();
    return seconds;
}

constexpr int REPEAT_COUNT = 15;
constexpr int FIELD_COUNT = 1'000'000;
constexpr int MB = 1024 * 1024;
constexpr int GB = 1024 * 1024 * 1024;
constexpr int MEMCOPY_SIZE = 4*MB;

constexpr const char* OUTPUT_PATH = "results.pb";

struct TestParams {
    TestType test_type;
    google::protobuf::Arena* arena;
    std::string* preallocated_buffer;
};


#define procedure_name(x) #x

using TestFunction = Timing (*)(TestParams& params);
static void time(TestResults& test_results, const char* name, TestFunction fn);
static Timing test_repeated_ints(TestParams& params);
static Timing test_repeated_zigzag(TestParams& params);
static Timing test_repeated_floats(TestParams& params);
static Timing test_repeated_strings(TestParams& params);
static Timing test_repeated_maps_ints(TestParams& params);
static Timing test_repeated_maps_with_strings(TestParams& params);
static Timing test_submessages(TestParams& params);
static Timing test_memcopy(TestParams& params);
static std::string string_with_length(int length);

int main() {
    TestResults test_results;
    test_results.set_source("C++");

    time(test_results, procedure_name(test_memcopy), test_memcopy);
    time(test_results, procedure_name(test_repeated_ints), test_repeated_ints);
    time(test_results, procedure_name(test_repeated_zigzag), test_repeated_zigzag);
    time(test_results, procedure_name(test_repeated_floats), test_repeated_floats);
    time(test_results, procedure_name(test_repeated_strings), test_repeated_strings);
    time(test_results, procedure_name(test_repeated_maps_ints), test_repeated_maps_ints);
    time(test_results, procedure_name(test_repeated_maps_with_strings), test_repeated_maps_with_strings);
    time(test_results, procedure_name(test_submessages), test_submessages);

    printf("| Procedure | Create Object | Serialize | Deserialize | Cleanup | Total | Bytes |\n");
    printf("| --- | --- | --- | --- | --- | --- | --- |\n");
    for (const auto& it : test_results.results()) {
        std::stringstream name;
        name << it.name() << " (" << TestType_Name(it.test_type()) << ")";
        const Timing& b = it.avg();
        printf("| %-41s | %5.1f | %5.1f (%5.2f GB/s) | %5.1f (%5.2f GB/s) | %5.1f | %5.1f (%5.2f GB/s) | %llu (%.1f MB) |\n", name.str().c_str(),
                1000*b.create_object(),
                1000*b.serialize(), b.byte_count()/b.serialize()/GB,
                1000*b.deserialize(), b.byte_count()/b.deserialize()/GB,
                1000*b.cleanup(),
                1000*b.total(), b.byte_count()/b.total()/GB,
                (unsigned long long)b.byte_count(), 1.0*b.byte_count()/MB
        );
    }

    // Output to a machine-readable format for plotting
    std::ofstream output_file(OUTPUT_PATH);
    if (test_results.SerializeToOstream(&output_file)) {
        std::cout << "Wrote " << OUTPUT_PATH << " (" << output_file.tellp() << " bytes)\n";
    } else {
        printf("Failed to write to output!\n");
    }
}

void time(TestResults& results, const char* name, TestFunction fn) {
    std::string preallocated_buffer;
    preallocated_buffer.reserve(GB);

    google::protobuf::Arena arena{
        google::protobuf::ArenaOptions{
            .start_block_size = 4LL * GB,
        }
    };

    for (int test_type_int = 0; test_type_int < TestType_ARRAYSIZE; test_type_int++) {
        TestType test_type = static_cast<TestType>(test_type_int);

        TestResult* result = results.add_results();
        result->set_name(name);
        result->set_test_type(test_type);

        TestParams params{};
        params.test_type = test_type;
        params.arena = &arena;

        switch(test_type) {
            case TestType::Default: break;
            case TestType::Arena: break;
            case TestType::Buffer:
                params.preallocated_buffer = &preallocated_buffer;
                break;
            default: break;
        }

        for (int repeat = 1; repeat <= REPEAT_COUNT; repeat++) {
            auto this_run = fn(params);
            *result->add_runs() = this_run;

            if (repeat == 1) {
                *result->mutable_max() = this_run;
                *result->mutable_min() = this_run;
                *result->mutable_total() = this_run;
                result->set_byte_count(this_run.byte_count());
            } else {
                auto save = [](Timing& destination, const Timing& this_run, double (*fn)(double a, double b)) {
                    destination.set_create_object(fn(destination.create_object(), this_run.create_object()));
                    destination.set_serialize(fn(destination.serialize(), this_run.serialize()));
                    destination.set_deserialize(fn(destination.deserialize(), this_run.deserialize()));
                    destination.set_cleanup(fn(destination.cleanup(), this_run.cleanup()));
                    destination.set_total(fn(destination.total(), this_run.total()));
                };
                save(*result->mutable_total(), this_run, [](auto a, auto b) -> double { return a + b; });
                save(*result->mutable_min(), this_run, [](auto a, auto b) -> double { return std::min(a, b); });
                save(*result->mutable_max(), this_run, [](auto a, auto b) -> double { return std::max(a, b); });
            }
            arena.Reset();
        }

        *result->mutable_avg() = result->total();
        result->mutable_avg()->set_create_object(result->avg().create_object() / REPEAT_COUNT);
        result->mutable_avg()->set_serialize(result->avg().serialize() / REPEAT_COUNT);
        result->mutable_avg()->set_deserialize(result->avg().deserialize() / REPEAT_COUNT);
        result->mutable_avg()->set_cleanup(result->avg().cleanup() / REPEAT_COUNT);
        result->mutable_avg()->set_total(result->avg().total() / REPEAT_COUNT);

        const auto& b = result->avg();

        printf("=== %s (%s) ===\n", result->name().c_str(), TestType_Name(result->test_type()).c_str());
        printf(" create object: %4.1fs\n", 1000*b.create_object());
        printf(" serialize:     %4.1fs (%4.2f GB/s) %llu bytes (%.1f MB)\n", 1000*b.serialize(), b.byte_count()/b.serialize()/GB, static_cast<unsigned long long>(b.byte_count()), 1.0*b.byte_count()/MB);
        printf(" deserialize:   %4.1fs (%4.2f GB/s)\n", 1000*b.deserialize(), b.byte_count()/b.deserialize()/GB);
        printf(" cleanup:       %4.1fs\n", 1000*b.cleanup());
        printf("total:          %4.1fs (%4.2f GB/s)\n\n", 1000*b.total(), b.byte_count()/b.total()/GB);
    }
}


template<typename T>
static T* WrapCreateMessage(TestParams& params, T* fallback) {
    // The arena API returns a pointer, so all things have to be a pointer.
    // We also cannot delete it, so it cannot be a unique_ptr.
    switch(params.test_type) {
        case TestType::Default:
            return fallback;
        case TestType::Arena:
            return google::protobuf::Arena::Create<T>(params.arena);
        case TestType::Buffer:
            // Use the arena to match the Jai implementation, and give the most favourable results
            return google::protobuf::Arena::Create<T>(params.arena);
        default: break;
    }
    assert(false && "Unimplemented test_type");
    return nullptr;
}

template<typename T>
static std::string* WrapSerialize(T& message, TestParams& params, std::string* fallback) {
    switch(params.test_type) {
        case TestType::Default:
            *fallback = message.SerializeAsString();
            return fallback;
        case TestType::Arena:
            *fallback = message.SerializeAsString();
            return fallback;
        case TestType::Buffer:
            (void)message.SerializeToString(params.preallocated_buffer);
            return params.preallocated_buffer;
        default: break;
    }
    assert(false && "Unimplemented test_type");
    return nullptr;
}

Timing test_repeated_ints(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Integers _message;
        Integers _decoded;
        Integers& message = *WrapCreateMessage(params, &_message);
        Integers& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Integers");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            message.add_ints(i * 10);
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}

Timing test_repeated_zigzag(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Integers _message;
        Integers _decoded;
        Integers& message = *WrapCreateMessage(params, &_message);
        Integers& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Integers");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            message.add_zigzagged(i * 10);
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}

Timing test_repeated_floats(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Floats _message;
        Floats _decoded;
        Floats& message = *WrapCreateMessage(params, &_message);
        Floats& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Floats");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            message.add_floats(i * 10);
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}

Timing test_repeated_strings(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Strings _message;
        Strings _decoded;
        Strings& message = *WrapCreateMessage(params, &_message);
        Strings& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special strings");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            std::string* str = message.add_strings();
            *str = "String with some characters: " + std::to_string(i);
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}

Timing test_repeated_maps_ints(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Maps _message;
        Maps _decoded;
        Maps& message = *WrapCreateMessage(params, &_message);
        Maps& decoded = *WrapCreateMessage(params, &_decoded);
        for (int i = 1; i <= FIELD_COUNT; i++) {
            (*message.mutable_map_int_to_int())[i] = i;
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}

Timing test_repeated_maps_with_strings(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Maps _message;
        Maps _decoded;
        Maps& message = *WrapCreateMessage(params, &_message);
        Maps& decoded = *WrapCreateMessage(params, &_decoded);
        for (int i = 1; i <= FIELD_COUNT/10; i++) {
            (*message.mutable_map_int_to_string())[i] = string_with_length(i % 1000);
            (*message.mutable_map_string_to_int())["str" + std::to_string(i)] = i;
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}

Timing test_submessages(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    {
        timings.set_create_object(-get_time());
        Messages _message;
        Messages _decoded;
        Messages& message = *WrapCreateMessage(params, &_message);
        Messages& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Super message container!");
        for (int i = 1; i <= FIELD_COUNT; i++) {
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
            Submessage* submessage = message.add_submessage();
            submessage->set_i32a(4);
            submessage->set_i32b(15152);
            submessage->set_f64a(5.122);
            submessage->set_f64b(-3.14);
            submessage->set_text("Text");
            submessage->set_the_enum(Submessage::ENUM_A);
            submessage->set_the_bool(true);
        }
        timings.set_create_object(timings.create_object() + get_time());

        timings.set_serialize(-get_time());
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        timings.set_deserialize(-get_time());
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.set_deserialize(timings.deserialize() + get_time());

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}


Timing test_memcopy(TestParams& params) {
    Timing timings{};
    timings.set_total(-get_time());

    // It would be nice to just do memcpy().
    // All this is to try and avoid the optimiser just removing everything.
    // There is most certainly a better way.
    {
        timings.set_create_object(-get_time());
        Floats _message;
        Floats _decoded;
        Floats& message = *WrapCreateMessage(params, &_message);
        Floats& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Floats");
        {
            float value;
            std::memset(&value, 1, sizeof(value));
            message.mutable_floats()->resize(MEMCOPY_SIZE/sizeof(float), value);
        }
        timings.set_create_object(timings.create_object() + get_time());

        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.set_byte_count(bytes.size());

        if (timings.byte_count() < MEMCOPY_SIZE) {
            printf("ERROR: Encoding too small. Test invalid. Got %d but expect ~%d\n", (int)timings.byte_count(), MEMCOPY_SIZE);
        }

        std::string destination;
        destination.reserve(bytes.size());
        std::string_view dest_view{destination.data(), bytes.size()};
        timings.set_serialize(-get_time());
        // --- The actual test is here ---
        std::memcpy(destination.data(), bytes.data(), bytes.size());
        timings.set_serialize(timings.serialize() + get_time());

        bytes[0] = 10; // don't re-use this buffer secretly
        (void)decoded.ParseFromArray(dest_view.data(), dest_view.size());
        (void)decoded.SerializeToString(&bytes);

        timings.set_deserialize(-get_time());
        int different = std::memcmp(bytes.data(), destination.data(), bytes.size());
        timings.set_deserialize(timings.deserialize() + get_time());
        if (different) {
            printf("ERROR: Serializations are different!\n");
        }

        timings.set_cleanup(-get_time());
    }
    timings.set_cleanup(timings.cleanup() + get_time());
    timings.set_total(timings.total() + get_time());
    return timings;
}


std::string string_with_length(int length) {
    return std::string(length, 'A');
}
