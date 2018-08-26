const validatorHelpers = { 
  validatorAndHandleForPublicKey: function(validators, publicKey) {
    for ( var i=0; i<validators.length; i++ ) {
      if ( validators[i].publicKey === publicKey ) {
        return { validator: validators[i], handle: i+1 };
      }
    }
    return { validator: null, handle: "?" };
  },
  
  quorumNodeForId: function(validator, nodeId) {
    if ( !validator || !nodeId ) {
      return null;
    }
    var quorumSet = validator.quorumSet;
    if (quorumSet) {
      if ( quorumSet.hashKey === nodeId ) {
        return quorumSet;
      }
      for (var i=0; i<quorumSet.validators.length; i++) {
        var v = quorumSet.validators[i];
        if ( v === nodeId ) {
          return { publicKey: v};
        }
      }
      for (var j=0; j<quorumSet.innerQuorumSets.length; j++) {
        var innerQS = quorumSet.innerQuorumSets[j];
        if ( innerQS.hashKey === nodeId ) {
          return innerQS;
        }
        for (var k=0; k<innerQS.validators.length; k++) {
          var innerV = innerQS.validators[k];
          if ( innerV === nodeId ) {
            return { publicKey: innerV};
          }
        }
      }
    }
    return null;
  }
}

export default validatorHelpers;