pragma solidity ^0.4.18;

import "./Ownable.sol";

contract Remittance is Ownable {

    uint publicKey;
    uint maxAmountToBob;
    bool contractIsActive;

    event LogToggleContractState(bool isContractLive);
    event LogCarolWithdrew(address indexed carol, uint amount);

    function Remittance(uint amount, address _carolAddress, string bobPassword, string carolPassword)
    public
    {
        // We are setting a max on how much Bob can withdraw, can't be zero
        require(amount > 0);
        maxAmountToBob = amount;
        // We assume Carol had given us her address and we make it required
        require(_carolAddress != 0);
        // create a secret key, that although is visible on the blockchain, takes carol's address
        // as part of the hash for added security -- typecast it to a uint.
        publicKey = uint(keccak256(carolPassword, bobPassword, _carolAddress));
    }

    // only Alice can do this. She will have to do this after she initializes the contract to be safe.
    // She can also use this function to pause the contract at anytime.
    function toggleContract(bool toggle)
    external
    onlyOwner
    {
        contractIsActive = toggle;
        LogToggleContractState(contractIsActive);
    }

    // Intended only for Carol to use
    function carolWithdraw(uint withdrawAmount, string carolPassword, string bobPassword)
    public
    {
        // Revert if Alice never activated the contract
        require(contractIsActive == true);
        // if the contract balance is empty, nothing can happen
        require(this.balance > 0);
        // Check that Carol is not withdrawing more than what was agreed upon with Bob
        require (withdrawAmount <= maxAmountToBob);
        // Verify that Bob gave Carol his password
        require(publicKey == uint(keccak256(carolPassword, bobPassword, msg.sender)));
        // prevent re-entry by making the contract inactive and log it
        contractIsActive = false;
        LogToggleContractState(false);
        // Log that Carol withdrew funds and how much, and that the contract is no longer active
        LogCarolWithdrew(msg.sender, withdrawAmount);
        // Interaction with untrusted address last        
        msg.sender.transfer(withdrawAmount);
    }

    // Once again, only Alice can withdraw the remainder
    function withdrawRemainder()
    external
    onlyOwner
    {
    owner.transfer(this.balance);
    }
}
