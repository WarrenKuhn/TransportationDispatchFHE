const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying TransportationDispatchFHE Contract...");

  try {
    // Get the ContractFactory
    const TransportationDispatchFHE = await ethers.getContractFactory("TransportationDispatchFHE");

    // Deploy the contract
    console.log("⏳ Deploying contract...");
    const contract = await TransportationDispatchFHE.deploy();

    await contract.deployed();

    console.log("✅ TransportationDispatchFHE deployed to:", contract.address);

    // Test basic functionality
    console.log("🔐 Testing FHE functionality...");

    const dispatchCount = await contract.getDispatchCount();
    console.log("📊 Initial dispatch count:", dispatchCount.toString());

    const totalVotes = await contract.getTotalVotes();
    console.log("🗳️ Initial total votes:", totalVotes.toString());

    console.log("✅ Contract deployed successfully!");

    // Update contract address for frontend
    console.log("\n📋 Update your frontend with this contract address:");
    console.log(`const CONTRACT_ADDRESS = "${contract.address}";`);

  } catch (error) {
    console.error("❌ Deployment failed:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });