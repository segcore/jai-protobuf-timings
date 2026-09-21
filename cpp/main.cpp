#include "google/protobuf/arena.h"
#include "sample.pb.h"

#include <cassert>
#include <chrono>
#include <cstdio>
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

struct Timings {
    std::string procedure_name_;
    double create_object;
    double serialize;
    double deserialize;
    double cleanup;
    double total;
    size_t byte_count;
};

enum class TestType {
    Default,
    Arena,
    Buffer,
    _count,
};

struct TestParams {
    TestType test_type;
    google::protobuf::Arena* arena;
    std::string* preallocated_buffer;
};


#define procedure_name(x) #x

using TestFunction = Timings (*)(TestParams& params);
static void time(std::vector<Timings>& results, const char* name, TestFunction fn);
static Timings test_repeated_ints(TestParams& params);
static Timings test_repeated_zigzag(TestParams& params);
static Timings test_repeated_floats(TestParams& params);
static Timings test_repeated_strings(TestParams& params);
static Timings test_repeated_maps_ints(TestParams& params);
static Timings test_repeated_maps_with_strings(TestParams& params);
static Timings test_submessages(TestParams& params);
static Timings test_memcopy(TestParams& params);
static std::string string_with_length(int length);

int main() {
    std::vector<Timings> results;

    time(results, procedure_name(test_memcopy), test_memcopy);
    time(results, procedure_name(test_repeated_ints), test_repeated_ints);
    time(results, procedure_name(test_repeated_zigzag), test_repeated_zigzag);
    time(results, procedure_name(test_repeated_floats), test_repeated_floats);
    time(results, procedure_name(test_repeated_strings), test_repeated_strings);
    time(results, procedure_name(test_repeated_maps_ints), test_repeated_maps_ints);
    time(results, procedure_name(test_repeated_maps_with_strings), test_repeated_maps_with_strings);
    time(results, procedure_name(test_submessages), test_submessages);

    printf("| Procedure | Create Object | Serialize | Deserialize | Cleanup | Total | Bytes |\n");
    printf("| --- | --- | --- | --- | --- | --- | --- |\n");
    for (const auto& it : results) {
        printf("| %-41s | %5.1f | %5.1f (%5.2f GB/s) | %5.1f (%5.2f GB/s) | %5.1f | %5.1f (%5.2f GB/s) | %llu (%.1f MB) |\n", it.procedure_name_.c_str(),
                1000*it.create_object,
                1000*it.serialize, it.byte_count/it.serialize/GB,
                1000*it.deserialize, it.byte_count/it.deserialize/GB,
                1000*it.cleanup,
                1000*it.total, it.byte_count/it.total/GB,
                (unsigned long long)it.byte_count, 1.0*it.byte_count/MB
        );
    }
}

