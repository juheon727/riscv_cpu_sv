import sys
from pathlib import Path

input_file = sys.argv[1]
output_file = sys.argv[2]

data = Path(input_file).read_bytes()

if len(data) % 4:
    raise ValueError("Machine code is not a multiple of 4 bytes")

with open(output_file, "w") as f:
    for i in range(0, len(data), 4):
        word = int.from_bytes(data[i:i+4], "little")
        f.write(f"{word:08X}\n")