import React, { Component } from 'react';
import QuorumViewer from '../components/QuorumViewer.js'
import validatorHelper from '../ValidatorHelper.js';
import verified from '../media/images/icon-verified.png';

class ValidatorPage extends Component {

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
    return validatorHelper.quorumNodeForId(this.selectedValidator(), decodeURIComponent(this.props.match.params.quorumNodeId));
  }

  handleClick(i) {
    var newPath = '/validators/' + this.props.validators[i].publicKey
    if ( newPath === this.props.location.pathname ) { return; }
    this.props.onStoreRoutePath('validators', newPath);
    this.props.history.push(newPath);
  }
  handleSelectedQuorumNode(id) {
    var newPath = null;
    if ( id === null || id.length === 0 ) {
      newPath = '/validators/' + this.props.match.params.publicKey;
    }
    else {
      newPath = '/validators/' + this.props.match.params.publicKey + '/quorum-node/' + encodeURIComponent(id[0]);
    }
    if ( newPath === this.props.location.pathname ) { return; }
    this.props.onStoreRoutePath('validators', newPath);
    this.props.history.push(newPath);
  }

  render() {
    const selectedValidator = this.selectedValidator();
    const selectedNode = this.selectedQuorumNode();
    var selectedNodeName = null;
    var selectedNodeId = null;
    var selectedNodeIdString = null;
    if ( selectedNode ) {
      selectedNodeId = selectedNode.hashKey;
      selectedNodeName = "Inner Quorum Set";
      selectedNodeIdString = selectedNode.hashKey ?
        "qsh: " + selectedNode.hashKey :
        "pk: " + selectedNode.publicKey;
      if ( selectedNode.publicKey ) {
        selectedNodeId = selectedNode.publicKey;
        const {validator, handle} = validatorHelper.validatorAndHandleForPublicKey(this.props.validators,
          selectedNode.publicKey);
        if ( validator ) {
          selectedNodeName = handle + ". " + (validator.name ? validator.name : "[name]");
        }
        else {
          selectedNodeName = "?. [uknown validator]";
        }
      }
      else if ( selectedNode.hashKey === selectedValidator.quorumSet.hashKey ) {
        selectedNodeName = "Root Quorum Set";
      }
      
    }
    
    return (
      <div className="page">
        <div className="left">
          <h3>Validators</h3>
          {this.props.validators !== null &&
          <ul>
            {
              this.props.validators.map( (item,index) =>
                <li key={item.publicKey}
                    onClick={() => this.handleClick(index)}
                    className={item === selectedValidator ? 'active' : 'not-active'}
                  >
                  {index+1}. {item.name ? item.name : "[name]" }
                  </li>
              )}
          </ul>
          }
        </div>

        <div className="middle">
          <div className="card">
          <h2>Validator</h2>
            { selectedValidator !== null &&
              <ul>
                <li className='bold'>
                  {validatorHelper.validatorAndHandleForPublicKey(this.props.validators, 
                    selectedValidator.publicKey).handle}.
                  {' '}
                  {selectedValidator.name ? selectedValidator.name : "[name]"}
                  {selectedValidator.verified ?
                    <img src={verified} className="verified-icon" alt="Verified Icon" />
                    :
                    ''
                  }
                </li>
                <li>
                  {selectedValidator.city ? selectedValidator.city : "[city]"}
                  {", "}
                  {selectedValidator.country ? selectedValidator.country : "[country]"}</li>
                <li>{selectedValidator.latitude}, {selectedValidator.longitude}</li>
                <li>
                  {selectedValidator.ip}
                  {selectedValidator.host ? ", " + selectedValidator.host : ""}
                </li>
                <li className='small'>{selectedValidator.version}</li>
                <li className='small'>PK: {selectedValidator.publicKey}</li>
              </ul>
            }
          </div>

          <div>
          <h3>Quorum Set</h3>
          <QuorumViewer validators={this.props.validators}
                        validator={this.selectedValidator()}
                        onSelectQuorumNode={(id) => this.handleSelectedQuorumNode(id)}
                        selectedQuorumNode={selectedNodeId} />
          </div>

          <div className="card">
            <h3>Quorum Node Impact</h3>
            {selectedNode === null &&
              <ul>
                <li className='bold'>None selected...</li>
                <li className='small'>{selectedNodeIdString}</li>
              </ul>
            }
            {selectedNode !== null &&
              <ul>
                <li className='bold'>{selectedNodeName}</li>
                <li className='small'>{selectedNodeIdString}</li>
              </ul>
            }
            
          </div>
        </div>
          
        <div className="right">
          <h3>Related Validators</h3>
          <p>Coming Soon...</p>
        </div>
      </div>
    );
  }

  componentDidUpdate() {
    if (!this.selectedValidator()) {
      var validators = this.props.validators;
      if ( validators.length > 0 && this.props.match.params.publicKey == null ) {
        this.props.history.push('/validators/' + validators[0].publicKey);
      }
    }
  }
}

export default ValidatorPage;

