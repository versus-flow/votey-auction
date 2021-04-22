
//emulator
import Versus from 0xbc08417e9d472f2e

//testnet
//import Auction, Versus from 0x1ff7e32d71183db0

/*
  Script used to get the first active drop in a versus 
 */
pub fun main() : [Versus.DropStatus] {

    return Versus.getDrops()
}
