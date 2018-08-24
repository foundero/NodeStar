const validatorHelpers = { 
  validatorHandleForPublicKey: function(validators, publicKey) {
    for ( var i=0; i<validators.length; i++ ) {
      if ( validators[i].publicKey === publicKey ) {
        return i+1
      }
    }
    return "?"
  }
}

export default validatorHelpers;