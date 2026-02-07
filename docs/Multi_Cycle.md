# Phase 3: Multi-Cycle Processor

## Architecture Overview

The multi-cycle processor breaks instruction execution into multiple clock cycles, with each cycle performing a specific task. This approach allows for a higher clock frequency compared to single-cycle designs by reducing the critical path length.

## Design Rationale

Single-cycle processors must complete all operations in one cycle, meaning the clock period is determined by the slowest instruction (typically a load). This wastes time on faster instructions. Multi-cycle processors address this by:

- Sharing hardware resources across multiple cycles
- Allowing different instructions to take different numbers of cycles
- Enabling a faster clock frequency

## Architecture Changes from Single-Cycle

### Memory Organization
Changed from Harvard to Von Neumann architecture:
- Single unified 12KB memory for both instructions and data
- Arbitration logic selects between instruction fetch and data access
- Module: `unified_memory.v`

### Internal Registers
Added five non-architectural registers to hold intermediate values:

| Register | Size | Purpose |
|----------|------|---------|
| IR | 32-bit | Instruction Register - holds current instruction |
| MDR | 64-bit | Memory Data Register - buffers memory reads |
| A | 64-bit | Holds rs1 operand value |
| B | 64-bit | Holds rs2 operand value |
| ALUOut | 64-bit | Stores ALU computation result |

Module: `internal_registers.v`

### Finite State Machine

Nine-state FSM controls instruction execution flow:

| State | Number | Purpose | Active For |
|-------|--------|---------|------------|
| FETCH | 0 | Fetch instruction from memory | All instructions |
| DECODE | 1 | Decode and read registers | All instructions |
| MEMADR | 2 | Calculate memory address | LD, SD |
| MEMREAD | 3 | Read from data memory | LD |
| MEMWB | 4 | Write memory data to register | LD |
| MEMWRITE | 5 | Write data to memory | SD |
| EXECUTE | 6 | Perform ALU operation | R-type |
| ALUWRITEBACK | 7 | Write ALU result to register | R-type |
| BRANCH | 8 | Branch decision and PC update | BEQ |

Module: `fsm_controller.v`

### State Transitions

```
All instructions: FETCH → DECODE

From DECODE:
  R-type → EXECUTE → ALUWRITEBACK → FETCH
  LD     → MEMADR → MEMREAD → MEMWB → FETCH
  SD     → MEMADR → MEMWRITE → FETCH
  BEQ    → BRANCH → FETCH
```

## Cycles Per Instruction

| Instruction Type | Cycles | Path |
|-----------------|--------|------|
| R-type (ADD, SUB, AND, OR) | 4 | Fetch → Decode → Execute → ALU Writeback |
| Load (LD) | 5 | Fetch → Decode → MemAddr → MemRead → Mem Writeback |
| Store (SD) | 4 | Fetch → Decode → MemAddr → MemWrite |
| Branch (BEQ) | 3 | Fetch → Decode → Branch |

Average CPI for typical programs: 4.25

## Control Signals by State

### FETCH
- MemRead = 1 (read instruction)
- IorD = 0 (use PC as address)
- IRWrite = 1 (load instruction into IR)
- PCWrite = 1 (update PC to PC+4)

### DECODE
- Read rs1 and rs2 into A and B registers
- Calculate branch target (PC + offset)

### EXECUTE (R-type)
- ALUSrcA = register A
- ALUSrcB = register B
- ALUOp = determined by funct3/funct7

### MEMADR (LD/SD)
- ALUSrcA = register A (base)
- ALUSrcB = immediate (offset)
- ALUOp = ADD

### MEMREAD (LD)
- MemRead = 1
- IorD = 1 (use ALUOut as address)

### MEMWRITE (SD)
- MemWrite = 1
- IorD = 1 (use ALUOut as address)

### ALUWRITEBACK / MEMWB
- RegWrite = 1
- MemtoReg = 0 for ALU result, 1 for memory data

## Performance Analysis

### Clock Frequency
Maximum frequency: 270.27 MHz (3.70 ns period)

Critical stage: MEMORY
- Register Clk-to-Q: 0.40 ns
- Address Mux: 0.30 ns
- Memory Access: 2.50 ns
- Wire + Setup: 0.50 ns
- Total: 3.70 ns

This represents a 2.54x improvement over single-cycle frequency (106.38 MHz).

### Execution Time
For a 10-instruction test program:
- Cycles: 42.5 (10 instructions × 4.25 average CPI)
- Time: 157.25 ns
- Comparison: 0.60x the performance of single-cycle

The multi-cycle design achieves higher frequency but pays a penalty in CPI. For this small test, overall performance is worse than single-cycle. However, the architectural benefits (resource sharing, lower power) make it valuable for certain applications.

## Files

| File | Lines | Purpose |
|------|-------|---------|
| rtl/fsm_controller.v | 190 | State machine controller |
| rtl/internal_registers.v | 65 | Intermediate value storage |
| rtl/unified_memory.v | 95 | Von Neumann memory |
| rtl/multi_cycle_processor.v | 185 | Top-level integration |
| tb/multi_cycle_processor_tb.v | 60 | Verification testbench |

## Verification

Test program executes correctly with results matching single-cycle implementation:
- All register values verified
- Memory contents verified
- State transitions logged and confirmed

## Block Diagram

See `docs/diagrams/fsm_state_diagram.png` for state machine visualization.
See `docs/diagrams/datapath_diagram.png` for complete datapath.
See `docs/diagrams/control_timing_diagram.png` for control signal timing.