void time(std::vector<Timings>& results, const char* name, TestFunction fn) {
    std::string preallocated_buffer;
    preallocated_buffer.reserve(GB);

    google::protobuf::Arena arena{
        google::protobuf::ArenaOptions{
            .start_block_size = 4LL * GB,
        }
    };

    for (int test_type_int = 0; test_type_int < static_cast<int>(TestType::_count); test_type_int++) {
        TestType test_type = static_cast<TestType>(test_type_int);
        Timings best{};
        TestParams params{};
        params.test_type = test_type;
        params.arena = &arena;

        std::string procedure_name_ = name;
        switch(test_type) {
            case TestType::Default: procedure_name_ += " (Default)"; break;
            case TestType::Arena:   procedure_name_ += " (Arena)"; break;
            case TestType::Buffer:
                procedure_name_ += " (Buffer)";
                params.preallocated_buffer = &preallocated_buffer;
                break;
            default: break;
        }

        for (int repeat = 1; repeat <= REPEAT_COUNT; repeat++) {
            auto this_run = fn(params);
            if (repeat == 1) {
                best = std::move(this_run);
            } else {
                best.create_object = std::min(best.create_object, this_run.create_object);
                best.serialize = std::min(best.serialize, this_run.serialize);
                best.deserialize = std::min(best.deserialize, this_run.deserialize);
                best.cleanup = std::min(best.cleanup, this_run.cleanup);
                best.total = std::min(best.total, this_run.total);
            }
            arena.Reset();
        }

        best.procedure_name_ = procedure_name_;
        printf("=== %s ===\n", best.procedure_name_.c_str());
        printf(" create object: %4.1fs\n", 1000*best.create_object);
        printf(" serialize:     %4.1fs (%4.2f GB/s) %llu bytes (%.1f MB)\n", 1000*best.serialize, best.byte_count/best.serialize/GB, static_cast<unsigned long long>(best.byte_count), 1.0*best.byte_count/MB);
        printf(" deserialize:   %4.1fs (%4.2f GB/s)\n", 1000*best.deserialize, best.byte_count/best.deserialize/GB);
        printf(" cleanup:       %4.1fs\n", 1000*best.cleanup);
        printf("total:          %4.1fs (%4.2f GB/s)\n\n", 1000*best.total, best.byte_count/best.total/GB);

        results.emplace_back(std::move(best));
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

Timings test_repeated_ints(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
        Integers _message;
        Integers _decoded;
        Integers& message = *WrapCreateMessage(params, &_message);
        Integers& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Integers");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            message.add_ints(i * 10);
        }
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

Timings test_repeated_zigzag(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
        Integers _message;
        Integers _decoded;
        Integers& message = *WrapCreateMessage(params, &_message);
        Integers& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Integers");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            message.add_zigzagged(i * 10);
        }
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

Timings test_repeated_floats(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
        Floats _message;
        Floats _decoded;
        Floats& message = *WrapCreateMessage(params, &_message);
        Floats& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special Floats");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            message.add_floats(i * 10);
        }
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

Timings test_repeated_strings(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
        Strings _message;
        Strings _decoded;
        Strings& message = *WrapCreateMessage(params, &_message);
        Strings& decoded = *WrapCreateMessage(params, &_decoded);
        message.set_id("Special strings");
        for (int i = 1; i <= FIELD_COUNT; i++) {
            std::string* str = message.add_strings();
            *str = "String with some characters: " + std::to_string(i);
        }
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

Timings test_repeated_maps_ints(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
        Maps _message;
        Maps _decoded;
        Maps& message = *WrapCreateMessage(params, &_message);
        Maps& decoded = *WrapCreateMessage(params, &_decoded);
        for (int i = 1; i <= FIELD_COUNT; i++) {
            (*message.mutable_map_int_to_int())[i] = i;
        }
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

Timings test_repeated_maps_with_strings(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
        Maps _message;
        Maps _decoded;
        Maps& message = *WrapCreateMessage(params, &_message);
        Maps& decoded = *WrapCreateMessage(params, &_decoded);
        for (int i = 1; i <= FIELD_COUNT/10; i++) {
            (*message.mutable_map_int_to_string())[i] = string_with_length(i % 1000);
            (*message.mutable_map_string_to_int())["str" + std::to_string(i)] = i;
        }
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}

Timings test_submessages(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    {
        timings.create_object -= get_time();
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
        timings.create_object += get_time();

        timings.serialize -= get_time();
        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();
        timings.serialize += get_time();

        timings.deserialize -= get_time();
        if (!decoded.ParseFromString(bytes)) printf("ERROR: Failed to deserialize\n");
        timings.deserialize += get_time();

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}


Timings test_memcopy(TestParams& params) {
    Timings timings{};
    timings.total -= get_time();

    // It would be nice to just do memcpy().
    // All this is to try and avoid the optimiser just removing everything.
    // There is most certainly a better way.
    {
        timings.create_object -= get_time();
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
        timings.create_object += get_time();

        std::string _bytes;
        std::string& bytes = *WrapSerialize(message, params, &_bytes);
        timings.byte_count = bytes.size();

        if (timings.byte_count < MEMCOPY_SIZE) {
            printf("ERROR: Encoding too small. Test invalid. Got %d but expect ~%d\n", (int)timings.byte_count, MEMCOPY_SIZE);
        }

        std::string destination;
        destination.reserve(bytes.size());
        std::string_view dest_view{destination.data(), bytes.size()};
        timings.serialize -= get_time();
        // --- The actual test is here ---
        std::memcpy(destination.data(), bytes.data(), bytes.size());
        timings.serialize += get_time();

        bytes[0] = 10; // don't re-use this buffer secretly
        (void)decoded.ParseFromArray(dest_view.data(), dest_view.size());
        (void)decoded.SerializeToString(&bytes);

        timings.deserialize -= get_time();
        int different = std::memcmp(bytes.data(), destination.data(), bytes.size());
        timings.deserialize += get_time();
        if (different) {
            printf("ERROR: Serializations are different!\n");
        }

        timings.cleanup -= get_time();
    }
    timings.cleanup += get_time();
    timings.total += get_time();
    return timings;
}


std::string string_with_length(int length) {
    return std::string(length, 'A');
}
