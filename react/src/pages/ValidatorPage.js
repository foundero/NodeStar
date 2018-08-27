import React, { Component } from 'react';
import QuorumViewer from '../components/QuorumViewer.js';
import ValidatorRow from '../components/ValidatorRow.js';
import ValidatorDetail from '../components/ValidatorDetail.js';
import QuorumNodeDetail from '../components/QuorumNodeDetail.js';
import validatorHelper from '../ValidatorHelper.js';
import { SegmentedControl } from 'segmented-control';
import update from 'immutability-helper';


class ValidatorPage extends Component {
  constructor(props) {
    super(props);
    this.state = {
      directToggle: true,
      outgoingToggle: true
    };
  }
  directToggle(isDirect) {
    this.setState(
      update(this.state, {
        directToggle: {$set: isDirect}
      })
    );
  }
  outgoingToggle(isOutgoing) {
    this.setState(
      update(this.state, {
        outgoingToggle: {$set: isOutgoing}
      })
    );
  }

  selectDefault() {
    var validators = this.props.validators;
    if (!this.selectedValidator() &&  validators.length > 0) {
      var newPath = '/validators/' + this.props.validators[0].publicKey
      this.props.onStoreRoutePath('validators', newPath);
      this.props.history.push(newPath);
    }
  }

  selectedValidator() {
    var validators = this.props.validators;
    for ( var i=0; i<validators.length; i++ ) {
      if ( validators[i].publicKey === this.props.match.params.publicKey ) {
        return validators[i];
      }
    }
    return null;
  }

  selectedQuorumNode() {
    var quorumNodeId = decodeURIComponent(this.props.match.params.quorumNodeId);
    return validatorHelper.quorumNodeForId(this.selectedValidator(), quorumNodeId);
  }

  handleValidatorClick(validatorId) {
    var newPath = '/validators/' + validatorId
    if ( newPath === this.props.location.pathname ) { return; }
    this.props.onStoreRoutePath('validators', newPath);
    this.props.history.push(newPath);
  }
  handleSelectedQuorumNode(id) {
    var newPath = null;
    if ( id === null  ) {
      newPath = '/validators/' + this.props.match.params.publicKey;
    }
    else {
      var quorumNodeId = encodeURIComponent(id);
      newPath = '/validators/' + this.props.match.params.publicKey + '/quorum-node/' + quorumNodeId;
    }
    if ( newPath === this.props.location.pathname ) { return; }
    this.props.onStoreRoutePath('validators', newPath);
    this.props.history.push(newPath);
  }

  render() {
    const selectedValidator = this.selectedValidator();
    const selectedNode = this.selectedQuorumNode();
    var relatedValidators = [];
    if (selectedValidator) {
      var set = null;
      if (this.state.directToggle) {
        if (this.state.outgoingToggle) {
          set = selectedValidator.directValidatorSet;
        }
        else {
          set = selectedValidator.directIncomingValidatorSet;
        }
      }
      else {
        if (this.state.outgoingToggle) {
          set = selectedValidator.indirectValidatorSet;
        }
        else {
          set = selectedValidator.indirectIncomingValidatorSet;
        }
      }
      relatedValidators = validatorHelper.sortSet(this.props.validators, set);
    }

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
                selectedValidator={selectedValidator}
                onClick={() => this.handleValidatorClick(validator.publicKey)}/>
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
          
        <div className="right">
          <h3>Related Validators</h3>
          <SegmentedControl
            name="directToggle"
            options={[
              { label: "indirect", value: false },
              { label: "direct", value: true, default: true}
            ]}
            setValue={newValue => this.directToggle(newValue)}
            style={{ width: '200px', color: '#0099FF', margin: '0px' }}
          />
          <SegmentedControl
            name="outgoingToggle"
            options={[
              { label: "incoming", value: false},
              { label: "outgoing", value: true, default: true }
            ]}
            setValue={newValue => this.outgoingToggle(newValue)}
            style={{ width: '200px', color: '#0099FF', margin: '0px' }}
          />

          <ul>
            { relatedValidators.map( (validatorId) =>
              <ValidatorRow
                key={validatorId}
                validators={this.props.validators}
                validatorId={validatorId}
                selectedValidator={selectedValidator}
                onClick={() => this.handleValidatorClick(validatorId)}/>
            )}
          </ul>

        </div>
      </div>
    );
  }

  componentWillMount() {
    this.props.onStoreRoutePath('validators', this.props.location.pathname);
    this.selectDefault();
  }
  componentDidUpdate() {
    this.selectDefault();
  }
}

export default ValidatorPage;

