//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract TransportAndGoodsRegistry {
    uint256 public registrationIdCounter; // Counter for registration IDs

    enum GoodsStatus { NotPicked, Picked, OnTheWay, ReachedToLocation, Received }

    struct Vehicle {
        string registrationNumber;
        string vehicleType;
        uint256 volumeInTons;
        address owner;
    }

    struct Goods {
        string loadType;
        uint256 volume;
        uint256 amountForTransporter; // Amount to give to transporter for transferring
        string fromLocation; // From location
        string toLocation; // To location
        GoodsStatus status;
    }

    struct Agreement {
        uint256 loadId;
        address transporter; 
        address goodsOwner;
        address receiver; //  receiver address
        uint256 transportationFee;
        bool isAgreementAccepted;
        bool isReceived; // flag to track if goods are received
    }

    mapping(uint256 => Vehicle) public vehicles;
    mapping(uint256 => Goods) public goodsRegistry;
    Agreement[] public agreements;
    mapping(uint256 => GoodsStatus) public goodsTracking; // Mapping to track goods status

    // Events
    event GoodsStatusUpdated(uint256 indexed loadId, GoodsStatus newStatus);
    event AgreementAccepted(uint256 indexed agreementIndex, address indexed transporter);

    constructor() {
        registrationIdCounter = 1; // Initialize counter to start from 1
    }

    function registerVehicle(
        string memory registrationNumber,
        string memory vehicleType,
        uint256 volumeInTons,
        address owner
    ) public {
        uint256 registrationId = registrationIdCounter++; // Assign current counter value and then increment
        vehicles[registrationId] = Vehicle(registrationNumber, vehicleType, volumeInTons, owner);
    }

    // Function to register goods
    function registerGoods(
        uint256 loadId,
        string memory loadType,
        uint256 volume,
        uint256 amountForTransporter,
        string memory fromLocation,
        string memory toLocation
    ) public {
        Goods memory newGoods = Goods(loadType, volume, amountForTransporter, fromLocation, toLocation, GoodsStatus.NotPicked);
        goodsRegistry[loadId] = newGoods;
    }

    // Function to update goods status
    function updateGoodsStatus(uint256 loadId, GoodsStatus newStatus) public {
        require(newStatus == GoodsStatus.Picked || newStatus == GoodsStatus.NotPicked || newStatus == GoodsStatus.OnTheWay || newStatus == GoodsStatus.ReachedToLocation || newStatus == GoodsStatus.Received, "Invalid status");
        require(msg.sender == agreements[loadId].transporter, "Only transporter can update status");
        goodsRegistry[loadId].status = newStatus;
        goodsTracking[loadId] = newStatus; // Update goods tracking
        emit GoodsStatusUpdated(loadId, newStatus);
    }

    // Function to create an agreement
    function createAgreement(
        uint256 loadId,
        address transporter,
        address receiver, // Added receiver parameter
        uint256 transportationFee
    ) public payable {
        Agreement memory newAgreement = Agreement({
            loadId: loadId,
            transporter: transporter,
            goodsOwner: msg.sender,
            receiver: receiver, // Set receiver
            transportationFee: transportationFee,
            isAgreementAccepted: false,
            isReceived: false
        });
        agreements.push(newAgreement);
        
        // Transfer the transportation fee to the contract
        require(msg.value >= transportationFee, "Insufficient funds");
        emit AgreementAccepted(agreements.length - 1, transporter);
    }

    // Function to accept an agreement
    function acceptAgreement(uint256 agreementIndex) public {
        require(agreementIndex < agreements.length, "Invalid agreement index");
        require(agreements[agreementIndex].transporter == msg.sender, "Only transporter can accept the agreement");
        agreements[agreementIndex].isAgreementAccepted = true;
        emit AgreementAccepted(agreementIndex, msg.sender);
    }

    // Function for receiver to update goods status to "Received"
    function receiveLoad(uint256 loadId) public {
        require(goodsTracking[loadId] == GoodsStatus.ReachedToLocation, "Goods not yet reached to location");
        require(msg.sender == agreements[loadId].receiver, "Only receiver can call this function");
        agreements[loadId].isReceived = true;
        
        // Transfer the transportation fee to the transporter once goods are received
        payable(agreements[loadId].transporter).transfer(agreements[loadId].transportationFee);
    }

    // Function to getVehicle info :
    function getVehicle(uint256 registrationId) public view returns (string memory, string memory, uint256, address) {
        Vehicle memory vehicle = vehicles[registrationId];
        return (vehicle.registrationNumber, vehicle.vehicleType, vehicle.volumeInTons, vehicle.owner);
    }

    // Function to get goods status based on load ID
    function getGoodsStatus(uint256 loadId) public view returns (GoodsStatus) {
        return goodsRegistry[loadId].status;
    }
}
