import "owned.sol";

contract bankTrusted is owned {
     MinnieBank public tokenBank;

     function bankTrusted(MinnieBank bankAddress) {
        tokenBank=bankAddress;
     }

    //// Modifier functions
    modifier onlyContributor {
        if (!tokenBank.isKnownContributor(msg.sender)){throw;} //Consumes all gas
        _;
    }

    event BankChanged(
        address newBank,
        address previousBank
    );

    // Allow to change owner to allow change in governance
    function changeBank(MinnieBank newBank) onlyOwner {
        BankChanged(newBank,tokenBank); //Trigger event OwnerChanged
        tokenBank = newBank;
    }

    function isTrusted() constant returns(bool) {
        for(uint i = 0; i < tokenBank.trustedAddressesCount(); i++) {
            if(tokenBank.trustedAddresses(i) == address(this)){return true;}
        }
        return false;
    }
}