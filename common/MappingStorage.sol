pragma solidity >=0.5.0 <0.7.0;


import "./Storage.sol";


contract MappingStorage is Storage {
    mapping(bytes32 => uint256) UIntStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => int) IntStorage;

    constructor() public {}

    function getUIntValue(bytes32 key) external view returns (uint256) {
        return UIntStorage[key];
    }

    function setUIntValue(bytes32 key, uint256 value) external onlyWhitelisted {
        UIntStorage[key] = value;
    }

    function deleteUIntValue(bytes32 key) external onlyWhitelisted {
        delete UIntStorage[key];
    }


    function getStringValue(bytes32 key) external view returns (string memory) {
        return StringStorage[key];
    }

    function setStringValue(bytes32 key, string calldata value) external onlyWhitelisted {
        StringStorage[key] = value;
    }

    function deleteStringValue(bytes32 key) external onlyWhitelisted {
        delete StringStorage[key];
    }


    function getAddressValue(bytes32 key) external view returns (address) {
        return AddressStorage[key];
    }

    function setAddressValue(bytes32 key, address value) external onlyWhitelisted {
        AddressStorage[key] = value;
    }

    function deleteAddressValue(bytes32 key) external onlyWhitelisted {
        delete AddressStorage[key];
    }


    function getBytesValue(bytes32 key) external view returns (bytes memory) {
        return BytesStorage[key];
    }

    function setBytesValue(bytes32 key, bytes calldata value) external onlyWhitelisted {
        BytesStorage[key] = value;
    }

    function deleteBytesValue(bytes32 key) external onlyWhitelisted {
        delete BytesStorage[key];
    }


    function getBytes32Value(bytes32 key) external view returns (bytes32) {
        return Bytes32Storage[key];
    }

    function setBytes32Value(bytes32 key, bytes32 value) external onlyWhitelisted {
        Bytes32Storage[key] = value;
    }

    function deleteBytes32Value(bytes32 key) external onlyWhitelisted {
        delete Bytes32Storage[key];
    }


    function getBooleanValue(bytes32 key) external view returns (bool) {
        return BooleanStorage[key];
    }

    function setBooleanValue(bytes32 key, bool value) external onlyWhitelisted {
        BooleanStorage[key] = value;
    }

    function deleteBooleanValue(bytes32 key) external onlyWhitelisted {
        delete BooleanStorage[key];
    }


    function getIntValue(bytes32 key) external view returns (int) {
        return IntStorage[key];
    }

    function setIntValue(bytes32 key, int value) external onlyWhitelisted {
        IntStorage[key] = value;
    }

    function deleteIntValue(bytes32 key) external onlyWhitelisted {
        delete IntStorage[key];
    }
}