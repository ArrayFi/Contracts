pragma solidity >=0.5.0 <0.7.0;


import "../library/Array.sol";
import "../library/Roles.sol";
import "../common/Ownable.sol";


contract BlacklistedRole is Ownable {
    using Roles for Roles.Role;
    using Array for address[];

    Roles.Role private _blacklisteds;
    address[] public blacklisteds;

    constructor () internal {}

    function _addBlacklisted(address account) internal {
        _blacklisteds.add(account);
        blacklisteds.push(account);
        emit BlacklistedAdded(account);
    }

    function addBlacklisted(address account) public onlyOwner {
        _addBlacklisted(account);
    }

    function addBlacklisted(address[] memory accounts) public onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            _addBlacklisted(accounts[index]);
        }
    }

    function _delBlacklisted(address account) internal {
        _blacklisteds.remove(account);

        if (blacklisteds.remove(account)) {
            emit BlacklistedRemoved(account);
        }
    }

    function delBlacklisted(address account) public onlyOwner {
        _delBlacklisted(account);
    }

    function getBlacklistedsLength() public view returns (uint256) {
        return blacklisteds.length;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisteds.has(account);
    }


    modifier onlyBlacklisted() {
        require(isBlacklisted(msg.sender), "BlacklistedRole: caller does not have the blacklisted role");
        _;
    }

    modifier onlyNotBlacklisted(address account) {
        require(!isBlacklisted(account), "BlacklistedRole: account has the blacklisted role");
        _;
    }


    event BlacklistedAdded(address indexed account);
    event BlacklistedRemoved(address indexed account);
}
