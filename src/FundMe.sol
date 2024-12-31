// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] private s_funders;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    mapping(address => uint256) private s_addressToAmountFunded;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "must be ower");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didnt send enough eth"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint i = 0; i < fundersLength; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "call reverted");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /**
     * View / Pure Functions (Getters)
     */
    function getAdressToFundedAmount(
        address _address
    ) external view returns (uint256) {
        return s_addressToAmountFunded[_address];
    }

    function getFunders(uint256 _index) external view returns (address) {
        return s_funders[_index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * FallBack and Receive Functions
     */

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
