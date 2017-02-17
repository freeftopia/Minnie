import "abstracts/owned.sol"

contract MinnieBank is owned {
    /* -
    This contract registers known contributors and their balances

    ToDo :
     - Add Givable Token
    */

    //////// VARIABLES AND CONSTANT FUNCTIONS

    address[] public contributors;
	// contributors is the list of contributor's ethereum account's address

    mapping(address => uint) public balanceOf;
	// Store the balance of each contributors
	// Token CAN NOT be split in less than 1 token

    address[] public trustedAddresses;
	// List of trusted contracts allowed to change contributors balances
	// Can only be change by the owner

    //Convenience functions to lookup public arrays
    //Constant functions : does not change state, doesn't need a transaction
    function contributorsCount() constant returns(uint){
        return contributors.length;
    }
    function trustedAddressesCount() constant returns(uint){
        return trustedAddresses.length;
    }

    //Check if the given address is a registered contributor
    //Constant function : does not change state, doesn't need a transaction
    function isKnownContributor(address contributor) constant returns(bool){
        for(uint i = 0; i < contributors.length; i++) {
            if (contributors[i] == contributor) {return true;}
        }
        return false;
    }

    //Get total token of all contributors
    //Constant function : does not change state, doesn't need a transaction
    //Note : Other functions MUST ensure that all Token holders are registered
    //contributors
    function totalSupply() constant returns(uint){
        uint supply=0;
        for(uint i = 0; i < contributors.length; i++) {
            supply = supply + balanceOf[contributors[i]];
        }
        return supply;
    }

    /////// Deployment function

    //Set initial state
    function MinnieBank(){
        trustedAddresses.push(owner); //Owner is a trusted address


        // DEV BLOCK
        // Uncomment this block in development to quickly initialise the state

        address contrib1 = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        address contrib2 = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;

        registerContributor(contrib1);
        registerContributor(contrib2);

        addTokenTo(contrib1,1500);
        addTokenTo(contrib2,400);
        // END DEV BLOCK



    }

    //////// MODIFIERS



    //functions using onlyTrusted can only be used from an address from trustedAddresses
    //Note : Owner address is ALWAYS a trusted address
    modifier onlyTrusted {
        bool present=false;
        for(uint i = 0; i < trustedAddresses.length; i++) {
            if(trustedAddresses[i] == msg.sender){present=true;}
        }
        if (!present){throw;} //Consumes all gas
        _;
    }

    //functions using onlyContributor can only be used from a registered contributor
    modifier onlyContributor {
        if (!isKnownContributor(msg.sender)){throw;} //Consumes all gas
        _;
    }

    //////// Events
    // Event can be watch by ethereum clients to trigger actions outside of the Ethereum VM

    event TrustedAddressAdded(
        address trustedAddress,
        uint index
    );

    event TrustedAddressRemoved(
        address trustedAddress
    );

    event ContributorAdded(
        address contributor,
        uint index
    );

    event ContributorRemoved(
        address contributor
    );

    event BalanceChanged(
        address contributor,
        uint newBalance
    );

    event TokenSupplyChanged(); //Do not indicate new supply since it will increase transaction gas cost

    //////// FUNCTIONS

    //// Admin Functions

    function addTrustedAddress(address newTrusted) onlyOwner returns(uint index) {
        trustedAddresses.push(newTrusted);
        TrustedAddressAdded(newTrusted,trustedAddresses.length-1);
        return trustedAddresses.length-1; //Return new address index
    }

    function removeTrustedAddress(address trustedAddress) onlyOwner {
        if(trustedAddress==owner){throw;} // you can't remove remove owner from trusted addresses

        uint index;
        bool found = false;
        for (uint j =0 ; j<trustedAddresses.length; j++){
            if(trustedAddress==trustedAddresses[j]){
                found=true;
                index=j;
                break;
            }
        }

        TrustedAddressRemoved(trustedAddress);
        delete trustedAddresses[index];
        //WARNING : trustedAddresses length is not changed, trustedAddresses[index] is
        //set to "0x0"
    }

    function changeOwner(address newOwner) onlyOwner {
        address oldOwner=owner; // Have to store it since we can't remove owner from trusted addresses
        addTrustedAddress(newOwner);
        owned.changeOwner(newOwner);
        removeTrustedAddress(oldOwner);
    }

    //Register a new contributors. Onwer only. Change in registration process can
    //be made in owner contract
    function registerContributor(address contributor) onlyOwner returns(uint index) {
        if(isKnownContributor(contributor)){return;}
        contributors.push(contributor);
        ContributorAdded(contributor,contributors.length-1);
        return contributors.length-1; //Return new address index
    }

    function removeContributor(address contributor) onlyOwner  {
        uint index;
        bool found = false;
        for (uint j =0 ; j<contributors.length; j++){
            if(contributor==contributors[j]){
                found=true;
                index=j;
                break;
            }
        }
        if(found){
            // Contributor MUST have an empty balance to be removed
            if (balanceOf[contributor]>0) {throw;}
            ContributorRemoved(contributor);
            for (uint i = index; i<contributors.length-1; i++){
                contributors[i] = contributors[i+1];
            }
            delete contributors[contributors.length-1];
            contributors.length--;
        } else {
            //unknown contributor
            return;
        }

    }

    //// Trusted Functions

    // Add Token to a registered contributor (increase TotalSupply)
    function addTokenTo(address contributor, uint amount) onlyTrusted returns(uint newBalance) {
        // You can only add token to registered contributors
        if (!isKnownContributor(contributor)){throw;} //Consumes all gas
        balanceOf[contributor]+=amount;
        BalanceChanged(contributor,balanceOf[contributor]);
        TokenSupplyChanged();
        return balanceOf[contributor];
    }

    // Remove Token from registered contributor (decrease TotalSupply)
    function removeTokenFrom(address contributor, uint amount) onlyTrusted returns(uint newBalance) {
        // You can only add token to registered contributors
        if (!isKnownContributor(contributor)){throw;} //Consumes all gas
        if(balanceOf[contributor]>amount){
            balanceOf[contributor]-=amount;
        } else {
            balanceOf[contributor]=0;
        }
        BalanceChanged(contributor,balanceOf[contributor]);
        TokenSupplyChanged();
        return balanceOf[contributor];
    }

    //// Contributor functions

    // Transfer token to an other contributor
    function transferTo(address contributor, uint amount) {
        if (!isKnownContributor(contributor)){throw;} //Consumes all gas
        if (balanceOf[msg.sender]<amount){throw;} //Ensure sender have enougth tokens

        balanceOf[msg.sender]-=amount;
        balanceOf[contributor]+=amount;
        BalanceChanged(msg.sender,balanceOf[msg.sender]);
        BalanceChanged(contributor,balanceOf[contributor]);
    }

}