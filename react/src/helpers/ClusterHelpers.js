// @flow
import type {Validator} from './ValidatorHelpers.js';

export type Cluster = {
  nodes: Set<string>,
  incoming: Set<string>,
  outgoing: Set<string>,
  incomingMinusSelf: number,
  level: number,
  outgoingClusters: Array<number>
}

const clusterHelpers = {
  calculateClusters: function(validators: Array<Validator>): Array<Cluster> {
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



function clustersCreate(validators: Array<Validator>, clusters: Array<Cluster>) {
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
        outgoing: v.indirectValidatorSet,
        incomingMinusSelf: 0,
        level: -999,
        outgoingClusters: []
      });
    }
  }
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    cluster.incomingMinusSelf = incomingMinusSelf(cluster);
  }
}

function clustersSort(clusters: Array<Cluster>) {
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

function clustersAddConnections(clusters: Array<Cluster>) {
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

function clusterAddLevels(clusters: Array<Cluster>) {
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
      cluster.level = min-1;
    }
    if (cluster.incomingMinusSelf === 0) {
      cluster.level = min;
      if (cluster.incoming.size === 0) {
        cluster.level = min-1;
      }
    }
    if (cluster.outgoing.size === 0 && i!==0) {
      cluster.level = min-1;
    }
  }
  // Make sure each cluster is above it's incoming one
  for (let i = 0; i<clusters.length; i++) {
    if (clusters[i].incomingMinusSelf !== 0) {
      for (let j = 0; j<clusters.length; j++) {
        let iPointsToj = false;
        for (let k=0; k<clusters[j].outgoingClusters.length; k++) {
          if (clusters[j].outgoingClusters[k] === i) {
            iPointsToj = true;
            break;
          }
        }
        if ( j!==i && iPointsToj && clusters[j].level >= clusters[i].level) {
          clusters[i].level = clusters[j].level + 1;
        }
      }
    }
  }
}

function clustersMarkLevels(clusters: Array<Cluster>, level: number, min: number) {
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    if (cluster.level >= level && cluster.level !== 1 ) continue;
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

function validatorsAddCluster(validators: Array<Validator>, clusters: Array<Cluster>) {
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

function incomingMinusSelf(cluster: Cluster): number {
  let count = cluster.incoming.size;
  if ( isSuperset(cluster.outgoing, cluster.nodes) ) {
    count -= cluster.nodes.size;
  }
  return count;
}

function matchingCluster(clusters: Array<Cluster>, validator: Validator): ?Cluster {
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

function eqSet(a: Set<any>, b: Set<any>): boolean {
  if ( a.size !== b.size ) return false;
  return isSuperset(a,b);
}

function isSuperset(a: Set<any>, b: Set<any>): boolean {
  for ( let bItem of b) if (!a.has(bItem)) return false;
  return true;
}


export default clusterHelpers;

