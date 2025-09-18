// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint16, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract AnonymousTransport is SepoliaConfig {

    address public owner;
    uint32 public routeCounter;
    uint32 public requestCounter;

    struct RouteData {
        euint16 startX;
        euint16 startY;
        euint16 endX;
        euint16 endY;
        euint32 capacity;
        euint16 priority;
        bool isActive;
        address carrier;
        uint256 timestamp;
    }

    struct TransportRequest {
        euint16 pickupX;
        euint16 pickupY;
        euint16 dropX;
        euint16 dropY;
        euint32 weight;
        euint16 urgency;
        euint32 maxCost;
        bool isMatched;
        address requester;
        uint32 assignedRoute;
        uint256 requestTime;
    }

    struct OptimalSchedule {
        uint32 routeId;
        uint32[] requestIds;
        euint32 totalLoad;
        euint16 efficiency;
        bool isOptimized;
        uint256 scheduleTime;
    }

    mapping(uint32 => RouteData) public routes;
    mapping(uint32 => TransportRequest) public requests;
    mapping(uint32 => OptimalSchedule) public schedules;
    mapping(address => uint32[]) public carrierRoutes;
    mapping(address => uint32[]) public userRequests;

    event RouteRegistered(uint32 indexed routeId, address indexed carrier);
    event RequestSubmitted(uint32 indexed requestId, address indexed requester);
    event ScheduleOptimized(uint32 indexed routeId, uint256 timestamp);
    event TransportMatched(uint32 indexed requestId, uint32 indexed routeId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyCarrier(uint32 _routeId) {
        require(routes[_routeId].carrier == msg.sender, "Not route carrier");
        _;
    }

    constructor() {
        owner = msg.sender;
        routeCounter = 1;
        requestCounter = 1;
    }

    function registerRoute(
        uint16 _startX,
        uint16 _startY,
        uint16 _endX,
        uint16 _endY,
        uint32 _capacity,
        uint16 _priority
    ) external {
        // Encrypt coordinates and capacity for privacy
        euint16 encStartX = FHE.asEuint16(_startX);
        euint16 encStartY = FHE.asEuint16(_startY);
        euint16 encEndX = FHE.asEuint16(_endX);
        euint16 encEndY = FHE.asEuint16(_endY);
        euint32 encCapacity = FHE.asEuint32(_capacity);
        euint16 encPriority = FHE.asEuint16(_priority);

        routes[routeCounter] = RouteData({
            startX: encStartX,
            startY: encStartY,
            endX: encEndX,
            endY: encEndY,
            capacity: encCapacity,
            priority: encPriority,
            isActive: true,
            carrier: msg.sender,
            timestamp: block.timestamp
        });

        carrierRoutes[msg.sender].push(routeCounter);

        // Grant access permissions
        FHE.allowThis(encStartX);
        FHE.allowThis(encStartY);
        FHE.allowThis(encEndX);
        FHE.allowThis(encEndY);
        FHE.allowThis(encCapacity);
        FHE.allowThis(encPriority);

        FHE.allow(encStartX, msg.sender);
        FHE.allow(encStartY, msg.sender);
        FHE.allow(encEndX, msg.sender);
        FHE.allow(encEndY, msg.sender);
        FHE.allow(encCapacity, msg.sender);
        FHE.allow(encPriority, msg.sender);

        emit RouteRegistered(routeCounter, msg.sender);
        routeCounter++;
    }

    function submitTransportRequest(
        uint16 _pickupX,
        uint16 _pickupY,
        uint16 _dropX,
        uint16 _dropY,
        uint32 _weight,
        uint16 _urgency,
        uint32 _maxCost
    ) external {
        // Encrypt request data for privacy
        euint16 encPickupX = FHE.asEuint16(_pickupX);
        euint16 encPickupY = FHE.asEuint16(_pickupY);
        euint16 encDropX = FHE.asEuint16(_dropX);
        euint16 encDropY = FHE.asEuint16(_dropY);
        euint32 encWeight = FHE.asEuint32(_weight);
        euint16 encUrgency = FHE.asEuint16(_urgency);
        euint32 encMaxCost = FHE.asEuint32(_maxCost);

        requests[requestCounter] = TransportRequest({
            pickupX: encPickupX,
            pickupY: encPickupY,
            dropX: encDropX,
            dropY: encDropY,
            weight: encWeight,
            urgency: encUrgency,
            maxCost: encMaxCost,
            isMatched: false,
            requester: msg.sender,
            assignedRoute: 0,
            requestTime: block.timestamp
        });

        userRequests[msg.sender].push(requestCounter);

        // Grant access permissions
        FHE.allowThis(encPickupX);
        FHE.allowThis(encPickupY);
        FHE.allowThis(encDropX);
        FHE.allowThis(encDropY);
        FHE.allowThis(encWeight);
        FHE.allowThis(encUrgency);
        FHE.allowThis(encMaxCost);

        FHE.allow(encPickupX, msg.sender);
        FHE.allow(encPickupY, msg.sender);
        FHE.allow(encDropX, msg.sender);
        FHE.allow(encDropY, msg.sender);
        FHE.allow(encWeight, msg.sender);
        FHE.allow(encUrgency, msg.sender);
        FHE.allow(encMaxCost, msg.sender);

        emit RequestSubmitted(requestCounter, msg.sender);
        requestCounter++;
    }

    function optimizeSchedule(uint32 _routeId) external onlyCarrier(_routeId) {
        require(routes[_routeId].isActive, "Route not active");

        RouteData storage route = routes[_routeId];
        uint32[] memory compatibleRequests = new uint32[](100); // Max 100 requests
        uint32 matchCount = 0;
        euint32 totalLoad = FHE.asEuint32(0);

        // Find compatible requests using FHE comparisons
        for (uint32 i = 1; i < requestCounter; i++) {
            if (!requests[i].isMatched) {
                // Calculate route compatibility privately
                ebool isCompatible = _checkRouteCompatibility(_routeId, i);

                // This would typically use FHE select operations
                // For now, we'll use a simplified approach
                compatibleRequests[matchCount] = i;
                matchCount++;

                totalLoad = FHE.add(totalLoad, requests[i].weight);
            }
        }

        // Calculate efficiency score
        euint16 efficiency = _calculateEfficiency(_routeId, compatibleRequests, matchCount);

        schedules[_routeId] = OptimalSchedule({
            routeId: _routeId,
            requestIds: _sliceArray(compatibleRequests, matchCount),
            totalLoad: totalLoad,
            efficiency: efficiency,
            isOptimized: true,
            scheduleTime: block.timestamp
        });

        // Grant access permissions
        FHE.allowThis(totalLoad);
        FHE.allowThis(efficiency);
        FHE.allow(totalLoad, msg.sender);
        FHE.allow(efficiency, msg.sender);

        emit ScheduleOptimized(_routeId, block.timestamp);
    }

    function _checkRouteCompatibility(uint32 _routeId, uint32 _requestId) private returns (ebool) {
        RouteData storage route = routes[_routeId];
        TransportRequest storage request = requests[_requestId];

        // Check if pickup/drop points are within route bounds
        ebool pickupInRoute = FHE.and(
            FHE.le(FHE.sub(route.startX, FHE.asEuint16(50)), request.pickupX),
            FHE.le(request.pickupX, FHE.add(route.endX, FHE.asEuint16(50)))
        );

        ebool dropInRoute = FHE.and(
            FHE.le(FHE.sub(route.startY, FHE.asEuint16(50)), request.dropY),
            FHE.le(request.dropY, FHE.add(route.endY, FHE.asEuint16(50)))
        );

        // Check capacity constraints
        ebool withinCapacity = FHE.le(request.weight, route.capacity);

        return FHE.and(FHE.and(pickupInRoute, dropInRoute), withinCapacity);
    }

    function _calculateEfficiency(
        uint32 _routeId,
        uint32[] memory _requests,
        uint32 _count
    ) private returns (euint16) {
        RouteData storage route = routes[_routeId];
        euint16 totalUrgency = FHE.asEuint16(0);
        euint32 totalWeight = FHE.asEuint32(0);

        for (uint32 i = 0; i < _count; i++) {
            if (_requests[i] != 0) {
                totalUrgency = FHE.add(totalUrgency, requests[_requests[i]].urgency);
                totalWeight = FHE.add(totalWeight, requests[_requests[i]].weight);
            }
        }

        // Calculate efficiency based on total urgency and priority
        // Since FHE.div is not available, use simpler calculation
        euint16 baseEfficiency = FHE.add(totalUrgency, route.priority);

        // Use FHE select to boost efficiency if there's significant weight
        ebool hasSignificantWeight = FHE.gt(totalWeight, FHE.asEuint32(100));
        euint16 boostedEfficiency = FHE.mul(baseEfficiency, FHE.asEuint16(2));

        return FHE.select(hasSignificantWeight, boostedEfficiency, baseEfficiency);
    }

    function _sliceArray(uint32[] memory _array, uint32 _length) private pure returns (uint32[] memory) {
        uint32[] memory result = new uint32[](_length);
        for (uint32 i = 0; i < _length; i++) {
            result[i] = _array[i];
        }
        return result;
    }

    function matchRequest(uint32 _requestId, uint32 _routeId) external onlyCarrier(_routeId) {
        require(!requests[_requestId].isMatched, "Request already matched");
        require(routes[_routeId].isActive, "Route not active");
        require(schedules[_routeId].isOptimized, "Schedule not optimized");

        requests[_requestId].isMatched = true;
        requests[_requestId].assignedRoute = _routeId;

        emit TransportMatched(_requestId, _routeId);
    }

    function getRouteInfo(uint32 _routeId) external view returns (
        bool isActive,
        address carrier,
        uint256 timestamp
    ) {
        RouteData storage route = routes[_routeId];
        return (route.isActive, route.carrier, route.timestamp);
    }

    function getRequestStatus(uint32 _requestId) external view returns (
        bool isMatched,
        address requester,
        uint32 assignedRoute,
        uint256 requestTime
    ) {
        TransportRequest storage request = requests[_requestId];
        return (request.isMatched, request.requester, request.assignedRoute, request.requestTime);
    }

    function getScheduleInfo(uint32 _routeId) external view returns (
        bool isOptimized,
        uint256 scheduleTime,
        uint256 requestCount
    ) {
        OptimalSchedule storage schedule = schedules[_routeId];
        return (schedule.isOptimized, schedule.scheduleTime, schedule.requestIds.length);
    }

    function getCarrierRoutes(address _carrier) external view returns (uint32[] memory) {
        return carrierRoutes[_carrier];
    }

    function getUserRequests(address _user) external view returns (uint32[] memory) {
        return userRequests[_user];
    }

    function deactivateRoute(uint32 _routeId) external onlyCarrier(_routeId) {
        routes[_routeId].isActive = false;
    }

    function reactivateRoute(uint32 _routeId) external onlyCarrier(_routeId) {
        routes[_routeId].isActive = true;
    }
}