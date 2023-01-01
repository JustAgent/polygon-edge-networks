// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BaseToken.sol";

contract Main is Ownable {
    struct Order {
        // The seller address is the address of the seller of the energy
        address seller;
        // The buyer address is the address of the buyer of the energy
        address buyer;
        // The provider address is the address of the provider of the energy
        address provider;
        // The energyAmount represents the amount of energy being sold
        uint256 energyAmount;
        // The pricePerUnit represents the price per unit of energy
        uint256 pricePerUnit;
        // The totalPrice represents the total price of the order (energyAmount * pricePerUnit)
        uint256 totalPrice;
        // The deliveryDate represents the date when the energy will be delivered
        uint256 deliveryDate;
        // The status of the order
        Status status;
        // The startSigns represent the signatures of the seller and buyer for the start of the order
        Signs startSigns;
        // The fulfillmentSigns represent the signatures of the seller and buyer for the completion of the order
        Signs fulfillmentSigns;
    }

    // The Signs struct represents the signatures of the seller and buyer for either the start or completion of the order
    struct Signs {
        // The buyerSign represents the signature of the buyer
        bool buyerSign;
        // The sellerSign represents the signature of the seller
        bool sellerSign;
    }

    // The Status enum represents the status of the order
    enum Status {
        // The order has been completed
        Fulfilled,
        // The order has been submitted and is currently in progress
        InProcess,
        // The order is waiting for signatures
        OnVerification,
        // The order has been declined
        Declined,
        // The order is waiting for prepayment
        Prepayment
    }

    // The orders mapping maps an order ID to an Order struct
    mapping(uint256 => Order) public orders;
    // The providers mapping maps an address to a bool indicating if the address is a provider
    mapping(address => bool) public providers;
    // The customerToBaseTokenAddress mapping maps an address to the address of the BaseToken contract for that address
    mapping(address => address) public customerToBaseTokenAddress;
    // The verifiedBaseToken mapping maps an address to a bool indicating if the address has been verified as a BaseToken contract
    mapping(address => bool) public verifiedBaseToken;
    // The totalOrders variable represents the total number of orders that have been created
    uint totalOrders;

    // The isActiveAndExists modifier checks if the order exists and is active (not declined or fulfilled)
    modifier isActiveAndExists(uint _orderId) {
        require(_orderId <= totalOrders, "Doesn't exist");
        require(orders[_orderId].status != Status.Declined, "Order declined");
        require(orders[_orderId].status != Status.Fulfilled, "Order fulfilled");
        _;
    }

    // The createOrder function allows a provider to create a new energy order
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
        // Create a new order with the provided parameters and set the initial status to OnVerification
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

    // The signOrder function allows the seller and buyer to sign the order
    function signOrder(
        uint _orderId,
        uint8 side
    ) external isActiveAndExists(_orderId) {
        // Check if the order ID is valid
        require(_orderId <= totalOrders, "Invalid order Id");
        // Check if the order is currently waiting for signatures
        require(orders[_orderId].status == Status.OnVerification);
        // Check if the side parameter is valid
        require(side == 0 || side == 1, "Select a correct side");
        // Get the order from storage
        Order storage order = orders[_orderId];

        // If the side is 0, the buyer is signing the order
        if (side == 0) {
            // Check if the msg.sender is the buyer of the order
            require(
                order.buyer == msg.sender,
                "Only the buyer can sign this order"
            );
            // Set the buyerSign variable to true
            order.startSigns.buyerSign = true;
        }
        // If the side is 1,the seller is signing the order
        if (side == 1) {
            // Check if the msg.sender is the seller of the order
            require(
                order.seller == msg.sender,
                "Only the seller can sign this order"
            );
            // Set the sellerSign variable to true
            order.startSigns.sellerSign = true;
        }
        // If both the seller and buyer have signed the order, set the status to Prepayment
        if (
            order.startSigns.sellerSign == true &&
            order.startSigns.buyerSign == true
        ) {
            order.status = Status.Prepayment;
            // event
        }
    }

    // The declineOrder function allows the seller, buyer, or provider to decline the order
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
    
    // The payOrder function allows the buyer to pay for the order
    function payOrder(uint _orderId) external isActiveAndExists(_orderId) {
        require(orders[_orderId].buyer == msg.sender, "You are not the buyer");
        Order storage order = orders[_orderId];
        require(order.status == Status.Prepayment, "Wrong status");

        BaseToken token = BaseToken(customerToBaseTokenAddress[msg.sender]);
        require(token.owner() == msg.sender, "Not the contract owner"); // change?
        // Transfer the total price of the order from the buyer's BaseToken contract to the seller's BaseToken contract
        require(token.balanceOf(msg.sender) >= order.totalPrice, "Not enough balance");

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

    // The fulfillOrder function allows the seller or the provider to mark an order as complete 
    // and transfer the payment to the seller. 
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
            BaseToken token = BaseToken(customerToBaseTokenAddress[orders[_orderId].buyer]);
            token.transferFrom(orders[_orderId].provider, orders[_orderId].seller, orders[_orderId].totalPrice);
            orders[_orderId].status = Status.Fulfilled;
        }
        //event
    }

    // Verify that customer's token fits all requirements
    function verifyBaseToken(address _tokenAddress) external onlyOwner {
        require(!verifiedBaseToken[_tokenAddress]);
        uint len;
        assembly {
            len := extcodesize(_tokenAddress)
        }
        // Check that it's contract
        require(len != 0);
        verifiedBaseToken[_tokenAddress] = true;
    }

    function deleteBaseToken(address _tokenAddress) external onlyOwner {
        require(verifiedBaseToken[_tokenAddress]);
        verifiedBaseToken[_tokenAddress] = false;
    }

    // Add provider that can manage orders
    function addProvider(address _provider) public onlyOwner {
        require(!providers[_provider], "Already a provider");
        providers[_provider] = true;
    }

    // Delete provider 
    function deleteProvider(address _provider) public onlyOwner {
        require(providers[_provider], "Not a provider");
        providers[_provider] = false;
    }

    // Customer can set the base token with which he will pay
    function setBaseToken(address _tokenAddress) external {
        require(verifiedBaseToken[_tokenAddress] == true, "Unverified token");
        uint len;
        assembly {
            len := extcodesize(_tokenAddress)
        }
        // Check that it's contract
        require(len != 0, "Not a base token contract");
        customerToBaseTokenAddress[msg.sender] = _tokenAddress;
    }

    function getOrder(uint _orderId) public view returns (Order memory) {
        require(_orderId <= totalOrders, "Doesn't exist");
        return orders[_orderId];
    }
}

// Add func that provider can't spend tokens
