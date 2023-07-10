pragma solidity >=0.5.0 <0.7.0;


import "../library/Array.sol";
import "../library/Roles.sol";
import "../common/Ownable.sol";


contract PauserRole is Ownable {
    using Roles for Roles.Role;
    using Array for address[];

    Roles.Role private _pausers;
    address[] public pausers;

    constructor () internal {}

    function _addPauser(address account) internal {
        _pausers.add(account);
        pausers.push(account);
        emit PauserAdded(account);
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function addPauser(address[] memory accounts) public onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            _addPauser(accounts[index]);
        }
    }

    function _delPauser(address account) internal {
        _pausers.remove(account);

        if (pausers.remove(account)) {
            emit PauserRemoved(account);
        }
    }

    function renouncePauser() public {
        _delPauser(msg.sender);
    }

    function delPauser(address account) public onlyOwner {
        _delPauser(account);
    }

    function getPausersLength() public view returns (uint256) {
        return pausers.length;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }


    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the pauser role");
        _;
    }


    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
}
