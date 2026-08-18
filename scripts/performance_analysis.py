#!/usr/bin/env python3
"""
Performance analysis script for systolic array
"""
import numpy as np
import matplotlib.pyplot as plt

def calculate_performance(N, data_width=16, acc_width=32):
    """
    Calculate performance metrics for NxN systolic array
    """
    # Theoretical peak throughput (operations/cycle)
    peak_throughput = N * N
    
    # Latency for NxN * NxM (assuming M=N for square)
    latency = 3 * N - 2
    
    # Area approximation (in terms of processing elements)
    area_pes = N * N
    
    # Memory bandwidth requirement (elements/cycle)
    # Each PE needs 2 inputs per cycle (A and B)
    bandwidth = 2 * N * N  # reads/writes per cycle
    
    # Utilization for large matrices
    utilization = 100.0  # approaches 100% for large matrices
    
    return {
        'peak_throughput': peak_throughput,
        'latency': latency,
        'area_pes': area_pes,
        'bandwidth': bandwidth,
        'utilization': utilization
    }

def plot_scaling():
    """
    Plot how performance scales with array size
    """
    N_values = list(range(2, 33, 2))  # 2, 4, 6, ..., 32
    throughputs = []
    latencies = []
    areas = []
    
    for N in N_values:
        perf = calculate_performance(N)
        throughputs.append(perf['peak_throughput'])
        latencies.append(perf['latency'])
        areas.append(perf['area_pes'])
    
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(10, 12))
    
    ax1.plot(N_values, throughputs, 'b-o', linewidth=2, markersize=6)
    ax1.set_title('Peak Throughput vs Array Size', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Operations/Cycle')
    ax1.set_xlabel('Array Dimension (N)')
    ax1.grid(True, alpha=0.3)
    
    ax2.plot(N_values, latencies, 'r-s', linewidth=2, markersize=6)
    ax2.set_title('Latency vs Array Size', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Cycles')
    ax2.set_xlabel('Array Dimension (N)')
    ax2.grid(True, alpha=0.3)
    
    ax3.plot(N_values, areas, 'g-^', linewidth=2, markersize=6)
    ax3.set_title('Area (Processing Elements) vs Array Size', fontsize=14, fontweight='bold')
    ax3.set_ylabel('Number of PEs')
    ax3.set_xlabel('Array Dimension (N)')
    ax3.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('scaling_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()

if __name__ == "__main__":
    print("Systolic Array Performance Analysis")
    print("=" * 40)
    
    # Example calculations
    for N in [4, 8, 16, 32]:
        perf = calculate_performance(N)
        print(f"NxN Array (N={N}):")
        print(f"  Peak Throughput: {perf['peak_throughput']} operations/cycle")
        print(f"  Latency: {perf['latency']} cycles")
        print(f"  Area: {perf['area_pes']} PEs")
        print(f"  Memory Bandwidth: {perf['bandwidth']} elements/cycle")
        print(f"  Utilization: {perf['utilization']}%")
        print()
    
    # Generate scaling plots
    print("Generating scaling plots...")
    plot_scaling()
