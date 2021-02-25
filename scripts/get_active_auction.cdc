// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

//emulator
import NonFungibleToken, Content, Art, Auction, Versus from 0xf8d6e0586b0a20c7

//testnet
//import Auction, Versus from 0x1ff7e32d71183db0

/*
  Script used to get the first active drop in a versus 
 */
pub fun main(address:Address) : Versus.DropStatus?{

    return Versus.getActiveDrop(address: address)
}
