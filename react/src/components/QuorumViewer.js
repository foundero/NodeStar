import React, { Component } from 'react';
import Graph from 'react-graph-vis';
import validatorHelper from '../ValidatorHelper.js';

var options = {
  physics: { enabled: false },
    layout: {
        hierarchical: {
          sortMethod: 'directed',
          levelSeparation: 180,
          nodeSpacing: 50
        }
    },
    edges: {
        color: "#000000"
    },
    interaction: {
      dragNodes: false,
      dragView: false,
      zoomView: false
    },
    width : "500px",
    height : "300px"
};




class QuorumViewer extends Component {

  selectQuorumNode(event) {
      var { nodes } = event;
      if ( nodes.length === 0 ) {
        this.props.onSelectQuorumNode(null);
      }
      else {
        this.props.onSelectQuorumNode(nodes);
      }
  }
  
  render() {
    console.log('render quorum graph');
    var graph = quorumGraph(this.props.validators, this.props.validator)
    return (
        
          <Graph graph={graph}
                 getNetwork={network => this.setState({network }) }
                 options={options}
                 events={{ select: (event) => {
                   this.selectQuorumNode(event)
                 }}}
                 style={{
                   width: '494px',
                   height: '300px',
                   border: '1px solid #bab8b8',
                   'borderRadius': '10px',
                   'backgroundColor': 'white',
                   'marginLeft': '2px'
                 }} />
        
    );
  }
  
  componentDidUpdate() {
    this.state.network.fit();
    if ( this.props.selectedQuorumNode ) {
      this.state.network.selectNodes([this.props.selectedQuorumNode]);
    }
    else {
      this.state.network.selectNodes([]);
    }
  }
}

export default QuorumViewer;


function quorumGraph(validators, validator) {
  if (validator == null) {
    return {nodes: [], edges: []};
  }
  var rootId = validator.quorumSet ? validator.quorumSet.hashKey : validator.publicKey; 
  var nodes = [{id: rootId, label: validatorHelper.validatorAndHandleForPublicKey(validators, validator.publicKey).handle, color:'#cbdaf2'}];
  var edges = [];
  var quorumSet = validator['quorumSet'];
  if (quorumSet !== null) {
    quorumSet['validators'].forEach( (v,index) => {
      if (index > quorumSet['validators'].length/2) return;
      nodes.push( {id: v, label: validatorHelper.validatorAndHandleForPublicKey(validators, v).handle, color:'#cbdaf2' } );
      edges.push( {from: rootId, to: v} );
    });
    quorumSet['innerQuorumSets'].forEach(innerQS => {
      var innerQSId = innerQS['hashKey'];
      nodes.push( {id: innerQSId, label: "", color:'#aaaaaa'} );
      edges.push( {from: rootId, to: innerQSId} );
      
      innerQS['validators'].forEach(innerV => {
        nodes.push( {id: innerV, label: validatorHelper.validatorAndHandleForPublicKey(validators, innerV).handle, color:'#cbdaf2'} );
        edges.push( {from: innerQSId, to: innerV} );
      });
    });
    quorumSet['validators'].forEach( (v,index) => {
      if (index <= quorumSet['validators'].length/2) return;
      nodes.push( {id: v, label: validatorHelper.validatorAndHandleForPublicKey(validators, v).handle, color:'#cbdaf2' } );
      edges.push( {from: rootId, to: v} );
    });
  }
  return {nodes: nodes, edges: edges};
}