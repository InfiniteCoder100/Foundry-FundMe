//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    modifier funded() {
        // This modifier will fund the contract before running the test
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Give USER 10 ETH
    }

    function testMinUSD() public view {
        console.log("Minimum USD required to fund:", fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwner() public view {
        console.log("Owner of the contract:", fundMe.i_owner());
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testGetOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public view {
        uint version = fundMe.getVersion();
        assertEq(version, 4);
    }
    //       function testPriceFeedVersionIsAccurate() public {
    //         if (block.chainid == 11155111) {
    //             uint256 version = fundMe.getVersion();
    //             assertEq(version, 4);
    //         } else if (block.chainid == 1) {
    //             uint256 version = fundMe.getVersion();
    //             assertEq(version, 6);
    //         }
    //   }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.withdraw(); // <- We try to withdraw as USER
    }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();

        vm.stopPrank();

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    // function testWithdrawWithMultipleFunders() public funded {
    //     address[] memory funders = new address[](3);
    //     funders[0] = USER;
    //     funders[1] = makeAddr("funder1");
    //     funders[2] = makeAddr("funder2");

    //     for (uint256 i = 0; i < funders.length; i++) {
    //         vm.deal(funders[i], STARTING_BALANCE);
    //         vm.prank(funders[i]);
    //         fundMe.fund{value: SEND_VALUE}();
    //     }

    //     uint256 initialBalance = address(fundMe).balance;
    //     uint256 expectedBalanceAfterWithdraw = initialBalance -
    //         (SEND_VALUE * funders.length);

    //     vm.prank(fundMe.getOwner());
    //     fundMe.withdraw();

    //     assertEq(address(fundMe).balance, 0);

    //     for (uint256 i = 0; i < funders.length; i++) {
    //         assertEq(fundMe.getAddressToAmountFunded(funders[i]), 0);
    //     }
    // }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }
}

// forge test --match-test testFunctionName (For running specific test function)
// forge test --match-contract FundMeTest (For running all tests in this contract)
// forge test --match-path test/MyTest.t.sol --match-test testFunctionName (For running specific test function in a specific file)
