pragma solidity >=0.5.0 <0.7.0;


import "../../common/Proxy.sol";
import "../../erc20/ERC20Storage.sol";
import "../../library/Address.sol";
import "../../erc20/ERC20Proxy.sol";
import "../common/ExternStorage.sol";
import "../common/MixinResolver.sol";


contract Combo is MixinResolver, ExternStorage {
    using Address for address;

    // Currency key which identifies this Combo to the Foundry system
    bytes32 public currencyKey;

    uint8 constant DECIMALS = 18;

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory _tokenName, string memory _tokenSymbol, bytes32 _currencyKey)
    ExternStorage(_tokenName, _tokenSymbol, DECIMALS)
    public
    {
        currencyKey = _currencyKey;
    }

    /* ========== SETTERS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice ERC20 transfer function
     * forward call on to _internalTransfer */
    function transfer(address to, uint value)
    public
    optionalProxy
    returns (bool)
    {
        return super._internalTransfer(caller, to, value);
    }

    /**
     * @notice ERC20 transferFrom function
     */
    function transferFrom(address from, address to, uint value)
    public
    optionalProxy
    returns (bool)
    {
        // Skip allowance update in case of infinite allowance
        if (erc20Storage.allowance(from, caller) != uint(- 1)) {
            // Reduce the allowance by the amount we're transferring.
            // The safeSub call will handle an insufficient allowance.
            erc20Storage.setAllowance(from, caller, erc20Storage.allowance(from, caller).sub(value));
        }

        return super._internalTransfer(from, to, value);
    }

    function foundryToTransferFrom(address from, address to, uint value) external onlyFoundryOrFeePool returns (bool){
        return super._internalTransfer(from, to, value);
    }

    // Allow foundry to issue a certain number of combos from an account.
    function issue(address account, uint amount)
    external
    onlyFoundryOrFeePool
    {
        erc20Storage.setBalance(account, erc20Storage.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

    // Allow synthetix or another synth contract to burn a certain number of synths from an account.
    function burn(address account, uint amount)
    external
    onlyFoundryOrFeePool
    {
        erc20Storage.setBalance(account, erc20Storage.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
    }

    // Allow owner to set the total supply on import.
    function setTotalSupply(uint amount)
    external
    optionalProxyAndOnlyOwner
    {
        totalSupply = amount;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyFoundryOrFeePool() {
        bool isFoundry = msg.sender == address(foundry());
        // bool isFeePool = msg.sender == address(feePool());

        // require(isFoundry || isFeePool, "Combo: Only Foundry, FeePool allowed");
        require(isFoundry, "Combo: Only Foundry allowed");
        _;
    }

    /* ========== EVENTS ========== */

    event Issued(address indexed account, uint value);

    bytes32 constant ISSUED_SIG = keccak256("Issued(address,uint256)");

    function emitIssued(address account, uint value) internal {
        proxy().note(abi.encode(value), 2, ISSUED_SIG, account.encode(), 0, 0);
    }

    event Burned(address indexed account, uint value);

    bytes32 constant BURNED_SIG = keccak256("Burned(address,uint256)");

    function emitBurned(address account, uint value) internal {
        proxy().note(abi.encode(value), 2, BURNED_SIG, account.encode(), 0, 0);
    }
}
