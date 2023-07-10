// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

interface MulticallExtended {
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory);
}