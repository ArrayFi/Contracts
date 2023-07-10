pragma solidity >=0.5.0 <0.7.0;


import "./Storage.sol";


contract ApprovalStorage is Storage {
    mapping(address => mapping(address => bool)) private _approvals;

    constructor() public {}

    function approval(address owner, address spender) public view returns (bool) {
        return _approvals[owner][spender];
    }

    function setApproval(address owner, address spender, bool newStatus) public onlyWhitelisted {
        _approvals[owner][spender] = newStatus;
    }
}
