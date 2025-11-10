`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2025 21:27:31
// Design Name: 
// Module Name: aes_shiftrows_128bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// AES ShiftRows module
// NIST FIPS-197 compliant implementation
// AES state is column-major: s0-s3 in col0, s4-s7 in col1, s8-s11 in col2, s12-s15 in col3
module aes_shiftrows_128bit(
    input  [127:0] data_in,
    input          enc_dec,     // 1=encryption, 0=decryption
    output [127:0] data_out
);

// Extract bytes from column-major layout (MSB first: s0 at [127:120])
wire [7:0] s0  = data_in[127:120];  wire [7:0] s1  = data_in[119:112];
wire [7:0] s2  = data_in[111:104];  wire [7:0] s3  = data_in[103:96];
wire [7:0] s4  = data_in[95:88];    wire [7:0] s5  = data_in[87:80];
wire [7:0] s6  = data_in[79:72];    wire [7:0] s7  = data_in[71:64];
wire [7:0] s8  = data_in[63:56];    wire [7:0] s9  = data_in[55:48];
wire [7:0] s10 = data_in[47:40];    wire [7:0] s11 = data_in[39:32];
wire [7:0] s12 = data_in[31:24];    wire [7:0] s13 = data_in[23:16];
wire [7:0] s14 = data_in[15:8];     wire [7:0] s15 = data_in[7:0];

// ShiftRows transformation
// Row 0 (s0,s4,s8,s12):   no shift - same for both enc/dec
// Row 2 (s2,s6,s10,s14):  shift 2 positions - same for both enc/dec
// Row 1 & Row 3 differ between encryption and decryption

// Shared rows (Row 0 and Row 2 are identical for enc/dec)
wire [7:0] row0[0:3];
assign row0[0] = s0;   assign row0[1] = s4;   assign row0[2] = s8;   assign row0[3] = s12;
wire [7:0] row2[0:3];
assign row2[0] = s10;  assign row2[1] = s14;  assign row2[2] = s2;   assign row2[3] = s6;

// Encryption: Row 1 shift left 1, Row 3 shift left 3
wire [7:0] enc_row1[0:3];
assign enc_row1[0] = s5;   assign enc_row1[1] = s9;   assign enc_row1[2] = s13;  assign enc_row1[3] = s1;
wire [7:0] enc_row3[0:3];
assign enc_row3[0] = s15;  assign enc_row3[1] = s3;   assign enc_row3[2] = s7;   assign enc_row3[3] = s11;

// Decryption: Row 1 shift right 1, Row 3 shift right 3
wire [7:0] dec_row1[0:3];
assign dec_row1[0] = s13;  assign dec_row1[1] = s1;   assign dec_row1[2] = s5;   assign dec_row1[3] = s9;
wire [7:0] dec_row3[0:3];
assign dec_row3[0] = s7;   assign dec_row3[1] = s11;  assign dec_row3[2] = s15;  assign dec_row3[3] = s3;

// Select based on enc_dec and pack output (column-major: byte 0 is MSB)
wire [7:0] out_row1[0:3];
wire [7:0] out_row3[0:3];
assign out_row1[0] = enc_dec ? enc_row1[0] : dec_row1[0];
assign out_row1[1] = enc_dec ? enc_row1[1] : dec_row1[1];
assign out_row1[2] = enc_dec ? enc_row1[2] : dec_row1[2];
assign out_row1[3] = enc_dec ? enc_row1[3] : dec_row1[3];
assign out_row3[0] = enc_dec ? enc_row3[0] : dec_row3[0];
assign out_row3[1] = enc_dec ? enc_row3[1] : dec_row3[1];
assign out_row3[2] = enc_dec ? enc_row3[2] : dec_row3[2];
assign out_row3[3] = enc_dec ? enc_row3[3] : dec_row3[3];

assign data_out = {row0[0], out_row1[0], row2[0], out_row3[0],
                   row0[1], out_row1[1], row2[1], out_row3[1],
                   row0[2], out_row1[2], row2[2], out_row3[2],
                   row0[3], out_row1[3], row2[3], out_row3[3]};

endmodule