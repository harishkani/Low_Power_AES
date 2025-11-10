# AES-128 FPGA Verification Guide

## Overview
This guide explains how to deploy and verify the AES-128 implementation on an FPGA using 7-segment displays.

## Hardware Requirements
- **FPGA Board:** Xilinx Basys3, Nexys A7, or similar
- **7-Segment Displays:** 8 digits (built-in on most boards)
- **Switches:** 16 switches for test vector selection
- **Buttons:** 4 push buttons for control
- **LEDs:** 16 LEDs for status indication
- **Clock:** 100MHz system clock

## Files Included
1. **aes_fpga_top.v** - Top-level FPGA module
2. **seven_seg_controller.v** - 7-segment display controller with multiplexing
3. **basys3_constraints.xdc** - Pin constraints for Basys3 board
4. **aes_core_fixed.v** - AES core (and all submodules)

## Controls

### Buttons
- **btnC (Center):** Start AES encryption/decryption
- **btnU (Up):** Toggle between Encrypt/Decrypt mode
- **btnL (Left):** Show previous group of 8 hex digits
- **btnR (Right):** Show next group of 8 hex digits
- **CPU_RESET:** Reset the entire system

### Switches (sw[3:0])
Select test vectors:
- **0000:** NIST FIPS 197 Appendix C.1
- **0001:** NIST FIPS 197 Appendix B
- **0010:** All zeros
- **0011:** All ones
- **0100:** Alternating pattern (0xAAAA... / 0x5555...)
- **0101:** Sequential pattern 1
- **0110:** Custom pattern 1 (DEADBEEF...)
- **0111:** Sequential (0x00010203... / 0x10111213...)
- **1000-1111:** Custom patterns based on switch values

### LEDs
- **LED[15]:** AES Ready (lit when operation complete)
- **LED[14]:** AES Busy (lit during computation)
- **LED[13]:** Encrypt mode indicator
- **LED[12]:** Decrypt mode indicator
- **LED[11:10]:** Current display group (0-3)
- **LED[9:6]:** Selected test vector number
- **LED[5:0]:** Unused

## 7-Segment Display

### Display Format
The 128-bit AES output (32 hex digits) is shown in **4 groups of 8 digits**:

- **Group 0:** Bytes 0-3  (bits 127:96)  - Output[31:0]
- **Group 1:** Bytes 4-7  (bits 95:64)   - Output[63:32]
- **Group 2:** Bytes 8-11 (bits 63:32)   - Output[95:64]
- **Group 3:** Bytes 12-15 (bits 31:0)   - Output[127:96]

Use **btnL/btnR** to cycle through groups.

### Reading the Display
The displays show hexadecimal digits from **left to right**:
```
Display:  [7] [6] [5] [4] [3] [2] [1] [0]
          MSB                         LSB
```

## Usage Steps

### Step 1: Load Design to FPGA
1. Open Vivado (or your FPGA tool)
2. Create new project
3. Add all Verilog files:
   - aes_fpga_top.v (set as top module)
   - seven_seg_controller.v
   - aes_core_fixed.v
   - aes_key_expansion_otf.v
   - aes_sbox.v
   - aes_inv_sbox.v
   - aes_subbytes_32bit.v
   - aes_shiftrows_128bit.v
   - aes_mixcolumns_32bit.v
4. Add constraints file: basys3_constraints.xdc
5. Synthesize, implement, and generate bitstream
6. Program the FPGA

### Step 2: Select Test Vector
1. Set switches sw[3:0] to select test vector (e.g., 0000 for NIST test)
2. Observe LED[9:6] to confirm selection

### Step 3: Set Operation Mode
1. Press **btnU** to toggle between Encrypt (LED13 on) / Decrypt (LED12 on)
2. Default is Encrypt mode

### Step 4: Run AES
1. Press **btnC** to start the AES operation
2. LED[14] (Busy) will light up during computation
3. LED[15] (Ready) will light up when complete (takes ~0.1ms)

### Step 5: View Result
1. The 7-segment displays show the first 8 hex digits of the result
2. Press **btnR** to view next 8 digits (Group 1)
3. Press **btnR** again for Group 2, then Group 3
4. Press **btnL** to go back
5. LED[11:10] shows current group number

