# RISC-V CPU in SystemVerilog

`riscv_cpu_sv` is a small 64-bit RISC-V CPU implementation written in synthesizable SystemVerilog. It is intended for learning and simulation: the core exposes instruction- and data-memory interfaces, while the testbenches provide simple synchronous memories and example programs.

The repository contains two implementations of the same instruction subset:

- `multicycle_subset/` — a simple five-state implementation (`IF`, `ID`, `EX`, `MEM`, `WB`).
- `pipeline/` — a five-stage implementation with pipeline registers, forwarding, load-use stalling, and branch flushing.

## Supported instructions

The decoder currently supports this subset of RV64I:

| Encoding | Instructions |
| --- | --- |
| R-type | `ADD`, `SUB`, `AND`, `OR` |
| I-type arithmetic | `ADDI`, `ANDI`, `ORI` |
| Loads/stores | `LD`, `SD` |
| Conditional branch | `BEQ` |

Instructions outside this subset are flagged as illegal by the decoder. The register file has 32 64-bit registers, and writes to `x0` are suppressed.

## Repository layout

```text
multicycle_subset/       Multicycle core, decoder, ALU, register file, memory
pipeline/                Pipelined core and pipeline-control logic
testbench/core_tb.sv     Hand-built instruction-memory simulation
testbench/core_tb_bin.sv Hex-program simulation, useful for the pipeline variant
testbench/control_tb.sv  Decoder unit testbench
testbench/assembly/      Example assembly and bin-to-hex conversion script
Makefile                 Icarus Verilog build and run targets
LICENSE                  MIT license
```

## Requirements

- SystemVerilog simulator with `always_ff`, `always_comb`, packed structs, and parameterized types
- GNU Make
- Icarus Verilog (`iverilog`) for the supplied Makefile
- Optional: a RISC-V assembler/linker when generating a hex image from `testbench/assembly/ld_use.s`

## Run the supplied simulation

The default target builds and runs the multicycle implementation:

```sh
make run
```

Select the pipelined implementation with the `rtl` variable:

```sh
make rtl=pipeline run
```

The build writes its simulator executable to `out/sim.out`. The testbench prints selected register and ALU values and creates `dump.vcd`, which can be opened with a waveform viewer such as GTKWave.

To remove generated files:

```sh
rm -rf out
```

## Generate the binary test program

`testbench/assembly/ld_use.s` exercises an immediate operation, store, load, and dependent add:

```asm
addi x2, x0, 16
sd   x2, 0(x0)
ld   x3, 0(x0)
add  x1, x2, x3
```

After assembling and linking it to a flat binary, convert the binary to the line-oriented hex format consumed by `$readmemh`:

```sh
python3 testbench/assembly/bin2hex.py program.bin testbench/assembly/ld_use.hex
```

The binary testbench expects `testbench/assembly/ld_use.hex` and is compiled explicitly, for example:

```sh
mkdir -p out
iverilog -g2012 -o out/sim_bin.out \
  pipeline/*.sv testbench/core_tb_bin.sv
out/sim_bin.out
```

## Core interface

Both top-level implementations expose the `riscv64_core` module with the same interface:

```systemverilog
module riscv64_core (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr,
    output logic [63:0] imem_addr,
    output logic        imem_read,
    input  logic [63:0] dmem_fetch,
    output logic        dmem_read,
    output logic        dmem_write,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_data
);
```

Instruction memory supplies a 32-bit instruction at `imem_addr`; data memory returns or stores a 64-bit value using the `dmem_*` signals. Memory is synchronous in the supplied testbenches.

## Design notes and limitations

- This is a simulation/learning core; no FPGA constraints, board wrapper, or bus protocol is included.
- The pipelined design forwards ALU results and stalls on load-use dependencies. Branches are resolved in the execute path and flush younger instructions.
- The decoder does not yet implement jumps, other branches, upper-immediate instructions, shifts, comparisons, byte/word accesses, or CSR/system instructions.
- The external memory model is intentionally minimal and is not a complete byte-addressable RISC-V memory system.
- The Makefile currently builds `testbench/core_tb.sv`; the decoder and binary-program testbenches are available for explicit simulator invocations.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
