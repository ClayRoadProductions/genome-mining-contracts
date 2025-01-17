// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../contracts/Converter.sol";
import "../contracts/EnergyStorage.sol";
import "../contracts/Controller.sol";
import "../contracts/Staking.sol";
import "../contracts/helpers/IConverter.sol";
import "../contracts/mocks/MockedERC20.sol";
import "../contracts/helpers/IStaking.sol";
import "../contracts/interfaces/ILiquidityBootstrapAuction.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

/**
 * @dev Tests for the ASM Genome Mining - Energy Converter contract
 */
contract ConverterTestContract is DSTest, IConverter, IStaking, Util {
    EnergyStorage energyStorage_;
    EnergyStorage lbaEnergyStorage_;
    Converter converterLogic_;
    Controller controller_;
    Staking stakingLogic_;
    StakingStorage astoStorage_;
    StakingStorage lpStorage_;
    MockedERC20 astoToken_;
    MockedERC20 lpToken_;

    uint256 initialBalance = 100e18;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // ILiquidityBootstrapAuction lba = ILiquidityBootstrapAuction(0x6D08cF8E2dfDeC0Ca1b676425BcFCF1b0e064afA); // rinkeby
    ILiquidityBootstrapAuction lba = ILiquidityBootstrapAuction(0x25720f1f60bd2F50C50841fF04d658da10BDf0B7); // goerli
    address someone = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
    address deployer = address(this);
    address multisig = deployer; // for the testing we use deployer as a multisig
    address dao = deployer; // for the testing we use deployer as a dao

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupTokens(); // mock tokens
        setupContracts();
        setupWallets();
    }

    function setupContracts() internal {
        controller_ = new Controller(multisig);
        astoStorage_ = new StakingStorage(address(controller_));
        lpStorage_ = new StakingStorage(address(controller_));
        energyStorage_ = new EnergyStorage(address(controller_));
        lbaEnergyStorage_ = new EnergyStorage(address(controller_));
        converterLogic_ = new Converter(address(controller_), address(lba), new Period[](0), 0);
        stakingLogic_ = new Staking(address(controller_));

        controller_.init(
            address(dao),
            address(astoToken_),
            address(astoStorage_),
            address(lpToken_),
            address(lpStorage_),
            address(stakingLogic_),
            address(converterLogic_),
            address(energyStorage_),
            address(lbaEnergyStorage_)
        );
        controller_.unpause();
    }

    function setupTokens() internal {
        astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance, 18);
        lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance, 18);
    }

    function setupWallets() internal {
        vm.deal(address(this), 1000); // adds 1000 ETH to the contract balance
        vm.deal(deployer, 1); // gas spendings
        vm.deal(someone, 1); // gas spendings
    }

    /** ----------------------------------
     * ! Logic
     * ----------------------------------- */

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND: wallet address is valid
     * @notice  THEN: should get correct consumed amount from mappings
     */
    function testGetConsumedEnergy() public skip(false) {
        assert(converterLogic_.getConsumedEnergy(someone) == 0);

        uint256 newConsumedAmount = 100;
        vm.startPrank(address(converterLogic_));
        energyStorage_.increaseConsumedAmount(someone, newConsumedAmount);
        assert(converterLogic_.getConsumedEnergy(someone) == newConsumedAmount);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND:  wallet address is invalid
     * @notice  THEN: should revert the message WRONG_ADDRESS
     */
    function testGetConsumedEnergy_wrong_wallet() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        converterLogic_.getConsumedEnergy(address(0));
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND: wallet address is valid
     * @notice  THEN: should get correct consumed amount from mappings
     */
    function testGetConsumedLBAEnergy() public skip(false) {
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 0);

        uint256 newConsumedAmount = 100;
        vm.startPrank(address(converterLogic_));
        lbaEnergyStorage_.increaseConsumedAmount(someone, newConsumedAmount);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == newConsumedAmount);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND:  wallet address is invalid
     * @notice  THEN: should revert the message WRONG_ADDRESS
     */
    function testGetConsumedLBAEnergy_wrong_wallet() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        converterLogic_.getConsumedLBAEnergy(address(0));
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND: wallet address is valid
     * @notice  THEN: should get correct earned amount from mappings
     */
    function testGetEarnedEnergy() public skip(false) {
        assert(converterLogic_.getEarnedEnergy(someone) == 0);

        uint256 newEarnedAmount = 100;
        vm.startPrank(address(converterLogic_));
        energyStorage_.increaseEarnedAmount(someone, newEarnedAmount);
        assert(converterLogic_.getEarnedEnergy(someone) == newEarnedAmount);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND:  wallet address is invalid
     * @notice  THEN: should revert the message WRONG_ADDRESS
     */
    function testGetEarnedEnergy_wrong_wallet() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        converterLogic_.getEarnedEnergy(address(0));
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND: wallet address is valid
     * @notice  THEN: should get correct earned amount from mappings
     */
    function testGetEarnedLBAEnergy() public skip(false) {
        assert(converterLogic_.getEarnedLBAEnergy(someone) == 0);

        uint256 newEarnedAmount = 100;
        vm.startPrank(address(converterLogic_));
        lbaEnergyStorage_.increaseEarnedAmount(someone, newEarnedAmount);
        assert(converterLogic_.getEarnedLBAEnergy(someone) == newEarnedAmount);
    }

    /**
     * @notice GIVEN: a wallet, and amount
     * @notice  WHEN: caller is a converter
     * @notice   AND:  wallet address is invalid
     * @notice  THEN: should revert the message WRONG_ADDRESS
     */
    function testGetEarnedLBAEnergy_wrong_wallet() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_ADDRESS));
        converterLogic_.getEarnedLBAEnergy(address(0));
    }

    /**
     * @notice GIVEN: Period struct data (startTime, endTime, astoMultiplier and lpMultiplier)
     * @notice  WHEN: manager calls `addPeriod` or `updatePeriod` function
     * @notice  THEN: period added or updated in the contract
     * @notice  AND: user can call `getCurrentPeriodId`, `getPeriod` or `getCurrentPeriod` to get the data
     */
    function testPeriod_happy_path() public skip(false) {
        vm.startPrank(multisig);

        assert(converterLogic_.periodIdCounter() == 0);

        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        converterLogic_.addPeriod(period);

        vm.warp(startTime + 1 days);

        uint256 periodId = converterLogic_.getCurrentPeriodId();
        assert(converterLogic_.periodIdCounter() == 1);
        assert(periodId == 1);

        Period memory p = converterLogic_.getCurrentPeriod();
        assert(p.startTime == period.startTime);
        assert(p.endTime == period.endTime);
        assert(p.astoMultiplier == period.astoMultiplier);
        assert(p.lpMultiplier == period.lpMultiplier);
        assert(p.lbaLPMultiplier == period.lbaLPMultiplier);

        uint128 startTimeNew = uint128(block.timestamp + 2 days);
        uint128 endTimeNew = startTimeNew + 60 days;
        uint128 astoMultiplierNew = 1.2 * 10**18;
        uint128 lpMultiplierNew = 1.5 * 10**18;
        uint128 lbaLPMultiplierNew = 2 * 10**18;

        Period memory periodNew = Period(
            startTimeNew,
            endTimeNew,
            astoMultiplierNew,
            lpMultiplierNew,
            lbaLPMultiplierNew
        );
        converterLogic_.updatePeriod(periodId, periodNew);

        uint256 periodIdNew = converterLogic_.getCurrentPeriodId();
        assert(converterLogic_.periodIdCounter() == 1);
        assert(periodIdNew == 0);

        Period memory pNew = converterLogic_.getPeriod(periodId);
        assert(pNew.startTime == startTimeNew);
        assert(pNew.endTime == endTimeNew);
        assert(pNew.astoMultiplier == astoMultiplierNew);
        assert(pNew.lpMultiplier == lpMultiplierNew);
        assert(pNew.lbaLPMultiplier == lbaLPMultiplierNew);
    }

    /**
     * @notice GIVEN: periodId
     * @notice  WHEN: user calls `getPeriod` function
     * @notice  AND: periodId is invalid
     * @notice  THEN: should revert the message WRONG_PERIOD_ID
     */
    function testGetPeriod_invalid_period_id() public skip(false) {
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_PERIOD_ID));
        converterLogic_.getPeriod(0);

        uint256 periodId = converterLogic_.periodIdCounter() + 1;
        vm.expectRevert(abi.encodeWithSelector(InvalidInput.selector, WRONG_PERIOD_ID));
        converterLogic_.getPeriod(periodId);
    }

    function testGetCurrentPeriodId_current_time_in_period() public skip(false) {
        vm.startPrank(multisig);

        uint256 periodId = converterLogic_.getCurrentPeriodId();
        assert(periodId == 0);

        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        converterLogic_.addPeriod(period);

        uint256 newPeriodId = converterLogic_.getCurrentPeriodId();
        assert(newPeriodId == 1);
    }

    function testGetCurrentPeriodId_current_time_early_than_startTime() public skip(false) {
        vm.startPrank(multisig);

        uint128 startTime = uint128(block.timestamp) + 1 days;
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        converterLogic_.addPeriod(period);

        uint256 periodId = converterLogic_.getCurrentPeriodId();
        assert(periodId == 0);
    }

    function testGetCurrentPeriodId_current_time_later_than_endTime() public skip(false) {
        vm.startPrank(multisig);

        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        converterLogic_.addPeriod(period);

        vm.warp(endTime + 1 days);
        uint256 periodId = converterLogic_.getCurrentPeriodId();
        assert(periodId == 0);
    }

    function testGetCurrentPeriodId_multiple_periods() public skip(false) {
        vm.startPrank(multisig);

        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](3);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(startTime + 60 days, startTime + 120 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[2] = Period(startTime + 120 days, startTime + 180 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        converterLogic_.addPeriods(periods);

        vm.warp(startTime - 1 days);
        assert(converterLogic_.getCurrentPeriodId() == 0);

        vm.warp(startTime + 10 days);
        assert(converterLogic_.getCurrentPeriodId() == 1);

        vm.warp(startTime + 70 days);
        assert(converterLogic_.getCurrentPeriodId() == 2);

        vm.warp(startTime + 130 days);
        assert(converterLogic_.getCurrentPeriodId() == 3);

        vm.warp(startTime + 190 days);
        assert(converterLogic_.getCurrentPeriodId() == 0);
    }

    /**
     * @notice GIVEN: Period struct data (startTime, endTime, astoMultiplier and lpMultiplier)
     * @notice  AND: Staking history list (time and amount)
     * @notice  AND: address and periodId
     * @notice  WHEN: user calls `calculateEnergy` function
     * @notice  THEN: return calculated enery based on staking history and token multipliers
     */
    function testEnergyCalculation_with_stake_history() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](3);
        astoHistory[0] = Stake(startTime, 5);
        astoHistory[1] = Stake(startTime + 1 days, 15);
        astoHistory[2] = Stake(startTime + 2 days, 25);

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime + 1 days, 2);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        vm.warp(startTime + 3 days);
        uint256 energy = converterLogic_.calculateEnergy(someone, converterLogic_.getCurrentPeriodId());
        uint256 expectedEnergy = (5 * 3 + 10 * 2 + 10) * astoMultiplier + 2 * 2 * lpMultiplier;
        assert(energy == expectedEnergy);
    }

    /**
     * @notice GIVEN: Period struct data (startTime, endTime, astoMultiplier and lpMultiplier)
     * @notice  AND: Staking and Unstaking history list (time and amount)
     * @notice  AND: address and periodId
     * @notice  WHEN: user calls `calculateEnergy` function
     * @notice  THEN: return calculated enery based on staking/unstaking history and token multipliers
     */
    function testEnergyCalculation_with_stake_and_unstake_history() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.36 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](3);
        astoHistory[0] = Stake(startTime, 5);
        astoHistory[1] = Stake(startTime + 1 days, 15);
        astoHistory[2] = Stake(startTime + 2 days, 5);

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime + 1 days, 2);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        vm.warp(startTime + 3 days);
        uint256 energy = converterLogic_.calculateEnergy(someone, converterLogic_.getCurrentPeriodId());
        uint256 expectedEnergy = (5 * 3 + 10) * astoMultiplier + 2 * 2 * lpMultiplier;
        assert(energy == expectedEnergy);
    }

    function testEnergyCalculation_with_new_production_cycle() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.36 * 10**18;

        Period[] memory periods = new Period[](3);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(startTime + 60 days, startTime + 120 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[2] = Period(startTime + 120 days, startTime + 180 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        converterLogic_.addPeriods(periods);

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 5);

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime + 1 days, 2);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        vm.warp(startTime + 63 days);
        uint256 energy = converterLogic_.calculateEnergy(someone, 1);
        uint256 expectedEnergy = 5 * 60 * astoMultiplier + 2 * 59 * lpMultiplier;
        assertEq(energy, expectedEnergy, "Energy didn't match in new production cycle");
    }

    function testLBAEnergyCalculation_with_lp_not_withdrawn() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(10));

        vm.warp(startTime + 3 days);
        uint256 lbaEnergy = converterLogic_.calculateAvailableLBAEnergy(someone, converterLogic_.getCurrentPeriodId());
        uint256 expectedLBAEnergy = (10 * 3) * lbaLPMultiplier;
        assert(lbaEnergy == expectedLBAEnergy);
    }

    function testLBAEnergyCalculation_with_new_production_cycle() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](3);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(startTime + 60 days, startTime + 120 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[2] = Period(startTime + 120 days, startTime + 180 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        converterLogic_.addPeriods(periods);

        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(10));

        vm.warp(startTime + 63 days); // 3 days after PC1 ends
        uint256 lbaEnergy = converterLogic_.calculateAvailableLBAEnergy(someone, 1);
        uint256 expectedLBAEnergy = (10 * 60) * lbaLPMultiplier; // only energy from PC1
        assert(lbaEnergy == expectedLBAEnergy);
    }

    function testLBAEnergyCalculation_with_lp_withdrawn() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(0));

        vm.warp(startTime + 3 days);
        uint256 lbaEnergy = converterLogic_.calculateAvailableLBAEnergy(someone, converterLogic_.getCurrentPeriodId());
        assert(lbaEnergy == 0);
    }

    /**
     * @notice GIVEN: Periods added to converter
     * @notice  AND: tokens staked
     * @notice  AND: address, period id and consumed amount
     * @notice  WHEN: user calls `useEnergy` function
     * @notice  THEN: increase consumed energy in storyage contract
     * @notice  THEN: getConsumedEnergy() returns the new amount
     */
    function testUseEnergy_happy_path() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](2);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(endTime, endTime + 60 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        vm.startPrank(multisig);
        converterLogic_.addPeriods(periods);
        converterLogic_.addConsumer(address(lba));
        vm.stopPrank();

        assert(converterLogic_.getConsumedEnergy(someone) == 0);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 0);

        vm.startPrank(address(lba));

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 100);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(new Stake[](0))
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(10));

        vm.warp(startTime + 1 days);
        converterLogic_.useEnergy(someone, 1, 100 * 10**18);
        assert(converterLogic_.getConsumedEnergy(someone) == 85 * 10**18);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 15 * 10**18);
    }

    function testUseEnergy_with_lp_withdrawn_from_LBA() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](2);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(endTime, endTime + 60 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        vm.startPrank(multisig);
        converterLogic_.addPeriods(periods);
        converterLogic_.addConsumer(address(lba));
        vm.stopPrank();

        vm.startPrank(address(lba));

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 100);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(new Stake[](0))
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(0));

        vm.warp(startTime + 1 days);
        converterLogic_.useEnergy(someone, 1, 100 * 10**18);
        assert(converterLogic_.getConsumedEnergy(someone) == 100 * 10**18);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 0);
    }

    function testUseEnergy_with_lp_withdrawn_from_LBA_after_first_use() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](2);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(endTime, endTime + 60 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        vm.startPrank(multisig);
        converterLogic_.addPeriods(periods);
        converterLogic_.addConsumer(address(lba));
        vm.stopPrank();

        vm.startPrank(address(lba));

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 100);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(new Stake[](0))
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(10));

        vm.warp(startTime + 1 days);
        converterLogic_.useEnergy(someone, 1, 10 * 10**18);
        assert(converterLogic_.getConsumedEnergy(someone) == 0);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 10 * 10**18);

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(0));

        converterLogic_.useEnergy(someone, 1, 5 * 10**18);
        assert(converterLogic_.getConsumedEnergy(someone) == 5 * 10**18);
        assert(converterLogic_.getConsumedLBAEnergy(someone) == 10 * 10**18);
    }

    function testUseEnergy_with_customized_lba_start_time() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period[] memory periods = new Period[](2);
        periods[0] = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        periods[1] = Period(endTime, endTime + 60 days, astoMultiplier, lpMultiplier, lbaLPMultiplier);

        uint256 lbaEnergyStartTime = startTime + 1 days;
        converterLogic_ = new Converter(address(controller_), address(lba), new Period[](0), lbaEnergyStartTime);
        controller_.setConverterLogic(address(converterLogic_));
        controller_.unpause();

        vm.startPrank(multisig);
        converterLogic_.addPeriods(periods);
        converterLogic_.addConsumer(address(lba));
        vm.stopPrank();

        vm.startPrank(address(lba));

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 100);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(new Stake[](0))
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector), abi.encode(10));

        vm.warp(startTime + 2 days);
        converterLogic_.useEnergy(someone, 1, 100 * 10**18);
        assertEq(converterLogic_.getConsumedEnergy(someone), 85 * 10**18, "Consumed energy should be 100e18");
        assertEq(converterLogic_.getConsumedLBAEnergy(someone), 15 * 10**18, "Consumder LBA energy  should be 15e18");
    }

    function testGetDailyASTOEnergyProduction_with_no_stakes() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](0);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        uint256 energy = converterLogic_.getDailyASTOEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 0);
    }

    function testGetDailyASTOEnergyProduction_with_multiple_stakes() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](3);
        astoHistory[0] = Stake(startTime, 5); // stake 5
        astoHistory[1] = Stake(startTime + 1 days, 15); // stake 10
        astoHistory[2] = Stake(startTime + 2 days, 10); // unstake 5

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );

        uint256 energy = converterLogic_.getDailyASTOEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 10 * astoMultiplier);
    }

    function testGetDailyLPEnergyProduction_with_no_stakes() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory lpHistory = new Stake[](0);

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        uint256 energy = converterLogic_.getDailyLPEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 0);
    }

    function testGetDailyLPEnergyProduction_with_multiple_stakes() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory lpHistory = new Stake[](3);
        lpHistory[0] = Stake(startTime, 5); // stake 5
        lpHistory[1] = Stake(startTime + 1 days, 15); // stake 10
        lpHistory[2] = Stake(startTime + 2 days, 10); // unstake 5

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );

        uint256 energy = converterLogic_.getDailyLPEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 10 * lpMultiplier);
    }

    function testGetDailyLBAEnergyProduction_with_no_claimable_lp() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector, someone), abi.encode(0));

        uint256 energy = converterLogic_.getDailyLBAEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 0);
    }

    function testGetDailyLBAEnergyProduction_with_claimable_lp() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector, someone), abi.encode(100));

        uint256 energy = converterLogic_.getDailyLBAEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 100 * lbaLPMultiplier);
    }

    function testGetDailyEnergyProduction_with_all_tokens() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](3);
        astoHistory[0] = Stake(startTime, 5); // stake 5
        astoHistory[1] = Stake(startTime + 1 days, 15); // stake 10
        astoHistory[2] = Stake(startTime + 2 days, 10); // unstake 5

        Stake[] memory lpHistory = new Stake[](3);
        lpHistory[0] = Stake(startTime, 10); // stake 10
        lpHistory[1] = Stake(startTime + 1 days, 5); // unstake 5
        lpHistory[2] = Stake(startTime + 2 days, 20); // stake 15

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector, someone), abi.encode(100));

        uint256 energy = converterLogic_.getDailyEnergyProduction(someone, converterLogic_.getCurrentPeriodId());
        assert(energy == 10 * astoMultiplier + 20 * lpMultiplier + 100 * lbaLPMultiplier);
    }

    function testGetEnergyForCurrentPeriod_with_invalid_period() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector, someone), abi.encode(100));

        vm.warp(startTime - 1 days);
        uint256 energy = converterLogic_.getEnergyForCurrentPeriod(someone);
        assertEq(energy, 0, "Energy should be zero when period hasn't started");

        vm.warp(endTime + 1 days);
        uint256 newEnergy = converterLogic_.getEnergyForCurrentPeriod(someone);
        assertEq(newEnergy, 0, "Energy should be zero when period has finished");
    }

    function testGetEnergyForCurrentPeriod_with_valid_period() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 5); // stake 5

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime, 10); // stake 10

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector, someone), abi.encode(100));

        vm.warp(startTime + 1 days);
        uint256 energy = converterLogic_.getEnergyForCurrentPeriod(someone);
        assertEq(energy, 5 * astoMultiplier + 10 * lpMultiplier + 100 * lbaLPMultiplier, "Energy should be 1618e17");
    }

    function testGetEnergy_with_more_consumed_than_generated() public skip(false) {
        uint128 startTime = uint128(block.timestamp);
        uint128 endTime = startTime + 60 days;
        uint128 astoMultiplier = 1 * 10**18;
        uint128 lpMultiplier = 1.36 * 10**18;
        uint128 lbaLPMultiplier = 1.5 * 10**18;

        Period memory period = Period(startTime, endTime, astoMultiplier, lpMultiplier, lbaLPMultiplier);
        vm.prank(multisig);
        converterLogic_.addPeriod(period);

        Stake[] memory astoHistory = new Stake[](1);
        astoHistory[0] = Stake(startTime, 5); // stake 5

        Stake[] memory lpHistory = new Stake[](1);
        lpHistory[0] = Stake(startTime, 10); // stake 10

        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 0, someone, uint256(endTime)),
            abi.encode(astoHistory)
        );
        vm.mockCall(
            address(stakingLogic_),
            abi.encodeWithSelector(stakingLogic_.getHistory.selector, 1, someone, uint256(endTime)),
            abi.encode(lpHistory)
        );
        vm.mockCall(
            address(lba),
            abi.encodeWithSelector(lba.lpTokenReleaseTime.selector),
            abi.encode(uint256(startTime))
        );
        vm.mockCall(address(lba), abi.encodeWithSelector(lba.claimableLPAmount.selector, someone), abi.encode(100));

        uint256 consumedAmount = 100 * 10**20;
        vm.startPrank(address(converterLogic_));
        energyStorage_.increaseConsumedAmount(someone, consumedAmount);

        vm.warp(startTime + 1 days);
        uint256 energy = converterLogic_.getEnergyForCurrentPeriod(someone);
        assertEq(energy, 100 * lbaLPMultiplier, "Energy should be 15e19");
    }

    /** ----------------------------------
     * ! Contract modifiers
     * ----------------------------------- */

    /**
     * @notice this modifier will skip the test
     */
    modifier skip(bool isSkipped) {
        if (!isSkipped) {
            _;
        }
    }

    /**
     * @notice this modifier will skip the testFail*** tests ONLY
     */
    modifier skipFailing(bool isSkipped) {
        if (isSkipped) {
            require(0 == 1);
        } else {
            _;
        }
    }
}
