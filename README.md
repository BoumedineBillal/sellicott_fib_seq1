![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# 16-bit RISC-V Core for Tiny Tapeout

A compact 16-bit RISC-V processor core implementing a simplified instruction set, designed to fit within Tiny Tapeout's 3x2 tile configuration.

## Features

- **Architecture**: 16-bit RISC-V-inspired design
- **Design**: Single-cycle execution
- **Register File**: 16 x 16-bit registers (x0 hardwired to 0)
- **ALU Operations**: ADD, SUB, AND, OR, XOR, SLL (Shift Left Logical)
- **Instructions Supported**:
  - R-type: ADD, SUB, AND, OR, XOR, SLL (operation encoded in rs2 field)
  - I-type: ADDI (Add Immediate)
  - U-type: LUI (Load Upper Immediate)
  - B-type: BEQ (Branch if Equal), BNE (Branch if Not Equal)
  - J-type: JAL (Jump and Link)
- **Internal Instruction Memory**: 32 x 16-bit words (64 bytes)
- **Clock Frequency**: 50 MHz (20ns period)
- **Tile Configuration**: 3x2 (6x standard tile area, ~6000 standard cells)

## Architecture

The core is implemented as a single integrated module for area efficiency:

1. **riscv_core.v**: Complete processor with fetch, decode, execute, and writeback
2. **tt_um_riscv_core.v**: Tiny Tapeout wrapper for I/O mapping

### Block Diagram

```
┌─────────────────────────────────────────────────┐
│  Tiny Tapeout Wrapper (tt_um_riscv_core)       │
│  ┌───────────────────────────────────────────┐ │
│  │  RISC-V Core (riscv_core)                 │ │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────┐ │ │
│  │  │ Register │  │   ALU    │  │ Control │ │ │
│  │  │ File 16x │  │  6 ops   │  │  Logic  │ │ │
│  │  │  16-bit  │  │          │  │         │ │ │
│  │  └──────────┘  └──────────┘  └─────────┘ │ │
│  │  ┌────────────────────────────────────┐   │ │
│  │  │  Instruction Memory (32 words)     │   │ │
│  │  └────────────────────────────────────┘   │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## Instruction Format

16-bit compressed instruction format:

```
R-type: [opcode:4][rd:4][rs1:4][rs2:4]
I-type: [opcode:4][rd:4][rs1:4][imm:4]
U-type: [opcode:4][rd:4][imm:8]
B-type: [opcode:4][----:4][rs1:4][rs2:4]  (imm in upper bits)
J-type: [opcode:4][rd:4][imm:8]
```

### Opcodes

- `0000`: R-type (operation in rs2: 0=ADD, 1=SUB, 2=AND, 3=OR, 4=XOR, 5=SLL)
- `0001`: ADDI (Add Immediate)
- `0010`: LUI (Load Upper Immediate)
- `0011`: BEQ (Branch if Equal)
- `0100`: BNE (Branch if Not Equal)
- `0101`: JAL (Jump and Link)

## I/O Interface

The design uses Tiny Tapeout's I/O pins through a serial instruction loading interface:

### Input Pins (ui_in[7:0])
- **ui_in[7:6]**: Mode select
  - `00`: Run mode (execute instructions)
  - `01`: Load instruction low byte
  - `10`: Load instruction high byte
  - `11`: Reserved
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
- **uio_out[7]**: Halt flag (output mode)

## Usage

### Loading Instructions

Instructions must be loaded into internal memory before execution. Each 16-bit instruction requires 2 loading cycles:

1. Set mode to `01` and provide low byte [7:0] via ui_in[5:0] + address
2. Set mode to `10` and provide high byte [15:8]

### Running Programs

After loading instructions, set mode to `00` to begin execution. The processor will execute until:
- It reaches the end of instruction memory (PC >= 64)
- It encounters a NOP instruction (`0x0000`)
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

Encoded instructions (16-bit):
```
0x1105  # ADDI x1, x0, 5
0x1203  # ADDI x2, x0, 3
0x0312  # ADD x3, x1, x2 (R-type, op=0)
0x0421  # SUB x4, x1, x2 (R-type, op=1)
0x0522  # AND x5, x1, x2 (R-type, op=2)
0x0000  # NOP (halt)
```

## Testing

The project includes both Verilog and cocotb Python testbenches:

- **test/tb.v**: Verilog testbench for simulation
- **test/test.py**: cocotb Python testbench for GitHub Actions

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
gtkwave test.vcd
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
- **Register File**: 256 flip-flops (16 registers × 16 bits)
- **Instruction Memory**: 512 bits (32 × 16-bit words)
- **ALU**: Combinational logic for 6 operations
- **Control Logic**: Instruction decoder and control signals
- **Total**: ~70-80% utilization of 3x2 tile (within budget)

### Timing

- **Clock Period**: 20ns (50 MHz)
- **Critical Path**: Register file → ALU → Register file writeback
- **Target**: Single-cycle execution for all supported instructions

### Limitations

- 16-bit data width (reduced from standard 32-bit RISC-V)
- 16 registers only (vs. 32 in RV32I)
- No data memory (Load/Store instructions not implemented)
- No multiplication/division (M extension)
- No interrupts or exceptions
- No CSR (Control and Status Registers)
- Limited instruction memory (32 words = 64 bytes)
- Serial instruction loading only (no external program memory)
- Simplified instruction set

## Design Tradeoffs

This design prioritizes **fitting within Tiny Tapeout constraints** while maintaining a functional processor:

- **16-bit vs 32-bit**: Reduces register file and datapath size by 50%
- **16 vs 32 registers**: Saves ~50% of register file area
- **Integrated design**: Single module eliminates inter-module routing overhead
- **3x2 tiles**: Maximum available space for more features while fitting constraints

## Future Improvements

Possible enhancements for larger tile sizes or future iterations:
- Expand to 32-bit datapath
- Add full 32-register file
- Implement data memory interface
- Add more RISC-V instructions (shifts, comparisons)
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
