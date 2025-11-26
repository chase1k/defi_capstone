// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IHevm {
    function ffi(string[] calldata) external returns (bytes memory);
    function deal(address who, uint256 amount) external;
}

contract DeployCodeHelper {
    address constant HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    IHevm constant hevm = IHevm(HEVM_ADDRESS);

    function _readArtifactBytecode(string memory artifactPath) internal returns (bytes memory) {
        string[] memory command = new string[](3);
        command[0] = "python3";
        command[1] = "scripts/get_bytecode.py";
        command[2] = artifactPath;

        bytes memory hexString = hevm.ffi(command);
        require(hexString.length > 0, "FFI failed to get bytecode");
        
        // Remove ALL whitespace characters
        bytes memory cleaned = new bytes(hexString.length);
        uint256 writePos = 0;
        
        for (uint256 i = 0; i < hexString.length; i++) {
            bytes1 char = hexString[i];
            if (char != 0x20 && char != 0x09 && char != 0x0a && char != 0x0d) {
                cleaned[writePos] = char;
                writePos++;
            }
        }
        
        bytes memory trimmed = new bytes(writePos);
        for (uint256 i = 0; i < writePos; i++) {
            trimmed[i] = cleaned[i];
        }
        
        hexString = trimmed;
        uint256 len = hexString.length;
        require(len > 0, "Hex string is empty after cleaning");
        
        // Remove "0x" prefix
        if (len >= 2 && hexString[0] == 0x30 && hexString[1] == 0x78) {
            bytes memory withoutPrefix = new bytes(len - 2);
            for (uint256 i = 0; i < len - 2; i++) {
                withoutPrefix[i] = hexString[i + 2];
            }
            hexString = withoutPrefix;
            len = len - 2;
        }
        
        // Decode hex string to bytes
        require(len % 2 == 0, "Invalid hex string length");
        require(len >= 2, "Hex string too short");
        bytes memory result = new bytes(len / 2);
        
        for (uint256 i = 0; i < len; i += 2) {
            uint8 high = _hexCharToByte(hexString[i]);
            uint8 low = _hexCharToByte(hexString[i + 1]);
            result[i / 2] = bytes1((high << 4) | low);
        }
        
        return result;
    }
    
    function _hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 c = uint8(char);
        if (c >= 48 && c <= 57) return c - 48;
        if (c >= 97 && c <= 102) return c - 87;
        if (c >= 65 && c <= 70) return c - 55;
        revert("Invalid hex character");
    }

    function deployCode(string memory artifactPath, bytes memory constructorArgs) internal returns (address deployed) {
        bytes memory bytecode = _readArtifactBytecode(artifactPath);
        require(bytecode.length > 0, "Bytecode is empty");
        
        bytes memory creationBytecode = abi.encodePacked(bytecode, constructorArgs);
        
        assembly {
            deployed := create(0, add(creationBytecode, 0x20), mload(creationBytecode))
        }
        require(deployed != address(0), "Contract deployment failed");
    }
}

