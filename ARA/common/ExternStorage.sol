
pragma solidity >=0.5.0 <0.7.0;

import "../../library/SafeMath.sol";
import "../../erc20/ERC20Storage.sol";
import "../../common/Proxyable.sol";
import "../../library/Address.sol";

/**
 * @title ERC20 Token contract, with detached state and designed to operate behind a proxy.
 */
contract ExternStorage is Proxyable {

    using SafeMath for uint;
    using Address for address;

    /* ========== STATE VARIABLES ========== */

    /* Stores balances and allowances. */
    ERC20Storage public erc20Storage;

    /* Other ERC20 fields. */
    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;

    /**
     * @dev Constructor.
     * @param _name Token's ERC20 name.
     * @param _symbol Token's ERC20 symbol.
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        public
    {

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return erc20Storage.allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     */
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return erc20Storage.balanceOf(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the erc20Storage at 0x000..
     * as balances would be unreachable.
     */
    function setErc20Storage(ERC20Storage _erc20Storage)
        external
        optionalProxyAndOnlyOwner
    {
        erc20Storage = _erc20Storage;
        emitTokenStateUpdated(address(_erc20Storage));
    }

    function _internalTransfer(address from, address to, uint value)
        internal
        returns (bool)
    {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0) && to != address(this) && to != address(proxy()), "ExternStorage: Cannot transfer to this address");

        // Insufficient balance will be handled by the safe subtraction.
        erc20Storage.setBalance(from, erc20Storage.balanceOf(from).sub(value));
        erc20Storage.setBalance(to, erc20Storage.balanceOf(to).add(value));

        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transfer_byProxy(address from, address to, uint value)
        internal
        returns (bool)
    {
        return _internalTransfer(from, to, value);
    }

    /**
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        /* Insufficient allowance will be handled by the safe subtraction. */
        erc20Storage.setAllowance(from, sender, erc20Storage.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value);
    }

    /**
     * @notice Approves spender to transfer on the message sender's behalf.
     */
    function approve(address spender, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = caller;

        erc20Storage.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }

    /* ========== EVENTS ========== */

    event Transfer(address indexed from, address indexed to, uint value);
    bytes32 constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");
    function emitTransfer(address from, address to, uint value) internal {
        proxy().note(abi.encode(value), 3, TRANSFER_SIG, from.encode(), to.encode(), 0);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    bytes32 constant APPROVAL_SIG = keccak256("Approval(address,address,uint256)");
    function emitApproval(address owner, address spender, uint value) internal {
        proxy().note(abi.encode(value), 3, APPROVAL_SIG, owner.encode(), spender.encode(), 0);
    }

    event TokenStateUpdated(address newTokenState);
    bytes32 constant TOKENSTATEUPDATED_SIG = keccak256("TokenStateUpdated(address)");
    function emitTokenStateUpdated(address newTokenState) internal {
        proxy().note(abi.encode(newTokenState), 1, TOKENSTATEUPDATED_SIG, 0, 0, 0);
    }
}
