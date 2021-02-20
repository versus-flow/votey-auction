
transaction(name: String) {
    prepare(signer: AuthAccount) {
        signer.contracts.remove(name: name)
    }
}