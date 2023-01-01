// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Main {
    struct Order {
        // uint256 orderId;
        address seller;
        address buyer;
        uint256 energyAmount;
        uint256 pricePerUnit;
        uint256 totalPrice;
        uint256 deliveryDate;
        Status fullfilmentStatus;
    }

    enum Status {
        Fulfilled,
        InProcess,
        OnVerification,
        Declined
    }

    mapping(uint256 => Order) public orders;
    mapping(address => bool) public intermediaries;
    uint totalOrders;

    function createOrder(
        address _seller,
        address _buyer,
        uint _energyAmount,
        uint _pricePerUnit,
        uint _deliveryDate
    ) external {
        uint orderId = totalOrders + 1;
        uint totalPrice = _energyAmount * _pricePerUnit;
        orders[orderId] = Order(
            _seller,
            _buyer,
            _energyAmount,
            _pricePerUnit,
            totalPrice,
            _deliveryDate,
            Status.OnVerification
        );
    }
}
