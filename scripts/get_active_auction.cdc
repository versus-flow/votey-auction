// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

//emulator
import Versus from 0xbc08417e9d472f2e

//testnet
//import Versus from 0x6bb8a74d4db97b46

/*
  Script used to get the first active drop in a versus 
 */
pub fun main() : Versus.DropStatus?{

    return Versus.getActiveDrop()
}
