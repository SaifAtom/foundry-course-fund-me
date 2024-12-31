// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address user = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, STARTING_BALANCE);
    }

    function testMinDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsDeployer() public view {
        assertEq(fundMe.getOwner(), address(msg.sender));
    }

    function testGetVersion() public view {
        console.log("Version: %d", fundMe.getVersion());
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // Next Instruction should revert
        fundMe.fund(); // Send 0 Eth
    }

    function testFundUpdatesFundersArrayAndMapping() public {
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amount = fundMe.getAdressToFundedAmount(user);
        address funder = fundMe.getFunders(0);
        assertEq(amount, SEND_VALUE);
        assertEq(funder, user);
    }

    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWidhdrawFailsIfNotOwner() public {
        vm.expectRevert(); // Next Instruction should revert
        vm.prank(user);
        fundMe.withdraw(); // Send 0 Eth
    }

    function testWidhrawAmountWithSingleFunder() public funded {
        // 1. Arrange
        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 fundMeStartingBalance = address(fundMe).balance;
        //2. Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //3. Assert
        assertEq(
            fundMe.getOwner().balance,
            ownerStartingBalance + fundMeStartingBalance
        );
        assertEq(address(fundMe).balance, 0);
    }

    function testWidhrawAmountWithMultipleFunders() public {
        // 1. Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Hoax is PRANK & DEAL combined
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }
        //2. Act
        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 fundMeStartingBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //3. Assert
        assertEq(
            fundMe.getOwner().balance,
            ownerStartingBalance + fundMeStartingBalance
        );
        assertEq(address(fundMe).balance, 0);
    }
}
