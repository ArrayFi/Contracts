pragma solidity >=0.5.0 <0.7.0;


import "../interface/IERC20.sol";
import "../common/Proxy.sol";


contract ERC20Proxy is IERC20, Proxy {
    constructor() public {}

    function name() public view returns (string memory) {
        return IERC20(address(proxyable())).name();
    }

    function symbol() public view returns (string memory) {
        return IERC20(address(proxyable())).symbol();
    }

    function decimals() public view returns (uint8) {
        return IERC20(address(proxyable())).decimals();
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(address(proxyable())).totalSupply();
    }

    function balanceOf(address account) external view returns (uint256) {
        return IERC20(address(proxyable())).balanceOf(account);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return IERC20(address(proxyable())).allowance(owner, spender);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        proxyable().setCaller(msg.sender);
        return IERC20(address(proxyable())).transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        proxyable().setCaller(msg.sender);
        return IERC20(address(proxyable())).approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        proxyable().setCaller(msg.sender);
        return IERC20(address(proxyable())).transferFrom(sender, recipient, amount);
    }
}
