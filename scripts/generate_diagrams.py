from graphviz import Digraph
import os

class ArchitectureDiagramGenerator:
    def __init__(self, output_dir='../docs/diagrams'):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
    
    def generate_high_level_architecture(self):
        """Generate high-level 5-stage architecture diagram"""
        dot = Digraph(comment='RISC-V 5-Stage Architecture', format='png')
        dot.attr(rankdir='LR', splines='ortho', size='10,6')
        dot.attr('node', shape='box', style='filled', fillcolor='lightblue', fontname='Arial')
        
        # Define stages
        dot.node('IF', 'Instruction\nFetch (IF)', fillcolor='#FFE5B4', width='1.5')
        dot.node('ID', 'Instruction\nDecode (ID)', fillcolor='#B4D7FF', width='1.5')
        dot.node('EX', 'Execute\n(EX)', fillcolor='#FFB4B4', width='1.5')
        dot.node('MEM', 'Memory\n(MEM)', fillcolor='#B4FFB4', width='1.5')
        dot.node('WB', 'Writeback\n(WB)', fillcolor='#E5B4FF', width='1.5')
        
        # Pipeline flow
        dot.edge('IF', 'ID', label='Instruction', fontsize='10')
        dot.edge('ID', 'EX', label='Control + Data', fontsize='10')
        dot.edge('EX', 'MEM', label='ALU Result', fontsize='10')
        dot.edge('MEM', 'WB', label='Data', fontsize='10')
        dot.edge('WB', 'ID', label='Writeback', style='dashed', constraint='false', color='blue')
        
        # Memories
        dot.node('IMEM', 'Instruction\nMemory\n(4KB)', shape='cylinder', fillcolor='#FFFFB4')
        dot.node('DMEM', 'Data\nMemory\n(8KB)', shape='cylinder', fillcolor='#FFFFB4')
        
        dot.edge('IMEM', 'IF', label='Instruction[31:0]', style='dotted')
        dot.edge('MEM', 'DMEM', label='Read/Write', dir='both', style='dotted')
        
        # Register file
        dot.node('RF', 'Register\nFile\n(32x64)', shape='folder', fillcolor='#D4E5FF')
        dot.edge('RF', 'ID', label='Read', style='dotted')
        dot.edge('WB', 'RF', label='Write', style='dotted')
        
        dot.render(f'{self.output_dir}/01_high_level_architecture', cleanup=True)
        print(" Generated 01_high_level_architecture.png")
    
    def generate_fetch_stage_detail(self):
        """Refined Fetch stage: PC as independent state element"""
        dot = Digraph(comment='Fetch Stage Detail', format='png')
        dot.attr(rankdir='LR', size='10,6')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        with dot.subgraph(name='cluster_fetch') as c:
            c.attr(label='Instruction Fetch Stage', style='filled', color='lightgrey')
            
            # State Element
            c.node('PC', 'Program Counter\n(64-bit Reg)', fillcolor='#FFE5B4', shape='box3d')
            
            # Logic Elements
            c.node('PCMUX', 'Next PC\nMux', shape='invtrapezium', fillcolor='white')
            c.node('PCADD', 'PC Adder\n(+4)', shape='circle', fillcolor='#FFD700')
            c.node('IMEM', 'Instruction Memory\n(1024 x 32)', shape='cylinder', fillcolor='#FFFFB4')
        
        # Inputs/Signals
        dot.node('BRANCH_TAKEN', 'PCSel\n(from EX)', shape='plaintext')
        dot.node('BRANCH_ADDR', 'Target Addr\n(from EX)', shape='plaintext')
        
        # The Path Flow
        # 1. PC Out to Memory and Adder
        dot.edge('PC', 'IMEM', label='addr')
        dot.edge('PC', 'PCADD', label='curr_pc')
        
        # 2. Sequential Path
        dot.edge('PCADD', 'PCMUX', label='pc+4')
        
        # 3. Branch Path
        dot.edge('BRANCH_ADDR', 'PCMUX', label='target')
        dot.edge('BRANCH_TAKEN', 'PCMUX', label='sel', style='dashed')
        
        # 4. Loop back to PC Input (The only 'loop')
        dot.edge('PCMUX', 'PC', label='next_pc')
        
        # Output
        dot.node('OUT_INSTR', 'Instruction[31:0] →', shape='plaintext')
        dot.edge('IMEM', 'OUT_INSTR')
        
        dot.render(f'{self.output_dir}/02_fetch_stage_detail', cleanup=True)
    
    def generate_decode_stage_detail(self):
        """Refined Decode: Centralized ImmGen and Control mapping"""
        dot = Digraph(comment='Decode Stage Detail', format='png')
        dot.attr(rankdir='LR', size='12,8')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        with dot.subgraph(name='cluster_decode') as c:
            c.attr(label='Instruction Decode Stage', style='filled', color='lightgrey')
            
            c.node('INSTR', 'Instruction[31:0]', shape='plaintext')
            c.node('CTRL', 'Main Control\nUnit', fillcolor='#FFB4B4', width='1.5')
            
            # Register File
            c.node('RF', 'Register File\n(32x64)', shape='folder', fillcolor='#D4E5FF')
            
            # Centralized Immediate Generator
            c.node('IMMGEN', 'Immediate Generator\n(I, S, B, U, J)', fillcolor='#B4FFB4')
            
        # Connections
        # Split the instruction bits
        dot.edge('INSTR', 'CTRL', label='opcode')
        dot.edge('INSTR', 'RF', label='rs1, rs2')
        dot.edge('INSTR', 'IMMGEN', label='imm_bits')
        
        # Outputs to next stage
        dot.node('EX_BUS', 'to Execute Stage', shape='note')
        dot.edge('RF', 'EX_BUS', label='ReadData1, ReadData2')
        dot.edge('IMMGEN', 'EX_BUS', label='ImmExt')
        dot.edge('CTRL', 'EX_BUS', label='ALUOp, ALUSrc, etc', style='dashed')
        
        dot.render(f'{self.output_dir}/03_decode_stage_detail', cleanup=True)
    
    def generate_execute_stage_detail(self):
        """Generate detailed execute stage diagram"""
        dot = Digraph(comment='Execute Stage Detail', format='png')
        dot.attr(rankdir='LR', size='10,6')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        with dot.subgraph(name='cluster_execute') as c:
            c.attr(label='Execute Stage', style='filled', color='lightgrey')
            
            # ALU Mux
            c.node('ALUMUX', 'ALU Src\nMux', shape='invtrapezium', fillcolor='white')
            
            # ALU
            c.node('ALU', 'ALU\n(64-bit)\n\nOperations:\n• ADD\n• SUB\n• AND\n• OR', 
                   fillcolor='#FFB4B4', width='2')
            
            # Branch comparator
            c.node('ZERO', 'Zero\nDetect', shape='diamond', fillcolor='#FFD700')
            c.node('BRANCH_LOGIC', 'Branch\nLogic', fillcolor='#FFA07A')
        
        # Inputs
        dot.node('IN_RD1', 'ReadData1[63:0]', shape='plaintext')
        dot.node('IN_RD2', 'ReadData2[63:0]', shape='plaintext')
        dot.node('IN_IMM', 'ImmExt[63:0]', shape='plaintext')
        dot.node('IN_ALUOP', 'ALUOp[3:0]', shape='plaintext')
        dot.node('IN_ALUSRC', 'ALUSrc', shape='plaintext')
        dot.node('IN_BRANCH', 'Branch', shape='plaintext')
        
        # Connections
        dot.edge('IN_RD1', 'ALU', label='operand1')
        dot.edge('IN_RD2', 'ALUMUX', label='reg_data')
        dot.edge('IN_IMM', 'ALUMUX', label='imm_data')
        dot.edge('IN_ALUSRC', 'ALUMUX', label='sel', style='dashed')
        dot.edge('ALUMUX', 'ALU', label='operand2')
        dot.edge('IN_ALUOP', 'ALU', label='operation', style='dashed')
        
        dot.edge('ALU', 'ZERO', label='result')
        dot.edge('ZERO', 'BRANCH_LOGIC', label='zero_flag')
        dot.edge('IN_BRANCH', 'BRANCH_LOGIC', label='branch')
        
        # Outputs
        dot.node('OUT_ALU', 'ALUResult[63:0] →', shape='plaintext')
        dot.node('OUT_ZERO', 'Zero →', shape='plaintext')
        dot.node('OUT_BRANCH', 'BranchTaken →', shape='plaintext')
        
        dot.edge('ALU', 'OUT_ALU')
        dot.edge('ZERO', 'OUT_ZERO')
        dot.edge('BRANCH_LOGIC', 'OUT_BRANCH')
        
        dot.render(f'{self.output_dir}/04_execute_stage_detail', cleanup=True)
        print(" Generated 04_execute_stage_detail.png")
    
    def generate_memory_stage_detail(self):
        """Generate detailed memory stage diagram"""
        dot = Digraph(comment='Memory Stage Detail', format='png')
        dot.attr(rankdir='TB', size='8,8')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        with dot.subgraph(name='cluster_memory') as c:
            c.attr(label='Memory Stage', style='filled', color='lightgrey')
            
            # Memory
            c.node('DMEM', 'Data Memory\n\n1024 x 64-bit\n(8 KB)\n\nByte-addressable', 
                   shape='cylinder', fillcolor='#FFFFB4', width='2.5')
            
            # Address decoder
            c.node('ADDR_DEC', 'Address\nDecoder\n(÷8)', fillcolor='#B4FFB4')
            
            # Control logic
            c.node('MEM_CTRL', 'Memory\nControl', fillcolor='#FFB4B4')
        
        # Inputs
        dot.node('IN_ADDR', 'ALUResult[63:0]\n(address)', shape='plaintext')
        dot.node('IN_WDATA', 'WriteData[63:0]', shape='plaintext')
        dot.node('IN_MEMRD', 'MemRead', shape='plaintext')
        dot.node('IN_MEMWR', 'MemWrite', shape='plaintext')
        dot.node('IN_CLK', 'clk', shape='plaintext')
        dot.node('IN_RESET', 'reset', shape='plaintext')
        
        # Connections
        dot.edge('IN_ADDR', 'ADDR_DEC', label='byte_addr')
        dot.edge('ADDR_DEC', 'DMEM', label='word_addr[9:0]')
        dot.edge('IN_WDATA', 'DMEM', label='write_data')
        dot.edge('IN_MEMRD', 'MEM_CTRL')
        dot.edge('IN_MEMWR', 'MEM_CTRL')
        dot.edge('MEM_CTRL', 'DMEM', label='rd/wr_en', style='dashed')
        dot.edge('IN_CLK', 'DMEM', label='clk', style='dotted', color='blue')
        dot.edge('IN_RESET', 'DMEM', label='rst', style='dotted', color='red')
        
        # Outputs
        dot.node('OUT_RDATA', 'ReadData[63:0] →', shape='plaintext')
        dot.edge('DMEM', 'OUT_RDATA', label='read_data')
        
        # Boundary check
        dot.node('BOUNDS', 'Bounds\nCheck', shape='diamond', fillcolor='#FFD700')
        dot.edge('ADDR_DEC', 'BOUNDS', label='addr', style='dotted')
        dot.edge('BOUNDS', 'DMEM', label='valid', style='dashed', color='green')
        
        dot.render(f'{self.output_dir}/05_memory_stage_detail', cleanup=True)
        print(" Generated 05_memory_stage_detail.png")
    
    def generate_writeback_stage_detail(self):
        """Generate detailed writeback stage diagram"""
        dot = Digraph(comment='Writeback Stage Detail', format='png')
        dot.attr(rankdir='LR', size='8,4')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        with dot.subgraph(name='cluster_writeback') as c:
            c.attr(label='Writeback Stage', style='filled', color='lightgrey')
            
            c.node('WBMUX', 'Writeback\nMux', shape='invtrapezium', fillcolor='white', width='1.5')
        
        # Inputs
        dot.node('IN_MEMDATA', 'ReadData[63:0]\n(from memory)', shape='plaintext')
        dot.node('IN_ALUDATA', 'ALUResult[63:0]\n(from execute)', shape='plaintext')
        dot.node('IN_M2R', 'MemtoReg', shape='plaintext')
        dot.node('IN_RD', 'Rd[4:0]', shape='plaintext')
        dot.node('IN_REGWR', 'RegWrite', shape='plaintext')
        
        # Connections
        dot.edge('IN_MEMDATA', 'WBMUX', label='mem_path')
        dot.edge('IN_ALUDATA', 'WBMUX', label='alu_path')
        dot.edge('IN_M2R', 'WBMUX', label='sel', style='dashed')
        
        # Outputs to register file
        dot.node('RF_WR', 'To Register File', fillcolor='#D4E5FF', shape='folder')
        dot.edge('WBMUX', 'RF_WR', label='WriteData[63:0]')
        dot.edge('IN_RD', 'RF_WR', label='WriteReg[4:0]')
        dot.edge('IN_REGWR', 'RF_WR', label='RegWrite', style='dashed')
        
        dot.render(f'{self.output_dir}/06_writeback_stage_detail', cleanup=True)
        print(" Generated 06_writeback_stage_detail.png")
    
    def generate_control_unit_detail(self):
        """Generate detailed control unit diagram"""
        dot = Digraph(comment='Control Unit Detail', format='png')
        dot.attr(rankdir='TB', size='10,10')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        # Inputs
        dot.node('OPCODE', 'opcode[6:0]', shape='ellipse', fillcolor='#FFE5B4')
        dot.node('FUNCT3', 'funct3[2:0]', shape='ellipse', fillcolor='#FFE5B4')
        dot.node('FUNCT7', 'funct7[6:0]', shape='ellipse', fillcolor='#FFE5B4')
        
        # Decoder
        dot.node('DECODER', 'Instruction\nDecoder', fillcolor='#B4D7FF', width='2')
        
        # Control signal groups
        with dot.subgraph(name='cluster_ex') as c:
            c.attr(label='Execute Control', style='filled', color='#FFE5E5')
            c.node('ALUOp_OUT', 'ALUOp[3:0]\n\n0010=ADD\n0110=SUB\n0111=AND\n0001=OR', 
                   fillcolor='#FFB4B4')
            c.node('ALUSrc_OUT', 'ALUSrc\n\n0=Register\n1=Immediate', fillcolor='#FFB4B4')
            c.node('Branch_OUT', 'Branch\n\n1=Branch Instr', fillcolor='#FFB4B4')
        
        with dot.subgraph(name='cluster_mem') as c:
            c.attr(label='Memory Control', style='filled', color='#E5FFE5')
            c.node('MemRead_OUT', 'MemRead\n\n1=Load', fillcolor='#B4FFB4')
            c.node('MemWrite_OUT', 'MemWrite\n\n1=Store', fillcolor='#B4FFB4')
        
        with dot.subgraph(name='cluster_wb') as c:
            c.attr(label='Writeback Control', style='filled', color='#F0E5FF')
            c.node('RegWrite_OUT', 'RegWrite\n\n1=Write Reg', fillcolor='#E5B4FF')
            c.node('MemtoReg_OUT', 'MemtoReg\n\n0=ALU\n1=Memory', fillcolor='#E5B4FF')
        
        # Connections
        dot.edge('OPCODE', 'DECODER')
        dot.edge('FUNCT3', 'DECODER')
        dot.edge('FUNCT7', 'DECODER')
        
        dot.edge('DECODER', 'ALUOp_OUT')
        dot.edge('DECODER', 'ALUSrc_OUT')
        dot.edge('DECODER', 'Branch_OUT')
        dot.edge('DECODER', 'MemRead_OUT')
        dot.edge('DECODER', 'MemWrite_OUT')
        dot.edge('DECODER', 'RegWrite_OUT')
        dot.edge('DECODER', 'MemtoReg_OUT')
        
        # Instruction type labels
        dot.node('RTYPE_LABEL', 'R-type: 0110011', shape='note', fillcolor='#FFE5B4')
        dot.node('ITYPE_LABEL', 'I-type Load: 0000011', shape='note', fillcolor='#B4D7FF')
        dot.node('STYPE_LABEL', 'S-type: 0100011', shape='note', fillcolor='#FFB4B4')
        dot.node('BTYPE_LABEL', 'B-type: 1100011', shape='note', fillcolor='#B4FFB4')
        
        dot.edge('DECODER', 'RTYPE_LABEL', style='dotted', constraint='false')
        dot.edge('DECODER', 'ITYPE_LABEL', style='dotted', constraint='false')
        dot.edge('DECODER', 'STYPE_LABEL', style='dotted', constraint='false')
        dot.edge('DECODER', 'BTYPE_LABEL', style='dotted', constraint='false')
        
        dot.render(f'{self.output_dir}/07_control_unit_detail', cleanup=True)
        print(" Generated 07_control_unit_detail.png")
    
    def generate_datapath_diagram(self):
        """Generate complete datapath with all connections"""
        dot = Digraph(comment='Complete Datapath', format='png')
        dot.attr(rankdir='LR', size='14,10')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
         # Fetch stage components
        with dot.subgraph(name='cluster_fetch') as c:
            c.attr(label='Fetch Stage', style='filled', color='lightgrey')
            c.node('PC', 'Program\nCounter', fillcolor='#FFE5B4')
            c.node('PCMUX', 'PC\nMux', shape='invtrapezium', fillcolor='white')
            c.node('PCADD', '+4', shape='circle', fillcolor='white')
            c.node('IMEM', 'Instruction\nMemory', shape='cylinder', fillcolor='#FFFFB4')
        
        # Decode stage components
        with dot.subgraph(name='cluster_decode') as c:
            c.attr(label='Decode Stage', style='filled', color='lightgrey')
            c.node('IFID', 'IF/ID\nRegister', shape='parallelogram', fillcolor='#E0E0E0')
            c.node('RF', 'Register\nFile\n(32x64)', shape='folder', fillcolor='#D4E5FF')
            c.node('CTRL', 'Control\nUnit', fillcolor='#B4D7FF')
            c.node('IMMGEN', 'Immediate\nGenerator', fillcolor='#B4D7FF')
        
        # Execute stage components
        with dot.subgraph(name='cluster_execute') as c:
            c.attr(label='Execute Stage', style='filled', color='lightgrey')
            c.node('IDEX', 'ID/EX\nRegister', shape='parallelogram', fillcolor='#E0E0E0')
            c.node('ALU', 'ALU\n(64-bit)', fillcolor='#FFB4B4')
            c.node('ALUMUX', 'ALU Src\nMux', shape='invtrapezium', fillcolor='white')
            c.node('BCMP', 'Branch\nComparator', fillcolor='#FFB4B4')
        
        # Memory stage components
        with dot.subgraph(name='cluster_memory') as c:
            c.attr(label='Memory Stage', style='filled', color='lightgrey')
            c.node('EXMEM', 'EX/MEM\nRegister', shape='parallelogram', fillcolor='#E0E0E0')
            c.node('DMEM', 'Data\nMemory\n(8KB)', shape='cylinder', fillcolor='#FFFFB4')
        
        # Writeback stage components
        with dot.subgraph(name='cluster_writeback') as c:
            c.attr(label='Writeback Stage', style='filled', color='lightgrey')
            c.node('MEMWB', 'MEM/WB\nRegister', shape='parallelogram', fillcolor='#E0E0E0')
            c.node('WBMUX', 'WB Src\nMux', shape='invtrapezium', fillcolor='white')
        
        # Main datapath connections
        dot.edge('PC', 'IMEM', label='pc_current')
        dot.edge('PC', 'PCADD')
        dot.edge('PCADD', 'PCMUX', label='pc+4')
        dot.edge('PCMUX', 'PC', style='dashed')
        dot.edge('IMEM', 'IFID', label='instruction[31:0]')
        
        dot.edge('IFID', 'RF', label='rs1, rs2')
        dot.edge('IFID', 'CTRL', label='opcode, funct3, funct7')
        dot.edge('IFID', 'IMMGEN', label='imm_fields')
        
        dot.edge('RF', 'IDEX', label='ReadData1\nReadData2')
        dot.edge('IMMGEN', 'IDEX', label='ImmExt')
        dot.edge('CTRL', 'IDEX', label='control_signals')
        
        dot.edge('IDEX', 'ALU', label='operand1')
        dot.edge('IDEX', 'ALUMUX')
        dot.edge('ALUMUX', 'ALU', label='operand2')
        dot.edge('ALU', 'EXMEM', label='ALUResult')
        
        dot.edge('EXMEM', 'DMEM', label='address\nwrite_data', dir='both')
        dot.edge('DMEM', 'MEMWB', label='ReadData')
        dot.edge('EXMEM', 'MEMWB', label='ALUResult')
        
        dot.edge('MEMWB', 'WBMUX')
        dot.edge('WBMUX', 'RF', label='WriteData', style='dashed')
        
        # Branch target calculation
        dot.edge('IFID', 'BCMP', label='PC', style='dotted', constraint='false')
        dot.edge('IMMGEN', 'BCMP', label='offset', style='dotted', constraint='false')
        dot.edge('BCMP', 'PCMUX', label='branch_target', style='dashed', constraint='false')
        
        dot.render(f'{self.output_dir}/08_complete_datapath', cleanup=True)
        print(" Generated 08_complete_datapath.png")
    
    def generate_alu_detail(self):
        """Generate ALU internal detail"""
        dot = Digraph(comment='ALU Detail', format='png')
        dot.attr(rankdir='TB', size='8,8')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        # Inputs
        dot.node('A', 'A[63:0]', shape='plaintext')
        dot.node('B', 'B[63:0]', shape='plaintext')
        dot.node('ALUOP', 'ALUOp[3:0]', shape='plaintext')
        
        # Arithmetic units
        with dot.subgraph(name='cluster_arith') as c:
            c.attr(label='Arithmetic Units', style='filled', color='#FFE5E5')
            c.node('ADD', 'Adder\n(A + B)', fillcolor='#FFB4B4')
            c.node('SUB', 'Subtractor\n(A - B)', fillcolor='#FFB4B4')
        
        # Logic units
        with dot.subgraph(name='cluster_logic') as c:
            c.attr(label='Logic Units', style='filled', color='#E5FFE5')
            c.node('AND', 'AND\n(A & B)', fillcolor='#B4FFB4')
            c.node('OR', 'OR\n(A | B)', fillcolor='#B4FFB4')
        
        # Result mux
        dot.node('RESULT_MUX', 'Result\nMux', shape='invtrapezium', fillcolor='white', width='1.5')
        
        # Zero detector
        dot.node('ZERO_DET', 'Zero\nDetector\n(result == 0)', shape='diamond', fillcolor='#FFD700')
        
        # Connections
        dot.edge('A', 'ADD')
        dot.edge('B', 'ADD')
        dot.edge('A', 'SUB')
        dot.edge('B', 'SUB')
        dot.edge('A', 'AND')
        dot.edge('B', 'AND')
        dot.edge('A', 'OR')
        dot.edge('B', 'OR')
        
        dot.edge('ADD', 'RESULT_MUX', label='0010')
        dot.edge('SUB', 'RESULT_MUX', label='0110')
        dot.edge('AND', 'RESULT_MUX', label='0111')
        dot.edge('OR', 'RESULT_MUX', label='0001')
        
        dot.edge('ALUOP', 'RESULT_MUX', label='select', style='dashed')
        
        dot.edge('RESULT_MUX', 'ZERO_DET', label='Result[63:0]')
        
        # Outputs
        dot.node('OUT_RESULT', 'ALUResult[63:0] →', shape='plaintext')
        dot.node('OUT_ZERO', 'Zero →', shape='plaintext')
        
        dot.edge('RESULT_MUX', 'OUT_RESULT')
        dot.edge('ZERO_DET', 'OUT_ZERO')
        
        dot.render(f'{self.output_dir}/09_alu_detail', cleanup=True)
        print(" Generated 09_alu_detail.png")
    
    def generate_immediate_generator_detail(self):
        """Generate immediate generator detail"""
        dot = Digraph(comment='Immediate Generator', format='png')
        dot.attr(rankdir='TB', size='8,10')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        # Input
        dot.node('INSTR', 'Instruction[31:0]', shape='plaintext')
        dot.node('OPCODE', 'opcode[6:0]', shape='ellipse', fillcolor='#FFE5B4')
        
        # Format decoders
        with dot.subgraph(name='cluster_formats') as c:
            c.attr(label='Immediate Formats', style='filled', color='lightgrey')
            
            c.node('ITYPE', 'I-Type\nimm[11:0] = [31:20]\nSign-extend to 64-bit', 
                   fillcolor='#B4D7FF', width='2.5')
            c.node('STYPE', 'S-Type\nimm[11:5] = [31:25]\nimm[4:0] = [11:7]\nSign-extend', 
                   fillcolor='#FFB4B4', width='2.5')
            c.node('BTYPE', 'B-Type\nimm[12|10:5] = [31:25]\nimm[4:1|11] = [11:7]\nSign-extend, LSB=0', 
                   fillcolor='#B4FFB4', width='2.5')
        
        # Mux
        dot.node('IMM_MUX', 'Immediate\nMux', shape='invtrapezium', fillcolor='white', width='1.5')
        
        # Connections
        dot.edge('INSTR', 'OPCODE', label='[6:0]')
        dot.edge('INSTR', 'ITYPE', label='[31:20]')
        dot.edge('INSTR', 'STYPE', label='[31:25],[11:7]')
        dot.edge('INSTR', 'BTYPE', label='[31:25],[11:7]')
        
        dot.edge('ITYPE', 'IMM_MUX', label='I-imm')
        dot.edge('STYPE', 'IMM_MUX', label='S-imm')
        dot.edge('BTYPE', 'IMM_MUX', label='B-imm')
        
        dot.edge('OPCODE', 'IMM_MUX', label='select', style='dashed')
        
        # Output
        dot.node('OUT', 'ImmExt[63:0] →', shape='plaintext')
        dot.edge('IMM_MUX', 'OUT')
        
        dot.render(f'{self.output_dir}/10_immediate_generator', cleanup=True)
        print(" Generated 10_immediate_generator.png")
    
    def generate_register_file_detail(self):
        """Generate register file detail"""
        dot = Digraph(comment='Register File', format='png')
        dot.attr(rankdir='TB', size='8,8')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        # Main register array
        dot.node('RF_ARRAY', 'Register Array\n\nx0 (zero) = 0x0 (hardwired)\nx1-x31 = 64-bit\n\nTotal: 32 registers', 
                 shape='folder', fillcolor='#D4E5FF', width='3', height='2')
        
        # Read ports
        dot.node('RD_PORT1', 'Read\nPort 1', fillcolor='#B4FFB4')
        dot.node('RD_PORT2', 'Read\nPort 2', fillcolor='#B4FFB4')
        
        # Write port
        dot.node('WR_PORT', 'Write\nPort', fillcolor='#FFB4B4')
        
        # Zero check
        dot.node('ZERO_CHK1', 'x0?\nCheck', shape='diamond', fillcolor='#FFD700')
        dot.node('ZERO_CHK2', 'x0?\nCheck', shape='diamond', fillcolor='#FFD700')
        dot.node('ZERO_CHK_WR', 'x0?\nBlock', shape='diamond', fillcolor='#FFD700')
        
        # Inputs
        dot.node('IN_RS1', 'rs1[4:0]', shape='plaintext')
        dot.node('IN_RS2', 'rs2[4:0]', shape='plaintext')
        dot.node('IN_RD', 'WriteReg[4:0]', shape='plaintext')
        dot.node('IN_WD', 'WriteData[63:0]', shape='plaintext')
        dot.node('IN_WE', 'RegWrite', shape='plaintext')
        dot.node('IN_CLK', 'clk', shape='plaintext')
        
        # Read path
        dot.edge('IN_RS1', 'ZERO_CHK1', label='addr1')
        dot.edge('ZERO_CHK1', 'RD_PORT1', label='!= 0')
        dot.edge('RD_PORT1', 'RF_ARRAY', label='read1', dir='both')
        
        dot.edge('IN_RS2', 'ZERO_CHK2', label='addr2')
        dot.edge('ZERO_CHK2', 'RD_PORT2', label='!= 0')
        dot.edge('RD_PORT2', 'RF_ARRAY', label='read2', dir='both')
        
        # Write path
        dot.edge('IN_RD', 'ZERO_CHK_WR', label='addr')
        dot.edge('IN_WD', 'WR_PORT')
        dot.edge('IN_WE', 'WR_PORT', style='dashed')
        dot.edge('IN_CLK', 'WR_PORT', style='dotted', color='blue')
        dot.edge('ZERO_CHK_WR', 'WR_PORT', label='!= 0', color='green')
        dot.edge('WR_PORT', 'RF_ARRAY', label='write')
        
        # Outputs
        dot.node('OUT_RD1', 'ReadData1[63:0] →', shape='plaintext')
        dot.node('OUT_RD2', 'ReadData2[63:0] →', shape='plaintext')
        
        dot.edge('ZERO_CHK1', 'OUT_RD1', label='== 0: return 0', style='dashed')
        dot.edge('RD_PORT1', 'OUT_RD1')
        dot.edge('ZERO_CHK2', 'OUT_RD2', label='== 0: return 0', style='dashed')
        dot.edge('RD_PORT2', 'OUT_RD2')
        
        dot.render(f'{self.output_dir}/11_register_file_detail', cleanup=True)
        print(" Generated 11_register_file_detail.png")
    
    def generate_instruction_flow_example(self):
        """Generate example instruction execution flow"""
        dot = Digraph(comment='Instruction Execution Example', format='png')
        dot.attr(rankdir='TB', size='10,12')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        dot.node('TITLE', 'Example: add x21, x6, x5', shape='plaintext', fontsize='16', fontname='bold')
        
        # Cycle 1: Fetch
        with dot.subgraph(name='cluster_c1') as c:
            c.attr(label='Cycle 1: Fetch', style='filled', color='#FFE5B4')
            c.node('C1_PC', 'PC = 0x0004', fillcolor='white')
            c.node('C1_INSTR', 'Instr = 0x005302B3', fillcolor='white')
        
        # Cycle 2: Decode
        with dot.subgraph(name='cluster_c2') as c:
            c.attr(label='Cycle 2: Decode', style='filled', color='#B4D7FF')
            c.node('C2_RS1', 'rs1 = x6 = 0x6', fillcolor='white')
            c.node('C2_RS2', 'rs2 = x5 = 0x5', fillcolor='white')
            c.node('C2_RD', 'rd = x21', fillcolor='white')
            c.node('C2_CTRL', 'ALUOp=ADD, RegWrite=1', fillcolor='white')
        
        # Cycle 3: Execute
        with dot.subgraph(name='cluster_c3') as c:
            c.attr(label='Cycle 3: Execute', style='filled', color='#FFB4B4')
            c.node('C3_ALU', 'ALU: 0x6 + 0x5 = 0xB', fillcolor='white')
            c.node('C3_ZERO', 'Zero = 0', fillcolor='white')
        
        # Cycle 4: Memory
        with dot.subgraph(name='cluster_c4') as c:
            c.attr(label='Cycle 4: Memory', style='filled', color='#B4FFB4')
            c.node('C4_BYPASS', 'No memory access\n(pass through)', fillcolor='white')
        
        # Cycle 5: Writeback
        with dot.subgraph(name='cluster_c5') as c:
            c.attr(label='Cycle 5: Writeback', style='filled', color='#E5B4FF')
            c.node('C5_WB', 'Write 0xB to x21', fillcolor='white')
        
        # Flow
        dot.edge('TITLE', 'C1_PC', style='invis')
        dot.edge('C1_INSTR', 'C2_RS1', style='invis')
        dot.edge('C2_CTRL', 'C3_ALU', style='invis')
        dot.edge('C3_ZERO', 'C4_BYPASS', style='invis')
        dot.edge('C4_BYPASS', 'C5_WB', style='invis')
        
        dot.render(f'{self.output_dir}/12_instruction_execution_example', cleanup=True)
        print(" Generated 12_instruction_execution_example.png")
    
    def generate_memory_map(self):
        """Generate memory layout diagram"""
        dot = Digraph(comment='Memory Map', format='png')
        dot.attr(rankdir='TB', size='6,10')
        dot.attr('node', shape='box', style='filled', fontname='Arial')
        
        dot.node('TITLE', 'RISC-V Processor Memory Map', shape='plaintext', fontsize='18', fontname='bold')
        
        # Instruction memory
        dot.node('IMEM_START', '0x0000', shape='plaintext')
        dot.node('IMEM_REGION', 
                 'Instruction Memory\n\n1024 entries\n32-bit instructions\n\nTotal: 4 KB', 
                 fillcolor='#FFE5B4', width='3', height='1.5')
        dot.node('IMEM_END', '0x0FFF', shape='plaintext')
        
        # Data memory
        dot.node('DMEM_START', '0x0000', shape='plaintext')
        dot.node('DMEM_REGION', 
                 'Data Memory\n\n1024 entries\n64-bit words\n\nTotal: 8 KB\n\nByte-addressable\n(word-aligned)', 
                 fillcolor='#B4FFB4', width='3', height='2')
        dot.node('DMEM_END', '0x1FFF', shape='plaintext')
        
        # Register file
        dot.node('RF_REGION', 
                 'Register File\n\nx0-x31\n32 registers\n64-bit each\n\nTotal: 256 bytes', 
                 fillcolor='#D4E5FF', width='3', height='1.5')
        
        # Connections
        dot.edge('TITLE', 'IMEM_START', style='invis')
        dot.edge('IMEM_START', 'IMEM_REGION', style='invis')
        dot.edge('IMEM_REGION', 'IMEM_END', style='invis')
        dot.edge('IMEM_END', 'DMEM_START', style='invis')
        dot.edge('DMEM_START', 'DMEM_REGION', style='invis')
        dot.edge('DMEM_REGION', 'DMEM_END', style='invis')
        dot.edge('DMEM_END', 'RF_REGION', style='invis')
        
        dot.render(f'{self.output_dir}/13_memory_map', cleanup=True)
        print(" Generated 13_memory_map.png")
    
    def generate_instruction_formats(self):
        """Generate RISC-V instruction format diagrams"""
        dot = Digraph(comment='Instruction Formats', format='png')
        dot.attr(rankdir='TB', size='10,12')
        dot.attr('node', shape='record', style='filled', fontname='Arial')
        
        dot.node('TITLE', 'RISC-V Instruction Formats (RV64I Subset)', 
                 shape='plaintext', fontsize='16', fontname='bold')
        
        # R-type
        dot.node('RTYPE', 
                 '{R-Type (add, sub, and, or)|{funct7\\n[31:25]|rs2\\n[24:20]|rs1\\n[19:15]|funct3\\n[14:12]|rd\\n[11:7]|opcode\\n[6:0]}}',
                 fillcolor='#FFE5B4')
        dot.node('RTYPE_EX', 'Example: add x21, x6, x5\n0000000 00101 00110 000 10101 0110011', 
                 shape='note', fillcolor='#FFFFB4')
        
        # I-type
        dot.node('ITYPE', 
                 '{I-Type (ld, addi)|{imm[11:0]\\n[31:20]|rs1\\n[19:15]|funct3\\n[14:12]|rd\\n[11:7]|opcode\\n[6:0]}}',
                 fillcolor='#B4D7FF')
        dot.node('ITYPE_EX', 'Example: ld x20, 0(x14)\n000000000000 01110 011 10100 0000011', 
                 shape='note', fillcolor='#FFFFB4')
        
        # S-type
        dot.node('STYPE', 
                 '{S-Type (sd)|{imm[11:5]\\n[31:25]|rs2\\n[24:20]|rs1\\n[19:15]|funct3\\n[14:12]|imm[4:0]\\n[11:7]|opcode\\n[6:0]}}',
                 fillcolor='#FFB4B4')
        dot.node('STYPE_EX', 'Example: sd x21, 0(x16)\n0000000 10101 10000 011 00000 0100011', 
                 shape='note', fillcolor='#FFFFB4')
        
        # B-type
        dot.node('BTYPE', 
                 '{B-Type (beq)|{imm[12,10:5]\\n[31:25]|rs2\\n[24:20]|rs1\\n[19:15]|funct3\\n[14:12]|imm[4:1,11]\\n[11:7]|opcode\\n[6:0]}}',
                 fillcolor='#B4FFB4')
        dot.node('BTYPE_EX', 'Example: beq x17, x18, 16\n0000001 10010 10001 000 01000 1100011', 
                 shape='note', fillcolor='#FFFFB4')
        
        # Connections
        dot.edge('TITLE', 'RTYPE', style='invis')
        dot.edge('RTYPE', 'RTYPE_EX', style='dotted')
        dot.edge('RTYPE_EX', 'ITYPE', style='invis')
        dot.edge('ITYPE', 'ITYPE_EX', style='dotted')
        dot.edge('ITYPE_EX', 'STYPE', style='invis')
        dot.edge('STYPE', 'STYPE_EX', style='dotted')
        dot.edge('STYPE_EX', 'BTYPE', style='invis')
        dot.edge('BTYPE', 'BTYPE_EX', style='dotted')
        
        dot.render(f'{self.output_dir}/14_instruction_formats', cleanup=True)
        print(" Generated 14_instruction_formats.png")
    
    def generate_control_truth_table(self):
        """Generate control signals truth table"""
        dot = Digraph(comment='Control Truth Table', format='png')
        dot.attr(rankdir='TB', size='12,8')
        dot.attr('node', shape='plaintext', fontname='Courier')
        
        table = '''<TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
    <TR><TD BGCOLOR="#B4D7FF" COLSPAN="10"><B>Control Signals Truth Table</B></TD></TR>
    <TR>
        <TD BGCOLOR="#E0E0E0"><B>Instruction</B></TD>
        <TD BGCOLOR="#E0E0E0"><B>Opcode</B></TD>
        <TD BGCOLOR="#FFE5E5"><B>ALUOp</B></TD>
        <TD BGCOLOR="#FFE5E5"><B>ALUSrc</B></TD>
        <TD BGCOLOR="#FFE5E5"><B>Branch</B></TD>
        <TD BGCOLOR="#E5FFE5"><B>MemRead</B></TD>
        <TD BGCOLOR="#E5FFE5"><B>MemWrite</B></TD>
        <TD BGCOLOR="#F0E5FF"><B>RegWrite</B></TD>
        <TD BGCOLOR="#F0E5FF"><B>MemtoReg</B></TD>
        <TD BGCOLOR="#E0E0E0"><B>RegDst</B></TD>
    </TR>
    <TR>
        <TD>add</TD><TD>0110011</TD>
        <TD BGCOLOR="#FFE5E5">0010</TD><TD BGCOLOR="#FFE5E5">0</TD><TD BGCOLOR="#FFE5E5">0</TD>
        <TD BGCOLOR="#E5FFE5">0</TD><TD BGCOLOR="#E5FFE5">0</TD>
        <TD BGCOLOR="#F0E5FF">1</TD><TD BGCOLOR="#F0E5FF">0</TD>
        <TD>1</TD>
    </TR>
    <TR>
        <TD>sub</TD><TD>0110011</TD>
        <TD BGCOLOR="#FFE5E5">0110</TD><TD BGCOLOR="#FFE5E5">0</TD><TD BGCOLOR="#FFE5E5">0</TD>
        <TD BGCOLOR="#E5FFE5">0</TD><TD BGCOLOR="#E5FFE5">0</TD>
        <TD BGCOLOR="#F0E5FF">1</TD><TD BGCOLOR="#F0E5FF">0</TD>
        <TD>1</TD>
    </TR>
    <TR>
        <TD>and</TD><TD>0110011</TD>
        <TD BGCOLOR="#FFE5E5">0111</TD><TD BGCOLOR="#FFE5E5">0</TD><TD BGCOLOR="#FFE5E5">0</TD>
        <TD BGCOLOR="#E5FFE5">0</TD><TD BGCOLOR="#E5FFE5">0</TD>
        <TD BGCOLOR="#F0E5FF">1</TD><TD BGCOLOR="#F0E5FF">0</TD>
        <TD>1</TD>
    </TR>
    <TR>
        <TD>or</TD><TD>0110011</TD>
        <TD BGCOLOR="#FFE5E5">0001</TD><TD BGCOLOR="#FFE5E5">0</TD><TD BGCOLOR="#FFE5E5">0</TD>
        <TD BGCOLOR="#E5FFE5">0</TD><TD BGCOLOR="#E5FFE5">0</TD>
        <TD BGCOLOR="#F0E5FF">1</TD><TD BGCOLOR="#F0E5FF">0</TD>
        <TD>1</TD>
    </TR>
    <TR>
        <TD>ld</TD><TD>0000011</TD>
        <TD BGCOLOR="#FFE5E5">0000</TD><TD BGCOLOR="#FFE5E5">1</TD><TD BGCOLOR="#FFE5E5">0</TD>
        <TD BGCOLOR="#E5FFE5">1</TD><TD BGCOLOR="#E5FFE5">0</TD>
        <TD BGCOLOR="#F0E5FF">1</TD><TD BGCOLOR="#F0E5FF">1</TD>
        <TD>1</TD>
    </TR>
    <TR>
        <TD>sd</TD><TD>0100011</TD>
        <TD BGCOLOR="#FFE5E5">0000</TD><TD BGCOLOR="#FFE5E5">1</TD><TD BGCOLOR="#FFE5E5">0</TD>
        <TD BGCOLOR="#E5FFE5">0</TD><TD BGCOLOR="#E5FFE5">1</TD>
        <TD BGCOLOR="#F0E5FF">0</TD><TD BGCOLOR="#F0E5FF">X</TD>
        <TD>0</TD>
    </TR>
    <TR>
        <TD>beq</TD><TD>1100011</TD>
        <TD BGCOLOR="#FFE5E5">0110</TD><TD BGCOLOR="#FFE5E5">0</TD><TD BGCOLOR="#FFE5E5">1</TD>
        <TD BGCOLOR="#E5FFE5">0</TD><TD BGCOLOR="#E5FFE5">0</TD>
        <TD BGCOLOR="#F0E5FF">0</TD><TD BGCOLOR="#F0E5FF">X</TD>
        <TD>0</TD>
    </TR>
    </TABLE>'''
        
        dot.node('TABLE', f'<{table}>')
        dot.render(f'{self.output_dir}/15_control_truth_table', cleanup=True)
        print(" Generated 15_control_truth_table.png")
    
    def generate_all_diagrams(self):
        """Generate all architecture diagrams"""
        print("\n" + "="*60)
        print("Generating Comprehensive Architecture Diagrams")
        print("="*60 + "\n")
        
        self.generate_high_level_architecture()
        self.generate_fetch_stage_detail()
        self.generate_decode_stage_detail()
        self.generate_execute_stage_detail()
        self.generate_memory_stage_detail()
        self.generate_writeback_stage_detail()
        self.generate_control_unit_detail()
        self.generate_datapath_diagram()
        self.generate_alu_detail()
        self.generate_immediate_generator_detail()
        self.generate_register_file_detail()
        self.generate_instruction_flow_example()
        self.generate_memory_map()
        self.generate_instruction_formats()
        self.generate_control_truth_table()
        
        print("\n" + "="*60)
        print(f" All 15 diagrams generated successfully!")
        print(f"  Output directory: {self.output_dir}")
        print("="*60 + "\n")


if __name__ == '__main__':
    import sys
    
    # Check for graphviz installation
    try:
        from graphviz import Digraph
    except ImportError:
        print("Error: graphviz Python package not found")
        print("Install with: pip install graphviz")
        sys.exit(1)
    
    generator = ArchitectureDiagramGenerator()
    generator.generate_all_diagrams()