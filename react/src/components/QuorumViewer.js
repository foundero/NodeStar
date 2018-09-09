// @flow
import React, { PureComponent } from 'react';
import Graph from 'react-graph-vis';
import validatorHelpers from '../helpers/ValidatorHelpers.js';

import type {Validator} from '../helpers/ValidatorHelpers.js';

type State = {
  network: any
};
type Props = {
  validators: Array<Validator>,
  validator: ?Validator,
  selectedQuorumNode: any,
  onSelectQuorumNode: (?string)=>void
};


const options = {
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
    nodes: {
      color: {
        background: '#dce6f7',
        border: '#888888',
        highlight: {
          border: '#000000',
          background: '#0099FF'
        }
      }
    },
    interaction: {
      dragNodes: false,
      dragView: false,
      zoomView: false
    },
    width : "480px",
    height : "300px"
};

const style = {
  width: '480px',
  height: '300px',
  border: '1px solid #bab8b8',
  'borderRadius': '10px',
  'backgroundColor': '#f7f7f7',
  'margin': 'auto'
}



class QuorumViewer extends PureComponent<Props,State> {

  selectQuorumNode(event: {nodes: ?Array<string>}) {
    const { nodes } = event;
    if ( !nodes || nodes.length === 0 ) {
      this.props.onSelectQuorumNode(null);
    }
    else if ( this.props.validator && this.props.validator.quorumSet ) {
      const id = nodes[0].slice(this.props.validator.quorumSet.hashKey.length);
      this.props.onSelectQuorumNode(id);
    }
  }

  quorumGraph(validators: Array<Validator>, validator: ?Validator): {nodes: Array<any>, edges: Array<any>}  {
    // TODO: this doesn't recurse -- so if we have depth>2 we need to refactor this.
    // but this would be annoying because we handle root specially
    if (validator == null) {
      return {nodes: [], edges: []};
    }
    let nodes = [];
    let edges = [];
    const quorumSet = validator.quorumSet;
    if (quorumSet) {
      const children = quorumSet.validators.length + quorumSet.innerQuorumSets.length;
      const rootId = quorumSet.hashKey
      const rootLabel = validatorHelpers.validatorAndHandleForPublicKey(validators, validator.publicKey).handle +
        "\n" + quorumSet.threshold + "/" + children;
      nodes.push( {id: rootId+rootId, label: rootLabel} );

      for (let i=0; i<quorumSet.validators.length; i++) {
        if (i > quorumSet.validators.length/2) { continue; }
        const v = quorumSet.validators[i];
        const label = validatorHelpers.validatorAndHandleForPublicKey(validators, v).handle;
        nodes.push( {id: rootId+v, label: label } );
        edges.push( {from: rootId+rootId, to:rootId+v} );
      }
      for (let j=0; j<quorumSet.innerQuorumSets.length; j++) {
        const innerQS = quorumSet.innerQuorumSets[j];
        const innerQSId = innerQS.hashKey;
        const label = innerQS.threshold + "/" + innerQS.validators.length;
        nodes.push( {id: rootId+innerQSId, label: label} );
        edges.push( {from: rootId+rootId, to: rootId+innerQSId} );
        
        for (let k=0; k<innerQS.validators.length; k++) {
          const innerV = innerQS.validators[k];
          const label = validatorHelpers.validatorAndHandleForPublicKey(validators, innerV).handle;
          nodes.push( {id: rootId+innerV, label: label} );
          edges.push( {from: rootId+innerQSId, to: rootId+innerV} );
        }
      }
      for (let l=0; l<quorumSet.validators.length; l++) {
        if (l <= quorumSet.validators.length/2) { continue; }
        const v = quorumSet.validators[l];
        const label = validatorHelpers.validatorAndHandleForPublicKey(validators, v).handle;
        nodes.push( {id: rootId+v, label: label } );
        edges.push( {from: rootId+rootId, to: rootId+v} );
      }
    }
    else {
      const rootLabel = validatorHelpers.validatorAndHandleForPublicKey(validators, validator.publicKey).handle;
      nodes.push( {id: validator.publicKey, label: rootLabel} );
    }
    return {nodes: nodes, edges: edges};
  }
  
  render() {
    console.log('render QuorumViewer');
    const graph = this.quorumGraph(this.props.validators, this.props.validator)
    return (
        
          <Graph graph={graph}
                 getNetwork={network => this.setState({network}) }
                 options={options}
                 events={{ select: (event) => {
                   this.selectQuorumNode(event)
                 }}}
                 style={style}
          />
    );
  }
  
  componentDidUpdate() {
    this.state.network.fit();
    const selectedNode = this.props.selectedQuorumNode;
    if ( selectedNode && this.props.validator ) {
      const selectedNodeId = selectedNode.publicKey ? selectedNode.publicKey : selectedNode.hashKey;
      this.state.network.selectNodes([this.props.validator.quorumSet.hashKey + selectedNodeId]);
    }
    else {
      this.state.network.selectNodes([]);
    }
  }
}

export default QuorumViewer;

