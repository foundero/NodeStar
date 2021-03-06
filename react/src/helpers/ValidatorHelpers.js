// @flow

export type QuorumSet = {
  hashKey: string,
  threshold: number,
  validators: Array<string>,
  innerQuorumSets: Array<QuorumSet>
}
export type Validator = {
  publicKey: string,
  verified: boolean,
  version: ?string,
  ip: ?string,
  port: ?string,
  city: ?string,
  country: ?string,
  latitude: ?string,
  longitude: ?string,
  name: ?string,
  host: ?string,
  quorumSet: QuorumSet, // Meh can actually be null i think? but makes things tough

  clusterId: number,
  directValidatorSet: Set<string>,
  indirectValidatorSet: Set<string>,
  directIncomingValidatorSet: Set<string>,
  indirectIncomingValidatorSet: Set<string>,
};

const validatorHelpers = {
  
  translatedJsonFromQuorumExplorer: function(json: any): any {
    let newValidators = [];
    for (const validatorId in json.nodes) {
      let v = json.nodes[validatorId];
      let validator = {}
      validator.publicKey = validatorId;
      validator.version = v.version_string;
      validator.verified = false;

      if ( v.address ) {
        let parts = v.address.split(':');
        validator.ip = parts[0];
        validator.port = parts[1];
      }
      else {
        validator.ip = null;
        validator.port = null;
      }

      validator.city = null;
      validator.country = null;
      validator.latitude = null;
      validator.longitude = null;

      if ( v.known_info ) {
        validator.verified = true;
        validator.name = v.known_info.name;
        validator.host = v.known_info.host;
      }

      if ( v.quorum ) {
        validator.quorumSet = translateQuorumSet(v.quorum, 'virual-hash-key');
      }
      newValidators.push(validator);
    }
    return newValidators;
  },
  
  calculateValidators: function(validators: Array<any>): Array<any> {
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


  validatorToURLId: function(publicKey: string): string {
    const chars = 6;
      if ( !publicKey ) {
        console.log('missing-pub-key');
      }

    if (publicKey.length>chars*2) {
      return publicKey.substring(0,chars) + '..' + publicKey.substring(publicKey.length - chars);
    }
    return publicKey;
  },

  quorumNodeToURLId: function(id: string): string {
    const chars = 6;
    let result = id;
    if (id && id.length>chars*2) {
      result = id.substring(0,chars) + '..' + id.substring(id.length - chars);
    }
    return encodeURIComponent(result);
  },

  validatorAndHandleForPublicKey: function(
    validators: Array<Validator>, publicKey: string): {validator: ?Validator, handle: string}
  {
    for ( let i=0; i<validators.length; i++ ) {
      if ( validators[i].publicKey === publicKey ) {
        return { validator: validators[i], handle: (i+1).toString() };
      }
    }
    return { validator: null, handle: "?" };
  },
  
  quorumNodeForURLId: function(validator: any, nodeId: string): ?any {
    if ( !validator || !validator.quorumSet || !nodeId ) {
      return null;
    }
    return quorumNodeForIdInQuorumSet(validator.quorumSet, nodeId);
  },

  sortSet: function(validators: Array<any>, set: Set<string>): Array<any> {
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

function translateQuorumSet(quorumSet: any, fakehashkey: string): any {
  let qs = {};
  qs.hashKey = fakehashkey
  qs.threshold = quorumSet.threshold;
  qs.validators = quorumSet.validators;
  qs.innerQuorumSets = [];
  for ( let i = 0; i<quorumSet.inner_sets.length; i++ ) {
    qs.innerQuorumSets.push(translateQuorumSet(quorumSet.inner_sets[i], fakehashkey+'-'+i));
  }
  return qs;
}

function directValidatorSet(validator: any): Set<any> {
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

function indirectValidatorSet(validators: Array<any>, validator: any): Set<string> {
  let touched = new Set([]);
  recurseIndirectValidators(validators, validator.publicKey, touched);
  return touched;
}

function recurseIndirectValidators(validators: Array<Validator>, validatorId: string, touched: Set<string>) {
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

function directIncomingValidatorSet(validators: Array<Validator>, validator: Validator): Set<string> {
  let set = new Set([]);
  for (let i=0; i<validators.length; i++) {
    const v = validators[i];
    if ( v.directValidatorSet.has(validator.publicKey) ) {
      set.add(v.publicKey);
    }
  }
  return set;
}

function indirectIncomingValidatorSet(validators: Array<Validator>, validator: Validator) {
  let set = new Set([]);
  for (let i=0; i<validators.length; i++) {
    const v = validators[i];
    if ( v.indirectValidatorSet.has(validator.publicKey) ) {
      set.add(v.publicKey);
    }
  }
  return set;
}

function compareValidators(a: Validator, b: Validator): number {
  const indirectIncomingDiff = b.indirectIncomingValidatorSet.size - a.indirectIncomingValidatorSet.size;
  if (indirectIncomingDiff !== 0) { return indirectIncomingDiff; }
  const indirectOutgoingDiff = b.indirectValidatorSet.size - a.indirectValidatorSet.size;
  if (indirectOutgoingDiff !== 0) { return indirectOutgoingDiff; }
  if ( a.name ) {
    if ( b.name ) {
      let aName = a.name;
      let bName = b.name;
      let aLower = aName.toLowerCase();
      let bLower = bName.toLowerCase();
      return aLower.localeCompare(bLower);
    }
    return -1;
  }
  else if (b.name) {
    return 1;
  }
  return a.publicKey.localeCompare(b.publicKey);
}

function quorumNodeForIdInQuorumSet(quorumSet: QuorumSet, nodeId: string): ?any {
  if ( !quorumSet || !nodeId ) {
    return null;
  }
  if ( validatorHelpers.quorumNodeToURLId(quorumSet.hashKey) === nodeId ) {
    return quorumSet;
  }
  for (let i=0; i<quorumSet.validators.length; i++) {
    const v = quorumSet.validators[i];
    if ( validatorHelpers.quorumNodeToURLId(v) === nodeId ) {
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
