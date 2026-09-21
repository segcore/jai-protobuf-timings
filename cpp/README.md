# C++ Protobuf Results

Compiled with the following commands.

```sh
# Debug
rm -rf build-debug
time (cmake . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug && cmake --build build-debug --parallel)

# Release
rm -rf build
time (cmake . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release     && cmake --build build --parallel)

# Incremental .cpp (release)
touch main.cpp
time cmake --build build

# Incremental .proto (release)
touch ../proto/sample.proto
time cmake --build build
```

## Compile times

Builds are performed with CMake and Ninja, and built in parallel.

First build must compile the protobuf libraries, protoc, etc., generate the C++ code, and
link it all together.

Incremental `main.cpp` means that main.cpp is touched before the incremental build.

Incremental `.proto` means that .proto file is touched before the incremental build.

All times are in seconds.

| Target  | First Build | Incremental main.cpp | Incremental .proto |
| ---     | ---         | ---                  | ---                |
| Debug   | 63.220      | 2.698                | 3.417              |
| Release | 108.758     | 2.393                | 3.657              |

## Run times (Release)

The best time is recorded for each section. All times are in *milliseconds*.

Three memory allocation strategies are tested.
* Default - Using the default general purpose heap allocator for all allocations.
* Arena - Using a google::protobuf::Arena for all message objects.
* Buffer - Passing-in a preallocated buffer to re-use in Serialization. Using a google::protobuf::Arena for all message objects.

| Procedure                                 | Create Object | Serialize         | Deserialize        | Cleanup | Total              | Bytes              |
| ---                                       | ---           | ---               | ---                | ---     | ---                | ---                |
| test_memcopy (Default)                    | 0.3           | 0.3 (13.27 Gb/s)  | 0.1 (38.32 Gb/s)   | 0.1     | 1.8 ( 2.16 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                      | 0.2           | 0.2 (16.96 Gb/s)  | 0.1 (45.80 Gb/s)   | 0.1     | 2.2 ( 1.76 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Buffer)                     | 0.1           | 0.1 (32.83 Gb/s)  | 0.1 (42.63 Gb/s)   | 0.0     | 0.7 ( 5.32 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints (Default)              | 2.3           | 2.9 ( 1.23 Gb/s)  | 3.4 ( 1.03 Gb/s)   | 0.1     | 9.4 ( 0.37 Gb/s)   | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)                | 2.5           | 2.9 ( 1.23 Gb/s)  | 3.2 ( 1.11 Gb/s)   | 0.0     | 8.7 ( 0.41 Gb/s)   | 3788658 (3.6 Mb)   |
| test_repeated_ints (Buffer)               | 2.5           | 2.9 ( 1.23 Gb/s)  | 3.2 ( 1.10 Gb/s)   | 0.0     | 8.7 ( 0.40 Gb/s)   | 3788658 (3.6 Mb)   |
| test_repeated_zigzag (Default)            | 2.7           | 3.2 ( 1.15 Gb/s)  | 4.3 ( 0.85 Gb/s)   | 0.3     | 10.5 ( 0.34 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)              | 2.3           | 3.1 ( 1.16 Gb/s)  | 3.3 ( 1.09 Gb/s)   | 0.0     | 8.8 ( 0.41 Gb/s)   | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Buffer)             | 2.3           | 3.1 ( 1.17 Gb/s)  | 3.4 ( 1.07 Gb/s)   | 0.0     | 8.8 ( 0.41 Gb/s)   | 3894341 (3.7 Mb)   |
| test_repeated_floats (Default)            | 1.3           | 0.1 (44.56 Gb/s)  | 0.1 (41.16 Gb/s)   | 0.0     | 1.5 ( 2.50 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)              | 1.7           | 0.1 (35.42 Gb/s)  | 0.1 (26.71 Gb/s)   | 0.0     | 2.0 ( 1.83 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Buffer)             | 2.4           | 0.1 (41.83 Gb/s)  | 0.1 (35.86 Gb/s)   | 0.0     | 2.6 ( 1.44 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings (Default)           | 33.5          | 17.7 ( 1.94 Gb/s) | 79.0 ( 0.43 Gb/s)  | 42.5    | 174.0 ( 0.20 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)             | 26.2          | 12.7 ( 2.71 Gb/s) | 36.7 ( 0.94 Gb/s)  | 0.0     | 76.1 ( 0.45 Gb/s)  | 36888913 (35.2 Mb) |
| test_repeated_strings (Buffer)            | 26.6          | 12.7 ( 2.71 Gb/s) | 36.7 ( 0.94 Gb/s)  | 0.0     | 76.2 ( 0.45 Gb/s)  | 36888913 (35.2 Mb) |
| test_repeated_maps_ints (Default)         | 124.7         | 77.8 ( 0.12 Gb/s) | 42.6 ( 0.22 Gb/s)  | 177.0   | 430.7 ( 0.02 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)           | 55.3          | 49.3 ( 0.19 Gb/s) | 29.7 ( 0.31 Gb/s)  | 0.0     | 135.0 ( 0.07 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Buffer)          | 55.6          | 49.4 ( 0.19 Gb/s) | 30.1 ( 0.31 Gb/s)  | 0.0     | 135.9 ( 0.07 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings (Default) | 27.2          | 43.8 ( 1.12 Gb/s) | 25.3 ( 1.93 Gb/s)  | 45.8    | 143.0 ( 0.34 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena)   | 20.5          | 35.7 ( 1.37 Gb/s) | 17.0 ( 2.88 Gb/s)  | 0.2     | 74.2 ( 0.66 Gb/s)  | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Buffer)  | 20.7          | 32.1 ( 1.52 Gb/s) | 17.0 ( 2.87 Gb/s)  | 0.0     | 69.9 ( 0.70 Gb/s)  | 52480857 (50.0 Mb) |
| test_submessages (Default)                | 33.9          | 29.8 ( 1.09 Gb/s) | 115.2 ( 0.28 Gb/s) | 52.7    | 232.8 ( 0.14 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                  | 14.8          | 28.5 ( 1.15 Gb/s) | 49.2 ( 0.66 Gb/s)  | 0.2     | 93.3 ( 0.35 Gb/s)  | 35000026 (33.4 Mb) |
| test_submessages (Buffer)                 | 14.6          | 25.4 ( 1.28 Gb/s) | 48.9 ( 0.67 Gb/s)  | 0.0     | 89.5 ( 0.36 Gb/s)  | 35000026 (33.4 Mb) |
