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
      if ( !nodes || nodes.length === 0 ) {
        this.props.onSelectQuorumNode(null);
      }
      else {
        const id = nodes[0].slice(this.props.validator.quorumSet.hashKey.length);
        this.props.onSelectQuorumNode(id);
      }
  }

  quorumGraph(validators, validator) {
    if (validator == null) {
      return {nodes: [], edges: []};
    }
    var validatorColor = '#cbdaf2';
    var qsColor = '#aaa';
    var nodes = [];
    var edges = [];
    var quorumSet = validator.quorumSet;
    if (quorumSet) {
      const children = quorumSet.validators.length + quorumSet.innerQuorumSets.length;
      const rootId = quorumSet.hashKey
      const rootLabel = validatorHelper.validatorAndHandleForPublicKey(validators, validator.publicKey).handle +
        "\n" + quorumSet.threshold + "/" + children;
      nodes.push( {id: rootId+rootId, label: rootLabel, color: validatorColor} );

      for (var i=0; i<quorumSet.validators.length; i++) {
        if (i > quorumSet.validators.length/2) { continue; }
        const v = quorumSet.validators[i];
        const label = validatorHelper.validatorAndHandleForPublicKey(validators, v).handle;
        nodes.push( {id: rootId+v, label: label, color: validatorColor } );
        edges.push( {from: rootId+rootId, to:rootId+v} );
      }
      for (var j=0; j<quorumSet.innerQuorumSets.length; j++) {
        const innerQS = quorumSet.innerQuorumSets[j];
        const innerQSId = innerQS.hashKey;
        const label = innerQS.threshold + "/" + innerQS.validators.length;
        nodes.push( {id: rootId+innerQSId, label: label, color:qsColor} );
        edges.push( {from: rootId+rootId, to: rootId+innerQSId} );
        
        for (var k=0; k<innerQS.validators.length; k++) {
          const innerV = innerQS.validators[k];
          const label = validatorHelper.validatorAndHandleForPublicKey(validators, innerV).handle;
          nodes.push( {id: rootId+innerV, label: label, color: validatorColor} );
          edges.push( {from: rootId+innerQSId, to: rootId+innerV} );
        }
      }
      for (var l=0; l<quorumSet.validators.length; l++) {
        if (l <= quorumSet.validators.length/2) { continue; }
        const v = quorumSet.validators[l];
        const label = validatorHelper.validatorAndHandleForPublicKey(validators, v).handle;
        nodes.push( {id: rootId+v, label: label, color: validatorColor } );
        edges.push( {from: rootId+rootId, to: rootId+v} );
      }
    }
    else {
      const rootLabel = validatorHelper.validatorAndHandleForPublicKey(validators, validator.publicKey).handle;
      nodes.push( {id: validator.publicKey, label: rootLabel, color: validatorColor} );
    }
    return {nodes: nodes, edges: edges};
  }
  
  render() {
    console.log('render quorum graph');
    if (this.state && this.state.network) {
      //this.state.network.destroy();
    }
    var graph = this.quorumGraph(this.props.validators, this.props.validator)
    return (
        
          <Graph graph={graph}
                 getNetwork={network => this.setState({network}) }
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
      this.state.network.selectNodes([this.props.validator.quorumSet.hashKey + this.props.selectedQuorumNode]);
    }
    else {
      this.state.network.selectNodes([]);
    }
  }
}

export default QuorumViewer;

