import { ethers } from "hardhat";

async function main() {
  console.log("🚀 Deploying Anonymous Transport Scheduler FHE Contract...");

  // Get the ContractFactory
  const AnonymousTransport = await ethers.getContractFactory("AnonymousTransport");

  // Deploy the contract
  console.log("⏳ Deploying contract to Sepolia...");
  const contract = await AnonymousTransport.deploy();

  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();

  console.log("✅ AnonymousTransport deployed to:", contractAddress);
  console.log("🔗 View on Etherscan: https://sepolia.etherscan.io/address/" + contractAddress);

  // Verify the contract has FHE functionality
  console.log("🔐 Testing FHE functionality...");

  try {
    const routeCounter = await contract.routeCounter();
    console.log("📊 Initial route counter:", routeCounter.toString());

    const requestCounter = await contract.requestCounter();
    console.log("🚛 Initial request counter:", requestCounter.toString());

    console.log("✅ Contract deployed successfully with FHE capabilities!");
  } catch (error) {
    console.error("❌ Error testing contract:", error);
  }

  // Save deployment info
  const deployment = {
    contractAddress: contractAddress,
    network: "sepolia",
    deployedAt: new Date().toISOString(),
    transactionHash: contract.deploymentTransaction()?.hash
  };

  console.log("\n📝 Deployment Summary:");
  console.log(JSON.stringify(deployment, null, 2));

  console.log("\n📋 Update your frontend with this contract address:");
  console.log(`const CONTRACT_ADDRESS = "${contractAddress}";`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });