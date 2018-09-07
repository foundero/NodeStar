// @flow
import React, { PureComponent } from 'react';
import QuorumViewer from '../components/QuorumViewer.js';
import ValidatorRow from '../components/ValidatorRow.js';
import ValidatorDetail from '../components/ValidatorDetail.js';
import QuorumNodeDetail from '../components/QuorumNodeDetail.js';
import RelatedValidators from '../components/RelatedValidators.js';
import validatorHelpers from '../helpers/ValidatorHelpers.js';

import type {Validator} from '../helpers/ValidatorHelpers.js';

type Props = {
  match: any,
  history: any,
  location: any,

  validators: Array<Validator>
};

class ValidatorPage extends PureComponent<Props> {

  selectDefault() {
    const validators = this.props.validators;
    if (!this.props.match.params.publicKey && !this.selectedValidator() &&  validators.length > 0) {
      const newPath = '/validators/' + validatorHelpers.validatorToURLId(this.props.validators[0].publicKey);
      this.props.history.push({pathname: newPath, search: this.props.location.search});
    }
  }

  selectedValidator(): ?Validator {
    const validators = this.props.validators;
    if ( !this.props.match.params.publicKey ) return null;
    for ( let i=0; i<validators.length; i++ ) {
      if ( validatorHelpers.validatorToURLId(validators[i].publicKey) ===
        validatorHelpers.validatorToURLId(this.props.match.params.publicKey) )
      {
        return validators[i];
      }
    }
    return null;
  }

  selectedQuorumNode(): ?string {
    const quorumNodeId = this.props.match.params.quorumNodeId;
    return validatorHelpers.quorumNodeForURLId(this.selectedValidator(), quorumNodeId);
  }

  handleSelectedQuorumNode(id: string) {
    let newPath = null;
    if ( id === null  ) {
      newPath = '/validators/' + this.props.match.params.publicKey;
    }
    else {
      const quorumNodeId = validatorHelpers.quorumNodeToURLId(id);
      newPath = '/validators/' + this.props.match.params.publicKey + '/quorum-node/' + quorumNodeId;
    }
    if ( newPath !== this.props.location.pathname ) {
      this.props.history.push({pathname: newPath, search: this.props.location.search});
    }
  }

  render() {
    console.log('render ValidatorPage');
    const selectedValidator = this.selectedValidator();
    const selectedNode = this.selectedQuorumNode();

    return (
      <div className="page">
        <div className="left">
          <h3>Validators</h3>
          <ul>
            { this.props.validators.map( (validator) =>
              <ValidatorRow
                key={validator.publicKey}
                validators={this.props.validators}
                validatorId={validator.publicKey}
                location={this.props.location} />
            )}
          </ul>
        </div>

        <div className="middle">
          <div className="card">
          <h2>Validator</h2>
            <ValidatorDetail
              location={this.props.location}
              validators={this.props.validators}
              validator={selectedValidator} />
          </div>

          <div>
            <h3>Quorum Set</h3>
            <QuorumViewer validators={this.props.validators}
                          validator={selectedValidator}
                          onSelectQuorumNode={(id) => this.handleSelectedQuorumNode(id)}
                          selectedQuorumNode={selectedNode} />
          </div>

          <div className="card">
            <QuorumNodeDetail validators={this.props.validators} validator={selectedValidator} node={selectedNode}/>
            
          </div>
        </div>
        
        <RelatedValidators
          validators={this.props.validators}
          validator={selectedValidator}
          location={this.props.location}/>  
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

export default ValidatorPage;

