#!/usr/bin/env python3
import json
import sys

def get_bytecode(json_file):
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # Try different possible locations for bytecode
    bytecode = None
    
    # Standard Solidity compiler output
    if 'bytecode' in data:
        if isinstance(data['bytecode'], str):
            bytecode = data['bytecode']
        elif isinstance(data['bytecode'], dict) and 'object' in data['bytecode']:
            bytecode = data['bytecode']['object']
    
    # Try evm.bytecode path
    if not bytecode and 'evm' in data:
        if 'bytecode' in data['evm']:
            if isinstance(data['evm']['bytecode'], str):
                bytecode = data['evm']['bytecode']
            elif isinstance(data['evm']['bytecode'], dict) and 'object' in data['evm']['bytecode']:
                bytecode = data['evm']['bytecode']['object']
    
    # Try deployedBytecode (some formats)
    if not bytecode and 'deployedBytecode' in data:
        if isinstance(data['deployedBytecode'], str):
            bytecode = data['deployedBytecode']
    
    if not bytecode:
        print("Error: Could not find bytecode in JSON", file=sys.stderr)
        sys.exit(1)
    
    # Clean the bytecode: remove whitespace, 0x prefix
    bytecode = bytecode.strip()
    if bytecode.startswith('0x') or bytecode.startswith('0X'):
        bytecode = bytecode[2:]
    
    # Output WITHOUT any newline or extra characters
    # Use sys.stdout.write instead of print to avoid adding newline
    sys.stdout.write('0x' + bytecode)
    sys.stdout.flush()

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <json_file>", file=sys.stderr)
        sys.exit(1)
    
    get_bytecode(sys.argv[1])