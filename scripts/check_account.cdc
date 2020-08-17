// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: DemoToken Vault Balance = 1050, No NFTs
// Account 0x02: DemoToken Vault Balance = 10, NFT.id = 1

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0x01cf0e2f2f715450
import DemoToken from 0x179b6b1cb6755e31
import Rocks from 0xf3fcd2c1a78f5eee
import VoteyAuction from 0xe03daebed8ca0615
// Contract Deployment:
// Acct 1 - 0x01cf0e2f2f715450 - onflow/NonFungibleToken.cdc
// Acct 2 - 0x179b6b1cb6755e31 - demo-token.cdc
// Acct 3 - 0xf3fcd2c1a78f5eee - rocks.cdc
// Acct 4 - 0xe03daebed8ca0615 - auction.cdc
pub struct AddressStatus {

  pub(set) var address:Address
  pub(set) var balance: UFix64
  pub(set) var rocks: {UInt64: {String : String}}
  pub(set) var auctions: {UInt64: VoteyAuction.AuctionStatus}
  init (_ address:Address) {
    self.address=address
    self.balance= UFix64(0)
    self.rocks= {}
    self.auctions ={}
  }
}

pub fun main(address:Address) {
    // get the accounts' public address objects
    let account = getAccount(address)
    let status= AddressStatus(address)
    log("=====================")
    log("Check account")
    log(account)
    
    if let demoTokenCapability =account.getCapability(/public/DemoTokenBalance) {
        if let demoTokens= demoTokenCapability.borrow<&{FungibleToken.Balance}>() {
          log("Balance of DemoTokens")
          log(demoTokens.balance)
          status.balance=demoTokens.balance
        }
    }

    if let rocksCap = account.getCapability(/public/RockCollection) {
       if let rocks= rocksCap.borrow<&{NonFungibleToken.CollectionPublic}>()  {
           log("Rocks in collection") 
           for id in rocks.getIDs() {
             var metadata=rocks.borrowNFT(id: id).metadata
             log(metadata)
             status.rocks[id]=metadata
           }
       }
    }
   
   
    if let auctionCap = account.getCapability(/public/NFTAuction) {
        if let auctions = auctionCap.borrow<&{VoteyAuction.AuctionPublic}>() {
          log("Items up for auction")
          let auctionStatus=auctions.getAuctionStatuses()
          for s in auctionStatus.keys {
              log(auctionStatus[s])
          }
          status.auctions=auctionStatus
        } else {
          log("No items for sale 1")
        }
    } else {
        log("No items for sale 2")
    } 
    log("=====================")
    //return status

}
