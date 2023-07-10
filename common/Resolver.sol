pragma solidity >=0.5.0 <0.7.0;


import "./Ownable.sol";


contract Resolver is Ownable {
    mapping(bytes32 => address) private _registries;

    constructor() public {}

    function addr(bytes32 node) public view returns (address) {
        return _registries[node];
    }

    function addr(bytes32 node, string memory reason) public view returns (address) {
        address content = _registries[node];
        require(content != address(0), reason);
        return content;
    }

    function _setAddr(bytes32 node, address content) internal {
        _registries[node] = content;
        emit AddrChanged(node, content);
    }

    function setAddr(bytes32[] memory nodes, address[] memory contents) public onlyOwner {
        require(nodes.length == contents.length, "Resolver: nodes and contents length mismatched");

        for (uint256 index = 0; index < nodes.length; index++) {
            _setAddr(nodes[index], contents[index]);
        }
    }


    event AddrChanged(bytes32 indexed node, address indexed content);
}
