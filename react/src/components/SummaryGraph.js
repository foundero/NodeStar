import React from 'react';
import {
  XYPlot,
  XAxis,
  YAxis,
  VerticalGridLines,
  HorizontalGridLines,
  VerticalRectSeries
} from 'react-vis';

function SummaryGraph(props) {
  const {
    validators
  } = props;
  if (!validators || validators.length===0) { return '...'; }

  let data = {}
  for (let i=0; i<validators.length; i++) {
    const v = validators[i];
    const propertyValue = v[props.propertyKey].size;
    if ( propertyValue in data ) {
      data[propertyValue] = data[propertyValue] + 1;
    }
    else {
      data[propertyValue] = 1;
    }
  }

  let d = [];
  for (let graphXProperty in data) {
    // skip loop if the property is from prototype
    if (!data.hasOwnProperty(graphXProperty)) continue;
    const graphX = parseInt(graphXProperty,10);
    const graphY = data[graphXProperty];
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

export default SummaryGraph