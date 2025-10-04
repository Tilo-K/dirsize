# dirsize

`dirsize` is a simple CLI tool to quickly display the total size of a directory and its contents.

## Features

- Recursively calculates the total size of a directory
- Human-readable output (e.g., KB, MB, GB)
- Fast and easy to use

## Installation

```sh
# Clone the repository
git clone https://github.com/yourusername/dirsize.git
cd dirsize

# Build the executable with Zig
zig build-exe ./src/main.zig -O ReleaseFast --name dirsize
```

## Windows

The performance of `dirsize` can be severely impacted by Windows defender real-time protection. With real-time protection enabled you can expect around 41x slowdowns.

But at least you are secure :)
