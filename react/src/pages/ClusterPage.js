import React, { Component } from 'react';
import ValidatorRow from '../components/ValidatorRow.js';
import RelatedValidators from '../components/RelatedValidators.js';
import ClusterViewer from '../components/ClusterViewer.js';
import validatorHelper from '../helpers/ValidatorHelper.js';

class ClusterPage extends Component {

  handleSelectedClusterNode(id) {
    let newPath = null;
    if ( id === null  ) {
      newPath = '/clusters'
    }
    else {
      newPath = '/clusters/' + (id);
    }
    if ( newPath === this.props.location.pathname ) { return; }

    this.props.onStoreRoutePath('clusters', newPath);
    this.props.history.push(newPath);
  }

  handleValidatorClick(validatorId) {
    const newPath = '/validators/' + validatorId
    if ( newPath === this.props.location.pathname ) { return; }
    this.props.history.push(newPath);
  }

  selectDefault() {
    if (!this.selectedClusterId() && this.props.validators.length > 0) {
      const newPath = '/clusters/1'
      this.props.onStoreRoutePath('clusters', newPath);
      this.props.history.push(newPath);
    }
  }

  selectedClusterId() {
    return this.props.match.params.clusterId;
  }


  render() {
    const {
      validators
    } = this.props;

    let clusters = calculateClusters();
    let validatorsInCluster = [];
    let validator = null;
    let validatorId = null;
    const tempSelectedClusterId = this.selectedClusterId();
    let selectedClusterId = null;
    if ( validators.length > 0 ) {
      clusters = calculateClusters(validators);
      if ( tempSelectedClusterId && tempSelectedClusterId <= clusters.length ) {
        selectedClusterId = tempSelectedClusterId;
        const cluster = clusters[selectedClusterId-1];
        validatorsInCluster = Array.from(cluster.nodes);
        validatorId = validatorsInCluster[0];
        validator = validatorHelper.validatorAndHandleForPublicKey(validators, validatorId).validator;
      }
    }

    return (
      <div className="page">
        <div className="left">
          <h3>Validators in Cluster</h3>
          <ul>
            { validatorsInCluster.map( (validatorId) =>
              <ValidatorRow
                key={validatorId}
                validators={this.props.validators}
                validatorId={validatorId}
                selectedValidator={null}
                onClick={() => this.handleValidatorClick(validatorId)} />
            )}
          </ul>
        </div>

        <div className="middle">
          <div className="card-tall">
            <h2>Clusters</h2>
            <ClusterViewer
              clusters={clusters}
              selectedClusterId={selectedClusterId}
              onSelectClusterNode={(id) => this.handleSelectedClusterNode(id)}
            />
          </div>
        </div>
        
        <RelatedValidators
          validators={this.props.validators}
          validator={validator}
          onClick={(v) => this.handleValidatorClick(v)}
          forCluster={true} />  
      </div>
    );
  }

  componentWillMount() {
    this.props.onStoreRoutePath('clusters', this.props.location.pathname);
    this.selectDefault();
  }
  componentDidUpdate() {
    this.selectDefault();
  }

}

/* Private Functions */

function calculateClusters(validators) {
  let clusters = [];
  if ( !validators ) return clusters;
  clustersCreate(validators, clusters);
  clustersSort(clusters);
  clustersAddConnections(clusters);
  clusterAddLevels(clusters);
  return clusters;
}

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
    markLevels(clusters, i, -10);
  }
  // Compute min and set all no-incoming to that row
  let min = 0;
  for (let i = 0; i<clusters.length; i++) {
    let cluster = clusters[i];
    if (incomingMinusSelf(cluster) > 0) {
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
    if (incomingMinusSelf(cluster) === 0) {
      cluster.level = min;
    }
  }
}

function markLevels(clusters, level, min) {
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

export default ClusterPage;

