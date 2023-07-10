pragma solidity >=0.5.0 <0.7.0;


import "../interface/IERC20.sol";
import "../library/SafeMath.sol";
import "../library/Address.sol";
import "../access/BlacklistedRole.sol";
import "../common/Pausable.sol";
import "../common/Proxyable.sol";
import "./ERC20Storage.sol";

contract ERC20Proxyable is IERC20, BlacklistedRole, Pausable, Proxyable {
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    ERC20Storage private _storage;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function database() public view returns (ERC20Storage) {
        return _storage;
    }

    function setStorage(ERC20Storage newStorage) public optionalProxyAndOnlyOwner {
        noteStorageTransferred(_storage, newStorage);
        _storage = newStorage;
    }

    function totalSupply() public view returns (uint256) {
        return _storage.totalSupply();
    }

    function setTotalSupply(uint256 newTotalSupply) public optionalProxyAndOnlyOwner {
        _storage.setTotalSupply(newTotalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _storage.balanceOf(account);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _storage.allowance(owner, spender);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20Proxyable: sender is the zero address");
        require(recipient != address(0), "ERC20Proxyable: recipient is the zero address");
        require(recipient != address(this) && recipient != address(proxy()), "ERC20Proxyable: transfer to proxyable or proxy address");

        _storage.setBalance(sender, _storage.balanceOf(sender).sub(amount, "ERC20Proxyable: transfer amount exceeds balance"));
        _storage.setBalance(recipient, _storage.balanceOf(recipient).add(amount));

        noteTransfer(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public optionalProxy whenNotPaused onlyNotBlacklisted(caller) onlyNotBlacklisted(recipient) returns (bool) {
        _transfer(caller, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public optionalProxy whenNotPaused onlyNotBlacklisted(caller) onlyNotBlacklisted(sender) onlyNotBlacklisted(recipient) returns (bool) {
        uint256 delta = _storage.allowance(sender, caller).sub(amount, "ERC20Proxyable: decreased allowance below zero");
        _transfer(sender, recipient, amount);
        _approve(sender, caller, delta);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20Proxyable: owner is the zero address");
        require(spender != address(0), "ERC20Proxyable: spender is the zero address");

        _storage.setAllowance(owner, spender, amount);
        noteApproval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public optionalProxy whenNotPaused onlyNotBlacklisted(caller) onlyNotBlacklisted(spender) returns (bool) {
        _approve(caller, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public optionalProxy whenNotPaused onlyNotBlacklisted(caller) onlyNotBlacklisted(spender) returns (bool) {
        _approve(caller, spender, _storage.allowance(caller, spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public optionalProxy whenNotPaused onlyNotBlacklisted(caller) onlyNotBlacklisted(spender) returns (bool) {
        _approve(caller, spender, _storage.allowance(caller, spender).sub(subtractedValue, "ERC20Proxyable: decreased allowance below zero"));
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20Proxyable: account is the zero address");

        _storage.setTotalSupply(_storage.totalSupply().add(amount));
        _storage.setBalance(account, _storage.balanceOf(account).add(amount));

        noteApproval(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20Proxyable: account is the zero address");

        _storage.setBalance(account, _storage.balanceOf(account).sub(amount, "ERC20Proxyable: burn amount exceeds balance"));
        _storage.setTotalSupply(_storage.totalSupply().sub(amount));

        noteApproval(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, caller, _storage.allowance(account, caller).sub(amount, "ERC20Proxyable: burn amount exceeds allowance"));
    }


    function noteTransfer(address from, address to, uint256 value) internal {
        proxy().note(abi.encode(value), 3, keccak256("Transfer(address,address,uint256)"), from.encode(), to.encode(), 0);
    }

    function noteApproval(address owner, address spender, uint256 value) internal {
        proxy().note(abi.encode(value), 3, keccak256("Approval(address,address,uint256)"), owner.encode(), spender.encode(), 0);
    }

    function noteStorageTransferred(ERC20Storage previousStorage, ERC20Storage newStorage) internal {
        proxy().note(abi.encode(now), 3, keccak256("StorageTransferred(address,address,uint256)"), address(previousStorage).encode(), address(newStorage).encode(), 0);
    }


    event StorageTransferred(ERC20Storage indexed previousStorage, ERC20Storage indexed newStorage, uint256 timestamp);
}
