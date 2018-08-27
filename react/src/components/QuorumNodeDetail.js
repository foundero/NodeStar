import React from 'react';
import validatorHelper from '../ValidatorHelper.js';
import {
  XYPlot,
  XAxis,
  YAxis,
  VerticalGridLines,
  HorizontalGridLines,
  VerticalBarSeries
} from 'react-vis';

function QuorumNodeDetail(props) {
  const validators = props.validators;
  const validator = props.validator;
  const node = props.node;

  if (!node) {
    return (
      <ul>
        <li className='bold'>No quorum set node selected.</li>
      </ul>
    );
  }

  let name = '';
  let idString = '';
  if (node.publicKey) {
      idString = "pk: " + node.publicKey
      const {validator, handle} = validatorHelper.validatorAndHandleForPublicKey(validators, node.publicKey);
      if (validator) {
        name = handle + ". " + (validator.name ? validator.name : "[name]");
      }
      else {
        name = "?. [Uknown Validator]";
      }
  }
  else if ( node.hashKey === validator.quorumSet.hashKey ) {
    idString = "qsh: " + node.hashKey;
    name = "Root Quorum Set";
  }
  else {
    idString = "qsh: " + node.hashKey;
    name = "Inner Quorum Set";
  }

  const BarSeries = VerticalBarSeries;

  var impact = impactOfNode(node, validator.quorumSet);
  impact.falsesGivenNodeTrue = impact.combinations - impact.truthsGivenNodeTrue;
  impact.falsesGivenNodeFalse = impact.combinations - impact.truthsGivenNodeFalse;
  impact.effected = impact.truthsGivenNodeTrue + impact.falsesGivenNodeFalse - impact.combinations;
  impact.affect = 100 * impact.effected / impact.combinations;
  impact.require = 100 * impact.effected / impact.truthsGivenNodeTrue;
  impact.influence = 100 * impact.effected / impact.falsesGivenNodeFalse;

  return (
    <div>

      <ul>
        <li className='bold'>
          {name}
        </li>
        {node.threshold &&
          <li>{node.threshold}/{node.validators.length+node.innerQuorumSets.length}</li>
        }
        <li className='small'>
          {idString}
        </li>
      </ul>

      <div style={{'width':'300px','marginLeft':'70px'}}>
        <XYPlot
          xType="ordinal"
          width={300}
          height={200}
          color={'#0099FF'}
          yDomain={[0, 100]}
          >
          <VerticalGridLines />
          <HorizontalGridLines />
          <XAxis
            style={{
              line: {stroke: '#000'},
              text: {fill: '#000', fontWeight: 600, 'fontFamily': 'sans-serif', 'fontSize':'0.8em'}
          }}/>
          <YAxis
            tickTotal={3}
            tickFormat={v => v+'%'}
            style={{
              line: {stroke: '#000'},
              text: {fill: '#000', fontWeight: 600, 'fontFamily': 'sans-serif', 'fontSize':'0.6em'}
          }}/>
          <BarSeries
            data={[
              {x: 'Affect', y: impact.affect},
              {x: 'Require', y: impact.require},
              {x: 'Influence', y: impact.influence}
            ]}/>
        </XYPlot>
      </div>

      <ul>
        <li className='bold'>Effected: {impact.effected}</li>
        <li className='bold'>Affect: {impact.affect}</li>
        <li className='bold'>Require: {impact.require}</li>
        <li className='bold'>Influence: {impact.influence}</li>
        <li>Combinations: {impact.combinations}</li>
        <li>True | Node True: {impact.truthsGivenNodeTrue}</li>
        <li>True | Node False: {impact.truthsGivenNodeFalse}</li>
        <li>False | Node True: {impact.falsesGivenNodeTrue}</li>
        <li>False | Node False: {impact.falsesGivenNodeFalse}</li>
      </ul>

    </div>
  );
}

