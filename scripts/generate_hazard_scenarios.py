#!/usr/bin/env python3
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch

def draw_hazard_scenarios():
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Pipeline Hazard Scenarios', fontsize=16, weight='bold')
    
    # Helper function to draw instruction boxes
    def draw_instr_box(ax, x, y, width, height, label, color):
        box = FancyBboxPatch((x, y), width, height, boxstyle="round,pad=0.05",
                            edgecolor='black', facecolor=color, linewidth=2)
        ax.add_patch(box)
        ax.text(x + width/2, y + height/2, label, ha='center', va='center',
                fontsize=10, weight='bold')
    
    # ==================== Scenario 1: EX Hazard (Forwarding from MEM) ====================
    ax1 = axes[0, 0]
    ax1.set_xlim(0, 10)
    ax1.set_ylim(0, 6)
    ax1.axis('off')
    ax1.set_title('EX Hazard - Forward from MEM', fontsize=12, weight='bold')
    
    # Timeline
    stages = ['IF', 'ID', 'EX', 'MEM', 'WB']
    for i, stage in enumerate(stages):
        ax1.text(2 + i*1.5, 5.5, stage, ha='center', fontsize=10, weight='bold')
    
    # Instruction 1: ADD x1, x2, x3
    colors = ['#90EE90', '#FFFACD', '#FFB6C1', '#B0E0E6', '#DDA0DD']
    for i, color in enumerate(colors):
        draw_instr_box(ax1, 2 + i*1.5, 3.5, 1.2, 0.6, '', color)
    ax1.text(0.5, 3.8, 'ADD x1,x2,x3', fontsize=9, weight='bold')
    
    # Instruction 2: SUB x4, x1, x5
    for i, color in enumerate(colors[:4]):
        draw_instr_box(ax1, 3.5 + i*1.5, 2.5, 1.2, 0.6, '', color)
    ax1.text(0.5, 2.8, 'SUB x4,x1,x5', fontsize=9, weight='bold')
    
    # Hazard indication
    ax1.annotate('', xy=(5.0, 3.5), xytext=(5.0, 3.1),
                arrowprops=dict(arrowstyle='->', color='red', lw=3))
    ax1.text(5.5, 3.3, 'Forward x1\nfrom MEM', fontsize=9, color='red', weight='bold')
    
    # ==================== Scenario 2: MEM Hazard (Forwarding from WB) ====================
    ax2 = axes[0, 1]
    ax2.set_xlim(0, 10)
    ax2.set_ylim(0, 6)
    ax2.axis('off')
    ax2.set_title('MEM Hazard - Forward from WB', fontsize=12, weight='bold')
    
    # Timeline
    for i, stage in enumerate(stages):
        ax2.text(2 + i*1.5, 5.5, stage, ha='center', fontsize=10, weight='bold')
    
    # Instruction 1: ADD x1, x2, x3
    for i, color in enumerate(colors):
        draw_instr_box(ax2, 2 + i*1.5, 3.5, 1.2, 0.6, '', color)
    ax2.text(0.5, 3.8, 'ADD x1,x2,x3', fontsize=9, weight='bold')
    
    # Instruction 2: NOP
    for i in range(4):
        draw_instr_box(ax2, 3.5 + i*1.5, 2.8, 1.2, 0.6, '', '#E0E0E0')
    ax2.text(0.5, 3.1, 'NOP', fontsize=9, weight='bold')
    
    # Instruction 3: SUB x4, x1, x5
    for i, color in enumerate(colors[:3]):
        draw_instr_box(ax2, 5.0 + i*1.5, 2.0, 1.2, 0.6, '', color)
    ax2.text(0.5, 2.3, 'SUB x4,x1,x5', fontsize=9, weight='bold')
    
    # Hazard indication
    ax2.annotate('', xy=(6.5, 3.5), xytext=(6.5, 2.6),
                arrowprops=dict(arrowstyle='->', color='green', lw=3))
    ax2.text(7.0, 3.0, 'Forward x1\nfrom WB', fontsize=9, color='green', weight='bold')
    
    # ==================== Scenario 3: Load-Use Hazard (Stall) ====================
    ax3 = axes[1, 0]
    ax3.set_xlim(0, 10)
    ax3.set_ylim(0, 6)
    ax3.axis('off')
    ax3.set_title('Load-Use Hazard - STALL Required', fontsize=12, weight='bold')
    
    # Timeline
    for i, stage in enumerate(stages):
        ax3.text(2 + i*1.5, 5.5, stage, ha='center', fontsize=10, weight='bold')
    
    # Instruction 1: LD x1, 0(x2)
    for i, color in enumerate(colors):
        draw_instr_box(ax3, 2 + i*1.5, 3.5, 1.2, 0.6, '', color)
    ax3.text(0.5, 3.8, 'LD x1,0(x2)', fontsize=9, weight='bold')
    
    # Stall (bubble)
    draw_instr_box(ax3, 3.5, 2.5, 1.2, 0.6, 'STALL', '#FFFF99')
    draw_instr_box(ax3, 5.0, 2.5, 1.2, 0.6, 'STALL', '#FFFF99')
    
    # Instruction 2: ADD x3, x1, x4 (delayed)
    for i, color in enumerate(colors[:3]):
        draw_instr_box(ax3, 6.5 + i*1.5, 2.5, 1.2, 0.6, '', color)
    ax3.text(0.5, 2.8, 'ADD x3,x1,x4', fontsize=9, weight='bold')
    
    # Hazard indication
    ax3.text(4.0, 1.5, 'Pipeline stalled for 1 cycle\nWaiting for LD to complete',
            fontsize=9, color='red', weight='bold', ha='center',
            bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', edgecolor='red', lw=2))
    
    # ==================== Scenario 4: Branch Hazard (Flush) ====================
    ax4 = axes[1, 1]
    ax4.set_xlim(0, 10)
    ax4.set_ylim(0, 6)
    ax4.axis('off')
    ax4.set_title('Control Hazard - Branch Flush', fontsize=12, weight='bold')
    
    # Timeline
    for i, stage in enumerate(stages):
        ax4.text(2 + i*1.5, 5.5, stage, ha='center', fontsize=10, weight='bold')
    
    # Instruction 1: BEQ x1, x2, LABEL
    for i, color in enumerate(colors[:3]):
        draw_instr_box(ax4, 2 + i*1.5, 3.5, 1.2, 0.6, '', color)
    ax4.text(0.5, 3.8, 'BEQ x1,x2,L', fontsize=9, weight='bold')
    
    # Wrong path instruction (flushed)
    draw_instr_box(ax4, 3.5, 2.5, 1.2, 0.6, 'FLUSH', '#FF9999')
    draw_instr_box(ax4, 5.0, 2.5, 1.2, 0.6, 'FLUSH', '#FF9999')
    ax4.text(0.5, 2.8, 'Wrong Path', fontsize=9, weight='bold')
    
    # Correct path instruction
    for i, color in enumerate(colors[:2]):
        draw_instr_box(ax4, 6.5 + i*1.5, 2.0, 1.2, 0.6, '', color)
    ax4.text(0.5, 2.3, 'L: (correct)', fontsize=9, weight='bold')
    
    # Hazard indication
    ax4.text(4.5, 1.2, 'Branch taken → Flush pipeline\nRestart from branch target',
            fontsize=9, color='red', weight='bold', ha='center',
            bbox=dict(boxstyle='round,pad=0.5', facecolor='#FFE6E6', edgecolor='red', lw=2))
    
    plt.tight_layout()
    return fig

if __name__ == '__main__':
    fig = draw_hazard_scenarios()
    fig.savefig('hazard_scenarios.png', dpi=300, bbox_inches='tight')
    print("Generated: hazard_scenarios.png")
    plt.close()