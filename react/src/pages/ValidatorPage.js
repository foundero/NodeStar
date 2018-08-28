import React, { PureComponent } from 'react';
import QuorumViewer from '../components/QuorumViewer.js';
import ValidatorRow from '../components/ValidatorRow.js';
import ValidatorDetail from '../components/ValidatorDetail.js';
import QuorumNodeDetail from '../components/QuorumNodeDetail.js';
import RelatedValidators from '../components/RelatedValidators.js';
import validatorHelpers from '../helpers/ValidatorHelpers.js';


class ValidatorPage extends PureComponent {

  selectDefault() {
    const validators = this.props.validators;
    if (!this.props.match.params.publicKey && !this.selectedValidator() &&  validators.length > 0) {
      const newPath = '/validators/' + this.props.validators[0].publicKey;
      this.props.history.push(newPath);
    }
  }

  selectedValidator() {
    const validators = this.props.validators;
    for ( let i=0; i<validators.length; i++ ) {
      if ( validators[i].publicKey === this.props.match.params.publicKey ) {
        return validators[i];
      }
    }
    return null;
  }

  selectedQuorumNode() {
    const quorumNodeId = decodeURIComponent(this.props.match.params.quorumNodeId);
    return validatorHelpers.quorumNodeForId(this.selectedValidator(), quorumNodeId);
  }

  handleSelectedQuorumNode(id) {
    let newPath = null;
    if ( id === null  ) {
      newPath = '/validators/' + this.props.match.params.publicKey;
    }
    else {
      const quorumNodeId = encodeURIComponent(id);
      newPath = '/validators/' + this.props.match.params.publicKey + '/quorum-node/' + quorumNodeId;
    }
    if ( newPath === this.props.location.pathname ) { return; }
    this.props.history.push(newPath);
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
                validatorId={validator.publicKey} />
            )}
          </ul>
        </div>

        <div className="middle">
          <div className="card">
          <h2>Validator</h2>
            <ValidatorDetail validators={this.props.validators} validator={selectedValidator} />
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
          validator={selectedValidator} />  
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

