const clusterHelpers = {
  calculateClusters: function(validators) {
    let clusters = [];
    if ( !validators ) return clusters;
    clustersCreate(validators, clusters);
    clustersSort(clusters);
    clustersAddConnections(clusters);
    clusterAddLevels(clusters);
    validatorsAddCluster(validators, clusters);
    return clusters;
  }
};

/* Private functions */



function clustersCreate(validators, clusters) {
  for (let i = 0; i<validators.length; i++) {
    const v = validators[i];
    let foundCluster = matchingCluster(clusters, v);
    if ( foundCluster ) {
      foundCluster.nodes.add(v.publicKey);
    }
    else {
      clusters.push({
        nodes: new Set([v.publicKey]),
        incoming: v.indirectIncomingValidatorSet,
        outgoing: v.indirectValidatorSet
      });
    }
  }
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    cluster.incomingMinusSelf = incomingMinusSelf(cluster);
  }
}

function clustersSort(clusters) {
  clusters.sort(function(a,b) {
    const incomingMinusSelfDiff = b.incomingMinusSelf - a.incomingMinusSelf;
    if (incomingMinusSelfDiff !== 0) return incomingMinusSelfDiff;
    const incomingDiff = b.incoming.size - a.incoming.size;
    if (incomingDiff !== 0) return incomingDiff;
    const outgoingDiff = b.outgoing.size - a.outgoing.size;
    if (outgoingDiff !== 0) return outgoingDiff;
    return 0;
  });
}

function clustersAddConnections(clusters) {
  for (let i=0; i<clusters.length; i++) {
    let iCluster = clusters[i];
    iCluster.outgoingClusters = [];

    let decendentClusters = [];
    for (let potentialDecendentIndex=0; potentialDecendentIndex<clusters.length; potentialDecendentIndex++) {
      let potentialDecendent = clusters[potentialDecendentIndex];
      if ( isSuperset(iCluster.outgoing, potentialDecendent.nodes) ) {
        decendentClusters.push(potentialDecendentIndex);
      }
    }
    for (let decendentClusterIndex=0; decendentClusterIndex<decendentClusters.length; decendentClusterIndex++) {
      let potentialChildIndex = decendentClusters[decendentClusterIndex];
      let potentialChild = clusters[potentialChildIndex];
      // only add it if it's a child
      let isChild = true;
      for (let j=0; j<decendentClusters.length; j++) {
        let jDecendentIndex = decendentClusters[j];
        if (potentialChildIndex === jDecendentIndex || jDecendentIndex === i) {
          continue;
        }
        if (isSuperset(clusters[jDecendentIndex].outgoing, potentialChild.nodes)) {
          isChild = false
          break
        }
      }
      if ( isChild ) {
        iCluster.outgoingClusters.push(potentialChildIndex);
      }
    }
  }
}

function clusterAddLevels(clusters) {
  // Set them all to 1
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    cluster.level = 1;
  }
  // Set the best node to 0
  if ( clusters.length > 0 ) {
    clusters[0].level = 0;
  }

  // Mark each layer out from root
  for (let i = -1; i>=-10; i--) {
    clustersMarkLevels(clusters, i, -10);
  }
  // Compute min and set all no-incoming to that row
  let min = 0;
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    if (cluster.incomingMinusSelf > 0) {
      if ( cluster.level <= min ) {
        min = cluster.level-1;
      }
    }
  }
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    if ( cluster.level < min ) {
      cluster.level = min;
    }
    if (cluster.incomingMinusSelf === 0) {
      cluster.level = min;
    }
  }
}

function clustersMarkLevels(clusters, level, min) {
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    if (cluster.level >= level & cluster.level !== 1 ) continue;
    let allOutgoingMarked = true;
    for (let j = 0; j<cluster.outgoingClusters.length; j++) {
      let jIndex = cluster.outgoingClusters[j];
      if ( jIndex === i ) {
        continue;
      }
      let jLevel = clusters[jIndex].level;
      if ( jLevel === 1 || jLevel === level ) {
        allOutgoingMarked = false;
        break;
      }
    }
    if ( allOutgoingMarked || level === min ) {
      cluster.level = level;
    }
  }
}

function validatorsAddCluster(validators, clusters) {
  for (let v = 0; v<validators.length; v++) {
    let validator = validators[v];
    for (let c = 0; c<clusters.length; c++) {
      let cluster = clusters[c];
      if (cluster.nodes.has(validator.publicKey)) {
        validator.clusterId = c+1;
        break;
      }
    }
  }
}

function incomingMinusSelf(cluster) {
  let count = cluster.incoming.size;
  if ( isSuperset(cluster.outgoing, cluster.nodes) ) {
    count -= cluster.nodes.size;
  }
  return count;
}

function matchingCluster(clusters, validator) {
  for (let i=0; i<clusters.length; i++) {
    let cluster = clusters[i];
    if (
      eqSet(cluster.incoming, validator.indirectIncomingValidatorSet) &&
      eqSet(cluster.outgoing, validator.indirectValidatorSet))
    {
      return cluster;
    }
  }
  return null;
}

function eqSet(a,b) {
  if ( a.size !== b.size ) return false;
  return isSuperset(a,b);
}

function isSuperset(a,b) {
  for ( let bItem of b) if (!a.has(bItem)) return false;
  return true;
}


export default clusterHelpers;