## Expected Results (NIST Test Vectors)

### Test Vector 0 (NIST FIPS 197 Appendix C.1)
```
Plaintext: 00112233445566778899AABBCCDDEEFF
Key:       000102030405060708090A0B0C0D0E0F
Expected:  69C4E0D86A7B0430D8CDB78070B4C55A
```

**7-Segment Display Groups:**
- Group 0: `69C4E0D8`
- Group 1: `6A7B0430`
- Group 2: `D8CDB780`
- Group 3: `70B4C55A`

### Test Vector 1 (NIST FIPS 197 Appendix B)
```
Plaintext: 3243F6A8885A308D313198A2E0370734
Key:       2B7E151628AED2A6ABF7158809CF4F3C
Expected:  3925841D02DC09FBDC118597196A0B32
```

**7-Segment Display Groups:**
- Group 0: `3925841D`
- Group 1: `02DC09FB`
- Group 2: `DC118597`
- Group 3: `196A0B32`

### Test Vector 2 (All Zeros)
```
Plaintext: 00000000000000000000000000000000
Key:       00000000000000000000000000000000
Expected:  66E94BD4EF8A2C3B884CFA59CA342B2E
```

## Verification Procedure

1. **Select Test Vector 0** (switches 0000)
2. **Ensure Encrypt mode** (LED13 on)
3. **Press btnC** to start
4. **Wait for Ready** (LED15 on)
5. **Read Group 0:** Should show `69C4E0D8`
6. **Press btnR** to see Group 1: `6A7B0430`
7. **Press btnR** again for Group 2: `D8CDB780`
8. **Press btnR** again for Group 3: `70B4C55A`
9. **Verify against expected:** `69C4E0D86A7B0430D8CDB78070B4C55A` ✓

Repeat for other test vectors to verify correctness.

## Troubleshooting

### No Display
- Check power and bitstream loaded correctly
- Verify clock constraint is correct (100MHz)
- Check 7-segment connections in constraints file

### Wrong Values
- Verify test vector selection (LED[9:6])
- Check enc/dec mode (LED[13:12])
- Ensure operation completed (LED15 on)
- Try different test vectors

### Display Flickering
- Normal multiplexing behavior
- Refresh rate is ~1kHz per digit (8kHz total)
- If excessive, adjust refresh_counter in seven_seg_controller.v

### Buttons Not Working
- Check debouncing (20-bit counter gives ~10ms debounce at 100MHz)
- Verify button constraints in XDC file
- Try pressing and holding for longer

## Synthesis Notes

### Resource Utilization (Approximate for Artix-7)
- **LUTs:** ~2,500-3,000
- **FFs:** ~1,500-2,000
- **Block RAMs:** 0 (design uses registers only)
- **DSPs:** 0
- **Maximum Frequency:** ~150MHz

### Timing
- AES operation takes approximately **100 clock cycles** per encryption/decryption
- At 100MHz: **1 microsecond** per operation
- Display refresh: 8kHz (no visible flicker)

## Modifying for Different FPGA Boards

### For Nexys A7 / Nexys 4 DDR
- Create new XDC file based on board's pin assignments
- All Verilog code remains the same
- Adjust clock frequency if different from 100MHz

### For Boards with Fewer Displays
- Modify `digit_sel` in aes_fpga_top.v to use fewer groups
- Adjust seven_seg_controller.v if needed

## Additional Tests

### Round-Trip Test
1. Select a test vector
2. Encrypt (btnU to set encrypt mode)
3. Press btnC
4. Note the output on 7-segment displays
5. Switch to decrypt mode (btnU)
6. Press btnC again
7. Verify output matches original plaintext

### Performance Test
- Observe LED[14] (busy indicator)
- Time how long it stays on (should be very brief at 100MHz)
- One AES block takes ~1 microsecond

## Conclusion
This FPGA implementation provides a physical verification of the AES-128 design with visual output through 7-segment displays. The modular design allows easy porting to different FPGA platforms and customization of test vectors.
