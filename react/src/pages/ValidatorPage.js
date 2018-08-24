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
    if ( validators.length > 0 && this.props.match.params.publicKey == null ) {
      this.props.history.push('/validators/' + validators[0].publicKey);
    }
    return null;
  }

  handleClick(i) {
    this.props.history.push('/validators/' + this.props.validators[i].publicKey);
  }

  render() {
    console.log('render Validator Page');
    const selectedValidator = this.selectedValidator();
    return (
      <div className="page">
        <div className="left">
          <h3>Validators</h3>
          {this.props.validators != null &&
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
            { selectedValidator != null &&
              <ul>
                <li className='bold'>
                  {validatorHelper.validatorHandleForPublicKey(this.props.validators, selectedValidator.publicKey)}.
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
          <QuorumViewer validators={this.props.validators} validator={this.selectedValidator()} />
          </div>

          <div className="card">
          <h3>Node Impact</h3>
          <p>Coming Soon...</p>
          </div>
        </div>
          
        <div className="right">
          <h3>Related Validators</h3>
          <p>Coming Soon...</p>
        </div>
      </div>
    );
  }
}

export default ValidatorPage;

