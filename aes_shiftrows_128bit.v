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
wire [7:0] s0  = data_in[127:120]; wire [7:0] s4  = data_in[95:88];
wire [7:0] s1  = data_in[119:112]; wire [7:0] s5  = data_in[87:80];
wire [7:0] s2  = data_in[111:104]; wire [7:0] s6  = data_in[79:72];
wire [7:0] s3  = data_in[103:96];  wire [7:0] s7  = data_in[71:64];

wire [7:0] s8  = data_in[63:56];   wire [7:0] s12 = data_in[31:24];
wire [7:0] s9  = data_in[55:48];   wire [7:0] s13 = data_in[23:16];
wire [7:0] s10 = data_in[47:40];   wire [7:0] s14 = data_in[15:8];
wire [7:0] s11 = data_in[39:32];   wire [7:0] s15 = data_in[7:0];

// ShiftRows (encryption): shift row i left by i positions
// Row 0 (s0,s4,s8,s12):   no shift    -> (s0,s4,s8,s12)
// Row 1 (s1,s5,s9,s13):   shift left 1 -> (s5,s9,s13,s1)
// Row 2 (s2,s6,s10,s14):  shift left 2 -> (s10,s14,s2,s6)
// Row 3 (s3,s7,s11,s15):  shift left 3 -> (s15,s3,s7,s11)

wire [7:0] enc_out[0:15];
assign enc_out[0]  = s0;   assign enc_out[4]  = s4;   assign enc_out[8]  = s8;   assign enc_out[12] = s12;
assign enc_out[1]  = s5;   assign enc_out[5]  = s9;   assign enc_out[9]  = s13;  assign enc_out[13] = s1;
assign enc_out[2]  = s10;  assign enc_out[6]  = s14;  assign enc_out[10] = s2;   assign enc_out[14] = s6;
assign enc_out[3]  = s15;  assign enc_out[7]  = s3;   assign enc_out[11] = s7;   assign enc_out[15] = s11;

// InverseShiftRows (decryption): shift row i right by i positions
// Row 0 (s0,s4,s8,s12):   no shift     -> (s0,s4,s8,s12)
// Row 1 (s1,s5,s9,s13):   shift right 1 -> (s13,s1,s5,s9)
// Row 2 (s2,s6,s10,s14):  shift right 2 -> (s10,s14,s2,s6)
// Row 3 (s3,s7,s11,s15):  shift right 3 -> (s7,s11,s15,s3)

wire [7:0] dec_out[0:15];
assign dec_out[0]  = s0;   assign dec_out[4]  = s4;   assign dec_out[8]  = s8;   assign dec_out[12] = s12;
assign dec_out[1]  = s13;  assign dec_out[5]  = s1;   assign dec_out[9]  = s5;   assign dec_out[13] = s9;
assign dec_out[2]  = s10;  assign dec_out[6]  = s14;  assign dec_out[10] = s2;   assign dec_out[14] = s6;
assign dec_out[3]  = s7;   assign dec_out[7]  = s11;  assign dec_out[11] = s15;  assign dec_out[15] = s3;

// Select based on enc_dec and pack output (column-major: byte 0 is MSB)
assign data_out = enc_dec ? 
    {enc_out[0],  enc_out[1],  enc_out[2],  enc_out[3],
     enc_out[4],  enc_out[5],  enc_out[6],  enc_out[7],
     enc_out[8],  enc_out[9],  enc_out[10], enc_out[11],
     enc_out[12], enc_out[13], enc_out[14], enc_out[15]} :
    {dec_out[0],  dec_out[1],  dec_out[2],  dec_out[3],
     dec_out[4],  dec_out[5],  dec_out[6],  dec_out[7],
     dec_out[8],  dec_out[9],  dec_out[10], dec_out[11],
     dec_out[12], dec_out[13], dec_out[14], dec_out[15]};

endmodule