let cache = {};
function impactOfNode(subjectNode, onNode) {
  // Check Cache
  if ( cache[idForNode(onNode)] && cache[idForNode(onNode)][idForNode(subjectNode)] )  {
    return cache[idForNode(onNode)][idForNode(subjectNode)];
  }
        
  let metrics = {
    combinations: 0, // Combinations, given node truthiness
    truthsGivenNodeTrue: 0,
    truthsGivenNodeFalse: 0
  };

  if ( idForNode(subjectNode) === idForNode(onNode) )  {
    // Impact of self on self is identity metrics
    metrics.combinations = 1;
    metrics.truthsGivenNodeTrue = 1;
    metrics.truthsGivenNodeFalse = 0;
    return metrics
  }
        
  // Split leafs from inner qs at this level and remove subject validator
  let validatorNodes = []
  let quorumSetNodes = []
  let includesSubjectValidator = 0
  for (let i=0; i<onNode.validators.length; i++) {
    let v = onNode.validators[i];
    if ( subjectNode.publicKey === v ) {
      includesSubjectValidator = 1;
    }
    else {
      validatorNodes.push({publicKey: v});
    }
  }
  for (let i=0; i<onNode.innerQuorumSets.length; i++) {
    let qs = onNode.innerQuorumSets[i];
    if ( qs.hashKey === subjectNode.hashKey ) {
      includesSubjectValidator = 1;
    }
    else {
      quorumSetNodes.push(qs);
    }
  }


  // Combinations
  metrics.combinations = Math.pow(2,validatorNodes.length);
  for (let i=0; i<quorumSetNodes.length; i++) {
    var qsNode = quorumSetNodes[i];
    metrics.combinations *= impactOfNode(subjectNode, qsNode).combinations
  }
        
  // For all combinations of qs nodes t/f -- represented by bits in i
  for (let i = 0; i < Math.pow(2,quorumSetNodes.length); i++) {
    let trueQSNodes = bitcount(i);
    let neededValidators = onNode.threshold - trueQSNodes - includesSubjectValidator;
    if ( neededValidators < 0 ) {
        neededValidators = 0;
    }
    if ( neededValidators > validatorNodes.length ) {
        continue;
    }

    for (let trueValidators = neededValidators; trueValidators<=validatorNodes.length; trueValidators++) {
      let binomialTerm = binomial(validatorNodes.length, trueValidators);
      let truthsGivenNodeTrue = 0
      let truthsGivenNodeFalse = 0

      // Given validator true
      if ( trueQSNodes + trueValidators + includesSubjectValidator >= onNode.threshold ) {
        truthsGivenNodeTrue = binomialTerm;
      }
      // Given validator false
      if ( trueQSNodes + trueValidators >= onNode.threshold ) {
        truthsGivenNodeFalse = binomialTerm;
      }

      // Now multiply out the qsNodes
      for ( let qsIndex = 0; qsIndex<quorumSetNodes.length; qsIndex++ ) {
        let qsNode = quorumSetNodes[qsIndex];
        let innerMetrics = impactOfNode(subjectNode, qsNode);

        let truthOfQSNode = i & (1<<qsIndex) > 0; //use qsIndex within i
        if ( truthOfQSNode ) {
          // qs node in question is true
          truthsGivenNodeTrue *= innerMetrics.truthsGivenNodeTrue;
          truthsGivenNodeFalse *= innerMetrics.truthsGivenNodeFalse;
        }
        else { // qs is false
          truthsGivenNodeTrue *= innerMetrics.falsesGivenNodeTrue;
          truthsGivenNodeFalse *= innerMetrics.falsesGivenNodeFalse;
        }
      }
      metrics.truthsGivenNodeTrue += truthsGivenNodeTrue;
      metrics.truthsGivenNodeFalse += truthsGivenNodeFalse;
    }
  }
        
  // Cache it
  if ( cache[idForNode(onNode)] )  {
    cache[idForNode(onNode)][idForNode(subjectNode)] = metrics;
  }
  else {
    let newObject = {};
    newObject[idForNode(subjectNode)] = metrics;
    cache[idForNode(onNode)] = newObject;
  }
  return metrics
}

function idForNode(node) {
  if (node.publicKey) {
    return node.publicKey;
  }
  else {
    return node.hashKey;
  }
}

function binomial(n, k) {
  if (k > n) { return 0; }
  let result = 1;
  for ( let i = 0; i < Math.min(k, n-k); i++) {
    result = (result * (n - i))/(i + 1);
  }
  return result;
}

function bitcount(n) {
  let tempN = n>>>0;
  let count = 0;
  while ( tempN !== 0 ) {
    tempN = tempN & (tempN-1>>>0)
    count += 1
  }
  return count;
}

export default QuorumNodeDetail;
