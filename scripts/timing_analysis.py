"""
Timing Analysis for RISC-V Processor Implementations
Analyzes critical paths and calculates maximum frequencies
"""

# Component delay assumptions (in nanoseconds)
# These are typical values for ASIC implementation in modern process nodes

DELAYS = {
    # Memory
    'memory_read': 2.5,      # SRAM read access time
    'memory_write': 2.0,     # SRAM write setup time
    
    # Register file
    'regfile_read': 1.0,     # Register read
    'regfile_write': 0.8,    # Register write setup
    
    # ALU operations
    'alu_add': 1.5,          # 64-bit adder
    'alu_sub': 1.5,          # 64-bit subtractor
    'alu_logic': 0.5,        # AND/OR/XOR
    'alu_compare': 1.2,      # Comparator
    
    # Control logic
    'decoder': 0.5,          # Instruction decoder
    'control': 0.3,          # Control signal generation
    'alu_control': 0.4,      # ALU control decoder
    
    # Multiplexers
    'mux_2to1': 0.3,         # 2:1 mux
    'mux_4to1': 0.5,         # 4:1 mux
    
    # Sign extension
    'sign_extend': 0.2,      # Immediate sign extension
    
    # Register setup/hold
    'reg_setup': 0.3,        # Flip-flop setup time
    'reg_clk_to_q': 0.4,     # Flip-flop propagation delay
    
    # Routing/interconnect
    'wire_short': 0.1,       # Short wire delay
    'wire_medium': 0.2,      # Medium wire delay
    'wire_long': 0.3,        # Long wire delay
}

def analyze_single_cycle():
    """Analyze critical path for single-cycle processor"""
    
    print("SINGLE-CYCLE PROCESSOR TIMING ANALYSIS")
    
    
    # Critical path: Memory -> RegFile -> ALU -> Memory -> RegFile
    paths = {
        'R-type (ADD)': [
            ('Instruction Memory Read', DELAYS['memory_read']),
            ('Wire to Control', DELAYS['wire_short']),
            ('Instruction Decode', DELAYS['decoder']),
            ('Control Signal Gen', DELAYS['control']),
            ('Wire to RegFile', DELAYS['wire_medium']),
            ('Register File Read', DELAYS['regfile_read']),
            ('Wire to ALU', DELAYS['wire_medium']),
            ('ALU Operation (ADD)', DELAYS['alu_add']),
            ('Wire to RegFile', DELAYS['wire_medium']),
            ('Register Write Setup', DELAYS['reg_setup']),
        ],
        
        'Load (LD)': [
            ('Instruction Memory Read', DELAYS['memory_read']),
            ('Instruction Decode', DELAYS['decoder']),
            ('Control Signal Gen', DELAYS['control']),
            ('Register File Read', DELAYS['regfile_read']),
            ('Wire to ALU', DELAYS['wire_medium']),
            ('ALU Add (Address Calc)', DELAYS['alu_add']),
            ('Wire to Data Memory', DELAYS['wire_long']),
            ('Data Memory Read', DELAYS['memory_read']),
            ('Wire to RegFile', DELAYS['wire_long']),
            ('Register Write Setup', DELAYS['reg_setup']),
        ],
        
        'Store (SD)': [
            ('Instruction Memory Read', DELAYS['memory_read']),
            ('Instruction Decode', DELAYS['decoder']),
            ('Control Signal Gen', DELAYS['control']),
            ('Register File Read', DELAYS['regfile_read']),
            ('ALU Add (Address Calc)', DELAYS['alu_add']),
            ('Wire to Data Memory', DELAYS['wire_long']),
            ('Data Memory Write', DELAYS['memory_write']),
        ],
    }
    
    max_delay = 0
    critical_path_name = ""
    
    for path_name, components in paths.items():
        total_delay = sum(delay for _, delay in components)
        print(f"\n{path_name}:")
        
        for component, delay in components:
            print(f"  {component:.<50} {delay:>6.2f} ns")
        print(f"  {'TOTAL':.<50} {total_delay:>6.2f} ns")
        
        if total_delay > max_delay:
            max_delay = total_delay
            critical_path_name = path_name
    
    f_max = 1000 / max_delay  # Convert to MHz
    period = max_delay
    
    
    print(f"Critical Path: {critical_path_name}")
    print(f"Maximum Delay: {max_delay:.2f} ns")
    print(f"Minimum Period: {period:.2f} ns")
    print(f"Maximum Frequency: {f_max:.2f} MHz")
    
    
    return f_max, period

