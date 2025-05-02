import cocotb
from cocotb.clock import Clock
from cocotb.triggers import *

async def automated_test(dut, row, col):
    dut.row.value = row
    dut.col.value = col
    dut.w_val.value = 1
    dut.re.value = 0
    dut.we.value = 0
    dut.shift.value = 0

    dut.reset.value = 0

    cocotb.start_soon(Clock(dut.clock, 10, units="ns").start())

    # Reset the DUT
    dut.reset.value = 1
    await FallingEdge(dut.clock)
    await FallingEdge(dut.clock)
    dut.reset.value = 0

    dut.re.value = 1
    await FallingEdge(dut.clock)
    if (dut.r_val != 0):
        print(row, col)
        assert(dut.r_val == 0)

    dut.re.value = 0
    await FallingEdge(dut.clock)
    dut.we.value = 1
    await FallingEdge(dut.clock)
    await FallingEdge(dut.clock)
    await FallingEdge(dut.clock)
    dut.we.value = 0
    dut.re.value = 1
    await FallingEdge(dut.clock)
    if (dut.r_val != 1):
        print(row, col)
        assert(dut.r_val == 1)
        for i in range(12):
            for j in range(20):
                dut.row.value = j
                dut.col.value = i
                await FallingEdge(dut.clock)
                if (dut.r_val == 1):
                    print(j, i)

    
@cocotb.test()
async def automated_tests(dut):
    for i in range(12):
        for j in range(20):
            await automated_test(dut, j, i)