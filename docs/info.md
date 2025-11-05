<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a simple 32-bit RISC-V processor core (RV32I subset) designed to fit within a Tiny Tapeout tile. The core features:

### Architecture

The processor uses a **single-cycle design** where each instruction completes in one clock cycle. It consists of:

1. **Register File**: 32 general-purpose registers (x0-x31), where x0 is hardwired to zero
2. **ALU**: Performs arithmetic and logic operations (ADD, SUB, AND, OR, XOR, shifts, comparisons)
3. **Control Unit**: Decodes instructions and generates control signals
4. **Instruction Memory**: Internal 64-word (256 byte) instruction storage

### Supported Instructions

**R-Type (Register-Register):**
- ADD, SUB, AND, OR, XOR
- SLT (Set Less Than), SLTU (Set Less Than Unsigned)
- SLL (Shift Left Logical), SRL (Shift Right Logical), SRA (Shift Right Arithmetic)

**I-Type (Immediate):**
- ADDI, ANDI, ORI, XORI, SLTI, SLTIU

**U-Type (Upper Immediate):**
- LUI (Load Upper Immediate)
- AUIPC (Add Upper Immediate to PC)

**B-Type (Branch):**
- BEQ (Branch if Equal), BNE (Branch if Not Equal)
- BLT (Branch if Less Than), BGE (Branch if Greater or Equal)

**J-Type (Jump):**
- JAL (Jump and Link)

### Execution Flow

1. **Fetch**: Read instruction from internal memory using program counter (PC)
2. **Decode**: Extract opcode, registers, and immediate values
3. **Execute**: Perform ALU operation or compute branch target
4. **Write-back**: Store result to destination register (if applicable)
5. **Update PC**: Increment by 4 or jump to branch/jump target

### Tiny Tapeout Integration

Due to limited I/O pins (8 inputs, 8 outputs, 8 bidirectional), the design uses a **serial instruction loading interface**:

- Instructions are loaded byte-by-byte through the input pins
- Output pins can display PC or ALU results (selected via control bits)
- The processor halts when reaching a NOP instruction or end of memory

## How to test

### Loading a Program

Before running, you must load instructions into the internal memory:

1. **Set mode bits** (ui_in[7:6]):
   - `01`: Load byte 0 (LSB)
   - `10`: Load byte 1
   - `11`: Load byte 2 or 3

2. **Provide data** through ui_in[5:0]

3. **Repeat** for each byte of each instruction

4. **Switch to run mode** (ui_in[7:6] = `00`)

### Example Test Sequence

Load this simple program:
```
ADDI x1, x0, 5    # x1 = 5      (0x00500093)
ADDI x2, x0, 3    # x2 = 3      (0x00300113)
ADD  x3, x1, x2   # x3 = 8      (0x002081B3)
SUB  x4, x1, x2   # x4 = 2      (0x40208233)
NOP               # Halt        (0x00000013)
```

### Monitoring Execution

Use the bidirectional pins (uio_in[1:0]) to select output:
- `00`: View PC low byte
- `01`: View PC high byte
- `10`: View ALU result low byte
- `11`: View ALU result high byte

The halt flag (uio_out[7]) goes high when execution stops.

### Running Tests

The project includes automated tests:

**Verilog Testbench (local):**
```bash
cd test
iverilog -o sim tb_riscv.v ../src/*.v
./sim
gtkwave tb_riscv.vcd
```

**cocotb Testbench (CI/CD):**
```bash
cd test
make
```

## External hardware

No external hardware is required for basic operation. The core runs entirely on-chip with internal instruction memory.

### Optional Additions

For extended functionality, you could add:

- **External instruction memory**: Use bidirectional pins to implement a memory interface
- **Debug LEDs**: Connect output pins to LEDs to visualize PC or ALU results
- **Input switches**: Use for manual instruction loading or control
- **Serial interface**: Implement UART for program loading and debugging

### Example Setup

```
Tiny Tapeout Chip
┌─────────────────┐
│  ui_in[7:0]    │ ← DIP switches (mode + data)
│  uo_out[7:0]   │ → LEDs (PC or ALU result)
│  uio[7:0]      │ ↔ Control switches / status LEDs
└─────────────────┘
```

## Pin Mapping

| Pin | Direction | Name | Description |
|-----|-----------|------|-------------|
| ui_in[7:6] | Input | mode[1:0] | Operation mode select |
| ui_in[5:0] | Input | data[5:0] | Data/address input |
| uo_out[7:0] | Output | output[7:0] | Multiplexed output (PC/ALU) |
| uio[1:0] | Input | out_sel[1:0] | Output selection control |
| uio[6:2] | Output | rd_addr[4:0] | Destination register address |
| uio[7] | Output | halted | Halt status flag |

## Clock and Reset

- **Clock**: 50 MHz (20ns period) recommended
- **Reset**: Active-low synchronous reset (rst_n)
- **Enable**: Active-high enable signal (ena)
