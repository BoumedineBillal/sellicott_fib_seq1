<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a compact **16-bit RISC-V processor core** designed to fit within Tiny Tapeout's 3x2 tile configuration (~6000 standard cells). The core features:

### Architecture

The processor uses a **single-cycle design** where each instruction completes in one clock cycle. It consists of:

1. **Register File**: 16 general-purpose registers (x0-x15), where x0 is hardwired to zero
2. **ALU**: Performs 6 operations: ADD, SUB, AND, OR, XOR, SLL (shift left logical)
3. **Control Unit**: Decodes instructions and generates control signals
4. **Instruction Memory**: Internal 32-word (64 byte) instruction storage

All components are integrated into a single `riscv_core.v` module for optimal area utilization.

### Data Width

- **16-bit** data width (reduced from standard 32-bit RISC-V)
- **16 registers** instead of 32 (saves ~50% of register file area)
- **16-bit instructions** with custom compressed format

This allows the design to fit within Tiny Tapeout constraints while maintaining full processor functionality.

### Supported Instructions

**R-Type (Register-Register):**
- ADD, SUB, AND, OR, XOR, SLL
- Format: `[opcode:4][rd:4][rs1:4][rs2:4]`
- Operation encoded in rs2 field (0=ADD, 1=SUB, 2=AND, 3=OR, 4=XOR, 5=SLL)

**I-Type (Immediate):**
- ADDI (Add Immediate)
- Format: `[opcode:4][rd:4][rs1:4][imm:4]`
- 4-bit immediate, sign-extended to 16 bits

**U-Type (Upper Immediate):**
- LUI (Load Upper Immediate)
- Format: `[opcode:4][rd:4][imm:8]`
- Loads 8-bit immediate into upper half of register

**B-Type (Branch):**
- BEQ (Branch if Equal), BNE (Branch if Not Equal)
- Format: `[opcode:4][reserved:4][rs1:4][rs2:4]`
- Branch target computed from sign-extended immediate

**J-Type (Jump):**
- JAL (Jump and Link)
- Format: `[opcode:4][rd:4][imm:8]`
- Saves return address (PC+2) to rd

### Execution Flow

1. **Fetch**: Read 16-bit instruction from internal memory using program counter (PC)
2. **Decode**: Extract opcode, register addresses, and immediate values
3. **Execute**: Perform ALU operation or compute branch target
4. **Write-back**: Store result to destination register (if applicable)
5. **Update PC**: Increment by 2 (word-aligned) or jump to branch/jump target

### Tiny Tapeout Integration

Due to limited I/O pins (8 inputs, 8 outputs, 8 bidirectional), the design uses a **serial instruction loading interface**:

- Instructions are loaded byte-by-byte through the input pins before execution
- Output pins can display PC or ALU results (selected via control bits)
- The processor halts when reaching a NOP instruction (`0x0000`) or end of memory

### Tile Configuration

The design uses a **3x2 tile** configuration (6x standard tile area), which provides approximately:
- 6000 standard cells
- Sufficient for 16 registers × 16 bits + 32-word instruction memory + control logic
- Estimated 70-80% utilization (within synthesis constraints)

## How to test

### Loading a Program

Before running, you must load instructions into the internal memory:

1. **Set mode bits** (ui_in[7:6]):
   - `00`: Run mode (execute program)
   - `01`: Load instruction low byte [7:0]
   - `10`: Load instruction high byte [15:8]

2. **Provide data** through ui_in[5:0] (data/address bits)

3. **Repeat** for each byte of each instruction

4. **Switch to run mode** (ui_in[7:6] = `00`)

### Example Test Sequence

Load this simple program:
```
ADDI x1, x0, 5    # x1 = 5      (0x1105)
ADDI x2, x0, 3    # x2 = 3      (0x1203)
ADD  x3, x1, x2   # x3 = 8      (0x0312)
SUB  x4, x1, x2   # x4 = 2      (0x0421)
AND  x5, x1, x2   # x5 = 1      (0x0522)
NOP               # Halt        (0x0000)
```

**Loading steps:**
1. Load 0x1105: low byte 0x05, high byte 0x11
2. Load 0x1203: low byte 0x03, high byte 0x12
3. Load 0x0312: low byte 0x12, high byte 0x03
4. Load 0x0421: low byte 0x21, high byte 0x04
5. Load 0x0522: low byte 0x22, high byte 0x05
6. Load 0x0000: low byte 0x00, high byte 0x00
7. Set mode to `00` to run

