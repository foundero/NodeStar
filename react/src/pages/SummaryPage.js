import React, { Component } from 'react';
import {
  XYPlot,
  XAxis,
  YAxis,
  VerticalGridLines,
  HorizontalGridLines,
  VerticalRectSeries
} from 'react-vis';

class SummaryPage extends Component {

  render() {
    return (
      <div className="page">
        <div className="left">
          <h3>Data</h3>
          <SummaryData validators={this.props.validators} />
        </div>

        <div className="middle-and-right">

          <h3>Outgoing Validators</h3>
          <div className='self-clear'>
            <div className='half-width'>
              Direct Outgoing
              <Graph propertyKey='directValidatorSet' validators={this.props.validators} />
            </div>
            <div className='half-width'>
              Indirect Outgoing
              <Graph propertyKey='indirectValidatorSet' validators={this.props.validators} />
            </div>
          </div>
          
          <h3>Incoming Validators</h3>
          <div className='self-clear'>
            <div className='half-width'>
              Direct Incoming
              <Graph propertyKey='directIncomingValidatorSet' validators={this.props.validators} />
            </div>
            <div className='half-width'>
              Indirect Incoming
              <Graph propertyKey='indirectIncomingValidatorSet' validators={this.props.validators} />
            </div>
          </div>
        
        </div>
      </div>
    );
  }
}

function SummaryData(props) {
  var validators = props.validators;
  if (!validators || validators.length===0) { return '...'; }
  return (
    <ul>
      <li>Source: stellarbeat.io</li>
      <li>Validators: {validators.length}</li>
      <li>Clusters: coming soon</li>
    </ul>
  );
}

function Graph(props) {
  const validators = props.validators;
  if (!validators || validators.length===0) { return '...'; }

  var data = {}
  for (var i=0; i<validators.length; i++) {
    var v = validators[i];
    var propertyValue = v[props.propertyKey].size;
    if ( propertyValue in data ) {
      data[propertyValue] = data[propertyValue] + 1;
    }
    else {
      data[propertyValue] = 1;
    }
  }

  var d = [];
  for (var graphXProperty in data) {
    // skip loop if the property is from prototype
    if (!data.hasOwnProperty(graphXProperty)) continue;

    var graphX = parseInt(graphXProperty,10);
    var graphY = data[graphXProperty];
    d.push({
      x0:graphX-0.5,
      x:graphX+0.5,
      y:graphY
    });
  }

  return (
    <XYPlot
      width={300}
      height={200}
      color={'#0099FF'}
      >
      <VerticalGridLines />
      <HorizontalGridLines />
      <XAxis
        tickTotal={6}
        style={{
          line: {stroke: '#000'},
          text: {fill: '#000', fontWeight: 600, 'fontFamily': 'sans-serif', 'fontSize':'0.6em'}
        }}/>
      <YAxis
        tickTotal={3}
        style={{
          line: {stroke: '#000'},
          text: {fill: '#000', fontWeight: 600, 'fontFamily': 'sans-serif', 'fontSize':'0.6em'}
        }}/>
      <VerticalRectSeries data={d} style={{stroke: '#fff'}}/>
    </XYPlot>
  );
}

export default SummaryPage;

