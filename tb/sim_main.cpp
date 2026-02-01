#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsingle_cycle_processor.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsingle_cycle_processor* top = new Vsingle_cycle_processor;
    
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");
    
    top->clk = 0;
    
    // START RESET: In single_cycle_processor.v, 'reset' is Active High.
    // So 1 = Reset, 0 = Run.
    top->reset = 1; 

    for (int i = 0; i < 200; i++) {
        // Release reset after 10 ticks
        if (i == 10) top->reset = 0; // 0 means "Running"
        
        top->clk = !top->clk;
        top->eval();
        tfp->dump(i);
    }
    
    top->final();
    tfp->close();
    delete top;
    return 0;
}