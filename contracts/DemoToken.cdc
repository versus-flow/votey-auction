// DemoToken is a fungible token used for testing marketplace purchases

// This has been left really really simple since we expect the Flow token will replace this.

// Import the Flow FungibleToken interface
import FungibleToken from 0xee82856bf20e2aa6


//TODO: Drop this
pub contract DemoToken: FungibleToken {
    /// The total number of tokens in existence.
    /// It is up to the implementer to ensure that the total supply
    /// stays accurate and up to date
    ///
    pub var totalSupply: UFix64

    /// TokensInitialized
    ///
    /// The event that is emitted when the contract is created
    ///
    pub event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    ///
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited into a Vault
    ///
    pub event TokensDeposited(amount: UFix64, to: Address?)
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

    // create vaultWithTokens
    //
    // This is for demo purposes only so we just create a vault with some tokens in it
     pub fun createVaultWithTokens(_ balance: UFix64): @FungibleToken.Vault {
         DemoToken.totalSupply= DemoToken.totalSupply+balance
        return <-create Vault(balance: balance)
    }

    init() {
         self.totalSupply = 0.0

         
         emit TokensInitialized(initialSupply: self.totalSupply)
    }

}
 