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
 
var events = {
    select: function(event) {
        var { nodes } = event;
        console.log("selected" + nodes);
    }
};



class QuorumViewer extends Component {
  
  constructor(props) {
    super(props);
    this.state = {
      
      selectedNode: null
    };
  }
  
  setNetworkInstance = nw => {
      this.network = nw;
  }
  
  render() {
    console.log('render quorum graph');
    var graph = quorumGraph(this.props.validators, this.props.validator)
    return (
        
          <Graph graph={graph}
                 getNetwork={network => this.setState({network }) }
                 options={options}
                 events={events}
                 style={{
                   width: '494px',
                   height: '300px',
                   border: '1px solid #bab8b8',
                   'border-radius': '10px',
                   'background-color': 'white',
                   'margin-left': '2px'
                 }} />
        
    );
  }
  
  componentDidUpdate() {
    console.log('quorum graph did update');
    this.state.network.fit()
  }
}

export default QuorumViewer;



function quorumGraph(validators, validator) {
  if (validator == null) {
    return {nodes: [], edges: []};
  }
  var rootId = "0"+validator.publicKey
  var nodes = [{id: rootId, label: validatorHelper.validatorHandleForPublicKey(validators, validator.publicKey), color:'#cbdaf2'}];
  var edges = [];
  var quorumSet = validator['quorumSet'];
  if (quorumSet !== null) {
    quorumSet['validators'].forEach( (v,index) => {
      if (index > quorumSet['validators'].length/2) return;
      nodes.push( {id: v, label: validatorHelper.validatorHandleForPublicKey(validators, v), color:'#cbdaf2' } );
      edges.push( {from: rootId, to: v} );
    });
    quorumSet['innerQuorumSets'].forEach(innerQS => {
      var innerQSId = innerQS['hashKey'];
      nodes.push( {id: innerQSId, label: "", color:'#aaaaaa'} );
      edges.push( {from: rootId, to: innerQSId} );
      
      innerQS['validators'].forEach(innerV => {
        nodes.push( {id: innerV, label: validatorHelper.validatorHandleForPublicKey(validators, innerV), color:'#cbdaf2'} );
        edges.push( {from: innerQSId, to: innerV} );
      });
    });
    quorumSet['validators'].forEach( (v,index) => {
      if (index <= quorumSet['validators'].length/2) return;
      nodes.push( {id: v, label: validatorHelper.validatorHandleForPublicKey(validators, v), color:'#cbdaf2' } );
      edges.push( {from: rootId, to: v} );
    });
  }
  return {nodes: nodes, edges: edges};
}