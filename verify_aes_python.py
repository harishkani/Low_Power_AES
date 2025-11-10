#!/usr/bin/env python3
"""
AES-128 Functional Verification Tool
Implements AES-128 in Python to verify expected outputs
"""

from Crypto.Cipher import AES
import sys

def bytes_to_hex(data):
    """Convert bytes to hex string"""
    return data.hex()

def hex_to_bytes(hex_str):
    """Convert hex string to bytes"""
    # Remove spaces and convert
    hex_str = hex_str.replace(' ', '').replace('_', '')
    return bytes.fromhex(hex_str)

def verify_test_vector(test_num, key_hex, plaintext_hex, expected_ciphertext_hex):
    """Verify a single test vector"""
    print(f"\n{'='*60}")
    print(f"Test Vector {test_num}")
    print(f"{'='*60}")

    # Convert inputs
    key = hex_to_bytes(key_hex)
    plaintext = hex_to_bytes(plaintext_hex)
    expected_ciphertext = hex_to_bytes(expected_ciphertext_hex)

    print(f"Key:       {bytes_to_hex(key)}")
    print(f"Plaintext: {bytes_to_hex(plaintext)}")
    print(f"Expected:  {bytes_to_hex(expected_ciphertext)}")

    # Encryption test
    cipher_enc = AES.new(key, AES.MODE_ECB)
    actual_ciphertext = cipher_enc.encrypt(plaintext)

    print(f"Actual:    {bytes_to_hex(actual_ciphertext)}")

    if actual_ciphertext == expected_ciphertext:
        print("Status:    ✓ PASS")
        enc_pass = True
    else:
        print("Status:    ✗ FAIL")
        enc_pass = False

    # Decryption test
    cipher_dec = AES.new(key, AES.MODE_ECB)
    decrypted_plaintext = cipher_dec.decrypt(expected_ciphertext)

    print(f"\nDecryption Test:")
    print(f"Decrypted: {bytes_to_hex(decrypted_plaintext)}")

    if decrypted_plaintext == plaintext:
        print("Status:    ✓ PASS")
        dec_pass = True
    else:
        print("Status:    ✗ FAIL")
        dec_pass = False

    return enc_pass and dec_pass

def main():
    """Main verification function"""
    print("=" * 80)
    print("AES-128 Functional Verification Tool")
    print("Verifying expected outputs using PyCryptodome")
    print("=" * 80)

    # Test vectors (same as in testbench)
    test_vectors = [
        {
            'name': 'NIST FIPS 197 Appendix C.1',
            'key': '000102030405060708090a0b0c0d0e0f',
            'plaintext': '00112233445566778899aabbccddeeff',
            'ciphertext': '69c4e0d86a7b0430d8cdb78070b4c55a'
        },
        {
            'name': 'NIST Test Vector 1',
            'key': '2b7e151628aed2a6abf7158809cf4f3c',
            'plaintext': '3243f6a8885a308d313198a2e0370734',
            'ciphertext': '3925841d02dc09fbdc118597196a0b32'
        },
        {
            'name': 'All Zeros',
            'key': '00000000000000000000000000000000',
            'plaintext': '00000000000000000000000000000000',
            'ciphertext': '66e94bd4ef8a2c3b884cfa59ca342b2e'
        },
        {
            'name': 'All Ones',
            'key': 'ffffffffffffffffffffffffffffffff',
            'plaintext': 'ffffffffffffffffffffffffffffffff',
            'ciphertext': 'a1f6258c877d5fcd8964484538bfc92c'
        },
        {
            'name': 'Test Vector 4',
            'key': '10a58869d74be5a374cf867cfb473859',
            'plaintext': '00000000000000000000000000000000',
            'ciphertext': '6d251e6944b051e04eaa6fb4dbf78465'
        },
        {
            'name': 'Test Vector 5',
            'key': 'caea65cdbb75e9169ecd22ebe6e54675',
            'plaintext': '00000000000000000000000000000000',
            'ciphertext': '6e29201190152df4ee058139def610bb'
        },
        {
            'name': 'Test Vector 6',
            'key': 'a2e2fa9baf7d20822ca9f0542f764a41',
            'plaintext': '00000000000000000000000000000000',
            'ciphertext': 'c3b44b95d9d2f25670eee9a0de099fa3'
        },
        {
            'name': 'Test Vector 7',
            'key': 'b6364ac4e1de1e285eaf144a2415f7a0',
            'plaintext': '00000000000000000000000000000000',
            'ciphertext': '5d9b05578fc944b3cf1ccf0e746cd581'
        }
    ]

    passed = 0
    failed = 0

    for i, tv in enumerate(test_vectors):
        if verify_test_vector(i, tv['key'], tv['plaintext'], tv['ciphertext']):
            passed += 1
        else:
            failed += 1

    # Summary
    print(f"\n{'='*80}")
    print("SUMMARY")
    print(f"{'='*80}")
    print(f"Total Tests: {len(test_vectors)}")
    print(f"Passed:      {passed}")
    print(f"Failed:      {failed}")

    if failed == 0:
        print("\n✓✓✓ ALL TESTS PASSED! ✓✓✓")
        print("\nYour Verilog design should produce these exact outputs.")
        print("If your simulation matches these values, both original and")
        print("optimized designs are functionally correct.")
        return 0
    else:
        print(f"\n✗✗✗ {failed} TESTS FAILED! ✗✗✗")
        return 1

if __name__ == '__main__':
    try:
        sys.exit(main())
    except ImportError:
        print("\nERROR: PyCryptodome not installed!")
        print("Install with: pip install pycryptodome")
        print("\nOr use system package manager:")
        print("  sudo apt-get install python3-pycryptodome")
        sys.exit(1)
    except Exception as e:
        print(f"\nERROR: {e}")
        sys.exit(1)
