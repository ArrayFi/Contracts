pragma solidity >=0.5.0 <0.7.0;


import "../../interface/IERC20.sol";
import "../../common/AddressResolver.sol";
import "../interface/IFoundry.sol";
import "../interface/IFoundryExtend.sol";
import "../interface/ICombo.sol";
import "../interface/IARAToken.sol";
import "../interface/IFeePool.sol";
import "../interface/IPrivatePlacement.sol";
import "../interface/IExchangeRates.sol";
import "../interface/IRewardEscrow.sol";
import "../interface/IRewardDistribution.sol";
import "../interface/IARAMortgage.sol";
import "../interface/IARAMinter.sol";
import "../interface/IRelationship.sol";
import "../interface/IProxyFee.sol";


contract MixinResolver is AddressResolver {

    function usdt() public view returns (IERC20) {
        return IERC20(resolver().addr("USDT", "MixinResolver: missing usdt address"));
    }

    function araToken() public view returns (IARAToken) {
        return IARAToken(resolver().addr("ARAToken", "MixinResolver: missing araToken address"));
    }

    function foundry() public view returns (IFoundry) {
        return IFoundry(resolver().addr("Foundry", "MixinResolver: missing foundry address"));
    }

    function foundryExtend() public view returns (IFoundryExtend) {
        return IFoundryExtend(resolver().addr("FoundryExtend", "MixinResolver: missing foundry-extend address"));
    }

    function usdr() public view returns (ICombo) {
        return ICombo(resolver().addr("USDR", "MixinResolver: missing usdk address"));
    }

    function feePool() public view returns (IFeePool) {
        return IFeePool(resolver().addr("FeePool", "MixinResolver: missing fee-pool address"));
    }

    function rates() public view returns (IExchangeRates) {
        return IExchangeRates(resolver().addr("ExchangeRates", "MixinResolver: missing exchange-rates address"));
    }

    function reward() public view returns (IRewardEscrow) {
        return IRewardEscrow(resolver().addr("RewardEscrow", "MixinResolver: missing reward-escrow address"));
    }

    function distribution() public view returns (IRewardDistribution) {
        return IRewardDistribution(resolver().addr("RewardDistribution", "MixinResolver: missing reward-distribution address"));
    }

    function mortgage() public view returns (IARAMortgage) {
        return IARAMortgage(resolver().addr("Mortgage", "MixinResolver: missing mortgage address"));
    }

    function araMinter() public view returns (IARAMinter) {
        return IARAMinter(resolver().addr("ARAMinter", "MixinResolver: missing araMinter address"));
    }
}