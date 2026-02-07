#!/usr/bin/env python3
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch

def draw_pipeline_timing():
    fig, ax = plt.subplots(figsize=(14, 8))
    ax.set_xlim(-1, 10)
    ax.set_ylim(0, 6.5)
    ax.axis('off')
    
    # Title
    ax.text(4.5, 6.2, 'Pipeline Timing Diagram - Ideal Case (No Hazards)',
           fontsize=14, weight='bold', ha='center')
    
    # Stage colors
    colors = {
        'IF': '#90EE90',
        'ID': '#FFFACD',
        'EX': '#FFB6C1',
        'MEM': '#B0E0E6',
        'WB': '#DDA0DD'
    }
    
    # Time labels (cycles)
    for i in range(9):
        ax.text(i, 5.7, f'T{i}', ha='center', fontsize=10, weight='bold')
        ax.axvline(x=i-0.5, color='gray', linewidth=0.5, linestyle=':', alpha=0.5)
    
    # Instructions
    instructions = ['I1', 'I2', 'I3', 'I4', 'I5']
    stage_names = ['IF', 'ID', 'EX', 'MEM', 'WB']
    
    for instr_idx, instr in enumerate(instructions):
        y_pos = 5 - instr_idx * 0.8
        
        # Instruction label
        ax.text(-0.7, y_pos, instr, fontsize=11, weight='bold', ha='center')
        
        # Draw stages
        for stage_idx, stage in enumerate(stage_names):
            x_pos = instr_idx + stage_idx
            if x_pos < 9:  # Don't draw beyond the timeline
                box = FancyBboxPatch((x_pos - 0.4, y_pos - 0.3),
                                    0.8, 0.6,
                                    boxstyle="round,pad=0.02",
                                    edgecolor='black',
                                    facecolor=colors[stage],
                                    linewidth=1.5)
                ax.add_patch(box)
                ax.text(x_pos, y_pos, stage, ha='center', va='center',
                       fontsize=9, weight='bold')
    
    # Performance metrics box
    metrics_text = ("Throughput: 1 instruction/cycle (after fill)\n"
                   "Latency: 5 cycles per instruction\n"
                   "Pipeline Speedup: ~5x (ideal)")
    ax.text(7.5, 1.5, metrics_text, fontsize=10,
           bbox=dict(boxstyle='round,pad=0.8', facecolor='lightyellow',
                    edgecolor='black', linewidth=2),
           verticalalignment='top')
    
    # Stage legend
    legend_y = 0.5
    for idx, (stage, color) in enumerate(colors.items()):
        x_pos = idx * 1.5
        box = FancyBboxPatch((x_pos - 0.3, legend_y - 0.15),
                            0.6, 0.3,
                            boxstyle="round,pad=0.02",
                            edgecolor='black',
                            facecolor=color,
                            linewidth=1.5)
        ax.add_patch(box)
        ax.text(x_pos, legend_y, stage, ha='center', va='center',
               fontsize=9, weight='bold')
    
    plt.tight_layout()
    return fig

if __name__ == '__main__':
    fig = draw_pipeline_timing()
    fig.savefig('pipeline_timing.png', dpi=300, bbox_inches='tight')
    print("Generated: pipeline_timing.png")
    plt.close()