def analyze_multi_cycle():
    """Analyze critical path for multi-cycle processor"""
    
    print("MULTI-CYCLE PROCESSOR TIMING ANALYSIS")
    
    
    # Critical path: Longest single stage
    stages = {
        'FETCH': [
            ('Memory Read', DELAYS['memory_read']),
            ('Wire to IR', DELAYS['wire_medium']),
            ('IR Setup', DELAYS['reg_setup']),
        ],
        
        'DECODE': [
            ('Register File Read', DELAYS['regfile_read']),
            ('Wire to A/B', DELAYS['wire_short']),
            ('A/B Setup', DELAYS['reg_setup']),
        ],
        
        'EXECUTE (ALU)': [
            ('Reg Clk-to-Q (A)', DELAYS['reg_clk_to_q']),
            ('Mux Select', DELAYS['mux_4to1']),
            ('ALU Operation', DELAYS['alu_add']),
            ('Wire to ALUOut', DELAYS['wire_medium']),
            ('ALUOut Setup', DELAYS['reg_setup']),
        ],
        
        'MEMORY': [
            ('Reg Clk-to-Q (ALUOut)', DELAYS['reg_clk_to_q']),
            ('Address Mux', DELAYS['mux_2to1']),
            ('Memory Access', DELAYS['memory_read']),
            ('Wire to MDR', DELAYS['wire_medium']),
            ('MDR Setup', DELAYS['reg_setup']),
        ],
        
        'WRITEBACK': [
            ('Reg Clk-to-Q (ALUOut/MDR)', DELAYS['reg_clk_to_q']),
            ('Result Mux', DELAYS['mux_2to1']),
            ('Wire to RegFile', DELAYS['wire_medium']),
            ('Register Write Setup', DELAYS['reg_setup']),
        ],
    }
    
    max_delay = 0
    critical_stage = ""
    
    for stage_name, components in stages.items():
        total_delay = sum(delay for _, delay in components)
        print(f"\n{stage_name}:")
        
        for component, delay in components:
            print(f"  {component:.<50} {delay:>6.2f} ns")
        print(f"  {'TOTAL':.<50} {total_delay:>6.2f} ns")
        
        if total_delay > max_delay:
            max_delay = total_delay
            critical_stage = stage_name
    
    f_max = 1000 / max_delay
    period = max_delay
    
    
    print(f"Critical Stage: {critical_stage}")
    print(f"Maximum Delay: {max_delay:.2f} ns")
    print(f"Minimum Period: {period:.2f} ns")
    print(f"Maximum Frequency: {f_max:.2f} MHz")
    
    
    return f_max, period

