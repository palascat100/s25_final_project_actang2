import cocotb
from cocotb.clock import Clock
from cocotb.triggers import *

@cocotb.test()
async def automated_test(dut):
    dut.toggle_async.value = 0
    dut.drop_async.value = 0
    dut.save_async.value = 0
    dut.rotate_async.value = 0

    dut.MISO.value = 0
    dut.reset.value = 0

    cocotb.start_soon(Clock(dut.clock, 10, units="ns").start())

    # Reset the DUT
    dut.reset.value = 1
    await FallingEdge(dut.clock)
    await FallingEdge(dut.clock)
    dut.reset.value = 0

    for _ in range(100000):
        await FallingEdge(dut.clock)