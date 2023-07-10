pragma solidity >=0.5.0 <0.7.0;


import "../interface/IERC20.sol";
import "./Address.sol";


library SafeERC20 {
    using Address for address;

    function execute(IERC20 erc20, bytes memory data) private {
        require(address(erc20).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(erc20).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: erc20 operation did not succeed");
        }

    }

    function safeApprove(IERC20 erc20, address spender, uint256 amount) internal {
        execute(erc20, abi.encodeWithSelector(erc20.approve.selector, spender, amount));
    }

    function safeTransfer(IERC20 erc20, address recipient, uint256 amount) internal {
        execute(erc20, abi.encodeWithSelector(erc20.transfer.selector, recipient, amount));
    }

    function safeTransferFrom(IERC20 erc20, address sender, address recipient, uint256 amount) internal {
        execute(erc20, abi.encodeWithSelector(erc20.transferFrom.selector, sender, recipient, amount));
    }
}
