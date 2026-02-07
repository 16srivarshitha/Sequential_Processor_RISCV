# Phase 4: Pipelined Processor

## Architecture Overview

The pipelined processor implements a classic 5-stage RISC pipeline that allows multiple instructions to execute concurrently. While each instruction still takes 5 cycles to complete, the pipeline can produce one result per cycle once filled.

## Pipeline Stages

### IF - Instruction Fetch
Fetches the next instruction from memory using the program counter.

Operations:
- Read instruction from memory at PC
- Update PC to PC+4
- Store instruction in IF/ID pipeline register

Critical path: 3.50 ns (PC → Memory → IF/ID setup)

### ID - Instruction Decode
Decodes the instruction and reads operands from the register file.

Operations:
- Extract opcode, rs1, rs2, rd, funct3, funct7
- Generate control signals
- Read register file
- Sign-extend immediate
- Store values in ID/EX pipeline register

Critical path: 2.90 ns

### EX - Execute
Performs ALU operations and forwards data when needed.

Operations:
- Select ALU inputs via forwarding muxes
- Perform ALU computation
- Generate zero flag for branches
- Store result in EX/MEM pipeline register

Critical path: 3.30 ns (includes forwarding mux)

### MEM - Memory Access
Accesses data memory for load and store instructions.

Operations:
- Read from or write to data memory
- Pass through ALU result
- Store values in MEM/WB pipeline register

Critical path: 3.50 ns (memory access dominates)

### WB - Write Back
Writes results back to the register file.

Operations:
- Select between ALU result and memory data
- Write to destination register

Critical path: 1.20 ns

## Pipeline Registers

Four pipeline registers separate the five stages:

| Register | Purpose | Signals Stored |
|----------|---------|----------------|
| IF/ID | Between fetch and decode | PC, instruction |
| ID/EX | Between decode and execute | PC, register data, immediate, control signals |
| EX/MEM | Between execute and memory | ALU result, register data, control signals |
| MEM/WB | Between memory and writeback | Memory data, ALU result, control signals |

Each register includes:
- Clock and reset inputs
- Flush capability (for control hazards)
- Stall capability for IF/ID (for load-use hazards)

## Hazard Handling

### Data Hazards

Data hazards occur when an instruction depends on the result of a previous instruction still in the pipeline.

Example:
```
ADD x3, x1, x2    # writes x3
SUB x4, x3, x1    # reads x3 (hazard)
```

Solution: Data forwarding (bypassing)

### Forwarding Unit

Detects when data should be forwarded from later stages back to the EX stage.

Forwarding paths:
- EX/MEM → EX (forward from MEM stage)
- MEM/WB → EX (forward from WB stage)

Control signals:
- ForwardA controls source for ALU input 1
- ForwardB controls source for ALU input 2

Values:
- 00: Use register file data (no hazard)
- 01: Forward from MEM stage (EX hazard)
- 10: Forward from WB stage (MEM hazard)

Priority: MEM stage forwarding takes precedence over WB stage.

### Load-Use Hazards

Special case where a load instruction is immediately followed by an instruction using the loaded value.

Example:
```
LD x1, 0(x2)      # loads x1
ADD x3, x1, x4    # uses x1 (can't forward in time)
```

Solution: Pipeline stall

The hazard detection unit inserts a bubble (NOP) between the load and the dependent instruction, giving the load time to complete.

Stall conditions:
- EX stage has a load (MemRead = 1)
- ID stage instruction reads the load destination
- Insert bubble in ID/EX, stall IF/ID

### Control Hazards

Branches create uncertainty about which instruction to fetch next.

Simple solution: Always predict not taken
- Fetch next sequential instruction
- If branch is taken, flush IF/ID and ID/EX registers
- Restart fetch from branch target

Branch penalty: 2 cycles

## Performance Analysis

### Clock Frequency
Maximum frequency: 285.71 MHz (3.50 ns period)

Critical stages: IF and MEM (tied at 3.50 ns)

This represents a 2.69x improvement over single-cycle frequency.

### Execution Performance

Test program (10 instructions):
- Cycles: 30
- CPI: 3.00
- Execution time: 105.00 ns

CPI breakdown:
- Base CPI: 1.00 (ideal pipeline)
- Pipeline fill overhead: +1.00 (5 cycles to fill, amortized)
- Stalls: +1.00 (1 load-use stall, amortized)
- Total CPI: 3.00

For larger programs, CPI approaches 1.0 as:
- Pipeline fill overhead becomes negligible
- Stalls become proportionally smaller
- Branch prediction could reduce control hazard penalty

### Comparison to Other Designs

Versus single-cycle:
- 2.69x higher frequency
- Similar execution time for small programs
- Better performance for large programs

Versus multi-cycle:
- 1.06x higher frequency
- 1.50x faster execution
- Better scalability with program size

## Hazard Statistics

From test program execution:
- Data forwards: 4 events
  - 2 from MEM stage (EX hazards)
  - 2 from WB stage (MEM hazards)
- Pipeline stalls: 1 event (load-use hazard)
- Pipeline flushes: 0 events (no branches taken in test)

Forwarding prevented 4 potential stalls, demonstrating effectiveness of the forwarding unit.

## Files

| File | Lines | Purpose |
|------|-------|---------|
| rtl/if_id_register.v | 25 | IF/ID pipeline register |
| rtl/id_ex_register.v | 90 | ID/EX pipeline register |
| rtl/ex_mem_register.v | 60 | EX/MEM pipeline register |
| rtl/mem_wb_register.v | 45 | MEM/WB pipeline register |
| rtl/hazard_detection_unit.v | 45 | Stall and flush control |
| rtl/forwarding_unit.v | 40 | Data forwarding logic |
| rtl/pipeline_control.v | 95 | Control signal generation |
| rtl/pipelined_processor.v | 310 | Top-level integration |
| rtl/register_file.v | 35 | Register file with forwarding |
| rtl/instruction_memory.v | 30 | Instruction memory |
| rtl/data_memory.v | 60 | Data memory |
| rtl/alu.v | 30 | Arithmetic logic unit |
| rtl/alu_control.v | 50 | ALU operation decoder |
| tb/pipelined_processor_tb.v | 250 | Comprehensive testbench |

## Verification

Comprehensive test program verifies:
- R-type arithmetic operations
- Immediate arithmetic
- Load and store operations
- Data hazard detection and forwarding
- Load-use hazard detection and stalling

All tests pass with correct final register and memory values.

## Design Decisions

### Register File Design
Includes internal forwarding for same-cycle write-then-read to handle the case where WB and ID occur simultaneously.

### Branch Handling
Branches resolved in ID stage rather than EX to minimize branch penalty from 3 cycles to 2 cycles.

### Conservative Stalling
All load-use hazards result in stalls. An alternative would be to forward from MEM/WB to EX on loads, eliminating some stalls.

### Memory Organization
Separate instruction and data memories maintain Harvard architecture benefits while allowing concurrent access in IF and MEM stages.

## Block Diagrams

See `docs/diagrams/pipeline_datapath.png` for complete datapath with forwarding paths.
See `docs/diagrams/hazard_scenarios.png` for hazard handling examples.
See `docs/diagrams/pipeline_timing.png` for instruction flow through pipeline.