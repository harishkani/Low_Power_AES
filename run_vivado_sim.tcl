################################################################################
# Vivado Simulation TCL Script
# Runs AES verification testbench
################################################################################

# Create simulation project
create_project -force sim_aes ./sim_project -part xc7a100tcsg324-1

# Add design source files
add_files {
    aes_core_fixed.v
    aes_core_optimized.v
    aes_subbytes_32bit.v
    aes_sbox.v
    aes_inv_sbox.v
    aes_shiftrows_128bit.v
    aes_mixcolumns_32bit.v
    aes_key_expansion_otf.v
}

# Add testbench
add_files -fileset sim_1 tb_aes_verification.v

# Set testbench as top
set_property top tb_aes_verification [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sim_1

# Launch simulation
launch_simulation

# Run for sufficient time (100us should be enough)
run 100us

# Close simulation
close_sim

puts "\n=========================================="
puts "Simulation Complete!"
puts "Check the TCL console output for results"
puts "==========================================\n"
