//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
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
}

// forge test --match-test testFunctionName (For running specific test function)
// forge test --match-contract FundMeTest (For running all tests in this contract)
// forge test --match-path test/MyTest.t.sol --match-test testFunctionName (For running specific test function in a specific file)
