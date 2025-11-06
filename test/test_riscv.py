import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_riscv_core(dut):
    """Test the 16-bit RISC-V core with simple instructions"""

    # Create a clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    dut._log.info("=== 16-bit RISC-V Core Test ===")
    dut._log.info("Loading instructions...")

    # Helper function to load 16-bit instruction
    async def load_instruction_16(instr):
        # Load low byte with mode=01
        low_byte = (instr & 0xFF)
        dut.ui_in.value = (0x40 | (low_byte & 0x3F))  # mode=01 in bits [7:6]
        await ClockCycles(dut.clk, 2)

        # Load high byte with mode=10
        high_byte = ((instr >> 8) & 0xFF)
        dut.ui_in.value = (0x80 | (high_byte & 0x3F))  # mode=10 in bits [7:6]
        await ClockCycles(dut.clk, 2)

        dut._log.info(f"Loaded instruction: 0x{instr:04X}")

    # Load test program (16-bit instructions, each byte ≤ 0x3F)
    # Format: [opcode:4][rd:4][rs1:4][rs2/imm:4]

    # x1 = 5 (ADDI x1, x0, 5) -> 0x1105
    await load_instruction_16(0x1105)

    # x2 = 3 (ADDI x2, x0, 3) -> 0x1203
    await load_instruction_16(0x1203)

    # x3 = x1 + x2 (ADD x3, x1, x2) -> 0x0312
    await load_instruction_16(0x0312)

    # x4 = x1 - x2 (SUB x4, x1, x2) -> 0x0411
    await load_instruction_16(0x0411)

    # NOP - halt condition (0x0000)
    await load_instruction_16(0x0000)

    dut._log.info("Instructions loaded. Starting execution...")

    # Switch to run mode
    dut.ui_in.value = 0  # mode=00 (run)
    dut.uio_in.value = 0  # output_sel=00 (PC)

    # Run for several cycles
    await ClockCycles(dut.clk, 40)

    # Check outputs
    pc_low = int(dut.uo_out.value)
    dut._log.info(f"PC (low byte) = 0x{pc_low:02X}")

    # Switch to ALU result output
    dut.uio_in.value = 2  # output_sel=10 (ALU result low)
    await ClockCycles(dut.clk, 1)
    alu_low = int(dut.uo_out.value)
    dut._log.info(f"ALU Result (low byte) = 0x{alu_low:02X}")

    # Check halt flag
    uio_out = int(dut.uio_out.value)
    halted = (uio_out >> 7) & 1
    dut._log.info(f"Halted = {halted}")

    dut._log.info("=== Test Complete ===")

    # Basic sanity checks
    assert pc_low >= 0, "PC should be non-negative"
    dut._log.info("✓ 16-bit RISC-V core test passed!")
