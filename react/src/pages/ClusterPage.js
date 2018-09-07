// @flow
import React, { PureComponent } from 'react';
import ValidatorRow from '../components/ValidatorRow.js';
import RelatedValidators from '../components/RelatedValidators.js';
import ClusterViewer from '../components/ClusterViewer.js';
import validatorHelpers from '../helpers/ValidatorHelpers.js';

import type {Validator} from '../helpers/ValidatorHelpers.js';
import type {Cluster} from '../helpers/ClusterHelpers.js';

type Props = {
  match: any,
  history: any,
  location: any,

  validators: Array<Validator>,
  clusters: Array<Cluster>
};

class ClusterPage extends PureComponent<Props> {

  handleSelectedClusterNode(id: string) {
    let newPath = null;
    if ( id === null  ) {
      newPath = '/clusters'
    }
    else {
      newPath = '/clusters/' + (id);
    }
    if ( newPath === this.props.location.pathname ) { return; }

    this.props.history.push({pathname: newPath, search: this.props.location.search});
  }

  selectDefault() {
    if (!this.selectedClusterId() && this.props.validators.length > 0) {
      const newPath = '/clusters/1'
      this.props.history.push({pathname: newPath, search: this.props.location.search});
    }
  }

  selectedClusterId() {
    return this.props.match.params.clusterId;
  }


  render() {
    console.log('render ClusterPage');
    const {
      validators,
      clusters,
      location
    } = this.props;

    let validatorsInCluster = [];
    let validator = null;
    let validatorId = null;
    const tempSelectedClusterId = this.selectedClusterId();
    let selectedClusterId = null;
    let selectedCluster = null;
    if ( validators.length > 0 ) {
      if ( tempSelectedClusterId && tempSelectedClusterId <= clusters.length ) {
        selectedClusterId = tempSelectedClusterId;
        selectedCluster = clusters[selectedClusterId-1];
        validatorsInCluster = Array.from(selectedCluster.nodes);
        validatorId = validatorsInCluster[0];
        validator = validatorHelpers.validatorAndHandleForPublicKey(validators, validatorId).validator;
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
                location={location} />
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
            <h3>Cluster Detail</h3>
            <ul>
            { selectedCluster === null &&
              <li>None selected...</li>
            }
            { selectedCluster !== null &&
              <React.Fragment>
                <li>Validators In Cluster: {selectedCluster.nodes.size}</li>
                <li>Outgoing Validators: {selectedCluster.outgoing.size}</li>
                <li>Incoming Validators: {selectedCluster.incoming.size}</li>
                <li>
                  References Self:
                  {String(selectedCluster.incoming.size !== selectedCluster.incomingMinusSelf)}
                </li>
              </React.Fragment>
            }
            </ul>
          </div>
        </div>
        
        <RelatedValidators
          validators={this.props.validators}
          validator={validator}
          forCluster={true}
          location={location} />  
      </div>
    );
  }

  componentWillMount() {
    this.selectDefault();
  }
  componentDidUpdate() {
    this.selectDefault();
  }

}

export default ClusterPage;

