import React, { Component } from 'react';
import QuorumGraph from '../components/QuorumViewer.js'

class ClusterPage extends Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedValidator: null
    };
  }

  handleClick(i) {
    this.setState({
      'selectedValidator': this.props.validators[i]
    });
  }

  render() {
    return (
      <div className="page">
        <div className="left">
          <h3>Validators in Cluster</h3>
          {this.props.validators != null &&
          <ul>
            {
              this.props.validators.map( (item,index) =>
                <li key={item.publicKey}>
                  {index+1}. {item.name ? item.name : "[name]" }
                  </li>
              )}
          </ul>
          }
        </div>

        <div className="middle">
          <h3>Cluster Detail</h3>
          <p>Coming Soon...</p>
          <h3>Clusters</h3>
          <QuorumGraph validators={this.props.validators} validator={this.state.selectedValidator} />
        </div>
          
        <div className="right">
          <h3>Related Validators</h3>
          <p>Coming Soon...</p>
        </div>
      </div>
    );
  }
}

export default ClusterPage;

