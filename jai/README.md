# Jai Protobuf Results

Compiled with

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
| Release    | 2.496                |

## Run times (Release)

The best time is recorded for each section. All times are in *milliseconds*.

| Procedure                               | Create Object | Serialize         | Deserialize       | Cleanup | Total             | Bytes              |
| ---                                     | ---           | ---               | ---               | ---     | ---               | ---                |
| test_memcopy                            | 0.0           | 0.7 (5.89 Gb/s)   | 0.1 (46.39 Gb/s)  | 0.2     | 2.4 (1.63 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.0           | 0.1 (47.15 Gb/s)  | 0.1 (47.58 Gb/s)  | 0.0     | 0.4 (9.44 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 3.5           | 10.5 (0.34 Gb/s)  | 10.4 (0.34 Gb/s)  | 0.2     | 26.5 (0.13 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 3.3           | 11.0 (0.32 Gb/s)  | 9.6 (0.37 Gb/s)   | 0.0     | 24.8 (0.14 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 3.8           | 12.4 (0.29 Gb/s)  | 11.3 (0.32 Gb/s)  | 0.2     | 28.1 (0.13 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 3.1           | 11.3 (0.32 Gb/s)  | 10.2 (0.36 Gb/s)  | 0.0     | 26.2 (0.14 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 4.8           | 0.7 (5.64 Gb/s)   | 0.4 (9.00 Gb/s)   | 0.1     | 6.2 (0.61 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 3.8           | 0.1 (41.56 Gb/s)  | 0.1 (32.08 Gb/s)  | 0.0     | 4.0 (0.93 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 123.9         | 24.3 (1.42 Gb/s)  | 27.9 (1.23 Gb/s)  | 4.0     | 180.8 (0.19 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 120.6         | 21.4 (1.61 Gb/s)  | 24.7 (1.39 Gb/s)  | 3.6     | 170.3 (0.20 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 46.6          | 55.3 (0.17 Gb/s)  | 83.0 (0.11 Gb/s)  | 0.4     | 188.1 (0.05 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 42.8          | 54.3 (0.17 Gb/s)  | 79.7 (0.12 Gb/s)  | 0.0     | 178.6 (0.05 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 60.1          | 35.7 (1.37 Gb/s)  | 31.2 (1.57 Gb/s)  | 5.1     | 132.5 (0.37 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 57.3          | 33.7 (1.45 Gb/s)  | 28.1 (1.74 Gb/s)  | 4.5     | 123.8 (0.39 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                        | 17.7          | 110.1 (0.30 Gb/s) | 122.9 (0.27 Gb/s) | 0.5     | 252.6 (0.13 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 10.3          | 107.8 (0.30 Gb/s) | 114.3 (0.29 Gb/s) | 0.0     | 233.2 (0.14 Gb/s) | 35000026 (33.4 Mb) |

Disabling asserts produce a noticable improvement with strings, maps and
submessages. Tested with:
```jai
#import "Basic"()(ENABLE_ASSERT=false);
```

| Procedure                               | Create Object | Serialize        | Deserialize      | Cleanup | Total             | Bytes              |
| ---                                     | ---           | ---              | ---              | ---     | ---               | ---                |
| test_memcopy                            | 0.0           | 0.7 (5.75 Gb/s)  | 0.1 (44.06 Gb/s) | 0.2     | 2.2 (1.78 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.0           | 0.1 (47.13 Gb/s) | 0.1 (47.52 Gb/s) | 0.0     | 0.4 (9.34 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 1.7           | 12.0 (0.29 Gb/s) | 5.4 (0.65 Gb/s)  | 0.2     | 20.5 (0.17 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 0.9           | 10.7 (0.33 Gb/s) | 4.5 (0.78 Gb/s)  | 0.0     | 16.2 (0.22 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 1.7           | 13.8 (0.26 Gb/s) | 6.4 (0.56 Gb/s)  | 0.2     | 22.5 (0.16 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 0.9           | 11.3 (0.32 Gb/s) | 5.6 (0.65 Gb/s)  | 0.0     | 17.9 (0.20 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 1.7           | 0.7 (5.67 Gb/s)  | 0.3 (10.78 Gb/s) | 0.1     | 2.9 (1.27 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 0.8           | 0.1 (43.81 Gb/s) | 0.1 (37.84 Gb/s) | 0.0     | 1.0 (3.84 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 116.9         | 15.5 (2.22 Gb/s) | 10.2 (3.37 Gb/s) | 3.9     | 146.9 (0.23 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 113.9         | 12.8 (2.68 Gb/s) | 7.3 (4.72 Gb/s)  | 3.5     | 137.8 (0.25 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 42.0          | 31.9 (0.29 Gb/s) | 52.3 (0.18 Gb/s) | 0.4     | 129.2 (0.07 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 39.4          | 31.0 (0.30 Gb/s) | 49.7 (0.19 Gb/s) | 0.0     | 120.2 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 59.0          | 28.5 (1.71 Gb/s) | 23.0 (2.13 Gb/s) | 5.0     | 115.9 (0.42 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 55.5          | 26.2 (1.87 Gb/s) | 20.1 (2.43 Gb/s) | 4.4     | 106.4 (0.46 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                        | 14.7          | 66.0 (0.49 Gb/s) | 49.7 (0.66 Gb/s) | 0.6     | 132.1 (0.25 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 8.4           | 63.0 (0.52 Gb/s) | 41.6 (0.78 Gb/s) | 0.0     | 113.4 (0.29 Gb/s) | 35000026 (33.4 Mb) |
