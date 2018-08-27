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
  },

  directValidatorSet: function(validator) {
    var set = new Set([]);
    var quorumSet = validator.quorumSet;
    if (quorumSet) {
      for (var i=0; i<quorumSet.validators.length; i++) {
        set.add(quorumSet.validators[i]);
      }
      for (var j=0; j<quorumSet.innerQuorumSets.length; j++) {
        var innerQS = quorumSet.innerQuorumSets[j];
        for (var k=0; k<innerQS.validators.length; k++) {
          set.add(innerQS.validators[k]);
        }
      }
    }
    return set;
  },

  indirectValidatorSet: function(validators, validator) {
    var touched = new Set([]);
    recurseValidators(validators, validator.publicKey, touched);
    return touched;
  },

  directIncomingValidatorSet: function(validators, validator) {
    var set = new Set([]);
    for (var i=0; i<validators.length; i++) {
      var v = validators[i];
      if ( v.directValidatorSet.has(validator.publicKey) ) {
        set.add(v.publicKey);
      }
    }
    return set;
  },

  indirectIncomingValidatorSet: function(validators, validator) {
    var set = new Set([]);
    for (var i=0; i<validators.length; i++) {
      var v = validators[i];
      if ( v.indirectValidatorSet.has(validator.publicKey) ) {
        set.add(v.publicKey);
      }
    }
    return set;
  },

  compareValidators: function(a, b) {
    var indirectIncomingDiff = b.indirectIncomingValidatorSet.size - a.indirectIncomingValidatorSet.size;
    if (indirectIncomingDiff !== 0) { return indirectIncomingDiff; }
    var indirectOutgoingDiff = b.indirectValidatorSet.size - a.indirectValidatorSet.size;
    if (indirectOutgoingDiff !== 0) { return indirectOutgoingDiff; }
    if (a.name) {
      if (b.name) {
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
      }
      return -1;
    }
    else if (b.name) {
      return 1;
    }
    return a.publicKey.localeCompare(b.publicKey);
  },

  sortSet: function(validators, set) {
    if (!set) return [];
    var array = Array.from(set);
    return array.sort( function(a,b) {
      var v1 = validatorHelpers.validatorAndHandleForPublicKey(validators, a).validator;
      var v2 = validatorHelpers.validatorAndHandleForPublicKey(validators, b).validator;
      if (v1 && v2) {
        return validatorHelpers.compareValidators(v1, v2);
      }
      if (v1) {
        return -1;
      }
      return 1;
    });
  }
}



function recurseValidators(validators, validatorId, touched) {
  var v = validatorHelpers.validatorAndHandleForPublicKey(validators, validatorId).validator;
  if (v) {
    var candidates = new Set([...v.directValidatorSet].filter(x => !touched.has(x)));
    for (let candidate of candidates) {
      touched.add(candidate);
    }
    for (let candidate of candidates) {
      recurseValidators(validators, candidate, touched);
    }
  }
}

export default validatorHelpers;
