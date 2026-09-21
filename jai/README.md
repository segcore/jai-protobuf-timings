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
| Debug x64  | 0.170                |
| Debug LLVM | 0.316                |
| Release    | 2.774                |

## Run times (Release)

The best time is recorded for each section. All times are in *milliseconds*.

Three memory allocation strategies are tested.
* Default - Using the default general purpose heap allocator for all allocations.
* Arena - Using a Flat_Pool (a large virtual memory mapping bump allocator) for all allocations.
* Buffer - Passing-in a preallocated buffer to use for Serialization. Flat_Pool used for all other allocations.

| Procedure                                 | Create Object | Serialize        | Deserialize      | Cleanup | Total             | Bytes              |
| ---                                       | ---           | ---              | ---              | ---     | ---               | ---                |
| test_memcopy (Default)                    | 0.0           | 0.7 (5.92 Gb/s)  | 0.1 (45.23 Gb/s) | 0.2     | 2.4 (1.65 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                      | 0.0           | 0.1 (47.08 Gb/s) | 0.1 (47.55 Gb/s) | 0.0     | 0.4 (9.28 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Buffer)                     | 0.0           | 0.1 (47.28 Gb/s) | 0.1 (53.15 Gb/s) | 0.0     | 0.4 (9.65 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints (Default)              | 3.9           | 4.1 (0.85 Gb/s)  | 6.2 (0.57 Gb/s)  | 0.2     | 15.7 (0.22 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)                | 2.6           | 3.7 (0.96 Gb/s)  | 5.3 (0.67 Gb/s)  | 0.0     | 12.5 (0.28 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Buffer)               | 3.0           | 2.6 (1.37 Gb/s)  | 5.3 (0.66 Gb/s)  | 0.0     | 11.3 (0.31 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag (Default)            | 3.7           | 4.6 (0.80 Gb/s)  | 6.5 (0.55 Gb/s)  | 0.2     | 15.5 (0.23 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)              | 3.8           | 4.0 (0.90 Gb/s)  | 5.6 (0.65 Gb/s)  | 0.0     | 13.6 (0.27 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Buffer)             | 2.7           | 2.8 (1.28 Gb/s)  | 5.6 (0.65 Gb/s)  | 0.0     | 11.6 (0.31 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats (Default)            | 3.5           | 0.7 (5.63 Gb/s)  | 0.4 (8.59 Gb/s)  | 0.1     | 4.9 (0.76 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)              | 3.3           | 0.1 (36.43 Gb/s) | 0.2 (20.80 Gb/s) | 0.0     | 3.7 (1.00 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Buffer)             | 3.9           | 0.1 (37.80 Gb/s) | 0.2 (19.99 Gb/s) | 0.0     | 4.2 (0.88 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings (Default)           | 121.7         | 11.4 (3.02 Gb/s) | 14.7 (2.33 Gb/s) | 4.1     | 154.8 (0.22 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)             | 118.8         | 8.4 (4.09 Gb/s)  | 11.4 (3.02 Gb/s) | 3.6     | 143.7 (0.24 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Buffer)            | 118.5         | 8.6 (3.98 Gb/s)  | 11.4 (3.02 Gb/s) | 3.7     | 142.6 (0.24 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints (Default)         | 46.1          | 14.7 (0.63 Gb/s) | 57.8 (0.16 Gb/s) | 0.5     | 120.0 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)           | 44.2          | 13.6 (0.68 Gb/s) | 53.2 (0.17 Gb/s) | 0.0     | 113.2 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Buffer)          | 44.4          | 7.5 (1.23 Gb/s)  | 53.4 (0.17 Gb/s) | 0.0     | 106.7 (0.09 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings (Default) | 61.2          | 19.5 (2.51 Gb/s) | 23.9 (2.05 Gb/s) | 5.3     | 110.5 (0.44 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena)   | 57.6          | 17.9 (2.73 Gb/s) | 20.9 (2.34 Gb/s) | 4.6     | 101.2 (0.48 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Buffer)  | 57.5          | 15.8 (3.10 Gb/s) | 20.9 (2.34 Gb/s) | 4.6     | 99.1 (0.49 Gb/s)  | 52480857 (50.0 Mb) |
| test_submessages (Default)                | 18.5          | 34.5 (0.95 Gb/s) | 62.9 (0.52 Gb/s) | 0.6     | 117.1 (0.28 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                  | 10.3          | 32.1 (1.02 Gb/s) | 53.7 (0.61 Gb/s) | 0.0     | 97.0 (0.34 Gb/s)  | 35000026 (33.4 Mb) |
| test_submessages (Buffer)                 | 10.3          | 15.0 (2.17 Gb/s) | 54.0 (0.60 Gb/s) | 0.0     | 79.6 (0.41 Gb/s)  | 35000026 (33.4 Mb) |

Disabling asserts can produce a small speed increase.
Tested with:
```jai
#import "Basic"()(ENABLE_ASSERT=false);
```

| Procedure                                 | Create Object | Serialize        | Deserialize      | Cleanup | Total             | Bytes              |
| ---                                       | ---           | ---              | ---              | ---     | ---               | ---                |
| test_memcopy (Default)                    | 0.0           | 0.6 (6.10 Gb/s)  | 0.1 (47.67 Gb/s) | 0.2     | 2.3 (1.70 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                      | 0.0           | 0.1 (47.00 Gb/s) | 0.1 (47.22 Gb/s) | 0.0     | 0.4 (9.04 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Buffer)                     | 0.0           | 0.1 (47.54 Gb/s) | 0.1 (53.59 Gb/s) | 0.0     | 0.4 (9.61 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints (Default)              | 1.8           | 4.3 (0.82 Gb/s)  | 5.3 (0.67 Gb/s)  | 0.2     | 12.0 (0.29 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)                | 0.9           | 3.9 (0.92 Gb/s)  | 4.4 (0.80 Gb/s)  | 0.0     | 9.3 (0.38 Gb/s)   | 3788658 (3.6 Mb)   |
| test_repeated_ints (Buffer)               | 0.9           | 2.7 (1.32 Gb/s)  | 4.5 (0.79 Gb/s)  | 0.0     | 8.1 (0.44 Gb/s)   | 3788658 (3.6 Mb)   |
| test_repeated_zigzag (Default)            | 1.8           | 4.8 (0.76 Gb/s)  | 5.7 (0.64 Gb/s)  | 0.2     | 12.7 (0.28 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)              | 0.9           | 4.5 (0.81 Gb/s)  | 4.9 (0.75 Gb/s)  | 0.0     | 10.4 (0.35 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Buffer)             | 0.9           | 3.0 (1.20 Gb/s)  | 4.8 (0.75 Gb/s)  | 0.0     | 8.8 (0.41 Gb/s)   | 3894341 (3.7 Mb)   |
| test_repeated_floats (Default)            | 1.8           | 0.7 (5.59 Gb/s)  | 0.4 (9.30 Gb/s)  | 0.1     | 3.1 (1.20 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)              | 0.8           | 0.1 (39.88 Gb/s) | 0.1 (32.30 Gb/s) | 0.0     | 1.1 (3.49 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Buffer)             | 0.8           | 0.1 (41.80 Gb/s) | 0.1 (31.70 Gb/s) | 0.0     | 1.1 (3.50 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings (Default)           | 116.6         | 14.1 (2.43 Gb/s) | 10.6 (3.25 Gb/s) | 4.2     | 146.3 (0.23 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)             | 113.5         | 10.4 (3.30 Gb/s) | 7.3 (4.70 Gb/s)  | 3.8     | 135.3 (0.25 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Buffer)            | 114.2         | 7.4 (4.66 Gb/s)  | 7.3 (4.70 Gb/s)  | 3.8     | 134.3 (0.26 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints (Default)         | 43.4          | 14.4 (0.64 Gb/s) | 50.5 (0.18 Gb/s) | 0.5     | 109.5 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)           | 38.4          | 13.3 (0.70 Gb/s) | 46.4 (0.20 Gb/s) | 0.0     | 98.6 (0.09 Gb/s)  | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Buffer)          | 38.6          | 7.1 (1.31 Gb/s)  | 45.9 (0.20 Gb/s) | 0.0     | 92.0 (0.10 Gb/s)  | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings (Default) | 59.8          | 18.8 (2.60 Gb/s) | 22.7 (2.15 Gb/s) | 5.2     | 106.8 (0.46 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena)   | 56.3          | 17.2 (2.84 Gb/s) | 19.9 (2.45 Gb/s) | 4.6     | 98.2 (0.50 Gb/s)  | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Buffer)  | 56.1          | 15.4 (3.18 Gb/s) | 19.5 (2.50 Gb/s) | 4.6     | 96.3 (0.51 Gb/s)  | 52480857 (50.0 Mb) |
| test_submessages (Default)                | 14.9          | 30.3 (1.08 Gb/s) | 55.4 (0.59 Gb/s) | 0.6     | 101.7 (0.32 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                  | 8.4           | 28.1 (1.16 Gb/s) | 46.6 (0.70 Gb/s) | 0.0     | 83.4 (0.39 Gb/s)  | 35000026 (33.4 Mb) |
| test_submessages (Buffer)                 | 8.4           | 13.2 (2.47 Gb/s) | 46.9 (0.70 Gb/s) | 0.0     | 68.6 (0.48 Gb/s)  | 35000026 (33.4 Mb) |
