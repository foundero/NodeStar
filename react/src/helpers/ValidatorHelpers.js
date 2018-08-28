const validatorHelpers = {

  calculateValidators(validators) {
    for (let i=0; i<validators.length; i++) {
      const v = validators[i];
      v.directValidatorSet = directValidatorSet(v);
    }
    for (let i=0; i<validators.length; i++) {
      const v = validators[i];
      v.indirectValidatorSet = indirectValidatorSet(validators, v);
    }
    for (let i=0; i<validators.length; i++) {
      const v = validators[i];
      v.directIncomingValidatorSet = directIncomingValidatorSet(validators, v);
    }
    for (let i=0; i<validators.length; i++) {
      const v = validators[i];
      v.indirectIncomingValidatorSet = indirectIncomingValidatorSet(validators, v);
    }

    return validators.sort(compareValidators);
  },

  validatorAndHandleForPublicKey: function(validators, publicKey) {
    for ( let i=0; i<validators.length; i++ ) {
      if ( validators[i].publicKey === publicKey ) {
        return { validator: validators[i], handle: i+1 };
      }
    }
    return { validator: null, handle: "?" };
  },
  
  quorumNodeForId: function(validator, nodeId) {
    if ( !validator || !validator.quorumSet || !nodeId ) {
      return null;
    }
    return quorumNodeForIdInQuorumSet(validator.quorumSet, nodeId);
  },

  sortSet: function(validators, set) {
    if (!set) return [];
    let array = Array.from(set);
    return array.sort( function(a,b) {
      const v1 = validatorHelpers.validatorAndHandleForPublicKey(validators, a).validator;
      const v2 = validatorHelpers.validatorAndHandleForPublicKey(validators, b).validator;
      if (v1 && v2) {
        return compareValidators(v1, v2);
      }
      if (v1) {
        return -1;
      }
      return 1;
    });
  }
};




/* Private Functions */


function directValidatorSet(validator) {
  let set = new Set([]);
  const quorumSet = validator.quorumSet;
  if (quorumSet) {
    for (let i=0; i<quorumSet.validators.length; i++) {
      set.add(quorumSet.validators[i]);
    }
    for (let j=0; j<quorumSet.innerQuorumSets.length; j++) {
      const innerQS = quorumSet.innerQuorumSets[j];
      for (let k=0; k<innerQS.validators.length; k++) {
        set.add(innerQS.validators[k]);
      }
    }
  }
  return set;
}

function indirectValidatorSet(validators, validator) {
  let touched = new Set([]);
  recurseIndirectValidators(validators, validator.publicKey, touched);
  return touched;
}

function recurseIndirectValidators(validators, validatorId, touched) {
  const v = validatorHelpers.validatorAndHandleForPublicKey(validators, validatorId).validator;
  if (v) {
    const candidates = new Set([...v.directValidatorSet].filter(x => !touched.has(x)));
    for (let candidate of candidates) {
      touched.add(candidate);
    }
    for (let candidate of candidates) {
      recurseIndirectValidators(validators, candidate, touched);
    }
  }
}

function directIncomingValidatorSet(validators, validator) {
  let set = new Set([]);
  for (let i=0; i<validators.length; i++) {
    const v = validators[i];
    if ( v.directValidatorSet.has(validator.publicKey) ) {
      set.add(v.publicKey);
    }
  }
  return set;
}

function indirectIncomingValidatorSet(validators, validator) {
  let set = new Set([]);
  for (let i=0; i<validators.length; i++) {
    const v = validators[i];
    if ( v.indirectValidatorSet.has(validator.publicKey) ) {
      set.add(v.publicKey);
    }
  }
  return set;
}

function compareValidators(a, b) {
  const indirectIncomingDiff = b.indirectIncomingValidatorSet.size - a.indirectIncomingValidatorSet.size;
  if (indirectIncomingDiff !== 0) { return indirectIncomingDiff; }
  const indirectOutgoingDiff = b.indirectValidatorSet.size - a.indirectValidatorSet.size;
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
}

function quorumNodeForIdInQuorumSet(quorumSet, nodeId) {
  if ( !quorumSet || !nodeId ) {
    return null;
  }
  if ( quorumSet.hashKey === nodeId ) {
    return quorumSet;
  }
  for (let i=0; i<quorumSet.validators.length; i++) {
    const v = quorumSet.validators[i];
    if ( v === nodeId ) {
      return { publicKey: v};
    }
  }
  for (let j=0; j<quorumSet.innerQuorumSets.length; j++) {
    const innerQS = quorumSet.innerQuorumSets[j];
    const foundNode = quorumNodeForIdInQuorumSet(innerQS, nodeId);
    if ( foundNode ) {
      return foundNode;
    }
  }
  return null;
}


export default validatorHelpers;
