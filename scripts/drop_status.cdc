// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

//emulator
import Versus from 0xbc08417e9d472f2e

//testnet
//import Auction, Versus from 0x1ff7e32d71183db0

/*
  Script used to get the first active drop in a versus 
 */
pub fun main(dropID: UInt64) : Versus.DropStatus {

    return Versus.getDrop(dropID)!
}