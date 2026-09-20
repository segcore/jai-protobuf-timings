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

| Procedure                               | Create Object | Serialize        | Deserialize      | Cleanup | Total             | Bytes              |
| ---                                     | ---           | ---              | ---              | ---     | ---               | ---                |
| test_memcopy                            | 0.0           | 0.7 (5.72 Gb/s)  | 0.1 (42.29 Gb/s) | 0.2     | 2.2 (1.79 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.0           | 0.1 (47.13 Gb/s) | 0.1 (47.46 Gb/s) | 0.0     | 0.4 (9.41 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 4.3           | 4.1 (0.87 Gb/s)  | 6.0 (0.59 Gb/s)  | 0.2     | 15.2 (0.23 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 3.6           | 3.6 (0.98 Gb/s)  | 5.2 (0.68 Gb/s)  | 0.0     | 12.6 (0.28 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 4.8           | 4.6 (0.79 Gb/s)  | 6.3 (0.57 Gb/s)  | 0.2     | 16.4 (0.22 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 3.9           | 3.9 (0.92 Gb/s)  | 5.5 (0.66 Gb/s)  | 0.0     | 13.3 (0.27 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 3.5           | 0.7 (5.71 Gb/s)  | 0.3 (10.89 Gb/s) | 0.1     | 4.7 (0.80 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 2.6           | 0.1 (43.87 Gb/s) | 0.1 (37.60 Gb/s) | 0.0     | 2.9 (1.28 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 123.6         | 13.8 (2.48 Gb/s) | 14.0 (2.46 Gb/s) | 4.0     | 156.6 (0.22 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 120.9         | 10.6 (3.24 Gb/s) | 11.1 (3.09 Gb/s) | 3.5     | 146.6 (0.23 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 45.3          | 14.3 (0.65 Gb/s) | 56.8 (0.16 Gb/s) | 0.4     | 118.6 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 41.7          | 13.5 (0.69 Gb/s) | 53.5 (0.17 Gb/s) | 0.0     | 109.7 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 59.4          | 19.1 (2.56 Gb/s) | 23.5 (2.08 Gb/s) | 5.1     | 107.3 (0.46 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 55.8          | 17.4 (2.81 Gb/s) | 20.6 (2.37 Gb/s) | 4.4     | 98.3 (0.50 Gb/s)  | 52480857 (50.0 Mb) |
| test_submessages                        | 17.7          | 35.3 (0.92 Gb/s) | 61.5 (0.53 Gb/s) | 0.5     | 115.6 (0.28 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 10.0          | 32.6 (1.00 Gb/s) | 52.9 (0.62 Gb/s) | 0.0     | 96.1 (0.34 Gb/s)  | 35000026 (33.4 Mb) |

Disabling asserts produces a small deserialization speed increase.
Tested with:
```jai
#import "Basic"()(ENABLE_ASSERT=false);
```

| Procedure                               | Create Object | Serialize        | Deserialize      | Cleanup | Total             | Bytes              |
| ---                                     | ---           | ---              | ---              | ---     | ---               | ---                |
| test_memcopy                            | 0.0           | 0.6 (6.40 Gb/s)  | 0.1 (48.12 Gb/s) | 0.2     | 1.9 (2.09 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.0           | 0.1 (47.11 Gb/s) | 0.1 (47.55 Gb/s) | 0.0     | 0.4 (9.43 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 1.9           | 4.2 (0.84 Gb/s)  | 5.0 (0.70 Gb/s)  | 0.2     | 11.9 (0.30 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 1.0           | 3.8 (0.92 Gb/s)  | 4.4 (0.81 Gb/s)  | 0.0     | 9.2 (0.38 Gb/s)   | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 1.7           | 4.4 (0.82 Gb/s)  | 5.5 (0.66 Gb/s)  | 0.2     | 12.4 (0.29 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 0.8           | 4.5 (0.81 Gb/s)  | 4.7 (0.77 Gb/s)  | 0.0     | 10.1 (0.36 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 1.6           | 0.7 (5.65 Gb/s)  | 0.3 (10.66 Gb/s) | 0.1     | 2.8 (1.34 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 0.8           | 0.1 (45.00 Gb/s) | 0.1 (39.63 Gb/s) | 0.0     | 0.9 (3.94 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 117.9         | 12.0 (2.86 Gb/s) | 10.1 (3.39 Gb/s) | 4.0     | 146.4 (0.23 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 114.2         | 11.1 (3.10 Gb/s) | 7.3 (4.68 Gb/s)  | 3.5     | 137.3 (0.25 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 41.2          | 13.8 (0.67 Gb/s) | 49.3 (0.19 Gb/s) | 0.4     | 105.8 (0.09 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 36.7          | 12.9 (0.72 Gb/s) | 45.0 (0.21 Gb/s) | 0.0     | 94.8 (0.10 Gb/s)  | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 58.3          | 18.6 (2.63 Gb/s) | 22.6 (2.16 Gb/s) | 5.1     | 104.7 (0.47 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 54.9          | 16.9 (2.89 Gb/s) | 19.7 (2.48 Gb/s) | 4.4     | 96.1 (0.51 Gb/s)  | 52480857 (50.0 Mb) |
| test_submessages                        | 14.5          | 32.2 (1.01 Gb/s) | 54.3 (0.60 Gb/s) | 0.5     | 102.0 (0.32 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 8.4           | 29.1 (1.12 Gb/s) | 46.1 (0.71 Gb/s) | 0.0     | 83.6 (0.39 Gb/s)  | 35000026 (33.4 Mb) |
