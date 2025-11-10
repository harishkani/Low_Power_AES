# Nexys A7-100T Quick Start Guide

## Board Information
- **FPGA:** Xilinx Artix-7 XC7A100T-1CSG324C
- **Clock:** 100MHz system clock
- **7-Segment Displays:** 8 digits (Common Anode)
- **Switches:** 16
- **LEDs:** 16
- **Push Buttons:** 5 (BTNC, BTNU, BTNL, BTNR, BTND + CPU_RESETN)

## Pin Differences from Basys3

The Nexys A7 has different pin assignments than Basys3. Use `nexys_a7_constraints.xdc` instead of `basys3_constraints.xdc`.

**Key Differences:**
- Switches 8-9 use LVCMOS18 instead of LVCMOS33
- Different package pins for all I/O
- Clock pin is E3 (not W5)
- Reset button is C12 (not U18)

## Vivado Project Setup

### Step 1: Create New Project
```
1. Open Vivado 2019.1 or later
2. File → New Project
3. Project Name: AES_Nexys_A7
4. Project Type: RTL Project
5. Do not specify sources at this time
6. Add Parts: xc7a100tcsg324-1
7. Finish
```

### Step 2: Add Source Files
```
1. Add Design Sources:
   - aes_fpga_top.v (set as Top module)
   - seven_seg_controller.v
   - aes_core_fixed.v
   - aes_key_expansion_otf.v
   - aes_sbox.v
   - aes_inv_sbox.v
   - aes_subbytes_32bit.v
   - aes_shiftrows_128bit.v
   - aes_mixcolumns_32bit.v

2. Add Constraints:
   - nexys_a7_constraints.xdc
```

### Step 3: Synthesis & Implementation
```
1. Click "Run Synthesis"
2. Wait for completion (~2-3 minutes)
3. Click "Run Implementation"
4. Click "Generate Bitstream"
```

### Step 4: Program FPGA
```
1. Connect Nexys A7 board via USB
2. Power on the board
3. Click "Open Hardware Manager"
4. Click "Auto Connect"
5. Right-click on device → Program Device
6. Select the .bit file
7. Click Program
```

## Resource Utilization (Nexys A7-100T)

Expected usage on XC7A100T:
```
Resource          Used    Available    Utilization
LUTs              2,800   63,400       4.4%
FFs               1,600   126,800      1.3%
BRAM              0       135          0.0%
DSP               0       240          0.0%
```

The design fits comfortably with plenty of room for additional features.

## Control Layout on Nexys A7

### Physical Layout
```
        [BTNU]           ← Toggle Encrypt/Decrypt
    [BTNL] [BTNC] [BTNR]  ← Left: Prev Group, Center: Start, Right: Next Group
        [BTND]           ← (unused)

    [CPU_RESETN]         ← System Reset (separate button)

    [SW15...SW0]         ← Test vector selection (use SW3-SW0)

    [LED15...LED0]       ← Status indicators

    [8 7-segment displays] ← AES output display
```

## Quick Test Procedure

### Test 1: NIST FIPS 197 Appendix C.1
```
1. Set SW3-SW0 = 0000 (all down)
2. Press CPU_RESETN
3. Press BTNC (center button)
4. Wait ~1 microsecond (instant to human eye)
5. LED15 lights up (Ready)
6. Read 7-segment display: 69C4E0D8
7. Press BTNR: 6A7B0430
8. Press BTNR: D8CDB780
9. Press BTNR: 70B4C55A

Expected complete output: 69C4E0D86A7B0430D8CDB78070B4C55A ✓
```

## LED Indicators

```
LED15: ● Ready (operation complete)
LED14: ● Busy (computing)
LED13: ● Encrypt mode
LED12: ● Decrypt mode
LED11-10: Current display group (00=Grp0, 01=Grp1, 10=Grp2, 11=Grp3)
LED9-6: Test vector number (binary)
LED5-0: Unused (off)
```

## Test Vectors Quick Reference

| SW[3:0] | Test Vector |
|---------|-------------|
| 0000    | NIST FIPS 197 Appendix C.1 |
| 0001    | NIST FIPS 197 Appendix B |
| 0010    | All zeros |
| 0011    | All ones |
| 0100    | Alternating (0xAAAA.../0x5555...) |
| 0101    | Sequential 1 |
| 0110    | Custom (DEADBEEF...) |
| 0111    | Sequential 2 |

## Expected Results for Test Vector 0

```
Input:
  Plaintext: 00112233445566778899AABBCCDDEEFF
  Key:       000102030405060708090A0B0C0D0E0F
  Mode:      Encrypt

7-Segment Display Output:
  Group 0 (press BTNC):     69C4E0D8
  Group 1 (press BTNR):     6A7B0430
  Group 2 (press BTNR):     D8CDB780
  Group 3 (press BTNR):     70B4C55A

Complete: 69C4E0D86A7B0430D8CDB78070B4C55A
```

## Timing Analysis

After implementation, verify timing in Vivado:
```
Reports → Timing → Report Timing Summary

Expected Results:
- WNS (Worst Negative Slack): Positive (0.5ns or better)
- TNS (Total Negative Slack): 0.000ns
- WHS (Worst Hold Slack): Positive
- Max Frequency: ~150MHz (actual requirement: 100MHz)
```

## Troubleshooting

### Issue: Displays show random values
**Solution:** Press CPU_RESETN button

### Issue: Nothing displays
**Check:**
- Is bitstream loaded? (DONE LED should be green)
- Is power connected?
- Check Vivado synthesis logs for errors

### Issue: Wrong output values
**Check:**
- Verify test vector selection (LED9-6)
- Check encrypt/decrypt mode (LED13/12)
- Press CPU_RESETN and try again

### Issue: Buttons don't respond
**Check:**
- Debouncing may need longer press
- Try holding button for 100ms
- Verify constraints file is correct

## Advanced: Viewing Internal Signals

To debug with ILA (Integrated Logic Analyzer):
```
1. Tools → Set up Debug
2. Select signals: aes_output, aes_ready, etc.
3. Re-run Implementation
4. Generate bitstream
5. Hardware Manager → Add ILA core
6. Trigger on btn_start
7. Capture and analyze
```

## Performance

At 100MHz clock:
- **AES Encryption:** ~1.0 µs
- **Key Expansion:** ~0.5 µs
- **Total Latency:** ~1.5 µs
- **Throughput:** ~667,000 blocks/second
- **Data Rate:** ~85 Mbps (for 128-bit blocks)

## Next Steps

1. **Verify all test vectors** (0-7)
2. **Test round-trip** (encrypt then decrypt)
3. **Measure power consumption** (using Xilinx Power Estimator)
4. **Add custom test vectors** (modify aes_fpga_top.v)
5. **Implement continuous mode** (for benchmarking)

## Files for Nexys A7

- `aes_fpga_top.v` - Top module (works for all boards)
- `seven_seg_controller.v` - Display controller (works for all boards)
- `nexys_a7_constraints.xdc` - **Use this for Nexys A7**
- All AES core files (unchanged)

## Additional Resources

- Nexys A7 Reference Manual: https://reference.digilentinc.com/nexys-a7
- Artix-7 FPGA Datasheet: Xilinx DS181
- Vivado Design Suite User Guide: UG893

---

**Board Tested:** Nexys A7-100T
**Vivado Version:** 2019.1 or later
**Status:** ✓ Verified Working
