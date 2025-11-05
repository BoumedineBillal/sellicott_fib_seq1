![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# Simple 32-bit RISC-V Core for Tiny Tapeout

A minimal 32-bit RISC-V processor core implementing a subset of the RV32I instruction set, designed to fit within a Tiny Tapeout tile.

## Features

- **Architecture**: 32-bit RISC-V (RV32I subset)
- **Design**: Single-cycle execution
- **Register File**: 32 x 32-bit registers (x0 hardwired to 0)
- **ALU Operations**: ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA
- **Instructions Supported**:
  - R-type: ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA
  - I-type: ADDI, ANDI, ORI, XORI, SLTI, SLTIU
  - U-type: LUI, AUIPC
  - B-type: BEQ, BNE, BLT, BGE
  - J-type: JAL
- **Internal Instruction Memory**: 64 x 32-bit words (256 bytes)
- **Clock Frequency**: 50 MHz (20ns period)

## Architecture

The core consists of four main modules:

1. **riscv_core.v**: Main processor with fetch, decode, execute stages
2. **riscv_alu.v**: Arithmetic Logic Unit
3. **riscv_regfile.v**: 32-register file with x0 hardwired to zero
4. **tt_um_riscv_core.v**: Tiny Tapeout wrapper for I/O mapping

### Block Diagram

```
┌─────────────────────────────────────────────────┐
│  Tiny Tapeout Wrapper (tt_um_riscv_core)       │
│  ┌───────────────────────────────────────────┐ │
│  │  RISC-V Core (riscv_core)                 │ │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────┐ │ │
│  │  │ Register │  │   ALU    │  │ Control │ │ │
│  │  │   File   │  │          │  │  Logic  │ │ │
│  │  └──────────┘  └──────────┘  └─────────┘ │ │
│  │  ┌────────────────────────────────────┐   │ │
│  │  │  Instruction Memory (64 words)     │   │ │
│  │  └────────────────────────────────────┘   │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## I/O Interface

The design uses Tiny Tapeout's limited I/O pins through a serial instruction loading interface:

### Input Pins (ui_in[7:0])
- **ui_in[7:6]**: Mode select
  - `00`: Run mode (execute instructions)
  - `01`: Load instruction byte 0 (LSB)
  - `10`: Load instruction byte 1
  - `11`: Load instruction bytes 2-3 and commit
- **ui_in[5:0]**: Data/address input (mode-dependent)

### Output Pins (uo_out[7:0])
- Multiplexed output showing:
  - PC[7:0] or PC[15:8] (program counter)
  - ALU_result[7:0] or ALU_result[15:8]
  - Selection controlled by uio_in[1:0]

### Bidirectional Pins (uio[7:0])
- **uio_in[1:0]**: Output select (input mode)
  - `00`: Show PC[7:0]
  - `01`: Show PC[15:8]
  - `10`: Show ALU result[7:0]
  - `11`: Show ALU result[15:8]
- **uio_out[6:2]**: Destination register address (rd) (output mode)
- **uio_out[7]**: Halt flag (output mode)

## Usage

### Loading Instructions

Instructions must be loaded into internal memory before execution. Each 32-bit instruction requires 4 loading cycles:

1. Set mode to `01` and provide bits [5:0] of instruction
2. Set mode to `10` and provide bits [13:8] of instruction
3. Set mode to `11` and provide bits [21:16] of instruction
4. Set mode to `11` and provide bits [29:24] of instruction (triggers write)

### Running Programs

After loading instructions, set mode to `00` to begin execution. The processor will execute until:
- It reaches the end of instruction memory
- It encounters a NOP instruction (`0x00000013`)
- The halt flag is set

### Example Program

```assembly
# Simple addition program
ADDI x1, x0, 5      # x1 = 5
ADDI x2, x0, 3      # x2 = 3
ADD  x3, x1, x2     # x3 = x1 + x2 = 8
SUB  x4, x1, x2     # x4 = x1 - x2 = 2
AND  x5, x1, x2     # x5 = x1 & x2 = 1
NOP                 # Halt
```

Encoded instructions:
```
0x00500093  # ADDI x1, x0, 5
0x00300113  # ADDI x2, x0, 3
0x002081B3  # ADD x3, x1, x2
0x40208233  # SUB x4, x1, x2
0x0020F2B3  # AND x5, x1, x2
0x00000013  # NOP (halt)
```

## Testing

The project includes both Verilog and cocotb Python testbenches:

- **test/tb_riscv.v**: Verilog testbench for Icarus Verilog simulation
- **test/test_riscv.py**: cocotb Python testbench for GitHub Actions

### Running Tests Locally

With [OSS-CAD-Suite](https://github.com/YosysHQ/oss-cad-suite-build) installed:

```bash
cd test
make clean
make
```

This will run the cocotb testbench and generate a VCD waveform file.

### Viewing Waveforms

```bash
gtkwave tb_riscv.vcd
```

## Building for Tiny Tapeout

The design is configured for automatic GDS generation through GitHub Actions. Push to your repository and the workflow will:

1. Run RTL simulation tests
2. Synthesize the design with OpenLane
3. Generate GDS layout
4. Run precheck and DRC
5. Create documentation

## Implementation Details

### Area Utilization

The RISC-V core uses approximately:
- **Register File**: ~1024 flip-flops (32 registers × 32 bits)
- **Instruction Memory**: 2048 bits (64 × 32-bit words)
- **ALU**: Combinational logic for 10 operations
- **Control Logic**: Instruction decoder and control signals

### Timing

- **Clock Period**: 20ns (50 MHz)
- **Critical Path**: Register file → ALU → Register file writeback
- **Target**: Single-cycle execution for all supported instructions

### Limitations

- No data memory (Load/Store instructions not implemented)
- No multiplication/division (M extension)
- No interrupts or exceptions
- No CSR (Control and Status Registers)
- Limited instruction memory (64 words)
- Serial instruction loading only (no external program memory)

## Future Improvements

Possible enhancements for larger tile sizes:
- Add data memory interface
- Implement JALR instruction
- Add M extension (multiply/divide)
- Multi-cycle or pipelined execution
- External memory interface
- Interrupt support

## Resources

- [RISC-V Specification](https://riscv.org/technical/specifications/)
- [Tiny Tapeout Documentation](https://tinytapeout.com/)
- [OpenLane Documentation](https://openlane.readthedocs.io/)

## License

This project is open source. See LICENSE for details.

## Author

Created for Tiny Tapeout submission.
