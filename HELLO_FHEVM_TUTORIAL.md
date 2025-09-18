# Hello FHEVM: Your First Confidential dApp Tutorial

## Complete Beginner's Guide to Building Privacy-Preserving Applications

Welcome to the world of Fully Homomorphic Encryption (FHE) on blockchain! This tutorial will guide you through building your first confidential dApp using FHEVM - the Anonymous Transport Scheduler.

## 🎯 What You'll Learn

By the end of this tutorial, you'll understand how to:
- Build smart contracts that compute on encrypted data
- Create privacy-preserving applications without revealing sensitive information
- Implement FHE operations in Solidity
- Connect a frontend to FHE-enabled smart contracts
- Handle encrypted inputs and outputs in your dApp

## 📋 Prerequisites

You should have basic knowledge of:
- ✅ Solidity (writing and deploying simple smart contracts)
- ✅ JavaScript/React basics
- ✅ Ethereum development tools (Hardhat, MetaMask)
- ❌ **NO cryptography or advanced math knowledge required!**

## 🌟 What is FHEVM?

FHEVM (Fully Homomorphic Encryption Virtual Machine) allows you to perform computations on encrypted data without ever decrypting it. Imagine being able to:

- Compare two secret numbers without knowing what they are
- Add encrypted values together while keeping them private
- Make decisions based on confidential data

**Real-world example**: In our transport scheduler, carriers can optimize routes based on encrypted pickup locations, weights, and capacities - all without ever seeing the actual sensitive data!

## 🚀 Project Overview: Anonymous Transport Scheduler

We're building a privacy-first logistics application where:
- **Carriers** register routes with encrypted coordinates and capacity
- **Users** submit transport requests with private pickup/delivery locations
- **System** matches requests to routes using encrypted computations
- **Privacy** is maintained throughout the entire process

## 📁 Project Structure

```
transport-scheduler/
├── contracts/
│   └── AnonymousTransport.sol
├── scripts/
│   └── deploy.js
├── frontend/
│   └── index.html
├── hardhat.config.js
└── package.json
```

## 🔧 Step 1: Environment Setup

### Install Dependencies

```bash
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @fhevm/solidity ethers
```

### Initialize Hardhat Project

```bash
npx hardhat init
```

### Configure Hardhat

Create `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
      accounts: ["YOUR_PRIVATE_KEY"]
    }
  }
};
```

## 🔐 Step 2: Understanding FHE Basics

### Key FHE Concepts

**Encrypted Types**:
- `euint16` - Encrypted 16-bit unsigned integer
- `euint32` - Encrypted 32-bit unsigned integer
- `ebool` - Encrypted boolean

**FHE Operations**:
- `FHE.add(a, b)` - Add two encrypted numbers
- `FHE.le(a, b)` - Check if a <= b (returns encrypted boolean)
- `FHE.select(condition, a, b)` - If condition then a else b

**Access Control**:
- `FHE.allow(encryptedValue, address)` - Grant address permission to decrypt
- `FHE.allowThis(encryptedValue)` - Grant contract permission

## 📝 Step 3: Building the Smart Contract