### Monitoring Execution

Use the bidirectional pins (uio_in[1:0]) to select output:
- `00`: View PC[7:0] (low byte of program counter)
- `01`: View PC[15:8] (high byte of program counter)
- `10`: View ALU result[7:0] (low byte)
- `11`: View ALU result[15:8] (high byte)

The halt flag (uio_out[7]) goes high when execution stops.

### Expected Results

After running the example program:
- x1 = 5
- x2 = 3
- x3 = 8 (5 + 3)
- x4 = 2 (5 - 3)
- x5 = 1 (5 & 3)
- Halt flag = 1

You can observe the ALU output changing as each instruction executes by selecting ALU result display mode.

### Running Automated Tests

The project includes automated tests:

**Verilog Testbench (local simulation):**
```bash
cd test
iverilog -o sim tb.v ../src/*.v
./sim
gtkwave test.vcd
```

**cocotb Testbench (CI/CD):**
```bash
cd test
make
```

The cocotb tests verify:
- Instruction loading mechanism
- Basic arithmetic operations (ADD, SUB)
- Logic operations (AND, OR, XOR)
- Branch instructions (BEQ, BNE)
- Jump instructions (JAL)
- Halt functionality

## External hardware

No external hardware is required for basic operation. The core runs entirely on-chip with internal instruction memory.

### Optional Additions

For extended functionality, you could add:

- **External instruction memory**: Use bidirectional pins to implement a memory interface for larger programs
- **Debug LEDs**: Connect output pins to LEDs to visualize PC or ALU results in real-time
- **Input switches**: Use DIP switches for manual instruction loading or mode control
- **Serial interface**: Implement UART for convenient program loading and debugging
- **Seven-segment display**: Display register values or PC in hexadecimal

### Example Setup

```
Tiny Tapeout Chip
┌─────────────────────┐
│  ui_in[7:6]  ←──┐  │  Mode select switches
│  ui_in[5:0]  ←──┘  │  Data/address input switches
│                     │
│  uo_out[7:0] ───→   │  8 LEDs (PC or ALU result)
│                     │
│  uio[1:0]    ←──┐  │  Output select switches
│  uio[7]      ───→   │  Halt indicator LED
└─────────────────────┘
```

## Pin Mapping

| Pin | Direction | Name | Description |
|-----|-----------|------|-------------|
| ui_in[7:6] | Input | mode[1:0] | Operation mode: 00=Run, 01=Load low, 10=Load high |
| ui_in[5:0] | Input | data[5:0] | Data/address input (mode-dependent) |
| uo_out[7:0] | Output | output[7:0] | Multiplexed output (PC or ALU result) |
| uio[1:0] | Input | out_sel[1:0] | Output selection: 00=PC low, 01=PC high, 10=ALU low, 11=ALU high |
| uio[7] | Output | halted | Halt status flag (high when stopped) |
| uio[6:2] | Output | (unused) | Reserved for future use |

## Clock and Reset

- **Clock**: 50 MHz (20ns period) recommended, supports up to ~100 MHz
- **Reset**: Active-low asynchronous reset (rst_n)
- **Enable**: Active-high enable signal (ena) - must be high for operation

## Design Constraints

The design is optimized for Tiny Tapeout's constraints:

- **Tile size**: 3x2 (160µm × 100µm per tile = 320µm × 200µm total)
- **Standard cells**: ~6000 cells available, ~70-80% utilized
- **Area optimizations**:
  - 16-bit instead of 32-bit datapath (50% reduction)
  - 16 registers instead of 32 (50% reduction)
  - Integrated single-module design (minimal routing overhead)
  - Compressed 16-bit instruction format (50% memory reduction)

## Performance

- **Clock frequency**: 50 MHz (20ns period)
- **Instructions per second**: Up to 50 million (1 instruction per cycle)
- **Program memory**: 32 instructions maximum
- **Execution model**: Single-cycle (no pipeline stalls)

## Limitations

- 16-bit data width (non-standard for RISC-V)
- Limited to 16 registers (x0-x15)
- No data memory - Load/Store instructions not implemented
- No multiplication/division
- No interrupts or exceptions
- Small instruction memory (32 words)
- Serial instruction loading (slower than direct memory interface)

These tradeoffs enable the design to fit within Tiny Tapeout constraints while maintaining a functional processor core.
