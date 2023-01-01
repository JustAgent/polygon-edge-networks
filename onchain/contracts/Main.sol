// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Main is ERC20, Ownable {

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    struct Order {
        // uint256 orderId;
        address seller;
        address buyer;
        address provider;
        uint256 energyAmount;
        uint256 pricePerUnit;
        uint256 totalPrice;
        uint256 deliveryDate;
        bool buyerSign;
        bool sellerSign;
        Status status;
    }

    enum Status {
        Fulfilled, // Order completed
        InProcess,  // Order submitted and currently in work
        OnVerification, // Waiting for signs
        Declined, // Someone declined
        Prepayment // Waiting for prepayment
    }

    mapping(uint256 => Order) public orders;
    mapping(address => bool) public providers;

    uint totalOrders;

    function createOrder(
        address _seller,
        address _buyer,
        uint _energyAmount,
        uint _pricePerUnit,
        uint _deliveryDate
    ) external {
        require(providers[msg.sender] == true, "Only for providers");
        uint orderId = totalOrders + 1;
        uint totalPrice = _energyAmount * _pricePerUnit;
        orders[orderId] = Order(
            _seller,
            _buyer,
            msg.sender,
            _energyAmount,
            _pricePerUnit,
            totalPrice,
            _deliveryDate,
            false,
            false,
            Status.OnVerification
        );
    }

    function signOrder(uint orderId, uint8 side) external returns(bool) {
        require(orderId <= totalOrders,"Invalid order ID");
        require(side == 0 || side == 1, "Select a correct side");
        Order storage order = orders[orderId]; //debug

        if (side == 0) {
            require(order.buyer == msg.sender,"Only the buyer can sign this order");
            order.buyerSign = true;
            if (order.sellerSign == true) {
                order.status = Status.Prepayment;
            }
            return true;
        }
        if (side == 1) {
            require(order.seller == msg.sender,"Only the seller can sign this order");
            order.sellerSign = true;
            if (order.buyerSign == true) {
                order.status = Status.Prepayment;
            }
            return true;
        }
        return false;
    } 

    function getOrder(uint orderId) public view returns (Order memory) {
        return orders[orderId];
    }


}
