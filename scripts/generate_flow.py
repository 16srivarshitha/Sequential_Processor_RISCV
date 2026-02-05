#!/usr/bin/env python3

import graphviz

def create_fsm_diagram():
    """Generate FSM state transition diagram for multi-cycle processor"""
    
    dot = graphviz.Digraph('FSM_State_Diagram', comment='Multi-Cycle Processor FSM')
    
    # Graph attributes for clean, professional look
    dot.attr(rankdir='TB', splines='ortho', nodesep='1.0', ranksep='1.2')
    dot.attr('node', shape='circle', style='filled', fillcolor='lightblue', 
             fontname='Arial', fontsize='12', width='1.2', height='1.2')
    dot.attr('edge', fontname='Arial', fontsize='10', arrowsize='0.8')
    
    # Define states
    states = {
        'FETCH': 'State 0\nFETCH',
        'DECODE': 'State 1\nDECODE',
        'MEMADR': 'State 2\nMEMADR',
        'MEMREAD': 'State 3\nMEMREAD',
        'MEMWB': 'State 4\nMEMWB',
        'MEMWRITE': 'State 5\nMEMWRITE',
        'EXECUTE': 'State 6\nEXECUTE',
        'ALUWRITEBACK': 'State 7\nALUWB',
        'BRANCH': 'State 8\nBRANCH'
    }
    
    # Add states
    for state_id, label in states.items():
        dot.node(state_id, label)
    
    # Add transitions with labels
    # From FETCH
    dot.edge('FETCH', 'DECODE', label='All instructions')
    
    # From DECODE
    dot.edge('DECODE', 'EXECUTE', label='R-type\n(0110011)')
    dot.edge('DECODE', 'MEMADR', label='Load/Store\n(0000011/0100011)')
    dot.edge('DECODE', 'BRANCH', label='Branch\n(1100011)')
    
    # From MEMADR
    dot.edge('MEMADR', 'MEMREAD', label='Load')
    dot.edge('MEMADR', 'MEMWRITE', label='Store')
    
    # From MEMREAD
    dot.edge('MEMREAD', 'MEMWB', label='')
    
    # From MEMWB
    dot.edge('MEMWB', 'FETCH', label='')
    
    # From MEMWRITE
    dot.edge('MEMWRITE', 'FETCH', label='')
    
    # From EXECUTE
    dot.edge('EXECUTE', 'ALUWRITEBACK', label='')
    
    # From ALUWRITEBACK
    dot.edge('ALUWRITEBACK', 'FETCH', label='')
    
    # From BRANCH
    dot.edge('BRANCH', 'FETCH', label='')
    
    return dot


def create_instruction_flow_diagrams():
    """Generate separate diagrams showing instruction flow for different types"""
    
    diagrams = {}
    
    # R-type instruction flow
    r_type = graphviz.Digraph('R_Type_Flow', comment='R-Type Instruction Flow')
    r_type.attr(rankdir='LR', splines='ortho')
    r_type.attr('node', shape='rectangle', style='filled', fillcolor='lightgreen',
                fontname='Arial', fontsize='11', width='1.5', height='0.8')
    r_type.attr('edge', fontname='Arial', fontsize='10')
    
    r_type.node('R0', 'FETCH\nCycle 1')
    r_type.node('R1', 'DECODE\nCycle 2')
    r_type.node('R2', 'EXECUTE\nCycle 3')
    r_type.node('R3', 'ALUWRITEBACK\nCycle 4')
    
    r_type.edge('R0', 'R1')
    r_type.edge('R1', 'R2')
    r_type.edge('R2', 'R3')
    
    diagrams['r_type'] = r_type
    
    # Load instruction flow
    load = graphviz.Digraph('Load_Flow', comment='Load Instruction Flow')
    load.attr(rankdir='LR', splines='ortho')
    load.attr('node', shape='rectangle', style='filled', fillcolor='lightyellow',
              fontname='Arial', fontsize='11', width='1.5', height='0.8')
    load.attr('edge', fontname='Arial', fontsize='10')
    
    load.node('L0', 'FETCH\nCycle 1')
    load.node('L1', 'DECODE\nCycle 2')
    load.node('L2', 'MEMADR\nCycle 3')
    load.node('L3', 'MEMREAD\nCycle 4')
    load.node('L4', 'MEMWB\nCycle 5')
    
    load.edge('L0', 'L1')
    load.edge('L1', 'L2')
    load.edge('L2', 'L3')
    load.edge('L3', 'L4')
    
    diagrams['load'] = load
    
    # Store instruction flow
    store = graphviz.Digraph('Store_Flow', comment='Store Instruction Flow')
    store.attr(rankdir='LR', splines='ortho')
    store.attr('node', shape='rectangle', style='filled', fillcolor='lightcoral',
               fontname='Arial', fontsize='11', width='1.5', height='0.8')
    store.attr('edge', fontname='Arial', fontsize='10')
    
    store.node('S0', 'FETCH\nCycle 1')
    store.node('S1', 'DECODE\nCycle 2')
    store.node('S2', 'MEMADR\nCycle 3')
    store.node('S3', 'MEMWRITE\nCycle 4')
    
    store.edge('S0', 'S1')
    store.edge('S1', 'S2')
    store.edge('S2', 'S3')
    
    diagrams['store'] = store
    
    # Branch instruction flow
    branch = graphviz.Digraph('Branch_Flow', comment='Branch Instruction Flow')
    branch.attr(rankdir='LR', splines='ortho')
    branch.attr('node', shape='rectangle', style='filled', fillcolor='lavender',
                fontname='Arial', fontsize='11', width='1.5', height='0.8')
    branch.attr('edge', fontname='Arial', fontsize='10')
    
    branch.node('B0', 'FETCH\nCycle 1')
    branch.node('B1', 'DECODE\nCycle 2')
    branch.node('B2', 'BRANCH\nCycle 3')
    
    branch.edge('B0', 'B1')
    branch.edge('B1', 'B2')
    
    diagrams['branch'] = branch
    
    return diagrams


