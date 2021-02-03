// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken, Art, Auction, Versus from 0x01cf0e2f2f715450

pub struct AddressStatus {

  pub(set) var address:Address
  pub(set) var balance: UFix64
  pub(set) var art: {UInt64: Art.Metadata}
  pub(set) var drops: {UInt64: Versus.DropStatus}
  init (_ address:Address) {
    self.address=address
    self.balance= 0.0
    self.art= {}
    self.drops ={}
  }
}

/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main(address:Address, name: String){
    // get the accounts' public address objects
    let account = getAccount(address)
    let status= AddressStatus(address)
    log(name)
    log("=====================")
    
    if let vault= account.getCapability(/public/flowTokenBalance).borrow<&{FungibleToken.Balance}>() {
       log("Balance of Flow")
       log(vault.balance)
       status.balance=vault.balance
    }


    if let versus = account.getCapability(/public/Versus).borrow<&{Versus.PublicDrop}>() {
      log("Drops available")
      log("=================")
      let versusStatuses=versus.getAllStatuses()
      for s in versusStatuses.keys {
          let status = versusStatuses[s]!
          if status.uniqueStatus.active != false {
            log("dropid")
            log(status.dropId)
            log("Price unique")
            log(status.uniquePrice)
            log("Price editioned")
            log(status.editionPrice)
            log("Winning")
            log(status.winning)
            log(status.uniqueStatus)
            for es in status.editionsStatuses.keys {
                let es = status.editionsStatuses[es]!
                log(es)
            }
          }
      }
      status.drops=versusStatuses
      return
    } 


    if let art= account.getCapability(/public/ArtCollection).borrow<&{Art.CollectionPublic}>()  {
       
        log("Art in collection") 
        for id in art.getIDs() {
          var art=art.borrowArt(id: id) 
          log(art?.metadata)
          status.art[id]=art!.metadata
        }
    }
    
    
    log("=====================")
    //return status

}
