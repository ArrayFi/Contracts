pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../common/MixinResolver.sol";
import "./RewardEscrowStorage.sol";
import "../../access/WhitelistedRole.sol";

contract RewardEscrow is MixinResolver, WhitelistedRole {
    using SafeMath for uint256;

    RewardEscrowStorage private _storage;
    uint256 private _period = 10 days;
    uint256 private maximum = 365 * 2;

    constructor() public {}

    function database() public view returns (RewardEscrowStorage) {
        return _storage;
    }

    function setStorage(RewardEscrowStorage newStorage) public onlyOwner {
        emit StorageTransferred(_storage, newStorage);
        _storage = newStorage;
    }

    function period() public view returns (uint256) {
        return _period;
    }

    function setPeriod(uint256 newPeriod) public onlyOwner {
        emit PeriodUpdated(_period, newPeriod);
        _period = newPeriod;
    }

    function getVestingLength(address account) public view returns (uint256) {
        return _storage.getVestingLength(account);
    }

    function getVestingEntries(address account) public view returns (uint256[1460] memory) {//520 to 1460
        return _storage.getVestingEntries(account);
    }

    function getVestingTime(address account, uint256 index) public view returns (uint256) {
        return _storage.getVestingTime(account, index);
    }

    function getVestingAmount(address account, uint256 index) public view returns (uint256) {
        return _storage.getVestingAmount(account, index);
    }

    function getNextVestingTime(address account) public view returns (uint256) {
        return _storage.getNextVestingTime(account);
    }

    function getNextVestingAmount(address account) public view returns (uint256) {
        return _storage.getNextVestingAmount(account);
    }

    function deposited(address account) public view returns (uint256) {
        return _storage.deposited(account);
    }

    function withdrawn(address account) public view returns (uint256) {
        return _storage.withdrawn(account);
    }

    function deposit(address account, uint256 amount) public onlyWhitelisted {
        require(account != address(0), "RewardEscrow: account is the zero address");
        require(amount != 0, "RewardEscrow: amount can not be zero");

        uint256 totalBalance = _storage.totalBalance().add(amount);
        require(totalBalance <= foundry().balanceOf(address(this)), "RewardEscrow: vesting amount exceeds balance");
        _storage.setTotalBalance(totalBalance);

        uint256 length = _storage.getVestingLength(account);
        require(length < maximum, "RewardEscrow: vesting length exceeds maximum");

        uint256 timestamp = now + _period;
        _storage.setTotalDepositedBalance(account, _storage.deposited(account).add(amount));
        if (length > 0) {
            require(_storage.getVestingTime(account, length - 1) < timestamp, "RewardEscrow: vesting timestamp should be asc");
        }
        _storage.addVestingSchedule(account, timestamp, amount);

        emit Deposited(account, now, amount);
    }

    function withdraw() public {
        uint256 length = _storage.getVestingLength(msg.sender);
        uint256 total;

        for (uint256 index = 0; index < length; index++) {
            uint256 timestamp = _storage.getVestingTime(msg.sender, index);
            if (timestamp > now) {
                break;
            }

            uint256 amount = _storage.getVestingAmount(msg.sender, index);
            if (amount == 0) {
                continue;
            }

            _storage.delVestingSchedule(msg.sender, index);
            total = total.add(amount);
        }

        if (total != 0) {
            _storage.setTotalBalance(_storage.totalBalance().sub(total, "RewardEscrow: withdraw amount exceeds total balance"));
            _storage.setTotalDepositedBalance(msg.sender, _storage.deposited(msg.sender).sub(total));
            _storage.setTotalWithdrawnBalance(msg.sender, _storage.withdrawn(msg.sender).add(total));

            foundry().transfer(msg.sender, total);

            emit Withdrawn(msg.sender, now, total);
        }
    }

    function withdraw(address account) public onlyWhitelisted returns (uint256) {
        uint256 length = _storage.getVestingLength(account);
        uint256 total;

        for (uint256 index = 0; index < length; index++) {
            uint256 timestamp = _storage.getVestingTime(account, index);
            if (timestamp > now) {
                break;
            }

            uint256 amount = _storage.getVestingAmount(account, index);
            if (amount == 0) {
                continue;
            }

            _storage.delVestingSchedule(account, index);
            total = total.add(amount);
        }

        if (total != 0) {
            _storage.setTotalBalance(_storage.totalBalance().sub(total, "RewardEscrow: withdraw amount exceeds total balance"));
            _storage.setTotalDepositedBalance(account, _storage.deposited(account).sub(total));
            _storage.setTotalWithdrawnBalance(account, _storage.withdrawn(account).add(total));

            foundry().transfer(account, total);

            emit Withdrawn(account, now, total);
        }
        return total;
    }

    function withdrawAble(address account) public view returns (uint256) {
        uint256 length = _storage.getVestingLength(account);
        uint256 total;

        for (uint256 index = 0; index < length; index++) {
            uint256 timestamp = _storage.getVestingTime(account, index);
            if (timestamp > now) {
                break;
            }

            uint256 amount = _storage.getVestingAmount(account, index);
            if (amount == 0) {
                continue;
            }
            total = total.add(amount);
        }
        
        return total;
    }

    event StorageTransferred(RewardEscrowStorage indexed previousStorage, RewardEscrowStorage indexed newStorage);
    event PeriodUpdated(uint256 indexed previousPeriod, uint256 indexed newPeriod);
    event Deposited(address indexed account, uint256 indexed timestamp, uint256 indexed amount);
    event Withdrawn(address indexed account, uint256 indexed timestamp, uint256 indexed amount);
}