def analyze_pipelined():
    """Analyze critical path for pipelined processor"""
    
    print("PIPELINED PROCESSOR TIMING ANALYSIS")
    
    
    # Critical path: Longest pipeline stage
    stages = {
        'IF (Instruction Fetch)': [
            ('PC Clk-to-Q', DELAYS['reg_clk_to_q']),
            ('Wire to Memory', DELAYS['wire_short']),
            ('Instruction Memory', DELAYS['memory_read']),
            ('Wire to IF/ID', DELAYS['wire_medium']),
            ('IF/ID Setup', DELAYS['reg_setup']),
        ],
        
        'ID (Instruction Decode)': [
            ('IF/ID Clk-to-Q', DELAYS['reg_clk_to_q']),
            ('Decode Logic', DELAYS['decoder']),
            ('Control Unit', DELAYS['control']),
            ('Register File Read', DELAYS['regfile_read']),
            ('Sign Extend', DELAYS['sign_extend']),
            ('Wire to ID/EX', DELAYS['wire_medium']),
            ('ID/EX Setup', DELAYS['reg_setup']),
        ],
        
        'EX (Execute)': [
            ('ID/EX Clk-to-Q', DELAYS['reg_clk_to_q']),
            ('Forwarding Mux', DELAYS['mux_4to1']),
            ('ALU Control', DELAYS['alu_control']),
            ('ALU Operation', DELAYS['alu_add']),
            ('Wire to EX/MEM', DELAYS['wire_medium']),
            ('EX/MEM Setup', DELAYS['reg_setup']),
        ],
        
        'MEM (Memory Access)': [
            ('EX/MEM Clk-to-Q', DELAYS['reg_clk_to_q']),
            ('Wire to Memory', DELAYS['wire_short']),
            ('Data Memory Read', DELAYS['memory_read']),
            ('Wire to MEM/WB', DELAYS['wire_medium']),
            ('MEM/WB Setup', DELAYS['reg_setup']),
        ],
        
        'WB (Write Back)': [
            ('MEM/WB Clk-to-Q', DELAYS['reg_clk_to_q']),
            ('Writeback Mux', DELAYS['mux_2to1']),
            ('Wire to RegFile', DELAYS['wire_medium']),
            ('Register Write Setup', DELAYS['reg_setup']),
        ],
    }
    
    max_delay = 0
    critical_stage = ""
    
    for stage_name, components in stages.items():
        total_delay = sum(delay for _, delay in components)
        print(f"\n{stage_name}:")
        
        for component, delay in components:
            print(f"  {component:.<50} {delay:>6.2f} ns")
        print(f"  {'TOTAL':.<50} {total_delay:>6.2f} ns")
        
        if total_delay > max_delay:
            max_delay = total_delay
            critical_stage = stage_name
    
    f_max = 1000 / max_delay
    period = max_delay
    
    
    print(f"Critical Stage: {critical_stage}")
    print(f"Maximum Delay: {max_delay:.2f} ns")
    print(f"Minimum Period: {period:.2f} ns")
    print(f"Maximum Frequency: {f_max:.2f} MHz")
    
    
    return f_max, period

def performance_comparison():
    """Compare performance across implementations"""
    
    print("PERFORMANCE COMPARISON")
    
    
    # Run timing analysis
    sc_freq, sc_period = analyze_single_cycle()
    mc_freq, mc_period = analyze_multi_cycle()
    pipe_freq, pipe_period = analyze_pipelined()
    
    # Test program characteristics
    num_instructions = 10
    
    # CPI values
    sc_cpi = 1.0        # Single-cycle: 1 instruction per cycle
    mc_cpi = 4.25       # Multi-cycle: average from test
    pipe_cpi = 3.0      # Pipelined: from test results
    
    # Calculate execution times (in nanoseconds)
    sc_time = num_instructions * sc_cpi * sc_period
    mc_time = num_instructions * mc_cpi * mc_period
    pipe_time = num_instructions * pipe_cpi * pipe_period
    
    print(f"\nTest Program: {num_instructions} instructions")
    
    
    print(f"\n{'Implementation':<20} {'f_max':<15} {'CPI':<10} {'Exec Time':<15} {'Speedup'}")
    
    print(f"{'Single-Cycle':<20} {sc_freq:>8.2f} MHz   {sc_cpi:>6.2f}   {sc_time:>8.2f} ns   {1.0:>6.2f}x")
    print(f"{'Multi-Cycle':<20} {mc_freq:>8.2f} MHz   {mc_cpi:>6.2f}   {mc_time:>8.2f} ns   {sc_time/mc_time:>6.2f}x")
    print(f"{'Pipelined':<20} {pipe_freq:>8.2f} MHz   {pipe_cpi:>6.2f}   {pipe_time:>8.2f} ns   {sc_time/pipe_time:>6.2f}x")
    
    
    print("KEY INSIGHTS:")
    print(f"  • Multi-cycle achieves {mc_freq/sc_freq:.2f}x higher frequency")
    print(f"  • Pipelined achieves {pipe_freq/sc_freq:.2f}x higher frequency")
    print(f"  • Pipelined is {mc_time/pipe_time:.2f}x faster than multi-cycle")
    print(f"  • Pipelined is {sc_time/pipe_time:.2f}x faster than single-cycle")
    

if __name__ == '__main__':
    performance_comparison()