pragma solidity >=0.5.0 <0.7.0;

import "../../erc20/ERC20Proxyable.sol";
import "../../library/SafeMath.sol";
import "../../interface/IERC20.sol";
import "../common/MixinResolver.sol";

contract Mortgage is ERC20Proxyable, MixinResolver {

    using SafeMath for uint;

    uint totalMortgage;

    address public systemReward;

    constructor(string memory name, string memory symbol, uint8 decimals)
    ERC20Proxyable(name, symbol, decimals)
    public
    {
    }

    function setSystemReward(address _systemReward) onlyOwner public {
        systemReward = _systemReward;
        emitSystemRewardChange(systemReward);
    }

    function mortgage(address account, address sender, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.add(amount);
        database().setBalance(account, database().balanceOf(account).add(amount));
        araToken().transferFrom(sender, address(this), amount);
        noteTransfer(sender, address(this), amount);
        return true;
    }

    function redemption(address account, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.sub(amount);
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        araToken().transfer(account, amount);
        noteTransfer(address(this), account, amount);
        return true;
    }

    function redemptionTo(address account, address receiver, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: account is zero address");
        require(receiver != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.sub(amount);
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        araToken().transfer(receiver, amount);
        noteTransfer(address(this), receiver, amount);
        return true;
    }

    function redemptionAll(address account, address receiver) onlyFoundry public returns (uint256) {
        require(account != address(0), "Mortgage: account is zero address");
        require(receiver != address(0), "Mortgage: transfer to the zero address");
        uint256 old = database().balanceOf(account);
        totalMortgage = totalMortgage.sub(old);

        database().setBalance(account, 0);
        araToken().transfer(receiver, old);
        noteTransfer(address(this), receiver, old);
        return old;
    }

    function redemptionReward(address account, uint256 amount) onlyFoundry public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.sub(amount);
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        araToken().transfer(account, amount);
        noteTransfer(address(this), account, amount);
        return true;
    }

    function transferReward(uint256 amount) onlyFoundry public {
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        totalMortgage = totalMortgage.add(amount);
        database().setBalance(address(distribution()), database().balanceOf(address(distribution())).add(amount));
        araMinter().mintMortgageReward(address(this), amount);
        foundry().distribute(amount);
        noteTransfer(systemReward, address(this), amount);
    }

    function innerTransfer(address account, address receiver, uint256 amount) onlyFoundryOrFeePool public returns (bool) {
        require(account != address(0), "Mortgage: transfer to the zero address");
        require(amount > 0, "Mortgage: transfer amount must bigger than zero");
        uint256 old = database().balanceOf(account);
        require(old >= amount, "Mortgage: not sufficient funds");
        database().setBalance(account, old.sub(amount));
        database().setBalance(receiver, database().balanceOf(receiver).add(amount));
        noteTransfer(address(this), receiver, amount);
        return true;
    }

    function innerTransferFrom(address from, address to, uint256 amount) onlyFoundry public returns (bool) {
        innerTransfer(from, to, amount);
        database().setAllowance(from, to, database().allowance(from, to).sub(amount, "Mortgage: transfer amount exceeds allowance"));
        noteApproval(from, to, amount);
        return true;
    }

    function getTotalMortgage()
    public view
    returns (uint)
    {
        return totalMortgage;
    }

    modifier onlyFoundry {
        require(msg.sender == address(foundryExtend()), "Mortgage: Only foundryExtend Authorised");
        _;
    }

    modifier onlyFoundryOrFeePool {
        require(msg.sender == address(foundryExtend()), "Mortgage: Only foundryExtend or feePool Authorised");
        _;
    }

    bytes32 constant SYSTEM_REWARD_CHANGE_SIG = keccak256("SystemRewardChange(address)");

    function emitSystemRewardChange(address account) internal {
        proxy().note(abi.encode(account), 2, SYSTEM_REWARD_CHANGE_SIG, account.encode(), 0, 0);
    }
}