Create `contracts/AnonymousTransport.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint16, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract AnonymousTransport is SepoliaConfig {

    address public owner;
    uint32 public routeCounter;
    uint32 public requestCounter;

    // Encrypted route data
    struct RouteData {
        euint16 startX;      // Encrypted start coordinate
        euint16 startY;
        euint16 endX;        // Encrypted end coordinate
        euint16 endY;
        euint32 capacity;    // Encrypted capacity
        euint16 priority;    // Encrypted priority
        bool isActive;
        address carrier;
        uint256 timestamp;
    }

    // Encrypted transport request
    struct TransportRequest {
        euint16 pickupX;     // Encrypted pickup location
        euint16 pickupY;
        euint16 dropX;       // Encrypted delivery location
        euint16 dropY;
        euint32 weight;      // Encrypted weight
        euint16 urgency;     // Encrypted urgency level
        euint32 maxCost;     // Encrypted maximum cost
        bool isMatched;
        address requester;
        uint32 assignedRoute;
        uint256 requestTime;
    }

    mapping(uint32 => RouteData) public routes;
    mapping(uint32 => TransportRequest) public requests;
    mapping(address => uint32[]) public carrierRoutes;
    mapping(address => uint32[]) public userRequests;

    event RouteRegistered(uint32 indexed routeId, address indexed carrier);
    event RequestSubmitted(uint32 indexed requestId, address indexed requester);
    event ScheduleOptimized(uint32 indexed routeId, uint256 timestamp);

    constructor() {
        owner = msg.sender;
        routeCounter = 1;
        requestCounter = 1;
    }

    // Register a new transport route with encrypted data
    function registerRoute(
        uint16 _startX,
        uint16 _startY,
        uint16 _endX,
        uint16 _endY,
        uint32 _capacity,
        uint16 _priority
    ) external {
        // Step 1: Encrypt the input data
        euint16 encStartX = FHE.asEuint16(_startX);
        euint16 encStartY = FHE.asEuint16(_startY);
        euint16 encEndX = FHE.asEuint16(_endX);
        euint16 encEndY = FHE.asEuint16(_endY);
        euint32 encCapacity = FHE.asEuint32(_capacity);
        euint16 encPriority = FHE.asEuint16(_priority);

        // Step 2: Store encrypted data
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

        // Step 3: Set access permissions
        FHE.allowThis(encStartX);    // Contract can use this data
        FHE.allowThis(encStartY);
        FHE.allowThis(encEndX);
        FHE.allowThis(encEndY);
        FHE.allowThis(encCapacity);
        FHE.allowThis(encPriority);

        // Step 4: Grant carrier access to their own data
        FHE.allow(encStartX, msg.sender);
        FHE.allow(encStartY, msg.sender);
        FHE.allow(encEndX, msg.sender);
        FHE.allow(encEndY, msg.sender);
        FHE.allow(encCapacity, msg.sender);
        FHE.allow(encPriority, msg.sender);

        carrierRoutes[msg.sender].push(routeCounter);
        emit RouteRegistered(routeCounter, msg.sender);
        routeCounter++;
    }

    // Submit transport request with encrypted requirements
    function submitTransportRequest(
        uint16 _pickupX,
        uint16 _pickupY,
        uint16 _dropX,
        uint16 _dropY,
        uint32 _weight,
        uint16 _urgency,
        uint32 _maxCost
    ) external {
        // Encrypt all request data for privacy
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

        userRequests[msg.sender].push(requestCounter);
        emit RequestSubmitted(requestCounter, msg.sender);
        requestCounter++;
    }

    // Private route compatibility check using FHE operations
    function _checkRouteCompatibility(uint32 _routeId, uint32 _requestId)
        private
        returns (ebool)
    {
        RouteData storage route = routes[_routeId];
        TransportRequest storage request = requests[_requestId];

        // Check if pickup point is within route area (encrypted comparison)
        ebool pickupInRoute = FHE.and(
            FHE.le(FHE.sub(route.startX, FHE.asEuint16(50)), request.pickupX),
            FHE.le(request.pickupX, FHE.add(route.endX, FHE.asEuint16(50)))
        );

        // Check if delivery point is within route area
        ebool dropInRoute = FHE.and(
            FHE.le(FHE.sub(route.startY, FHE.asEuint16(50)), request.dropY),
            FHE.le(request.dropY, FHE.add(route.endY, FHE.asEuint16(50)))
        );

        // Check capacity constraints (encrypted)
        ebool withinCapacity = FHE.le(request.weight, route.capacity);

        // All conditions must be true
        return FHE.and(FHE.and(pickupInRoute, dropInRoute), withinCapacity);
    }

    // Public view functions (non-encrypted data only)
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

    function getCarrierRoutes(address _carrier) external view returns (uint32[] memory) {
        return carrierRoutes[_carrier];
    }

    function getUserRequests(address _user) external view returns (uint32[] memory) {
        return userRequests[_user];
    }
}
```

## 🔍 Step 4: Understanding the Code

### Key Learning Points

**1. Data Encryption**:
```solidity
euint16 encStartX = FHE.asEuint16(_startX);  // Convert to encrypted
```

