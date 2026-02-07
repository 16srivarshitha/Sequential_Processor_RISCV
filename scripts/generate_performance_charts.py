import matplotlib.pyplot as plt
import numpy as np

def create_performance_charts():
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('RISC-V Processor Performance Comparison', fontsize=16, weight='bold')
    
    implementations = ['Single-Cycle', 'Multi-Cycle', 'Pipelined']
    colors = ['#FF6B6B', '#4ECDC4', '#45B7D1']
    
    # Chart 1: Maximum Frequency
    frequencies = [106.38, 270.27, 285.71]
    ax1.bar(implementations, frequencies, color=colors, edgecolor='black', linewidth=1.5)
    ax1.set_ylabel('Frequency (MHz)', fontsize=11, weight='bold')
    ax1.set_title('Maximum Clock Frequency', fontsize=12, weight='bold')
    ax1.set_ylim(0, 320)
    ax1.grid(axis='y', alpha=0.3)
    for i, (impl, freq) in enumerate(zip(implementations, frequencies)):
        ax1.text(i, freq + 10, f'{freq:.1f} MHz', ha='center', fontsize=10, weight='bold')
    
    # Chart 2: CPI (Cycles Per Instruction)
    cpis = [1.0, 4.25, 3.0]
    ax2.bar(implementations, cpis, color=colors, edgecolor='black', linewidth=1.5)
    ax2.set_ylabel('CPI', fontsize=11, weight='bold')
    ax2.set_title('Cycles Per Instruction', fontsize=12, weight='bold')
    ax2.set_ylim(0, 5)
    ax2.grid(axis='y', alpha=0.3)
    for i, (impl, cpi) in enumerate(zip(implementations, cpis)):
        ax2.text(i, cpi + 0.15, f'{cpi:.2f}', ha='center', fontsize=10, weight='bold')
    
    # Chart 3: Execution Time
    exec_times = [94.0, 157.25, 105.0]
    ax3.bar(implementations, exec_times, color=colors, edgecolor='black', linewidth=1.5)
    ax3.set_ylabel('Execution Time (ns)', fontsize=11, weight='bold')
    ax3.set_title('Execution Time (10 instructions)', fontsize=12, weight='bold')
    ax3.set_ylim(0, 180)
    ax3.grid(axis='y', alpha=0.3)
    for i, (impl, time) in enumerate(zip(implementations, exec_times)):
        ax3.text(i, time + 5, f'{time:.1f} ns', ha='center', fontsize=10, weight='bold')
    
    # Chart 4: Speedup Comparison
    speedups = [1.0, 0.60, 0.90]
    bars = ax4.bar(implementations, speedups, color=colors, edgecolor='black', linewidth=1.5)
    ax4.axhline(y=1.0, color='red', linestyle='--', linewidth=2, alpha=0.7, label='Baseline')
    ax4.set_ylabel('Speedup (relative to single-cycle)', fontsize=11, weight='bold')
    ax4.set_title('Performance Speedup', fontsize=12, weight='bold')
    ax4.set_ylim(0, 1.2)
    ax4.grid(axis='y', alpha=0.3)
    ax4.legend()
    for i, (impl, speedup) in enumerate(zip(implementations, speedups)):
        ax4.text(i, speedup + 0.03, f'{speedup:.2f}x', ha='center', fontsize=10, weight='bold')
    
    plt.tight_layout()
    return fig

def create_critical_path_comparison():
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Critical path delays
    implementations = {
        'Single-Cycle\n(Load)': [
            ('Instr Mem', 2.5),
            ('Decode', 0.5),
            ('Control', 0.3),
            ('RegFile Read', 1.0),
            ('ALU', 1.5),
            ('Data Mem', 2.5),
            ('Wires/Setup', 1.1),
        ],
        'Multi-Cycle\n(Memory Stage)': [
            ('Clk-to-Q', 0.4),
            ('Mux', 0.3),
            ('Memory', 2.5),
            ('Wires/Setup', 0.5),
        ],
        'Pipelined\n(IF/MEM Stages)': [
            ('Clk-to-Q', 0.4),
            ('Memory', 2.5),
            ('Wires/Setup', 0.6),
        ],
    }
    
    y_pos = 0
    colors_map = {
        'Instr Mem': '#FF6B6B',
        'Data Mem': '#FF6B6B',
        'Memory': '#FF6B6B',
        'Decode': '#4ECDC4',
        'Control': '#4ECDC4',
        'RegFile Read': '#95E1D3',
        'ALU': '#45B7D1',
        'Mux': '#F38181',
        'Clk-to-Q': '#AA96DA',
        'Wires/Setup': '#EAEAEA',
    }
    
    for impl_name, components in implementations.items():
        x_offset = 0
        for comp_name, delay in components:
            color = colors_map.get(comp_name, '#CCCCCC')
            ax.barh(y_pos, delay, left=x_offset, height=0.6, 
                   color=color, edgecolor='black', linewidth=1)
            if delay > 0.5:
                ax.text(x_offset + delay/2, y_pos, comp_name, 
                       ha='center', va='center', fontsize=8, weight='bold')
            x_offset += delay
        
        total = sum(d for _, d in components)
        ax.text(x_offset + 0.3, y_pos, f'{total:.2f} ns', 
               va='center', fontsize=10, weight='bold')
        y_pos += 1
    
    ax.set_yticks(range(len(implementations)))
    ax.set_yticklabels(implementations.keys(), fontsize=11)
    ax.set_xlabel('Delay (ns)', fontsize=12, weight='bold')
    ax.set_title('Critical Path Comparison', fontsize=14, weight='bold')
    ax.grid(axis='x', alpha=0.3)
    ax.set_xlim(0, 11)
    
    plt.tight_layout()
    return fig

if __name__ == '__main__':
    fig1 = create_performance_charts()
    fig1.savefig('docs/diagrams/performance_comparison.png', dpi=300, bbox_inches='tight')
    print("Generated: performance_comparison.png")
    
    fig2 = create_critical_path_comparison()
    fig2.savefig('docs/diagrams/critical_path_comparison.png', dpi=300, bbox_inches='tight')
    print("Generated: critical_path_comparison.png")
    
    plt.close('all')