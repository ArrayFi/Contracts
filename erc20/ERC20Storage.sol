pragma solidity >=0.5.0 <0.7.0;


import "../common/Storage.sol";


contract ERC20Storage is Storage {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() public {}

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setTotalSupply(uint256 newTotalSupply) public onlyWhitelisted {
        _totalSupply = newTotalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setBalance(address account, uint256 newBalance) public onlyWhitelisted {
        _balances[account] = newBalance;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAllowance(address owner, address spender, uint256 newAllowance) public onlyWhitelisted {
        _allowances[owner][spender] = newAllowance;
    }
}
