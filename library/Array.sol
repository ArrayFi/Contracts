pragma solidity >=0.5.0 <0.7.0;


library Array {
    function remove(bytes32[] storage array, bytes32 element) internal returns (bool) {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                delete array[index];
                array[index] = array[array.length - 1];
                array.length--;
                return true;
            }
        }
        return false;
    }

    function remove(address[] storage array, address element) internal returns (bool) {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                delete array[index];
                array[index] = array[array.length - 1];
                array.length--;
                return true;
            }
        }
        return false;
    }
}
