import React, { PureComponent } from 'react';
import Graph from 'react-graph-vis';

const options = {
  physics: { enabled: false },
    layout: {
        hierarchical: {
          sortMethod: 'directed',
          direction: 'DU',
          levelSeparation: 130,//80,
          nodeSpacing: 120//40
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
      },
      scaling: {
        label: {
          enabled: true
        }
      }
    },
    interaction: {
      dragNodes: false,
      dragView: false,
      zoomView: false
    },
    width : "480px",
    height : "500px"
};

const style = {
  width: '480px',
  height: '500px',
  border: '1px solid #bab8b8',
  'borderRadius': '10px',
  'backgroundColor': '#f7f7f7',
  'margin': 'auto'
}



class ClusterViewer extends PureComponent {

  selectClusterNode(event) {
    const { nodes } = event;
    if ( !nodes || nodes.length === 0 ) {
      this.props.onSelectClusterNode(null);
    }
    else {
      this.props.onSelectClusterNode(nodes[0]);
    }
  }

  clusterGraph(clusters) {
    if (clusters == null) {
      return {nodes: [], edges: []};
    }

    let nodes = [];
    let edges = [];
    for (let i = 0; i<clusters.length; i++) {
      let cluster = clusters[i];
      let incomingMinusSelf = cluster.incomingMinusSelf;
      let difference = cluster.incoming.size - incomingMinusSelf;
      let sublabel = incomingMinusSelf + '+' + difference;
      nodes.push( {
        value: cluster.nodes.size,
        level: cluster.level,
        id: i+1,
        label: cluster.nodes.size + '\n' + sublabel} );
      for (let j = 0; j<cluster.outgoingClusters.length; j++) {
        edges.push( {from: i+1, to: cluster.outgoingClusters[j]+1} );
      }
    }
    return {nodes: nodes, edges: edges};
  }
  
  render() {
    console.log('render ClusterViewer');
    const graph = this.clusterGraph(this.props.clusters)
    return (
          <Graph graph={graph}
                 getNetwork={network => this.setState({network}) }
                 options={options}
                 events={{ select: (event) => {
                   this.selectClusterNode(event)
                 }}}
                 style={style}
          />
    );
  }
  
  componentDidUpdate() {
    this.state.network.fit();
    const selectedNodeId = this.props.selectedClusterId;
    if ( selectedNodeId ) {
      this.state.network.selectNodes([selectedNodeId]);
    }
    else {
      this.state.network.selectNodes([]);
    }
  }
}

export default ClusterViewer;

