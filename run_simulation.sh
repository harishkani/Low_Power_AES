#!/bin/bash

################################################################################
# AES Verification Simulation Script
# Runs testbench to verify both original and optimized designs
################################################################################

echo "=========================================="
echo "AES Design Verification"
echo "=========================================="

# Check for Icarus Verilog
if command -v iverilog &> /dev/null; then
    echo "Using Icarus Verilog..."

    # Compile all source files
    iverilog -o aes_sim \
        -g2012 \
        tb_aes_verification.v \
        aes_core_fixed.v \
        aes_core_optimized.v \
        aes_subbytes_32bit.v \
        aes_sbox.v \
        aes_inv_sbox.v \
        aes_shiftrows_128bit.v \
        aes_mixcolumns_32bit.v \
        aes_key_expansion_otf.v

    if [ $? -eq 0 ]; then
        echo "Compilation successful!"
        echo ""
        echo "Running simulation..."
        echo "=========================================="

        # Run simulation
        vvp aes_sim

        # Check result
        if [ $? -eq 0 ]; then
            echo ""
            echo "Simulation completed successfully!"
        else
            echo ""
            echo "ERROR: Simulation failed!"
            exit 1
        fi
    else
        echo "ERROR: Compilation failed!"
        exit 1
    fi

elif command -v vlog &> /dev/null; then
    echo "Using ModelSim/Questa..."

    # Create work library
    if [ ! -d "work" ]; then
        vlib work
    fi

    # Compile all source files
    vlog -sv \
        tb_aes_verification.v \
        aes_core_fixed.v \
        aes_core_optimized.v \
        aes_subbytes_32bit.v \
        aes_sbox.v \
        aes_inv_sbox.v \
        aes_shiftrows_128bit.v \
        aes_mixcolumns_32bit.v \
        aes_key_expansion_otf.v

    if [ $? -eq 0 ]; then
        echo "Compilation successful!"
        echo ""
        echo "Running simulation..."
        echo "=========================================="

        # Run simulation
        vsim -c -do "run -all; quit" tb_aes_verification

        if [ $? -eq 0 ]; then
            echo ""
            echo "Simulation completed successfully!"
        else
            echo ""
            echo "ERROR: Simulation failed!"
            exit 1
        fi
    else
        echo "ERROR: Compilation failed!"
        exit 1
    fi

else
    echo "ERROR: No Verilog simulator found!"
    echo ""
    echo "Please install one of the following:"
    echo "  - Icarus Verilog: sudo apt-get install iverilog"
    echo "  - ModelSim/Questa"
    echo "  - Or use Vivado simulation (see run_vivado_sim.tcl)"
    echo ""
    echo "Alternatively, you can run the Vivado simulation:"
    echo "  vivado -mode batch -source run_vivado_sim.tcl"
    exit 1
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
