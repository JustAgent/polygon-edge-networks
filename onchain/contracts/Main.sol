// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BaseToken.sol";

contract Main is Ownable {

    struct Order {
        // uint256 orderId;
        address seller;
        address buyer;
        address provider;
        uint256 energyAmount;
        uint256 pricePerUnit;
        uint256 totalPrice;
        uint256 deliveryDate;
        Status status;
        Signs startSigns;
        Signs fulfillmentSigns;
    }
    struct Signs {
        bool buyerSign;
        bool sellerSign;
    }
    enum Status {
        Fulfilled, // Order completed
        InProcess, // Order submitted and currently in work
        OnVerification, // Waiting for signs
        Declined, // Someone declined
        Prepayment // Waiting for prepayment
    }

    mapping(uint256 => Order) public orders;
    mapping(address => bool) public providers;
    mapping(address => address) public customerToBaseTokenAddress;
    mapping(address => bool) public verifiedBaseToken;
    uint totalOrders;

    modifier isActiveAndExists(uint _orderId) {
        require(orders[_orderId].status != Status.Declined, "Order declined");
        require(orders[_orderId].status != Status.Fulfilled, "Order declined");
        require(_orderId <= totalOrders, "Doesn't exist");
        _;
    }

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
            Status.OnVerification,
            Signs(false, false),
            Signs(false, false)
        );
        totalOrders += 1;
        // event
    }

    function signOrder(
        uint _orderId,
        uint8 side
    ) external isActiveAndExists(_orderId) {
        require(_orderId <= totalOrders, "Invalid order ID"); //modifier
        require(orders[_orderId].status == Status.OnVerification);
        require(side == 0 || side == 1, "Select a correct side");
        Order storage order = orders[_orderId]; //debug

        if (side == 0) {
            require(
                order.buyer == msg.sender,
                "Only the buyer can sign this order"
            );
            order.startSigns.buyerSign = true;
        }
        if (side == 1) {
            require(
                order.seller == msg.sender,
                "Only the seller can sign this order"
            );
            order.startSigns.sellerSign = true;
        }
        if (
            order.startSigns.sellerSign == true &&
            order.startSigns.buyerSign == true
        ) {
            order.status = Status.Prepayment;
            // event
        }
    }

    function declineOrder(uint _orderId) public isActiveAndExists(_orderId) {
        require(
            orders[_orderId].status != Status.InProcess,
            "Order is in progress"
        );
        require(
            msg.sender == orders[_orderId].buyer ||
                msg.sender == orders[_orderId].seller ||
                msg.sender == orders[_orderId].provider,
            "You are not the order participiant"
        );
        orders[_orderId].status = Status.Declined;

        // event
    }

    function payOrder(uint _orderId) external isActiveAndExists(_orderId) {
        require(orders[_orderId].buyer == msg.sender, "You are not the buyer");
        Order storage order = orders[_orderId]; //debug
        BaseToken token = BaseToken(customerToBaseTokenAddress[msg.sender]);
        require(token.owner() == msg.sender, "Not the contract owner"); // change?

        uint balanceBefore = token.balanceOf(order.provider);
        require(
            token.transferFrom(msg.sender, order.provider, order.totalPrice),
            "Payment failed"
        );
        uint balanceAfter = token.balanceOf(order.provider);

        require(
            balanceAfter == balanceBefore + order.totalPrice,
            "Something went wrong"
        );
        order.status = Status.InProcess;
        // event
    }

    function fulfillOrder(uint _orderId) public isActiveAndExists(_orderId) {
        require(
            msg.sender == orders[_orderId].buyer ||
                msg.sender == orders[_orderId].seller,
            "You are not the order participiant"
        );
        require(
            orders[_orderId].status == Status.InProcess,
            "Not even in process"
        );
        if (msg.sender == orders[_orderId].buyer) {
            orders[_orderId].fulfillmentSigns.buyerSign = true;
        }
        if (msg.sender == orders[_orderId].seller) {
            orders[_orderId].fulfillmentSigns.sellerSign = true;
        }
        if (
            orders[_orderId].fulfillmentSigns.sellerSign == true &&
            orders[_orderId].fulfillmentSigns.buyerSign == true
        ) {
            orders[_orderId].status = Status.Fulfilled;
        }
        //event
    }

    function verifyBaseToken(address _tokenAddress) external onlyOwner {
        verifiedBaseToken[_tokenAddress] = true;
    }

    function deleteBaseToken(address _tokenAddress) external onlyOwner {
        verifiedBaseToken[_tokenAddress] = false;
    }

    function setBaseToken(address _tokenAddress) external {
        require(verifiedBaseToken[_tokenAddress] == true, "Unverified token");
        uint len;
        assembly {
            len := extcodesize(_tokenAddress)
        }
        // Check that it's contract
        require(len != 0);
        customerToBaseTokenAddress[msg.sender] = _tokenAddress;
    }

    function getOrder(uint _orderId) public view returns (Order memory) {
        require(_orderId <= totalOrders, "Doesn't exist");
        return orders[_orderId];
    }
}

// Add func that provider can't spend tokens