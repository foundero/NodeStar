import React, { PureComponent } from 'react';
import SummaryGraph from '../components/SummaryGraph.js'
import { NavLink } from "react-router-dom";

class SummaryPage extends PureComponent {

  render() {
    console.log('render SummaryPage');
    return (
      <div className="page">
        <div className="left">
          <h3>Data</h3>
          <SummaryData {...this.props} />
        </div>

        <div className="middle-and-right">

          <h3>Outgoing Validators</h3>
          <div className='self-clear'>
            <div className='half-width'>
              Direct Outgoing
              <SummaryGraph propertyKey='directValidatorSet' validators={this.props.validators} />
            </div>
            <div className='half-width'>
              Indirect Outgoing
              <SummaryGraph propertyKey='indirectValidatorSet' validators={this.props.validators} />
            </div>
          </div>
          
          <h3>Incoming Validators</h3>
          <div className='self-clear'>
            <div className='half-width'>
              Direct Incoming
              <SummaryGraph propertyKey='directIncomingValidatorSet' validators={this.props.validators} />
            </div>
            <div className='half-width'>
              Indirect Incoming
              <SummaryGraph propertyKey='indirectIncomingValidatorSet' validators={this.props.validators} />
            </div>
          </div>
        
        </div>
      </div>
    );
  }
}

function SummaryData(props) {
  const {
    datasource,
    validators,
    clusters
  } = props;

  if (!validators || validators.length===0) { return '...'; }
  return (
    <ul>
      { datasource === 'stellarbeat' &&
        <li><a href="https://stellarbeat.io">Data Source: stellarbeat.io</a></li>
      }
      { datasource !== 'stellarbeat' &&
        <li><a href="http://quorumexplorer.com/">Data Source: quorumexplorer.com</a></li>
      }
      <li><NavLink to="/validators">Validator Count: {validators.length}</NavLink></li>
      <li><NavLink to="/clusters">Cluster Count: {clusters.length}</NavLink></li>
    </ul>
  );
}

export default SummaryPage;

