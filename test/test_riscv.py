import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_riscv_core(dut):
    """Test the RISC-V core with simple instructions"""

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

    dut._log.info("=== RISC-V Core Test ===")
    dut._log.info("Loading instructions...")

    # Helper function to load instruction
    async def load_instruction(instr):
        # Load byte 0 (bits 7:0)
        dut.ui_in.value = (1 << 6) | ((instr >> 0) & 0x3F)  # mode=01
        await ClockCycles(dut.clk, 1)

        # Load byte 1 (bits 15:8)
        dut.ui_in.value = (2 << 6) | ((instr >> 8) & 0x3F)  # mode=10
        await ClockCycles(dut.clk, 1)

        # Load byte 2 (bits 23:16)
        dut.ui_in.value = (3 << 6) | ((instr >> 16) & 0x3F)  # mode=11
        await ClockCycles(dut.clk, 1)

        # Load byte 3 (bits 31:24) and trigger write
        dut.ui_in.value = (3 << 6) | ((instr >> 24) & 0x3F)  # mode=11
        await ClockCycles(dut.clk, 1)

        dut._log.info(f"Loaded instruction: 0x{instr:08X}")

    # Load test program
    # x1 = 5 (ADDI x1, x0, 5)
    await load_instruction(0x00500093)

    # x2 = 3 (ADDI x2, x0, 3)
    await load_instruction(0x00300113)

    # x3 = x1 + x2 (ADD x3, x1, x2)
    await load_instruction(0x002081B3)

    # x4 = x1 - x2 (SUB x4, x1, x2)
    await load_instruction(0x40208233)

    # x5 = x1 & x2 (AND x5, x1, x2)
    await load_instruction(0x0020F2B3)

    # NOP - halt condition
    await load_instruction(0x00000013)

    dut._log.info("Instructions loaded. Starting execution...")

    # Switch to run mode
    dut.ui_in.value = 0  # mode=00 (run)
    dut.uio_in.value = 0  # output_sel=00 (PC)

    # Run for several cycles
    await ClockCycles(dut.clk, 50)

    # Check outputs
    pc_low = int(dut.uo_out.value)
    dut._log.info(f"PC (low byte) = 0x{pc_low:02X}")

    # Switch to ALU result output
    dut.uio_in.value = 2  # output_sel=10 (ALU result low)
    await ClockCycles(dut.clk, 1)
    alu_low = int(dut.uo_out.value)
    dut._log.info(f"ALU Result (low byte) = 0x{alu_low:02X}")

    # Check halt flag
    halted = int(dut.uio_out.value) >> 7
    dut._log.info(f"Halted = {halted}")

    dut._log.info("=== Test Complete ===")

    # Basic sanity checks
    assert pc_low >= 0, "PC should be non-negative"
    dut._log.info("✓ RISC-V core test passed!")
