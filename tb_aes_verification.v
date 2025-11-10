`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Comprehensive Testbench for AES Verification
// Tests both original and optimized designs with NIST test vectors
////////////////////////////////////////////////////////////////////////////////

module tb_aes_verification;

// Clock and reset
reg clk;
reg rst_n;

// Control signals
reg start;
reg enc_dec;  // 1=encrypt, 0=decrypt

// Data and key
reg [127:0] data_in;
reg [127:0] key_in;

// Outputs - Original Design
wire [127:0] data_out_original;
wire ready_original;

// Outputs - Optimized Design
wire [127:0] data_out_optimized;
wire ready_optimized;

// Test tracking
integer test_num;
integer cycle_count_original;
integer cycle_count_optimized;
integer errors;
integer total_tests;

////////////////////////////////////////////////////////////////////////////////
// Instantiate Original AES Core
////////////////////////////////////////////////////////////////////////////////
aes_core_fixed original_core (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .enc_dec(enc_dec),
    .data_in(data_in),
    .key_in(key_in),
    .data_out(data_out_original),
    .ready(ready_original)
);

////////////////////////////////////////////////////////////////////////////////
// Instantiate Optimized AES Core
////////////////////////////////////////////////////////////////////////////////
aes_core_optimized optimized_core (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .enc_dec(enc_dec),
    .data_in(data_in),
    .key_in(key_in),
    .data_out(data_out_optimized),
    .ready(ready_optimized)
);

////////////////////////////////////////////////////////////////////////////////
// Clock Generation (100 MHz)
////////////////////////////////////////////////////////////////////////////////
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period = 100 MHz
end

////////////////////////////////////////////////////////////////////////////////
// Test Vectors (NIST FIPS 197)
////////////////////////////////////////////////////////////////////////////////
reg [127:0] test_keys [0:7];
reg [127:0] test_plaintexts [0:7];
reg [127:0] test_ciphertexts [0:7];

initial begin
    // Test Vector 0 (NIST FIPS 197 Appendix C.1)
    test_keys[0]       = 128'h000102030405060708090a0b0c0d0e0f;
    test_plaintexts[0] = 128'h00112233445566778899aabbccddeeff;
    test_ciphertexts[0]= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    // Test Vector 1 (NIST)
    test_keys[1]       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    test_plaintexts[1] = 128'h3243f6a8885a308d313198a2e0370734;
    test_ciphertexts[1]= 128'h3925841d02dc09fbdc118597196a0b32;

    // Test Vector 2 (All zeros)
    test_keys[2]       = 128'h00000000000000000000000000000000;
    test_plaintexts[2] = 128'h00000000000000000000000000000000;
    test_ciphertexts[2]= 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;

    // Test Vector 3 (All ones)
    test_keys[3]       = 128'hffffffffffffffffffffffffffffffff;
    test_plaintexts[3] = 128'hffffffffffffffffffffffffffffffff;
    test_ciphertexts[3]= 128'ha1f6258c877d5fcd8964484538bfc92c;

    // Test Vector 4
    test_keys[4]       = 128'h10a58869d74be5a374cf867cfb473859;
    test_plaintexts[4] = 128'h00000000000000000000000000000000;
    test_ciphertexts[4]= 128'h6d251e6944b051e04eaa6fb4dbf78465;

    // Test Vector 5
    test_keys[5]       = 128'hcaea65cdbb75e9169ecd22ebe6e54675;
    test_plaintexts[5] = 128'h00000000000000000000000000000000;
    test_ciphertexts[5]= 128'h6e29201190152df4ee058139def610bb;

    // Test Vector 6
    test_keys[6]       = 128'ha2e2fa9baf7d20822ca9f0542f764a41;
    test_plaintexts[6] = 128'h00000000000000000000000000000000;
    test_ciphertexts[6]= 128'hc3b44b95d9d2f25670eee9a0de099fa3;

    // Test Vector 7
    test_keys[7]       = 128'hb6364ac4e1de1e285eaf144a2415f7a0;
    test_plaintexts[7] = 128'h00000000000000000000000000000000;
    test_ciphertexts[7]= 128'h5d9b05578fc944b3cf1ccf0e746cd581;
end

////////////////////////////////////////////////////////////////////////////////
// Test Execution Task
////////////////////////////////////////////////////////////////////////////////
task run_encryption_test;
    input integer test_id;
    input [127:0] key;
    input [127:0] plaintext;
    input [127:0] expected_ciphertext;
    reg [127:0] result_original;
    reg [127:0] result_optimized;
    integer cycles_orig;
    integer cycles_opt;
begin
    $display("\n========================================");
    $display("ENCRYPTION TEST %0d", test_id);
    $display("========================================");
    $display("Key:       %h", key);
    $display("Plaintext: %h", plaintext);
    $display("Expected:  %h", expected_ciphertext);

    // Setup
    enc_dec = 1'b1;  // Encrypt mode
    key_in = key;
    data_in = plaintext;

    // Wait for ready to be low
    @(posedge clk);
    @(posedge clk);

    // Start encryption
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    // Count cycles for original design
    cycles_orig = 0;
    while (!ready_original) begin
        @(posedge clk);
        cycles_orig = cycles_orig + 1;
        if (cycles_orig > 200) begin
            $display("ERROR: Original design timeout!");
            errors = errors + 1;
            cycles_orig = -1;
            break;
        end
    end
    result_original = data_out_original;

    // Count cycles for optimized design (should finish faster)
    cycles_opt = 0;
    while (!ready_optimized) begin
        @(posedge clk);
        cycles_opt = cycles_opt + 1;
        if (cycles_opt > 200) begin
            $display("ERROR: Optimized design timeout!");
            errors = errors + 1;
            cycles_opt = -1;
            break;
        end
    end
    result_optimized = data_out_optimized;

    // Display results
    $display("\n--- ORIGINAL DESIGN ---");
    $display("Output:    %h", result_original);
    $display("Cycles:    %0d", cycles_orig);
    if (result_original === expected_ciphertext)
        $display("Status:    PASS ✓");
    else begin
        $display("Status:    FAIL ✗");
        errors = errors + 1;
    end

    $display("\n--- OPTIMIZED DESIGN ---");
    $display("Output:    %h", result_optimized);
    $display("Cycles:    %0d", cycles_opt);
    if (result_optimized === expected_ciphertext)
        $display("Status:    PASS ✓");
    else begin
        $display("Status:    FAIL ✗");
        errors = errors + 1;
    end

    // Check if both produce same result
    $display("\n--- COMPARISON ---");
    if (result_original === result_optimized) begin
        $display("Original == Optimized: PASS ✓");
    end else begin
        $display("Original == Optimized: FAIL ✗");
        $display("Mismatch detected!");
        errors = errors + 1;
    end

    // Check cycle count
    if (cycles_orig > 0 && cycles_opt > 0) begin
        $display("Speedup: %.2fx faster (%0d vs %0d cycles)",
                 real'(cycles_orig) / real'(cycles_opt),
                 cycles_orig, cycles_opt);

        // Verify expected cycle counts
        if (cycles_orig != 129) begin
            $display("WARNING: Original expected 129 cycles, got %0d", cycles_orig);
        end
        if (cycles_opt != 32) begin
            $display("WARNING: Optimized expected 32 cycles, got %0d", cycles_opt);
        end
    end

    cycle_count_original = cycle_count_original + cycles_orig;
    cycle_count_optimized = cycle_count_optimized + cycles_opt;
    total_tests = total_tests + 1;

    // Wait before next test
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
end
endtask

////////////////////////////////////////////////////////////////////////////////
// Decryption Test Task
////////////////////////////////////////////////////////////////////////////////
task run_decryption_test;
    input integer test_id;
    input [127:0] key;
    input [127:0] ciphertext;
    input [127:0] expected_plaintext;
    reg [127:0] result_original;
    reg [127:0] result_optimized;
    integer cycles_orig;
    integer cycles_opt;
begin
    $display("\n========================================");
    $display("DECRYPTION TEST %0d", test_id);
    $display("========================================");
    $display("Key:        %h", key);
    $display("Ciphertext: %h", ciphertext);
    $display("Expected:   %h", expected_plaintext);

    // Setup
    enc_dec = 1'b0;  // Decrypt mode
    key_in = key;
    data_in = ciphertext;

    // Wait for ready to be low
    @(posedge clk);
    @(posedge clk);

    // Start decryption
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    // Count cycles for original design
    cycles_orig = 0;
    while (!ready_original) begin
        @(posedge clk);
        cycles_orig = cycles_orig + 1;
        if (cycles_orig > 200) begin
            $display("ERROR: Original design timeout!");
            errors = errors + 1;
            cycles_orig = -1;
            break;
        end
    end
    result_original = data_out_original;

    // Count cycles for optimized design
    cycles_opt = 0;
    while (!ready_optimized) begin
        @(posedge clk);
        cycles_opt = cycles_opt + 1;
        if (cycles_opt > 200) begin
            $display("ERROR: Optimized design timeout!");
            errors = errors + 1;
            cycles_opt = -1;
            break;
        end
    end
    result_optimized = data_out_optimized;

    // Display results
    $display("\n--- ORIGINAL DESIGN ---");
    $display("Output:    %h", result_original);
    $display("Cycles:    %0d", cycles_orig);
    if (result_original === expected_plaintext)
        $display("Status:    PASS ✓");
    else begin
        $display("Status:    FAIL ✗");
        errors = errors + 1;
    end

    $display("\n--- OPTIMIZED DESIGN ---");
    $display("Output:    %h", result_optimized);
    $display("Cycles:    %0d", cycles_opt);
    if (result_optimized === expected_plaintext)
        $display("Status:    PASS ✓");
    else begin
        $display("Status:    FAIL ✗");
        errors = errors + 1;
    end

    // Check if both produce same result
    $display("\n--- COMPARISON ---");
    if (result_original === result_optimized) begin
        $display("Original == Optimized: PASS ✓");
    end else begin
        $display("Original == Optimized: FAIL ✗");
        $display("Mismatch detected!");
        errors = errors + 1;
    end

    // Check cycle count
    if (cycles_orig > 0 && cycles_opt > 0) begin
        $display("Speedup: %.2fx faster (%0d vs %0d cycles)",
                 real'(cycles_orig) / real'(cycles_opt),
                 cycles_orig, cycles_opt);

        // Verify expected cycle counts
        if (cycles_orig != 175) begin
            $display("WARNING: Original expected 175 cycles, got %0d", cycles_orig);
        end
        if (cycles_opt != 44) begin
            $display("WARNING: Optimized expected 44 cycles, got %0d", cycles_opt);
        end
    end

    cycle_count_original = cycle_count_original + cycles_orig;
    cycle_count_optimized = cycle_count_optimized + cycles_opt;
    total_tests = total_tests + 1;

    // Wait before next test
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
end
endtask

////////////////////////////////////////////////////////////////////////////////
// Main Test Sequence
////////////////////////////////////////////////////////////////////////////////
initial begin
    // Initialize
    $display("\n");
    $display("================================================================================");
    $display("AES CORE VERIFICATION TESTBENCH");
    $display("Comparing Original vs Optimized Designs");
    $display("================================================================================");

    errors = 0;
    total_tests = 0;
    cycle_count_original = 0;
    cycle_count_optimized = 0;

    rst_n = 0;
    start = 0;
    enc_dec = 1;
    data_in = 128'h0;
    key_in = 128'h0;

    // Reset
    #100;
    rst_n = 1;
    #50;

    // Run all encryption tests
    $display("\n\n");
    $display("################################################################################");
    $display("# ENCRYPTION TESTS");
    $display("################################################################################");

    for (test_num = 0; test_num < 8; test_num = test_num + 1) begin
        run_encryption_test(
            test_num,
            test_keys[test_num],
            test_plaintexts[test_num],
            test_ciphertexts[test_num]
        );
    end

    // Run all decryption tests
    $display("\n\n");
    $display("################################################################################");
    $display("# DECRYPTION TESTS");
    $display("################################################################################");

    for (test_num = 0; test_num < 8; test_num = test_num + 1) begin
        run_decryption_test(
            test_num,
            test_keys[test_num],
            test_ciphertexts[test_num],
            test_plaintexts[test_num]
        );
    end

    // Final summary
    $display("\n\n");
    $display("================================================================================");
    $display("FINAL SUMMARY");
    $display("================================================================================");
    $display("Total Tests:   %0d", total_tests);
    $display("Errors:        %0d", errors);

    if (errors == 0) begin
        $display("\n✓✓✓ ALL TESTS PASSED! ✓✓✓");
        $display("\nBoth original and optimized designs produce correct outputs.");
    end else begin
        $display("\n✗✗✗ %0d TESTS FAILED! ✗✗✗", errors);
    end

    $display("\n--- PERFORMANCE COMPARISON ---");
    $display("Average cycles (Original):  %.1f", real'(cycle_count_original) / real'(total_tests));
    $display("Average cycles (Optimized): %.1f", real'(cycle_count_optimized) / real'(total_tests));
    $display("Overall Speedup:            %.2fx",
             real'(cycle_count_original) / real'(cycle_count_optimized));

    $display("\nExpected Performance:");
    $display("  Original:  129 cycles (encryption), 175 cycles (decryption)");
    $display("  Optimized: 32 cycles (encryption), 44 cycles (decryption)");
    $display("  Expected Speedup: ~4x");

    $display("\n================================================================================");
    $display("Simulation Complete");
    $display("================================================================================\n");

    // Finish simulation
    #1000;
    $finish;
end

// Timeout watchdog
initial begin
    #100000000; // 100ms timeout
    $display("\nERROR: Simulation timeout!");
    $finish;
end

endmodule