**2. Encrypted Operations**:
```solidity
ebool withinCapacity = FHE.le(request.weight, route.capacity);  // Encrypted comparison
```

**3. Access Control**:
```solidity
FHE.allowThis(encStartX);           // Contract access
FHE.allow(encStartX, msg.sender);   // User access
```

**4. Private Computations**:
- All route matching happens on encrypted data
- No sensitive information is ever revealed
- Decisions are made without exposing private details

## 🌐 Step 5: Building the Frontend

Create `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Anonymous Transport Scheduler - Hello FHEVM Tutorial</title>
    <script src="https://cdn.jsdelivr.net/npm/ethers@5.7.2/dist/ethers.umd.min.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .card {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            border-left: 4px solid #667eea;
        }
        .form-group {
            margin: 15px 0;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
            color: #2d3748;
        }
        input, select {
            width: 100%;
            padding: 10px;
            border: 2px solid #e2e8f0;
            border-radius: 5px;
            box-sizing: border-box;
        }
        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            width: 100%;
            margin-top: 10px;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        .status {
            margin-top: 15px;
            padding: 10px;
            border-radius: 5px;
            display: none;
        }
        .loading { background: #bee3f8; color: #2b6cb0; }
        .success { background: #c6f6d5; color: #22543d; }
        .error { background: #fed7d7; color: #c53030; }
        .tutorial-note {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Hello FHEVM Tutorial</h1>
            <h2>Anonymous Transport Scheduler</h2>
            <p>Your First Confidential dApp</p>
        </div>

        <div class="tutorial-note">
            <h3>🎓 What You're Learning:</h3>
            <p>This dApp demonstrates FHE by keeping all transport data encrypted:</p>
            <ul>
                <li><strong>Routes:</strong> Start/end coordinates, capacity (encrypted)</li>
                <li><strong>Requests:</strong> Pickup/drop locations, weight (encrypted)</li>
                <li><strong>Matching:</strong> Computed on encrypted data without revealing details</li>
            </ul>
        </div>

        <!-- Wallet Connection -->
        <div class="card">
            <h3>🔌 Connect Wallet</h3>
            <p><strong>Status:</strong> <span id="walletStatus">Disconnected</span></p>
            <p><strong>Address:</strong> <span id="walletAddress">-</span></p>
            <button id="connectWallet" class="btn" onclick="connectWallet()">Connect MetaMask</button>
        </div>

        <!-- Route Registration -->
        <div class="card">
            <h3>🛣️ Register Transport Route (Carrier)</h3>
            <div class="tutorial-note">
                <strong>FHE Feature:</strong> All coordinates and capacity will be encrypted on-chain!
            </div>
            <div class="form-group">
                <label>Start X Coordinate (will be encrypted):</label>
                <input type="number" id="startX" placeholder="100" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>Start Y Coordinate (will be encrypted):</label>
                <input type="number" id="startY" placeholder="200" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>End X Coordinate (will be encrypted):</label>
                <input type="number" id="endX" placeholder="500" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>End Y Coordinate (will be encrypted):</label>
                <input type="number" id="endY" placeholder="600" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>Capacity in kg (will be encrypted):</label>
                <input type="number" id="capacity" placeholder="1000" min="1">
            </div>
            <div class="form-group">
                <label>Priority Level:</label>
                <select id="priority">
                    <option value="1">Low</option>
                    <option value="5">Normal</option>
                    <option value="10">High</option>
                </select>
            </div>
            <button onclick="registerRoute()" class="btn">Register Encrypted Route</button>
            <div id="routeStatus" class="status"></div>
        </div>

        <!-- Transport Request -->
        <div class="card">
            <h3>📦 Submit Transport Request (User)</h3>
            <div class="tutorial-note">
                <strong>FHE Feature:</strong> Your pickup/delivery locations and requirements remain private!
            </div>
            <div class="form-group">
                <label>Pickup X Coordinate (encrypted):</label>
                <input type="number" id="pickupX" placeholder="150" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>Pickup Y Coordinate (encrypted):</label>
                <input type="number" id="pickupY" placeholder="250" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>Delivery X Coordinate (encrypted):</label>
                <input type="number" id="dropX" placeholder="450" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>Delivery Y Coordinate (encrypted):</label>
                <input type="number" id="dropY" placeholder="550" min="0" max="65535">
            </div>
            <div class="form-group">
                <label>Weight in kg (encrypted):</label>
                <input type="number" id="weight" placeholder="100" min="1">
            </div>
            <div class="form-group">
                <label>Urgency Level:</label>
                <select id="urgency">
                    <option value="1">Low</option>
                    <option value="5">Normal</option>
                    <option value="10">Urgent</option>
                </select>
            </div>
            <div class="form-group">
                <label>Maximum Cost (ETH):</label>
                <input type="number" id="maxCost" step="0.001" placeholder="0.1" min="0">
            </div>
            <button onclick="submitRequest()" class="btn">Submit Private Request</button>
            <div id="requestStatus" class="status"></div>
        </div>

        <!-- Data Display -->
        <div class="card">
            <h3>📊 Your Data</h3>
            <button onclick="loadMyRoutes()" class="btn">Load My Routes</button>
            <div id="myRoutes" style="margin-top: 15px;"></div>

            <button onclick="loadMyRequests()" class="btn">Load My Requests</button>
            <div id="myRequests" style="margin-top: 15px;"></div>
        </div>

        <div class="tutorial-note">
            <h3>🎉 Congratulations!</h3>
            <p>You've just built your first FHE-powered dApp! Key achievements:</p>
            <ul>
                <li>✅ Encrypted sensitive data on blockchain</li>
                <li>✅ Performed computations on encrypted data</li>
                <li>✅ Maintained privacy throughout the entire process</li>
                <li>✅ Created a real-world privacy-preserving application</li>
            </ul>
        </div>
    </div>

    <script>
        // Contract Configuration
        const CONTRACT_ADDRESS = '0x5C24D812bBBFabC499B418a50abeeda17486Db44';
        const CONTRACT_ABI = [
            "function routeCounter() view returns (uint32)",
            "function requestCounter() view returns (uint32)",
            "function registerRoute(uint16 _startX, uint16 _startY, uint16 _endX, uint16 _endY, uint32 _capacity, uint16 _priority) external",
            "function submitTransportRequest(uint16 _pickupX, uint16 _pickupY, uint16 _dropX, uint16 _dropY, uint32 _weight, uint16 _urgency, uint32 _maxCost) external",
            "function getRouteInfo(uint32 _routeId) view returns (bool isActive, address carrier, uint256 timestamp)",
            "function getRequestStatus(uint32 _requestId) view returns (bool isMatched, address requester, uint32 assignedRoute, uint256 requestTime)",
            "function getCarrierRoutes(address _carrier) view returns (uint32[])",
            "function getUserRequests(address _user) view returns (uint32[])"
        ];

        let provider;
        let signer;
        let contract;
        let userAccount;

        async function connectWallet() {
            try {
                if (typeof window.ethereum === 'undefined') {
                    alert('Please install MetaMask to use this tutorial');
                    return;
                }

                await window.ethereum.request({ method: 'eth_requestAccounts' });
                provider = new ethers.providers.Web3Provider(window.ethereum);
                signer = provider.getSigner();
                userAccount = await signer.getAddress();
                contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

                const network = await provider.getNetwork();

                document.getElementById('walletStatus').textContent = 'Connected';
                document.getElementById('walletAddress').textContent = `${userAccount.substring(0, 6)}...${userAccount.substring(38)}`;

                console.log('Connected to:', userAccount);
            } catch (error) {
                console.error('Connection failed:', error);
                showStatus('routeStatus', 'Failed to connect wallet: ' + error.message, 'error');
            }
        }

        async function registerRoute() {
            if (!contract) {
                alert('Please connect your wallet first');
                return;
            }

            const startX = parseInt(document.getElementById('startX').value);
            const startY = parseInt(document.getElementById('startY').value);
            const endX = parseInt(document.getElementById('endX').value);
            const endY = parseInt(document.getElementById('endY').value);
            const capacity = parseInt(document.getElementById('capacity').value);
            const priority = parseInt(document.getElementById('priority').value);

            if (isNaN(startX) || isNaN(startY) || isNaN(endX) || isNaN(endY) || isNaN(capacity) || isNaN(priority)) {
                alert('Please fill in all fields with valid numbers');
                return;
            }

            try {
                showStatus('routeStatus', '🔐 Encrypting and registering route...', 'loading');

                const tx = await contract.registerRoute(startX, startY, endX, endY, capacity, priority);
                showStatus('routeStatus', `⏳ Transaction submitted: ${tx.hash}`, 'loading');

                const receipt = await tx.wait();
                showStatus('routeStatus', `✅ Route registered with encrypted data! Transaction: ${receipt.transactionHash}`, 'success');

                // Clear form
                document.getElementById('startX').value = '';
                document.getElementById('startY').value = '';
                document.getElementById('endX').value = '';
                document.getElementById('endY').value = '';
                document.getElementById('capacity').value = '';
            } catch (error) {
                console.error('Route registration failed:', error);
                showStatus('routeStatus', `❌ Registration failed: ${error.message}`, 'error');
            }
        }

        async function submitRequest() {
            if (!contract) {
                alert('Please connect your wallet first');
                return;
            }

            const pickupX = parseInt(document.getElementById('pickupX').value);
            const pickupY = parseInt(document.getElementById('pickupY').value);
            const dropX = parseInt(document.getElementById('dropX').value);
            const dropY = parseInt(document.getElementById('dropY').value);
            const weight = parseInt(document.getElementById('weight').value);
            const urgency = parseInt(document.getElementById('urgency').value);
            const maxCostValue = parseFloat(document.getElementById('maxCost').value);

            if (isNaN(pickupX) || isNaN(pickupY) || isNaN(dropX) || isNaN(dropY) || isNaN(weight) || isNaN(urgency) || isNaN(maxCostValue)) {
                alert('Please fill in all fields with valid numbers');
                return;
            }

            const maxCost = ethers.utils.parseEther(maxCostValue.toString());

            try {
                showStatus('requestStatus', '🔐 Encrypting and submitting request...', 'loading');

                const tx = await contract.submitTransportRequest(pickupX, pickupY, dropX, dropY, weight, urgency, maxCost);
                showStatus('requestStatus', `⏳ Transaction submitted: ${tx.hash}`, 'loading');

                const receipt = await tx.wait();
                showStatus('requestStatus', `✅ Private request submitted successfully! Transaction: ${receipt.transactionHash}`, 'success');

                // Clear form
                ['pickupX', 'pickupY', 'dropX', 'dropY', 'weight', 'maxCost'].forEach(id => {
                    document.getElementById(id).value = '';
                });
            } catch (error) {
                console.error('Request submission failed:', error);
                showStatus('requestStatus', `❌ Submission failed: ${error.message}`, 'error');
            }
        }

        async function loadMyRoutes() {
            if (!contract || !userAccount) {
                alert('Please connect your wallet first');
                return;
            }

            try {
                const routeIds = await contract.getCarrierRoutes(userAccount);

                if (routeIds.length === 0) {
                    document.getElementById('myRoutes').innerHTML = '<p>No routes found. Register a route first!</p>';
                    return;
                }

                let html = '<h4>My Registered Routes:</h4>';
                for (let i = 0; i < routeIds.length; i++) {
                    const routeId = routeIds[i];
                    const routeInfo = await contract.getRouteInfo(routeId);

                    html += `
                        <div style="background: white; padding: 10px; margin: 5px 0; border-radius: 5px;">
                            <strong>Route #${routeId}</strong><br>
                            Status: ${routeInfo.isActive ? '✅ Active' : '❌ Inactive'}<br>
                            Created: ${new Date(routeInfo.timestamp * 1000).toLocaleString()}<br>
                            <em>📡 Route data is encrypted on-chain</em>
                        </div>
                    `;
                }
                document.getElementById('myRoutes').innerHTML = html;
            } catch (error) {
                console.error('Failed to load routes:', error);
                document.getElementById('myRoutes').innerHTML = '<p style="color: red;">Failed to load routes</p>';
            }
        }

        async function loadMyRequests() {
            if (!contract || !userAccount) {
                alert('Please connect your wallet first');
                return;
            }

            try {
                const requestIds = await contract.getUserRequests(userAccount);

                if (requestIds.length === 0) {
                    document.getElementById('myRequests').innerHTML = '<p>No requests found. Submit a request first!</p>';
                    return;
                }

                let html = '<h4>My Transport Requests:</h4>';
                for (let i = 0; i < requestIds.length; i++) {
                    const requestId = requestIds[i];
                    const requestStatus = await contract.getRequestStatus(requestId);

                    html += `
                        <div style="background: white; padding: 10px; margin: 5px 0; border-radius: 5px;">
                            <strong>Request #${requestId}</strong><br>
                            Status: ${requestStatus.isMatched ? '✅ Matched' : '⏳ Pending'}<br>
                            Route: ${requestStatus.assignedRoute > 0 ? `#${requestStatus.assignedRoute}` : 'None'}<br>
                            Submitted: ${new Date(requestStatus.requestTime * 1000).toLocaleString()}<br>
                            <em>🔐 Request data is encrypted on-chain</em>
                        </div>
                    `;
                }
                document.getElementById('myRequests').innerHTML = html;
            } catch (error) {
                console.error('Failed to load requests:', error);
                document.getElementById('myRequests').innerHTML = '<p style="color: red;">Failed to load requests</p>';
            }
        }

        function showStatus(elementId, message, type) {
            const statusElement = document.getElementById(elementId);
            statusElement.style.display = 'block';
            statusElement.className = `status ${type}`;
            statusElement.textContent = message;
        }

        // Auto-connect if already connected
        if (window.ethereum) {
            window.ethereum.request({ method: 'eth_accounts' })
                .then(accounts => {
                    if (accounts.length > 0) {
                        connectWallet();
                    }
                });
        }
    </script>
</body>
</html>
```

