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

| Procedure                       | Create Object | Serialize         | Deserialize        | Cleanup | Total              | Bytes              |
| ---                             | ---           | ---               | ---                | ---     | ---                | ---                |
| test_memcopy                    | 0.2           | 0.7 ( 5.37 Gb/s)  | 0.1 (41.51 Gb/s)   | 0.3     | 3.0 ( 1.30 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints              | 2.6           | 3.2 ( 1.10 Gb/s)  | 4.3 ( 0.81 Gb/s)   | 0.1     | 10.5 ( 0.33 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag            | 3.8           | 3.2 ( 1.14 Gb/s)  | 4.5 ( 0.80 Gb/s)   | 0.5     | 12.6 ( 0.29 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats            | 2.3           | 0.1 (43.18 Gb/s)  | 0.1 (37.20 Gb/s)   | 0.0     | 2.5 ( 1.48 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings           | 35.8          | 17.1 ( 2.00 Gb/s) | 79.5 ( 0.43 Gb/s)  | 45.4    | 179.4 ( 0.19 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints         | 112.4         | 80.0 ( 0.12 Gb/s) | 42.2 ( 0.22 Gb/s)  | 182.6   | 419.4 ( 0.02 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings | 27.8          | 42.9 ( 1.14 Gb/s) | 25.4 ( 1.93 Gb/s)  | 44.9    | 142.1 ( 0.34 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                | 34.1          | 30.0 ( 1.09 Gb/s) | 113.7 ( 0.29 Gb/s) | 53.2    | 233.9 ( 0.14 Gb/s) | 35000026 (33.4 Mb) |
