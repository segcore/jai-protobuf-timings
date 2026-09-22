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
| Debug   | 114.909     | 2.931                | 3.459              |
| Release | 121.921     | 2.697                | 3.727              |

## Run times (Release)

The best time is recorded for each section. All times are in *milliseconds*.

Three memory allocation strategies are tested.
* Default - Using the default general purpose heap allocator for all allocations.
* Arena - Using a google::protobuf::Arena for all message objects.
* Buffer - Passing-in a preallocated buffer to re-use in Serialization. Using a google::protobuf::Arena for all message objects.

| Procedure                                 | Create Object | Serialize         | Deserialize        | Cleanup | Total              | Bytes              |
| ---                                       | ---           | ---               | ---                | ---     | ---                | ---                |
| test_memcopy (Default)                    | 0.3           | 0.8 ( 4.78 GB/s)  | 0.1 (37.96 GB/s)   | 0.4     | 3.4 ( 1.15 GB/s)   | 4194325 (4.0 MB)   |
| test_memcopy (Arena)                      | 0.2           | 0.8 ( 4.84 GB/s)  | 0.1 (38.97 GB/s)   | 0.2     | 2.5 ( 1.57 GB/s)   | 4194325 (4.0 MB)   |
| test_memcopy (Buffer)                     | 0.2           | 0.2 (18.73 GB/s)  | 0.1 (34.34 GB/s)   | 0.0     | 1.0 ( 3.74 GB/s)   | 4194325 (4.0 MB)   |
| test_repeated_ints (Default)              | 3.8           | 2.8 ( 1.24 GB/s)  | 4.1 ( 0.86 GB/s)   | 0.5     | 11.2 ( 0.31 GB/s)  | 3788658 (3.6 MB)   |
| test_repeated_ints (Arena)                | 2.6           | 3.2 ( 1.11 GB/s)  | 3.1 ( 1.14 GB/s)   | 0.0     | 8.9 ( 0.40 GB/s)   | 3788658 (3.6 MB)   |
| test_repeated_ints (Buffer)               | 2.6           | 3.2 ( 1.10 GB/s)  | 3.0 ( 1.16 GB/s)   | 0.0     | 8.9 ( 0.40 GB/s)   | 3788658 (3.6 MB)   |
| test_repeated_zigzag (Default)            | 3.8           | 3.1 ( 1.16 GB/s)  | 5.1 ( 0.71 GB/s)   | 0.5     | 12.6 ( 0.29 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_zigzag (Arena)              | 2.7           | 3.2 ( 1.12 GB/s)  | 4.1 ( 0.89 GB/s)   | 0.0     | 10.0 ( 0.36 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_zigzag (Buffer)             | 2.5           | 3.4 ( 1.06 GB/s)  | 4.2 ( 0.87 GB/s)   | 0.0     | 10.1 ( 0.36 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_floats (Default)            | 2.3           | 0.1 (40.99 GB/s)  | 0.2 (22.49 GB/s)   | 0.0     | 2.6 ( 1.43 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_floats (Arena)              | 2.0           | 0.2 (23.26 GB/s)  | 0.2 (16.92 GB/s)   | 0.0     | 2.4 ( 1.55 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_floats (Buffer)             | 2.0           | 0.2 (21.63 GB/s)  | 0.2 (17.19 GB/s)   | 0.0     | 2.4 ( 1.53 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_strings (Default)           | 39.1          | 18.4 ( 1.86 GB/s) | 81.9 ( 0.42 GB/s)  | 46.0    | 185.5 ( 0.19 GB/s) | 36888913 (35.2 MB) |
| test_repeated_strings (Arena)             | 29.8          | 13.1 ( 2.62 GB/s) | 39.4 ( 0.87 GB/s)  | 0.0     | 82.4 ( 0.42 GB/s)  | 36888913 (35.2 MB) |
| test_repeated_strings (Buffer)            | 29.9          | 13.2 ( 2.59 GB/s) | 38.0 ( 0.90 GB/s)  | 0.0     | 81.1 ( 0.42 GB/s)  | 36888913 (35.2 MB) |
| test_repeated_maps_ints (Default)         | 137.5         | 81.0 ( 0.11 GB/s) | 43.6 ( 0.21 GB/s)  | 180.2   | 442.2 ( 0.02 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_ints (Arena)           | 57.6          | 52.5 ( 0.18 GB/s) | 30.4 ( 0.31 GB/s)  | 0.0     | 140.5 ( 0.07 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_ints (Buffer)          | 60.3          | 55.2 ( 0.17 GB/s) | 30.7 ( 0.30 GB/s)  | 0.0     | 146.3 ( 0.06 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_with_strings (Default) | 28.5          | 44.1 ( 1.11 GB/s) | 26.2 ( 1.86 GB/s)  | 46.4    | 145.2 ( 0.34 GB/s) | 52480857 (50.0 MB) |
| test_repeated_maps_with_strings (Arena)   | 22.1          | 36.3 ( 1.35 GB/s) | 17.4 ( 2.80 GB/s)  | 0.3     | 76.1 ( 0.64 GB/s)  | 52480857 (50.0 MB) |
| test_repeated_maps_with_strings (Buffer)  | 22.0          | 33.2 ( 1.47 GB/s) | 17.3 ( 2.82 GB/s)  | 0.0     | 72.5 ( 0.67 GB/s)  | 52480857 (50.0 MB) |
| test_submessages (Default)                | 35.5          | 29.9 ( 1.09 GB/s) | 117.1 ( 0.28 GB/s) | 55.4    | 237.8 ( 0.14 GB/s) | 35000026 (33.4 MB) |
| test_submessages (Arena)                  | 15.0          | 29.0 ( 1.12 GB/s) | 50.4 ( 0.65 GB/s)  | 0.3     | 94.7 ( 0.34 GB/s)  | 35000026 (33.4 MB) |
| test_submessages (Buffer)                 | 14.3          | 26.0 ( 1.25 GB/s) | 49.9 ( 0.65 GB/s)  | 0.0     | 90.2 ( 0.36 GB/s)  | 35000026 (33.4 MB) |
