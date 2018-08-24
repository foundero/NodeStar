import React, { Component } from 'react';
import QuorumGraph from '../components/QuorumViewer.js'

class ValidatorPage extends Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedValidator: null
    };
  }

  handleClick(i) {
    console.log('clicked: '+(i+1));
    this.setState({
      'selectedValidator': this.props.validators[i]
    });
  }

  render() {
    console.log('render Validator Page')
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
                    className={item === this.state.selectedValidator ? 'active' : 'not-active'}
                  >
                  {index+1}. {item.name ? item.name : "[name]" }
                  </li>
              )}
          </ul>
          }
        </div>

        <div className="middle">
          <h3>Validator Detail</h3>
          <p>Coming Soon...</p>
          <h3>Quorum Set</h3>
          <QuorumGraph validators={this.props.validators} validator={this.state.selectedValidator} />
          <h3>Node Impact</h3>
          <p>Coming Soon...</p>
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