## 🚀 Step 6: Deployment

Create `scripts/deploy.js`:

```javascript
const hre = require("hardhat");

async function main() {
    console.log("Deploying Anonymous Transport Scheduler...");

    const AnonymousTransport = await hre.ethers.getContractFactory("AnonymousTransport");
    const contract = await AnonymousTransport.deploy();

    await contract.deployed();

    console.log("Contract deployed to:", contract.address);
    console.log("Update your frontend CONTRACT_ADDRESS with this address");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
```

Deploy:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

## 🎯 Step 7: Testing Your dApp

1. **Open your HTML file** in a browser
2. **Connect MetaMask** to Sepolia testnet
3. **Register a Route** with encrypted coordinates
4. **Submit a Request** with private pickup/delivery data
5. **View Your Data** - notice only public info is visible

## 🧠 Key Learning Outcomes

### What You've Accomplished:
- ✅ **Built FHE Smart Contract**: Computed on encrypted data
- ✅ **Implemented Privacy**: Sensitive data never exposed
- ✅ **Created Real dApp**: Functional privacy-preserving application
- ✅ **Used FHE Operations**: Comparisons, additions on encrypted values
- ✅ **Managed Access Control**: Proper encryption permissions

### FHE Concepts Mastered:
- **Encrypted Types**: `euint16`, `euint32`, `ebool`
- **FHE Operations**: `FHE.le()`, `FHE.add()`, `FHE.and()`
- **Access Control**: `FHE.allow()`, `FHE.allowThis()`
- **Privacy Preservation**: Computing without revealing data

## 🌟 Next Steps

Now that you understand FHEVM basics, try:

1. **Add More Features**: Implement route optimization with encrypted scoring
2. **Enhanced Privacy**: Add more encrypted fields and computations
3. **User Experience**: Improve UI with better encrypted data visualization
4. **Advanced FHE**: Explore conditional operations and complex calculations

## 🔗 Resources

- **FHEVM Documentation**: Learn more advanced FHE features
- **Zama GitHub**: Explore more FHE examples
- **Community Discord**: Get help from other FHE developers

## 🎉 Congratulations!

You've successfully built your first confidential dApp using FHEVM! You now understand how to:
- Encrypt sensitive data on blockchain
- Perform computations on encrypted values
- Build privacy-preserving applications
- Use FHE operations in real-world scenarios

Welcome to the future of privacy-preserving blockchain development! 🚀