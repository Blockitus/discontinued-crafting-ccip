// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC20.sol";
import {LinkTokenInterface} from "../LinkTokenInterface.sol";
import {ChainsListerOperator} from "./ChainsListerOperator.sol";

contract CCIPTokenSender is ChainsListerOperator {
    IRouterClient router;
    LinkTokenInterface link;

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();

    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    constructor(address _router, address _link) {
        router = IRouterClient(_router);
        link = LinkTokenInterface(_link);
    }

    function transferToken(
        uint64 _destinationChainSelector, 
        address _receiver, 
        address _token, 
        uint256 _amount) external onlyOwner onlyWhitelistedChain(_destinationChainSelector) returns (bytes32 messageId) {

            Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
            Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
                token: _token,
                amount: _amount
            });

            tokenAmounts[0] = tokenAmount;

            Client.EVM2AnyMessage memory message = _buildCcipMessage(
                _receiver,
                "",
                tokenAmounts,
                address(link)
            );
            
            uint256 fees = _ccipFeesManagement(_destinationChainSelector, message);

            IERC20(_token).approve(address(router), _amount);

            messageId = router.ccipSend(_destinationChainSelector, message); 

            emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(link),
            fees
            );   
        
        }

    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));

        if (amount == 0) revert NothingToWithdraw();
        
        IERC20(_token).transfer(_beneficiary, amount);
    }

    function _buildCcipMessage(
        address _receiver, 
        bytes memory _data,
        Client.EVMTokenAmount[] memory _tokenAmounts,
        address _feeToken
    ) private pure returns (Client.EVM2AnyMessage memory message) {

        message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: _data,
            tokenAmounts: _tokenAmounts,
            feeToken: _feeToken,
            extraArgs: Client._argsToBytes(
            Client.EVMExtraArgsV1({gasLimit: 0})
            )
            });

    }

    function _ccipFeesManagement(uint64 _destinationChainSelector, Client.EVM2AnyMessage memory message) private returns(uint256 fees) {
        fees = router.getFee(_destinationChainSelector, message);
        if (fees > link.balanceOf(address(this)))
            revert NotEnoughBalance(link.balanceOf(address(this)), fees);
        link.approve(address(router), fees);
    }



}