def create_comparison_table():
    """Generate comparison table between single-cycle and multi-cycle"""
    
    comparison = graphviz.Digraph('Comparison', comment='Single vs Multi-Cycle Comparison')
    comparison.attr(rankdir='TB')
    comparison.attr('node', shape='plaintext', fontname='Arial', fontsize='11')
    
    # Create HTML table
    table_html = '''<
    <TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0" CELLPADDING="8">
        <TR>
            <TD BGCOLOR="lightgray"><B>Metric</B></TD>
            <TD BGCOLOR="lightblue"><B>Single-Cycle</B></TD>
            <TD BGCOLOR="lightgreen"><B>Multi-Cycle</B></TD>
        </TR>
        <TR>
            <TD><B>CPI</B></TD>
            <TD>1</TD>
            <TD>3-5 (avg ~4.2)</TD>
        </TR>
        <TR>
            <TD><B>Clock Period</B></TD>
            <TD>Sum of all stages</TD>
            <TD>Longest single stage</TD>
        </TR>
        <TR>
            <TD><B>Critical Path</B></TD>
            <TD>PC → Mem → RF → ALU → Mem → RF</TD>
            <TD>Memory access or ALU operation</TD>
        </TR>
        <TR>
            <TD><B>Hardware Resources</B></TD>
            <TD>2 Memories, 3 Adders</TD>
            <TD>1 Memory, 1 ALU (shared)</TD>
        </TR>
        <TR>
            <TD><B>Instruction Types</B></TD>
            <TD COLSPAN="2">R-type, Load, Store, Branch</TD>
        </TR>
        <TR>
            <TD><B>R-type Cycles</B></TD>
            <TD>1</TD>
            <TD>4</TD>
        </TR>
        <TR>
            <TD><B>Load Cycles</B></TD>
            <TD>1</TD>
            <TD>5</TD>
        </TR>
        <TR>
            <TD><B>Store Cycles</B></TD>
            <TD>1</TD>
            <TD>4</TD>
        </TR>
        <TR>
            <TD><B>Branch Cycles</B></TD>
            <TD>1</TD>
            <TD>3</TD>
        </TR>
        <TR>
            <TD><B>Expected Speedup</B></TD>
            <TD>1x (baseline)</TD>
            <TD>1.5-2.5x (depends on workload)</TD>
        </TR>
    </TABLE>
    >'''
    
    comparison.node('table', table_html)
    
    return comparison


def main():
    """Generate all diagrams"""
    
    print("Generating FSM state transition diagram...")
    fsm_diagram = create_fsm_diagram()
    fsm_diagram.render('docs/diagrams/fsm_state_diagram', format='png', cleanup=True)
    fsm_diagram.render('docs/diagrams/fsm_state_diagram', format='svg', cleanup=True)
    
    print("Generating instruction flow diagrams...")
    flow_diagrams = create_instruction_flow_diagrams()
    for name, diagram in flow_diagrams.items():
        diagram.render(f'docs/diagrams/{name}_flow', format='png', cleanup=True)
        diagram.render(f'docs/diagrams/{name}_flow', format='svg', cleanup=True)
    
    print("Generating comparison table...")
    comparison = create_comparison_table()
    comparison.render('docs/diagrams/single_vs_multi_comparison', format='png', cleanup=True)
    comparison.render('docs/diagrams/single_vs_multi_comparison', format='svg', cleanup=True)
    
    print("\nAll diagrams generated successfully!")
    print("Output directory: docs/diagrams/")
    print("\nGenerated files:")
    print("  - fsm_state_diagram.png/svg")
    print("  - r_type_flow.png/svg")
    print("  - load_flow.png/svg")
    print("  - store_flow.png/svg")
    print("  - branch_flow.png/svg")
    print("  - single_vs_multi_comparison.png/svg")


if __name__ == "__main__":
    main()