# AES Decryption Verification Guide

## How Decryption Works on the Board

The current design uses the **SAME test vector inputs** but you toggle the mode with BTNU:
- **Encrypt mode (LED13 ON):** Encrypts plaintext → ciphertext
- **Decrypt mode (LED12 ON):** Decrypts ciphertext → plaintext

**Important:** The test vectors in `aes_fpga_top.v` currently provide PLAINTEXT as input. To properly test decryption, you need to either:
1. Use round-trip testing (encrypt then decrypt)
2. Modify test vectors to provide ciphertext as input

## NIST Test Vector 0 - Round-Trip Verification

### Test Vector 0 (SW[3:0] = 0000)
```
Key: 000102030405060708090A0B0C0D0E0F
```

### Encryption (LED13 ON)
```
Input (Plaintext):  00112233445566778899AABBCCDDEEFF

Expected Output (Ciphertext):
  Group 0: 69C4E0D8
  Group 1: 6A7B0430
  Group 2: D8CDB780
  Group 3: 70B4C55A

Complete: 69C4E0D86A7B0430D8CDB78070B4C55A
```

### Decryption (LED12 ON) - Current Limitation
```
With current code, decryption will use the same plaintext input,
which won't give meaningful results.

For proper decryption test, you need ciphertext as input.
```

## Recommended Testing Approach

### Method 1: Round-Trip Test (Current Design)

Since the design encrypts plaintext, you can verify correctness by:

1. **Encrypt** (BTNU until LED13 is ON):
   - Input: 00112233445566778899AABBCCDDEEFF
   - Expected: 69C4E0D86A7B0430D8CDB78070B4C55A ✓

2. **Decrypt** (press BTNU to toggle LED12 ON):
   - The design will decrypt the plaintext (not ideal)
   - Result won't match expected values

**Limitation:** Current test vectors provide plaintext, not ciphertext.

### Method 2: Modify Test Vectors for Decryption (Recommended)

To properly test decryption, modify `aes_fpga_top.v`:

## Modified Test Vector Code

Replace the test vector section in `aes_fpga_top.v` with this:

```verilog
// Test Vector Selection with Encryption/Decryption support
always @(*) begin
    case (sw[3:0])
        // NIST FIPS 197 Appendix C.1
        4'd0: begin
            if (enc_dec_mode) begin
                // Encryption: plaintext → ciphertext
                plaintext = 128'h00112233445566778899aabbccddeeff;
                key       = 128'h000102030405060708090a0b0c0d0e0f;
            end else begin
                // Decryption: ciphertext → plaintext
                plaintext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;  // Use ciphertext as input
                key       = 128'h000102030405060708090a0b0c0d0e0f;
            end
        end

        // NIST FIPS 197 Appendix B
        4'd1: begin
            if (enc_dec_mode) begin
                plaintext = 128'h3243f6a8885a308d313198a2e0370734;
                key       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
            end else begin
                plaintext = 128'h3925841d02dc09fbdc118597196a0b32;  // Ciphertext for decryption
                key       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
            end
        end

        // All zeros
        4'd2: begin
            if (enc_dec_mode) begin
                plaintext = 128'h00000000000000000000000000000000;
                key       = 128'h00000000000000000000000000000000;
            end else begin
                plaintext = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;  // Ciphertext
                key       = 128'h00000000000000000000000000000000;
            end
        end

        // All ones
        4'd3: begin
            if (enc_dec_mode) begin
                plaintext = 128'hffffffffffffffffffffffffffffffff;
                key       = 128'hffffffffffffffffffffffffffffffff;
            end else begin
                plaintext = 128'hbcbf217cb280cf30b2517052193ab979;  // Ciphertext
                key       = 128'hffffffffffffffffffffffffffffffff;
            end
        end

        // Keep other test vectors as-is for patterns 4-15
        default: begin
            plaintext = {sw[15:0], sw[15:0], sw[15:0], sw[15:0], sw[15:0], sw[15:0], sw[15:0], sw[15:0]};
            key       = {~sw[15:0], ~sw[15:0], ~sw[15:0], ~sw[15:0], ~sw[15:0], ~sw[15:0], ~sw[15:0], ~sw[15:0]};
        end
    endcase
end
```

## Expected Results After Modification

### Test Vector 0 (SW[3:0] = 0000)

**Encryption Mode (LED13 ON):**
```
Input:  00112233445566778899AABBCCDDEEFF
Output: 69C4E0D86A7B0430D8CDB78070B4C55A ✓

Display groups:
  Group 0: 69C4E0D8
  Group 1: 6A7B0430
  Group 2: D8CDB780
  Group 3: 70B4C55A
```

**Decryption Mode (LED12 ON - press BTNU):**
```
Input:  69C4E0D86A7B0430D8CDB78070B4C55A
Output: 00112233445566778899AABBCCDDEEFF ✓

Display groups:
  Group 0: 00112233
  Group 1: 44556677
  Group 2: 8899AABB
  Group 3: CCDDEEFF
```

### Test Vector 1 (SW[3:0] = 0001)

**Encryption Mode:**
```
Input:  3243F6A8885A308D313198A2E0370734
Output: 3925841D02DC09FBDC118597196A0B32 ✓
```

**Decryption Mode:**
```
Input:  3925841D02DC09FBDC118597196A0B32
Output: 3243F6A8885A308D313198A2E0370734 ✓
```

### Test Vector 2 (SW[3:0] = 0010)

**Encryption Mode:**
```
Input:  00000000000000000000000000000000
Output: 66E94BD4EF8A2C3B884CFA59CA342B2E ✓
```

**Decryption Mode:**
```
Input:  66E94BD4EF8A2C3B884CFA59CA342B2E
Output: 00000000000000000000000000000000 ✓
```

### Test Vector 3 (SW[3:0] = 0011)

**Encryption Mode:**
```
Input:  FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
Output: BCBF217CB280CF30B2517052193AB979 ✓
```

**Decryption Mode:**
```
Input:  BCBF217CB280CF30B2517052193AB979
Output: FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ✓
```

## Quick Verification Steps

### Without Code Modification (Current Design)
```
1. Set SW[3:0] = 0000
2. Ensure LED13 is ON (encrypt mode)
3. Press BTNC
4. Verify: 69C4E0D86A7B0430D8CDB78070B4C55A
5. Decryption test not possible (needs ciphertext input)
```

### With Code Modification (Recommended)
```
1. Set SW[3:0] = 0000
2. Ensure LED13 is ON (encrypt mode)
3. Press BTNC
4. Verify: 69C4E0D86A7B0430D8CDB78070B4C55A ✓

5. Press BTNU (toggle to decrypt, LED12 ON)
6. Press BTNC
7. Verify: 00112233445566778899AABBCCDDEEFF ✓

8. Press BTNU (toggle back to encrypt)
9. Press BTNC
10. Verify: 69C4E0D86A7B0430D8CDB78070B4C55A ✓
```

## Summary

**Current Design:** Only encryption test vectors are loaded
**To Test Decryption:** Modify test vectors to load ciphertext when in decrypt mode
**Best Verification:** Round-trip test (encrypt → decrypt → should match original)

Would you like me to create the modified `aes_fpga_top.v` file with proper decryption test vectors?
