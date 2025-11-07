// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/*
    CarRental Smart Contract
    --------------------------------
    This smart contract allows a car owner to rent out their car to users.
    It includes modifiers, events, and ownership transfer functionality.
*/

contract CarRental {
    // -------------------------------
    // State Variables
    // -------------------------------
    address payable public owner;       // Contract owner (car owner)
    bool public available;              // Car availability status
    uint public ratePerDay;             // Rental rate in wei per day
    address public currentRenter;       // Address of the current renter
    uint public rentalEndTime;          // Time when rental ends

    // -------------------------------
    // Events
    // -------------------------------
    event CarRented(address indexed renter, uint daysRented, uint amountPaid);
    event CarReturned(address indexed renter);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // -------------------------------
    // Constructor
    // -------------------------------
    constructor(uint _ratePerDay) {
        owner = payable(msg.sender);
        available = true;
        ratePerDay = _ratePerDay;
    }

    // -------------------------------
    // Modifiers
    // -------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the car owner can perform this action.");
        _;
    }

    modifier onlyRenter() {
        require(msg.sender == currentRenter, "Only the current renter can perform this action.");
        _;
    }

    // -------------------------------
    // Public Functions
    // -------------------------------

    // Function to rent the car
    function rentCar(uint numDays) public payable {
        require(available, "Car is not available for rent.");
        uint totalCost = ratePerDay * numDays;
        require(msg.value >= totalCost, "Insufficient Ether sent.");

        currentRenter = msg.sender;
        rentalEndTime = block.timestamp + (numDays * 1 days);
        available = false;

        // Transfer payment to owner
        (bool sent, ) = owner.call{value: msg.value}("");
        require(sent, "Failed to transfer payment to owner.");

        emit CarRented(msg.sender, numDays, msg.value);
    }

    // Function for renter to return the car (after rental period)
    function returnCar() public onlyRenter {
        require(block.timestamp >= rentalEndTime, "Rental period has not ended yet.");
        available = true;
        currentRenter = address(0);
        rentalEndTime = 0;

        emit CarReturned(msg.sender);
    }

    // Owner can update the rental rate
    function updateRate(uint newRate) public onlyOwner {
        ratePerDay = newRate;
    }

    // Transfer ownership of the smart contract
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Check remaining rental time
    function timeLeft() public view returns (uint) {
        if (block.timestamp >= rentalEndTime) {
            return 0;
        } else {
            return rentalEndTime - block.timestamp;
        }
    }
}
