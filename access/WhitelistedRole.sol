pragma solidity >=0.5.0 <0.7.0;


import "../library/Array.sol";
import "../library/Roles.sol";
import "../common/Ownable.sol";


contract WhitelistedRole is Ownable {
    using Roles for Roles.Role;
    using Array for address[];

    Roles.Role private _whitelisteds;
    address[] public whitelisteds;

    constructor () internal {}

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        whitelisteds.push(account);
        emit WhitelistedAdded(account);
    }

    function addWhitelisted(address account) public onlyOwner {
        _addWhitelisted(account);
    }

    function addWhitelisted(address[] memory accounts) public onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            _addWhitelisted(accounts[index]);
        }
    }

    function _delWhitelisted(address account) internal {
        _whitelisteds.remove(account);

        if (whitelisteds.remove(account)) {
            emit WhitelistedRemoved(account);
        }
    }

    function renounceWhitelisted() public {
        _delWhitelisted(msg.sender);
    }

    function delWhitelisted(address account) public onlyOwner {
        _delWhitelisted(account);
    }

    function getWhitelistedsLength() public view returns (uint256) {
        return whitelisteds.length;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }


    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "WhitelistedRole: caller does not have the whitelisted role");
        _;
    }

    modifier onlyWhitelisting(address account) {
        require(isWhitelisted(account), "WhitelistedRole: caller does not have the whitelisted role");
        _;
    }


    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);
}
