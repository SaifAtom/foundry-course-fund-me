// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
pragma solidity 0.8.19;

contract DeployFundMe is Script {
    function run() public returns (FundMe) {
        HelperConfig helpherConfig = new HelperConfig();
        vm.startBroadcast();
        FundMe fundMe = new FundMe(helpherConfig.activeNetworkConfig());
        vm.stopBroadcast();
        return fundMe;
    }
}
