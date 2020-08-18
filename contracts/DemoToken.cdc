// DemoToken is a fungible token used for testing
// marketplace purchases

// Import the Flow FungibleToken interface
import FungibleToken from 0xee82856bf20e2aa6


pub contract DemoToken: FungibleToken {

    // Total supply of all DemoTokens in existence.
    pub var totalSupply: UFix64

    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited into a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when tokens are minted
    pub event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)
    
    // Event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // Keeps track of the total account balance for this Vault
        pub var balance: UFix64

        // Initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount of tokens from the Vault.
        //
        // It creates a new temporary Vault that contains the
        // withdrawn tokens and returns the temporary Vault to 
        // the calling context to be deposited elsewhere
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        //
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        //
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @DemoToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            DemoToken.totalSupply = DemoToken.totalSupply - self.balance
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @FungibleToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    pub resource Administrator {
        // createNewMinter
        //
        // Function that returns a new minter resource
        //
        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        // createNewBurner
        //
        // Function that returns a new burner resource
        //
        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens
    //
    pub resource Minter {

        // the amount of tokens that the minter is allowed to mint
        pub var allowedAmount: UFix64

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context
        //
        pub fun mintTokens(amount: UFix64): @DemoToken.Vault {
            pre {
                amount > UFix64(0): "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            DemoToken.totalSupply = DemoToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }

    }

    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens
    //
    pub resource Burner {

        // burnTokens
        //
        // Function that destroys a vault instance, effectively burning the tokens
        //
        // Note: the burned tokens are automatically subtracted from
        // the totalSupply in the Vault destructor
        //
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @DemoToken.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    // The init function initializes the fields for the DemoToken contract.
    init() {
        self.totalSupply = 0.0

        // Create the Vault with the total supply of tokens and save it in storage
        let vault <-create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: /storage/DemoTokenVault)

        // Create a public capability to the stored Vault that only exposes
        // the 'deposit' method through the 'Receiver' interface
        //
        self.account.link<&{FungibleToken.Receiver}>(
            /public/DemoTokenReceiver,
            target: /storage/DemoTokenVault
        )

        // Create a public capability to the stored Vault that only exposes
        // the 'balance' field through the 'Balance' interface
        self.account.link<&{FungibleToken.Balance}>(
            /public/DemoTokenBalance,
            target: /storage/DemoTokenVault
        )

        let admin <-create Administrator()
        self.account.save(<-admin, to: /storage/DemoTokenAdmin)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
 