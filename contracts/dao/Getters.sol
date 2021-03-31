/*
    Copyright 2020 Dynamic Dollar Devs, based on the works of the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./State.sol";
import "../Constants.sol";

contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 Interface
     */

    function name() public view returns (string memory) {
        return "Dynamic Set Dollar Stake";
    }

    function symbol() public view returns (string memory) {
        return "DSDS";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _state.accounts[account].balance;
    }

    function totalSupply() public view returns (uint256) {
        return _state.balance.supply;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    /**
     * Global
     */

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function oracle() public view returns (IOracle) {
        return _state.provider.oracle;
    }

    function pool() public view returns (address) {
        return _state.provider.pool;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalDebt() public view returns (uint256) {
        return _state.balance.debt;
    }

    function totalRedeemable() public view returns (uint256) {
        return _state.balance.redeemable;
    }

    function totalCouponUnderlying() public view returns (uint256) {
        return _state13.couponUnderlying;
    }

    function totalCoupons() public view returns (uint256) {
        return _state.balance.coupons;
    }

    function treasury() public view returns (address) {
        return Constants.getTreasuryAddress();
    }

    // DIP-10
    function totalCDSDBonded() public view returns (uint256) {
        return cdsd().balanceOf(address(this));
    }

    function dip10TotalRedeemable() public view returns (uint256) {
        return _state10.dip10TotalRedeemable;
    }

    function globalInterestMultiplier() public view returns (uint256) {
        return _state10.globalInterestMultiplier;
    }

    function expansionStartEpoch() public view returns (uint256) {
        return _state10.expansionStartEpoch;
    }

    function dip10TotalRedeemed() public view returns (uint256) {
        return _state10.dip10TotalRedeemed;
    }

    function totalCDSD() public view returns (uint256) {
        return cdsd().totalSupply();
    }

    function cdsd() public view returns (IDollar) {
        return _state10.cDSD;
    }

    // end DIP-10

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        uint256 totalSupplyAmount = totalSupply();
        if (totalSupplyAmount == 0) {
            return 0;
        }
        return totalBonded().mul(balanceOf(account)).div(totalSupplyAmount);
    }

    function balanceOfCoupons(address account, uint256 epoch) public view returns (uint256) {
        if (outstandingCoupons(epoch) == 0) {
            return 0;
        }
        return _state.accounts[account].coupons[epoch];
    }

    function balanceOfCouponUnderlying(address account, uint256 epoch) public view returns (uint256) {
        return _state13.couponUnderlyingByAccount[account][epoch];
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function fluidUntil(address account) public view returns (uint256) {
        return _state.accounts[account].fluidUntil;
    }

    function lockedUntil(address account) public view returns (uint256) {
        return _state.accounts[account].lockedUntil;
    }

    function allowanceCoupons(address owner, address spender) public view returns (uint256) {
        return _state.accounts[owner].couponAllowances[spender];
    }

    // DIP-10
    function balanceOfCDSDBonded(address account) public view returns (uint256) {
        uint256 amount = depositedCDSDByAccount(account).mul(_state10.globalInterestMultiplier).div(intrestMultiplierEntryByAccount(account));

        uint256 cappedAmount = cDSDBondedCap(account);

        return amount > cappedAmount ? cappedAmount : amount;
    }

    function cDSDBondedCap(address account) public view returns (uint256) {
        return depositedCDSDByAccount(account).add(earnableCDSDByAccount(account)).sub(earnedCDSDByAccount(account));
    }

    function depositedCDSDByAccount(address account) public view returns (uint256) {
        return _state10.accounts[account].depositedCDSD;
    }

    function intrestMultiplierEntryByAccount(address account) public view returns (uint256) {
        return _state10.accounts[account].interestMultiplierEntry;
    }

    function earnableCDSDByAccount(address account) public view returns (uint256) {
        return _state10.accounts[account].earnableCDSD;
    }

    function earnedCDSDByAccount(address account) public view returns (uint256) {
        return _state10.accounts[account].earnedCDSD;
    }

    function redeemedCDSDByAccount(address account) public view returns (uint256) {
        return _state10.accounts[account].redeemedCDSD;
    }

    function getRedeemedThisExpansion(address account) public view returns (uint256) {
        uint256 currentExpansion = _state10.expansionStartEpoch;
        uint256 accountExpansion = _state10.accounts[account].lastRedeemedExpansionStart;

        if (currentExpansion != accountExpansion) {
            return 0;
        }else{
            return _state10.accounts[account].redeemedThisExpansion;
        }
    }

    function getCurrentRedeemableCDSDByAccount(address account) public view returns (uint256) {
        return dip10TotalRedeemable()
            .mul(balanceOfCDSDBonded(account))
            .div(totalCDSDBonded())
            .sub(getRedeemedThisExpansion(account));
    }




    function totalCDSDDeposited() public view returns (uint256) {
        return _state10.totalCDSDDeposited;
    }

    function totalCDSDEarnable() public view returns (uint256) {
        return _state10.totalCDSDEarnable;
    }

    function totalCDSDEarned() public view returns (uint256) {
        return _state10.totalCDSDEarned;
    }
    function totalCDSDRedeemed() public view returns (uint256) {
        return _state10.totalCDSDRedeemed;
    }


    function maxCDSDOutstanding() public view returns (uint256) {
        return totalCDSDDeposited()
            .add(totalCDSDEarnable())
            .sub(totalCDSDEarned())
            .sub(totalCDSDRedeemed());
    }

    // end DIP-10

    /**
     * Epoch
     */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        Constants.EpochStrategy memory current = Constants.getEpochStrategy();

        return epochTimeWithStrategy(current);
    }

    function epochTimeWithStrategy(Constants.EpochStrategy memory strategy) private view returns (uint256) {
        return blockTimestamp().sub(strategy.start).div(strategy.period).add(strategy.offset);
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function outstandingCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.outstanding;
    }

    function couponsExpiration(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.expiration;
    }

    function expiringCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.expiring.length;
    }

    function expiringCouponsAtIndex(uint256 epoch, uint256 i) public view returns (uint256) {
        return _state.epochs[epoch].coupons.expiring[i];
    }

    function totalBondedAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].bonded;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= Constants.getBootstrappingPeriod();
    }

    /**
     * Governance
     */

    function recordedVote(address account, address candidate) public view returns (Candidate.Vote) {
        return _state.candidates[candidate].votes[account];
    }

    function startFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].start;
    }

    function periodFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].period;
    }

    function approveFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].approve;
    }

    function rejectFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].reject;
    }

    function votesFor(address candidate) public view returns (uint256) {
        return approveFor(candidate).add(rejectFor(candidate));
    }

    function isNominated(address candidate) public view returns (bool) {
        return _state.candidates[candidate].start > 0;
    }

    function isInitialized(address candidate) public view returns (bool) {
        return _state.candidates[candidate].initialized;
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}
