# Jai Protobuf Results

Compiled with Jai compiler v0.2.030.

```sh
time jai main.jai -x64 # Debug x64
time jai main.jai      # Debug LLVM
time jai main.jai -o   # Release
```

## Compile times

Jai does not do incremental builds. The protobuf parsing, code generation, and
compiliation all happens at build time. All time is included in the total time.

| Target     | Build Time (seconds) |
| ---        | ---                  |
| Debug x64  | 0.176                |
| Debug LLVM | 0.324                |
| Release    | 3.027                |

## Run times (Release)

The average time is recorded for each section. All times are in *milliseconds*.

Three memory allocation strategies are tested.
* Default - Using the default general purpose heap allocator for all allocations.
* Arena - Using a Flat_Pool (a large virtual memory mapping bump allocator) for all allocations.
* Buffer - Passing-in a preallocated buffer to use for Serialization. Flat_Pool used for all other allocations.

| Procedure                                 | Create Object | Serialize         | Deserialize       | Cleanup | Total              | Bytes              |
| ---                                       | ---           | ---               | ---               | ---     | ---                | ---                |
| test_memcopy (Default)                    | 0.0           | 1.0 ( 3.81 GB/s)  | 0.2 (26.00 GB/s)  | 0.4     | 3.7 ( 1.04 GB/s)   | 4194325 (4.0 MB)   |
| test_memcopy (Arena)                      | 0.0           | 0.2 (22.86 GB/s)  | 0.1 (27.79 GB/s)  | 0.0     | 0.9 ( 4.19 GB/s)   | 4194325 (4.0 MB)   |
| test_memcopy (Buffer)                     | 0.0           | 0.2 (21.06 GB/s)  | 0.2 (23.85 GB/s)  | 0.0     | 1.1 ( 3.58 GB/s)   | 4194325 (4.0 MB)   |
| test_repeated_ints (Default)              | 4.6           | 4.3 ( 0.81 GB/s)  | 6.8 ( 0.52 GB/s)  | 0.3     | 16.0 ( 0.22 GB/s)  | 3788658 (3.6 MB)   |
| test_repeated_ints (Arena)                | 4.1           | 4.0 ( 0.89 GB/s)  | 5.3 ( 0.66 GB/s)  | 0.0     | 13.4 ( 0.26 GB/s)  | 3788658 (3.6 MB)   |
| test_repeated_ints (Buffer)               | 3.8           | 2.8 ( 1.26 GB/s)  | 5.3 ( 0.66 GB/s)  | 0.0     | 11.9 ( 0.30 GB/s)  | 3788658 (3.6 MB)   |
| test_repeated_zigzag (Default)            | 5.0           | 5.0 ( 0.73 GB/s)  | 6.7 ( 0.55 GB/s)  | 0.3     | 16.8 ( 0.22 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_zigzag (Arena)              | 4.0           | 4.4 ( 0.83 GB/s)  | 5.6 ( 0.65 GB/s)  | 0.0     | 14.0 ( 0.26 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_zigzag (Buffer)             | 4.0           | 3.0 ( 1.19 GB/s)  | 5.6 ( 0.65 GB/s)  | 0.0     | 12.7 ( 0.29 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_floats (Default)            | 4.8           | 0.7 ( 5.21 GB/s)  | 0.6 ( 6.50 GB/s)  | 0.1     | 6.3 ( 0.59 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_floats (Arena)              | 3.8           | 0.2 (22.16 GB/s)  | 0.2 (15.96 GB/s)  | 0.0     | 4.2 ( 0.89 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_floats (Buffer)             | 3.8           | 0.2 (22.00 GB/s)  | 0.2 (16.41 GB/s)  | 0.0     | 4.2 ( 0.89 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_strings (Default)           | 131.9         | 15.2 ( 2.25 GB/s) | 14.7 ( 2.34 GB/s) | 4.3     | 166.1 ( 0.21 GB/s) | 36888913 (35.2 MB) |
| test_repeated_strings (Arena)             | 129.0         | 11.8 ( 2.90 GB/s) | 11.5 ( 2.99 GB/s) | 3.7     | 156.0 ( 0.22 GB/s) | 36888913 (35.2 MB) |
| test_repeated_strings (Buffer)            | 129.5         | 10.1 ( 3.40 GB/s) | 11.4 ( 3.00 GB/s) | 3.8     | 154.8 ( 0.22 GB/s) | 36888913 (35.2 MB) |
| test_repeated_maps_ints (Default)         | 49.9          | 14.9 ( 0.62 GB/s) | 58.1 ( 0.16 GB/s) | 0.6     | 123.5 ( 0.08 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_ints (Arena)           | 46.4          | 14.2 ( 0.66 GB/s) | 54.3 ( 0.17 GB/s) | 0.0     | 114.8 ( 0.08 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_ints (Buffer)          | 45.6          | 8.1 ( 1.15 GB/s)  | 54.2 ( 0.17 GB/s) | 0.0     | 107.9 ( 0.09 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_with_strings (Default) | 61.9          | 19.9 ( 2.45 GB/s) | 24.8 ( 1.97 GB/s) | 5.5     | 112.2 ( 0.44 GB/s) | 52480857 (50.0 MB) |
| test_repeated_maps_with_strings (Arena)   | 59.1          | 18.6 ( 2.63 GB/s) | 21.9 ( 2.23 GB/s) | 4.7     | 104.2 ( 0.47 GB/s) | 52480857 (50.0 MB) |
| test_repeated_maps_with_strings (Buffer)  | 58.8          | 16.3 ( 2.99 GB/s) | 21.7 ( 2.25 GB/s) | 4.7     | 101.6 ( 0.48 GB/s) | 52480857 (50.0 MB) |
| test_submessages (Default)                | 18.9          | 36.4 ( 0.90 GB/s) | 63.5 ( 0.51 GB/s) | 0.7     | 119.4 ( 0.27 GB/s) | 35000026 (33.4 MB) |
| test_submessages (Arena)                  | 10.4          | 34.4 ( 0.95 GB/s) | 54.8 ( 0.59 GB/s) | 0.0     | 99.5 ( 0.33 GB/s)  | 35000026 (33.4 MB) |
| test_submessages (Buffer)                 | 10.4          | 15.0 ( 2.18 GB/s) | 53.6 ( 0.61 GB/s) | 0.0     | 79.0 ( 0.41 GB/s)  | 35000026 (33.4 MB) |

Disabling asserts can produce a small speed increase.
Tested with:
```jai
#import "Basic"()(ENABLE_ASSERT=false);
```

| Procedure                                 | Create Object | Serialize         | Deserialize       | Cleanup | Total              | Bytes              |
| ---                                       | ---           | ---               | ---               | ---     | ---                | ---                |
| test_memcopy (Default)                    | 0.0           | 0.7 ( 5.44 GB/s)  | 0.1 (39.01 GB/s)  | 0.3     | 2.6 ( 1.51 GB/s)   | 4194325 (4.0 MB)   |
| test_memcopy (Arena)                      | 0.0           | 0.1 (38.91 GB/s)  | 0.1 (46.14 GB/s)  | 0.0     | 0.5 ( 7.92 GB/s)   | 4194325 (4.0 MB)   |
| test_memcopy (Buffer)                     | 0.0           | 0.1 (39.07 GB/s)  | 0.1 (50.48 GB/s)  | 0.0     | 0.5 ( 7.75 GB/s)   | 4194325 (4.0 MB)   |
| test_repeated_ints (Default)              | 1.9           | 4.8 ( 0.74 GB/s)  | 5.8 ( 0.61 GB/s)  | 0.3     | 12.7 ( 0.28 GB/s)  | 3788658 (3.6 MB)   |
| test_repeated_ints (Arena)                | 0.9           | 5.1 ( 0.69 GB/s)  | 4.5 ( 0.78 GB/s)  | 0.0     | 10.5 ( 0.33 GB/s)  | 3788658 (3.6 MB)   |
| test_repeated_ints (Buffer)               | 0.9           | 3.1 ( 1.14 GB/s)  | 4.5 ( 0.78 GB/s)  | 0.0     | 8.5 ( 0.41 GB/s)   | 3788658 (3.6 MB)   |
| test_repeated_zigzag (Default)            | 2.0           | 5.1 ( 0.71 GB/s)  | 6.0 ( 0.61 GB/s)  | 0.3     | 13.3 ( 0.27 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_zigzag (Arena)              | 1.0           | 5.0 ( 0.73 GB/s)  | 4.9 ( 0.74 GB/s)  | 0.0     | 10.9 ( 0.33 GB/s)  | 3894341 (3.7 MB)   |
| test_repeated_zigzag (Buffer)             | 1.0           | 3.2 ( 1.15 GB/s)  | 4.9 ( 0.74 GB/s)  | 0.0     | 9.0 ( 0.40 GB/s)   | 3894341 (3.7 MB)   |
| test_repeated_floats (Default)            | 2.0           | 0.7 ( 5.36 GB/s)  | 0.5 ( 6.91 GB/s)  | 0.1     | 3.4 ( 1.11 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_floats (Arena)              | 0.9           | 0.1 (30.83 GB/s)  | 0.1 (25.81 GB/s)  | 0.0     | 1.1 ( 3.27 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_floats (Buffer)             | 0.9           | 0.1 (27.57 GB/s)  | 0.2 (23.51 GB/s)  | 0.0     | 1.2 ( 3.21 GB/s)   | 4000021 (3.8 MB)   |
| test_repeated_strings (Default)           | 118.4         | 14.5 ( 2.38 GB/s) | 10.9 ( 3.15 GB/s) | 4.3     | 148.0 ( 0.23 GB/s) | 36888913 (35.2 MB) |
| test_repeated_strings (Arena)             | 115.3         | 11.1 ( 3.09 GB/s) | 7.7 ( 4.49 GB/s)  | 3.7     | 137.8 ( 0.25 GB/s) | 36888913 (35.2 MB) |
| test_repeated_strings (Buffer)            | 114.7         | 9.9 ( 3.46 GB/s)  | 7.5 ( 4.58 GB/s)  | 3.6     | 135.7 ( 0.25 GB/s) | 36888913 (35.2 MB) |
| test_repeated_maps_ints (Default)         | 43.4          | 13.9 ( 0.67 GB/s) | 51.1 ( 0.18 GB/s) | 0.6     | 109.0 ( 0.09 GB/s) | 9966980 (9.5 MB)   |
| test_repeated_maps_ints (Arena)           | 39.4          | 12.6 ( 0.74 GB/s) | 47.6 ( 0.20 GB/s) | 0.0     | 99.6 ( 0.09 GB/s)  | 9966980 (9.5 MB)   |
| test_repeated_maps_ints (Buffer)          | 39.3          | 7.1 ( 1.31 GB/s)  | 46.8 ( 0.20 GB/s) | 0.0     | 93.2 ( 0.10 GB/s)  | 9966980 (9.5 MB)   |
| test_repeated_maps_with_strings (Default) | 60.1          | 19.1 ( 2.56 GB/s) | 22.7 ( 2.15 GB/s) | 5.3     | 107.2 ( 0.46 GB/s) | 52480857 (50.0 MB) |
| test_repeated_maps_with_strings (Arena)   | 56.3          | 17.3 ( 2.82 GB/s) | 19.5 ( 2.51 GB/s) | 4.6     | 97.7 ( 0.50 GB/s)  | 52480857 (50.0 MB) |
| test_repeated_maps_with_strings (Buffer)  | 56.6          | 15.4 ( 3.17 GB/s) | 19.5 ( 2.51 GB/s) | 4.6     | 96.1 ( 0.51 GB/s)  | 52480857 (50.0 MB) |
| test_submessages (Default)                | 15.6          | 32.2 ( 1.01 GB/s) | 55.7 ( 0.58 GB/s) | 0.6     | 104.2 ( 0.31 GB/s) | 35000026 (33.4 MB) |
| test_submessages (Arena)                  | 8.7           | 29.7 ( 1.10 GB/s) | 47.2 ( 0.69 GB/s) | 0.0     | 85.6 ( 0.38 GB/s)  | 35000026 (33.4 MB) |
| test_submessages (Buffer)                 | 8.7           | 13.2 ( 2.47 GB/s) | 46.3 ( 0.70 GB/s) | 0.0     | 68.2 ( 0.48 GB/s)  | 35000026 (33.4 MB) |
