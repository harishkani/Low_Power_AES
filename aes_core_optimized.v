`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// AES-128 Core - OPTIMIZED Version - Phase 1
//
// OPTIMIZATIONS APPLIED:
// 1. Parallel column processing (4x SubBytes, 4x MixColumns)
// 2. Overlapped key expansion with encryption/decryption
// 3. One-hot state encoding for faster transitions
// 4. Optimized for 200 MHz operation
//
// EXPECTED PERFORMANCE:
// - Encryption: ~32 cycles (vs 129 original) = 4x improvement
// - Decryption: ~44 cycles (vs 175 original) = 4x improvement
// - Throughput @ 200MHz: ~800 Mbps (vs 99 Mbps original) = 8x improvement
//
// Handles both encryption and decryption
// NO RAM inference - stores keys as shift register
////////////////////////////////////////////////////////////////////////////////

module aes_core_optimized(
    input wire         clk,
    input wire         rst_n,
    input wire         start,
    input wire         enc_dec,      // 1=encrypt, 0=decrypt
    input wire [127:0] data_in,
    input wire [127:0] key_in,
    output reg [127:0] data_out,
    output reg         ready
);

////////////////////////////////////////////////////////////////////////////////
// State Machine Parameters - ONE-HOT ENCODING
////////////////////////////////////////////////////////////////////////////////
localparam IDLE           = 7'b0000001;
localparam KEY_EXPAND     = 7'b0000010;
localparam ROUND0         = 7'b0000100;
localparam ENC_SUB        = 7'b0001000;
localparam ENC_SHIFT_MIX  = 7'b0010000;
localparam DEC_SHIFT_SUB  = 7'b0100000;
localparam DEC_ADD_MIX    = 7'b1000000;
// DONE state merged into ready signal

////////////////////////////////////////////////////////////////////////////////
// Registers and Wires
////////////////////////////////////////////////////////////////////////////////
reg [6:0]   state;          // One-hot encoded
reg [3:0]   round_cnt;
reg [1:0]   phase;          // For decryption sub-phases
reg [127:0] aes_state;
reg [127:0] temp_state;
reg         enc_dec_reg;

// Key expansion interface
reg         key_start;
reg         key_next;
wire [31:0] key_word;
wire [5:0]  key_addr;
wire        key_ready;

// Key expansion progress tracking for overlapped execution
reg [5:0]   keys_loaded;    // Track how many keys are loaded
wire        enough_keys_for_round;

// Round key storage - using individual registers to avoid RAM inference
reg [31:0] rk00, rk01, rk02, rk03, rk04, rk05, rk06, rk07, rk08, rk09;
reg [31:0] rk10, rk11, rk12, rk13, rk14, rk15, rk16, rk17, rk18, rk19;
reg [31:0] rk20, rk21, rk22, rk23, rk24, rk25, rk26, rk27, rk28, rk29;
reg [31:0] rk30, rk31, rk32, rk33, rk34, rk35, rk36, rk37, rk38, rk39;
reg [31:0] rk40, rk41, rk42, rk43;

////////////////////////////////////////////////////////////////////////////////
// Key Expansion Module Instance
////////////////////////////////////////////////////////////////////////////////
aes_key_expansion_otf key_exp (
    .clk(clk),
    .rst_n(rst_n),
    .start(key_start),
    .key(key_in),
    .round_key(key_word),
    .word_addr(key_addr),
    .ready(key_ready),
    .next(key_next)
);

////////////////////////////////////////////////////////////////////////////////
// Overlapped Key Expansion Logic
////////////////////////////////////////////////////////////////////////////////
// Check if we have enough keys loaded for the current round
assign enough_keys_for_round = (keys_loaded >= ((round_cnt + 1) * 4));

////////////////////////////////////////////////////////////////////////////////
// Round Key Selection Logic - Parallel for all 4 columns
////////////////////////////////////////////////////////////////////////////////
wire [5:0] key_index0 = enc_dec_reg ? (round_cnt * 4 + 0) : ((10 - round_cnt) * 4 + 0);
wire [5:0] key_index1 = enc_dec_reg ? (round_cnt * 4 + 1) : ((10 - round_cnt) * 4 + 1);
wire [5:0] key_index2 = enc_dec_reg ? (round_cnt * 4 + 2) : ((10 - round_cnt) * 4 + 2);
wire [5:0] key_index3 = enc_dec_reg ? (round_cnt * 4 + 3) : ((10 - round_cnt) * 4 + 3);

// Round keys for all 4 columns
reg [31:0] current_rkey0, current_rkey1, current_rkey2, current_rkey3;

// Key selection multiplexers
always @(*) begin
    case (key_index0)
        6'd0:  current_rkey0 = rk00;  6'd1:  current_rkey0 = rk01;
        6'd2:  current_rkey0 = rk02;  6'd3:  current_rkey0 = rk03;
        6'd4:  current_rkey0 = rk04;  6'd5:  current_rkey0 = rk05;
        6'd6:  current_rkey0 = rk06;  6'd7:  current_rkey0 = rk07;
        6'd8:  current_rkey0 = rk08;  6'd9:  current_rkey0 = rk09;
        6'd10: current_rkey0 = rk10;  6'd11: current_rkey0 = rk11;
        6'd12: current_rkey0 = rk12;  6'd13: current_rkey0 = rk13;
        6'd14: current_rkey0 = rk14;  6'd15: current_rkey0 = rk15;
        6'd16: current_rkey0 = rk16;  6'd17: current_rkey0 = rk17;
        6'd18: current_rkey0 = rk18;  6'd19: current_rkey0 = rk19;
        6'd20: current_rkey0 = rk20;  6'd21: current_rkey0 = rk21;
        6'd22: current_rkey0 = rk22;  6'd23: current_rkey0 = rk23;
        6'd24: current_rkey0 = rk24;  6'd25: current_rkey0 = rk25;
        6'd26: current_rkey0 = rk26;  6'd27: current_rkey0 = rk27;
        6'd28: current_rkey0 = rk28;  6'd29: current_rkey0 = rk29;
        6'd30: current_rkey0 = rk30;  6'd31: current_rkey0 = rk31;
        6'd32: current_rkey0 = rk32;  6'd33: current_rkey0 = rk33;
        6'd34: current_rkey0 = rk34;  6'd35: current_rkey0 = rk35;
        6'd36: current_rkey0 = rk36;  6'd37: current_rkey0 = rk37;
        6'd38: current_rkey0 = rk38;  6'd39: current_rkey0 = rk39;
        6'd40: current_rkey0 = rk40;  6'd41: current_rkey0 = rk41;
        6'd42: current_rkey0 = rk42;  6'd43: current_rkey0 = rk43;
        default: current_rkey0 = 32'h0;
    endcase

    case (key_index1)
        6'd0:  current_rkey1 = rk00;  6'd1:  current_rkey1 = rk01;
        6'd2:  current_rkey1 = rk02;  6'd3:  current_rkey1 = rk03;
        6'd4:  current_rkey1 = rk04;  6'd5:  current_rkey1 = rk05;
        6'd6:  current_rkey1 = rk06;  6'd7:  current_rkey1 = rk07;
        6'd8:  current_rkey1 = rk08;  6'd9:  current_rkey1 = rk09;
        6'd10: current_rkey1 = rk10;  6'd11: current_rkey1 = rk11;
        6'd12: current_rkey1 = rk12;  6'd13: current_rkey1 = rk13;
        6'd14: current_rkey1 = rk14;  6'd15: current_rkey1 = rk15;
        6'd16: current_rkey1 = rk16;  6'd17: current_rkey1 = rk17;
        6'd18: current_rkey1 = rk18;  6'd19: current_rkey1 = rk19;
        6'd20: current_rkey1 = rk20;  6'd21: current_rkey1 = rk21;
        6'd22: current_rkey1 = rk22;  6'd23: current_rkey1 = rk23;
        6'd24: current_rkey1 = rk24;  6'd25: current_rkey1 = rk25;
        6'd26: current_rkey1 = rk26;  6'd27: current_rkey1 = rk27;
        6'd28: current_rkey1 = rk28;  6'd29: current_rkey1 = rk29;
        6'd30: current_rkey1 = rk30;  6'd31: current_rkey1 = rk31;
        6'd32: current_rkey1 = rk32;  6'd33: current_rkey1 = rk33;
        6'd34: current_rkey1 = rk34;  6'd35: current_rkey1 = rk35;
        6'd36: current_rkey1 = rk36;  6'd37: current_rkey1 = rk37;
        6'd38: current_rkey1 = rk38;  6'd39: current_rkey1 = rk39;
        6'd40: current_rkey1 = rk40;  6'd41: current_rkey1 = rk41;
        6'd42: current_rkey1 = rk42;  6'd43: current_rkey1 = rk43;
        default: current_rkey1 = 32'h0;
    endcase

    case (key_index2)
        6'd0:  current_rkey2 = rk00;  6'd1:  current_rkey2 = rk01;
        6'd2:  current_rkey2 = rk02;  6'd3:  current_rkey2 = rk03;
        6'd4:  current_rkey2 = rk04;  6'd5:  current_rkey2 = rk05;
        6'd6:  current_rkey2 = rk06;  6'd7:  current_rkey2 = rk07;
        6'd8:  current_rkey2 = rk08;  6'd9:  current_rkey2 = rk09;
        6'd10: current_rkey2 = rk10;  6'd11: current_rkey2 = rk11;
        6'd12: current_rkey2 = rk12;  6'd13: current_rkey2 = rk13;
        6'd14: current_rkey2 = rk14;  6'd15: current_rkey2 = rk15;
        6'd16: current_rkey2 = rk16;  6'd17: current_rkey2 = rk17;
        6'd18: current_rkey2 = rk18;  6'd19: current_rkey2 = rk19;
        6'd20: current_rkey2 = rk20;  6'd21: current_rkey2 = rk21;
        6'd22: current_rkey2 = rk22;  6'd23: current_rkey2 = rk23;
        6'd24: current_rkey2 = rk24;  6'd25: current_rkey2 = rk25;
        6'd26: current_rkey2 = rk26;  6'd27: current_rkey2 = rk27;
        6'd28: current_rkey2 = rk28;  6'd29: current_rkey2 = rk29;
        6'd30: current_rkey2 = rk30;  6'd31: current_rkey2 = rk31;
        6'd32: current_rkey2 = rk32;  6'd33: current_rkey2 = rk33;
        6'd34: current_rkey2 = rk34;  6'd35: current_rkey2 = rk35;
        6'd36: current_rkey2 = rk36;  6'd37: current_rkey2 = rk37;
        6'd38: current_rkey2 = rk38;  6'd39: current_rkey2 = rk39;
        6'd40: current_rkey2 = rk40;  6'd41: current_rkey2 = rk41;
        6'd42: current_rkey2 = rk42;  6'd43: current_rkey2 = rk43;
        default: current_rkey2 = 32'h0;
    endcase

    case (key_index3)
        6'd0:  current_rkey3 = rk00;  6'd1:  current_rkey3 = rk01;
        6'd2:  current_rkey3 = rk02;  6'd3:  current_rkey3 = rk03;
        6'd4:  current_rkey3 = rk04;  6'd5:  current_rkey3 = rk05;
        6'd6:  current_rkey3 = rk06;  6'd7:  current_rkey3 = rk07;
        6'd8:  current_rkey3 = rk08;  6'd9:  current_rkey3 = rk09;
        6'd10: current_rkey3 = rk10;  6'd11: current_rkey3 = rk11;
        6'd12: current_rkey3 = rk12;  6'd13: current_rkey3 = rk13;
        6'd14: current_rkey3 = rk14;  6'd15: current_rkey3 = rk15;
        6'd16: current_rkey3 = rk16;  6'd17: current_rkey3 = rk17;
        6'd18: current_rkey3 = rk18;  6'd19: current_rkey3 = rk19;
        6'd20: current_rkey3 = rk20;  6'd21: current_rkey3 = rk21;
        6'd22: current_rkey3 = rk22;  6'd23: current_rkey3 = rk23;
        6'd24: current_rkey3 = rk24;  6'd25: current_rkey3 = rk25;
        6'd26: current_rkey3 = rk26;  6'd27: current_rkey3 = rk27;
        6'd28: current_rkey3 = rk28;  6'd29: current_rkey3 = rk29;
        6'd30: current_rkey3 = rk30;  6'd31: current_rkey3 = rk31;
        6'd32: current_rkey3 = rk32;  6'd33: current_rkey3 = rk33;
        6'd34: current_rkey3 = rk34;  6'd35: current_rkey3 = rk35;
        6'd36: current_rkey3 = rk36;  6'd37: current_rkey3 = rk37;
        6'd38: current_rkey3 = rk38;  6'd39: current_rkey3 = rk39;
        6'd40: current_rkey3 = rk40;  6'd41: current_rkey3 = rk41;
        6'd42: current_rkey3 = rk42;  6'd43: current_rkey3 = rk43;
        default: current_rkey3 = 32'h0;
    endcase
end

////////////////////////////////////////////////////////////////////////////////
// PARALLEL Column Extraction for all 4 columns
////////////////////////////////////////////////////////////////////////////////
wire [31:0] state_col0 = aes_state[127:96];
wire [31:0] state_col1 = aes_state[95:64];
wire [31:0] state_col2 = aes_state[63:32];
wire [31:0] state_col3 = aes_state[31:0];

wire [31:0] temp_col0 = temp_state[127:96];
wire [31:0] temp_col1 = temp_state[95:64];
wire [31:0] temp_col2 = temp_state[63:32];
wire [31:0] temp_col3 = temp_state[31:0];

////////////////////////////////////////////////////////////////////////////////
// PARALLEL SubBytes - 4 instances for all columns
////////////////////////////////////////////////////////////////////////////////
wire [31:0] subbytes_input0 = (state == DEC_SHIFT_SUB && phase == 2'd1) ? temp_col0 : state_col0;
wire [31:0] subbytes_input1 = (state == DEC_SHIFT_SUB && phase == 2'd1) ? temp_col1 : state_col1;
wire [31:0] subbytes_input2 = (state == DEC_SHIFT_SUB && phase == 2'd1) ? temp_col2 : state_col2;
wire [31:0] subbytes_input3 = (state == DEC_SHIFT_SUB && phase == 2'd1) ? temp_col3 : state_col3;

wire [31:0] col_subbed0, col_subbed1, col_subbed2, col_subbed3;

aes_subbytes_32bit subbytes_inst0 (
    .data_in(subbytes_input0),
    .enc_dec(enc_dec_reg),
    .data_out(col_subbed0)
);

aes_subbytes_32bit subbytes_inst1 (
    .data_in(subbytes_input1),
    .enc_dec(enc_dec_reg),
    .data_out(col_subbed1)
);

aes_subbytes_32bit subbytes_inst2 (
    .data_in(subbytes_input2),
    .enc_dec(enc_dec_reg),
    .data_out(col_subbed2)
);

aes_subbytes_32bit subbytes_inst3 (
    .data_in(subbytes_input3),
    .enc_dec(enc_dec_reg),
    .data_out(col_subbed3)
);

////////////////////////////////////////////////////////////////////////////////
// ShiftRows Module Instance (operates on entire 128-bit state)
////////////////////////////////////////////////////////////////////////////////
wire [127:0] state_shifted;

aes_shiftrows_128bit shiftrows_inst (
    .data_in(enc_dec_reg ? temp_state : aes_state),
    .enc_dec(enc_dec_reg),
    .data_out(state_shifted)
);

wire [31:0] shifted_col0 = state_shifted[127:96];
wire [31:0] shifted_col1 = state_shifted[95:64];
wire [31:0] shifted_col2 = state_shifted[63:32];
wire [31:0] shifted_col3 = state_shifted[31:0];

////////////////////////////////////////////////////////////////////////////////
// PARALLEL MixColumns - 4 instances for all columns
////////////////////////////////////////////////////////////////////////////////
wire [31:0] col_mixed0, col_mixed1, col_mixed2, col_mixed3;

aes_mixcolumns_32bit mixcols_inst0 (
    .data_in(enc_dec_reg ? shifted_col0 : state_col0),
    .enc_dec(enc_dec_reg),
    .data_out(col_mixed0)
);

aes_mixcolumns_32bit mixcols_inst1 (
    .data_in(enc_dec_reg ? shifted_col1 : state_col1),
    .enc_dec(enc_dec_reg),
    .data_out(col_mixed1)
);

aes_mixcolumns_32bit mixcols_inst2 (
    .data_in(enc_dec_reg ? shifted_col2 : state_col2),
    .enc_dec(enc_dec_reg),
    .data_out(col_mixed2)
);

aes_mixcolumns_32bit mixcols_inst3 (
    .data_in(enc_dec_reg ? shifted_col3 : state_col3),
    .enc_dec(enc_dec_reg),
    .data_out(col_mixed3)
);

////////////////////////////////////////////////////////////////////////////////
// Control Logic
////////////////////////////////////////////////////////////////////////////////
wire is_last_round = (round_cnt == 4'd10);

////////////////////////////////////////////////////////////////////////////////
// Main State Machine - ONE-HOT ENCODED
////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= IDLE;
        round_cnt   <= 4'd0;
        phase       <= 2'd0;
        aes_state   <= 128'h0;
        temp_state  <= 128'h0;
        data_out    <= 128'h0;
        ready       <= 1'b0;
        key_start   <= 1'b0;
        key_next    <= 1'b0;
        keys_loaded <= 6'd0;
        enc_dec_reg <= 1'b1;

        // Reset all round keys - compact format
        {rk00, rk01, rk02, rk03} <= 128'h0;
        {rk04, rk05, rk06, rk07} <= 128'h0;
        {rk08, rk09, rk10, rk11} <= 128'h0;
        {rk12, rk13, rk14, rk15} <= 128'h0;
        {rk16, rk17, rk18, rk19} <= 128'h0;
        {rk20, rk21, rk22, rk23} <= 128'h0;
        {rk24, rk25, rk26, rk27} <= 128'h0;
        {rk28, rk29, rk30, rk31} <= 128'h0;
        {rk32, rk33, rk34, rk35} <= 128'h0;
        {rk36, rk37, rk38, rk39} <= 128'h0;
        {rk40, rk41, rk42, rk43} <= 128'h0;
    end else begin
        // Default: clear control signals
        key_next <= 1'b0;

        // Background key loading - continues in parallel with encryption/decryption
        if (key_ready && keys_loaded < 6'd44) begin
            case (key_addr)
                6'd0:  rk00 <= key_word;  6'd1:  rk01 <= key_word;
                6'd2:  rk02 <= key_word;  6'd3:  rk03 <= key_word;
                6'd4:  rk04 <= key_word;  6'd5:  rk05 <= key_word;
                6'd6:  rk06 <= key_word;  6'd7:  rk07 <= key_word;
                6'd8:  rk08 <= key_word;  6'd9:  rk09 <= key_word;
                6'd10: rk10 <= key_word;  6'd11: rk11 <= key_word;
                6'd12: rk12 <= key_word;  6'd13: rk13 <= key_word;
                6'd14: rk14 <= key_word;  6'd15: rk15 <= key_word;
                6'd16: rk16 <= key_word;  6'd17: rk17 <= key_word;
                6'd18: rk18 <= key_word;  6'd19: rk19 <= key_word;
                6'd20: rk20 <= key_word;  6'd21: rk21 <= key_word;
                6'd22: rk22 <= key_word;  6'd23: rk23 <= key_word;
                6'd24: rk24 <= key_word;  6'd25: rk25 <= key_word;
                6'd26: rk26 <= key_word;  6'd27: rk27 <= key_word;
                6'd28: rk28 <= key_word;  6'd29: rk29 <= key_word;
                6'd30: rk30 <= key_word;  6'd31: rk31 <= key_word;
                6'd32: rk32 <= key_word;  6'd33: rk33 <= key_word;
                6'd34: rk34 <= key_word;  6'd35: rk35 <= key_word;
                6'd36: rk36 <= key_word;  6'd37: rk37 <= key_word;
                6'd38: rk38 <= key_word;  6'd39: rk39 <= key_word;
                6'd40: rk40 <= key_word;  6'd41: rk41 <= key_word;
                6'd42: rk42 <= key_word;  6'd43: rk43 <= key_word;
            endcase
            keys_loaded <= keys_loaded + 1'b1;
            if (keys_loaded < 6'd43) begin
                key_next <= 1'b1;
            end
        end

        case (1'b1)  // One-hot case statement
            ////////////////////////////////////////////////////////////////////////
            // IDLE: Wait for start signal
            ////////////////////////////////////////////////////////////////////////
            state[0]: begin  // IDLE
                ready <= 1'b0;
                if (start) begin
                    aes_state   <= data_in;
                    temp_state  <= 128'h0;
                    round_cnt   <= 4'd0;
                    phase       <= 2'd0;
                    enc_dec_reg <= enc_dec;
                    key_start   <= 1'b1;
                    keys_loaded <= 6'd0;
                    state       <= KEY_EXPAND;
                end
            end

            ////////////////////////////////////////////////////////////////////////
            // KEY_EXPAND: Start key expansion and wait for initial keys
            ////////////////////////////////////////////////////////////////////////
            state[1]: begin  // KEY_EXPAND
                key_start <= 1'b0;

                // Wait for first 4 round keys (needed for ROUND0)
                // Key expansion continues in background
                if (keys_loaded >= 6'd4) begin
                    state <= ROUND0;
                end
            end

            ////////////////////////////////////////////////////////////////////////
            // ROUND0: Initial AddRoundKey - PARALLEL on all 4 columns
            ////////////////////////////////////////////////////////////////////////
            state[2]: begin  // ROUND0
                // Process all 4 columns in parallel (single cycle)
                aes_state[127:96] <= aes_state[127:96] ^ current_rkey0;
                aes_state[95:64]  <= aes_state[95:64]  ^ current_rkey1;
                aes_state[63:32]  <= aes_state[63:32]  ^ current_rkey2;
                aes_state[31:0]   <= aes_state[31:0]   ^ current_rkey3;

                round_cnt <= 4'd1;
                state     <= enc_dec_reg ? ENC_SUB : DEC_SHIFT_SUB;
            end

            ////////////////////////////////////////////////////////////////////////
            // ENCRYPTION: SubBytes → ShiftRows → MixColumns → AddRoundKey
            ////////////////////////////////////////////////////////////////////////
            state[3]: begin  // ENC_SUB
                // SubBytes on ALL 4 columns in parallel (single cycle)
                temp_state[127:96] <= col_subbed0;
                temp_state[95:64]  <= col_subbed1;
                temp_state[63:32]  <= col_subbed2;
                temp_state[31:0]   <= col_subbed3;

                state <= ENC_SHIFT_MIX;
            end

            state[4]: begin  // ENC_SHIFT_MIX
                // Wait for keys if needed
                if (enough_keys_for_round) begin
                    // ShiftRows → MixColumns (skip in last round) → AddRoundKey
                    // Process ALL 4 columns in parallel (single cycle)
                    aes_state[127:96] <= (is_last_round ? shifted_col0 : col_mixed0) ^ current_rkey0;
                    aes_state[95:64]  <= (is_last_round ? shifted_col1 : col_mixed1) ^ current_rkey1;
                    aes_state[63:32]  <= (is_last_round ? shifted_col2 : col_mixed2) ^ current_rkey2;
                    aes_state[31:0]   <= (is_last_round ? shifted_col3 : col_mixed3) ^ current_rkey3;

                    if (is_last_round) begin
                        // Done - output result
                        data_out <= {
                            (is_last_round ? shifted_col0 : col_mixed0) ^ current_rkey0,
                            (is_last_round ? shifted_col1 : col_mixed1) ^ current_rkey1,
                            (is_last_round ? shifted_col2 : col_mixed2) ^ current_rkey2,
                            (is_last_round ? shifted_col3 : col_mixed3) ^ current_rkey3
                        };
                        ready <= 1'b1;
                        if (!start) begin
                            state <= IDLE;
                        end
                    end else begin
                        round_cnt <= round_cnt + 1'b1;
                        state     <= ENC_SUB;
                    end
                end
                // If not enough keys, stay in this state (stall)
            end

            ////////////////////////////////////////////////////////////////////////
            // DECRYPTION: InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns
            ////////////////////////////////////////////////////////////////////////
            state[5]: begin  // DEC_SHIFT_SUB
                if (phase == 2'd0) begin
                    // Phase 0: Apply InvShiftRows to entire state (single cycle)
                    temp_state <= state_shifted;
                    phase      <= 2'd1;
                end else begin
                    // Phase 1: Apply InvSubBytes on ALL 4 columns in parallel (single cycle)
                    aes_state[127:96] <= col_subbed0;
                    aes_state[95:64]  <= col_subbed1;
                    aes_state[63:32]  <= col_subbed2;
                    aes_state[31:0]   <= col_subbed3;

                    phase <= 2'd0;
                    state <= DEC_ADD_MIX;
                end
            end

            state[6]: begin  // DEC_ADD_MIX
                if (phase == 2'd0) begin
                    // Wait for keys if needed
                    if (enough_keys_for_round) begin
                        // Phase 0: AddRoundKey on ALL 4 columns in parallel (single cycle)
                        aes_state[127:96] <= aes_state[127:96] ^ current_rkey0;
                        aes_state[95:64]  <= aes_state[95:64]  ^ current_rkey1;
                        aes_state[63:32]  <= aes_state[63:32]  ^ current_rkey2;
                        aes_state[31:0]   <= aes_state[31:0]   ^ current_rkey3;

                        if (is_last_round) begin
                            // Done - output result
                            data_out <= {
                                aes_state[127:96] ^ current_rkey0,
                                aes_state[95:64]  ^ current_rkey1,
                                aes_state[63:32]  ^ current_rkey2,
                                aes_state[31:0]   ^ current_rkey3
                            };
                            ready <= 1'b1;
                            if (!start) begin
                                state <= IDLE;
                            end
                        end else begin
                            phase <= 2'd1;
                        end
                    end
                    // If not enough keys, stay in this state (stall)
                end else begin
                    // Phase 1: InvMixColumns on ALL 4 columns in parallel (single cycle)
                    aes_state[127:96] <= col_mixed0;
                    aes_state[95:64]  <= col_mixed1;
                    aes_state[63:32]  <= col_mixed2;
                    aes_state[31:0]   <= col_mixed3;

                    round_cnt <= round_cnt + 1'b1;
                    phase     <= 2'd0;
                    state     <= DEC_SHIFT_SUB;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
