import React, { Component } from 'react';

class SummaryPage extends Component {

  render() {
    console.log('render Summary Page')
    return (
      <div className="page">
        <div className="left">
          <h3>Data</h3>
        </div>

        <div className="middle-and-right">
          <h3>sIncoming</h3>
          <p>Coming Soon...</p>
          <h3>Outgoing</h3>
          <p>Coming Soon...</p>
          <h3>Quorum Sets</h3>
          <p>Coming Soon...</p>
        </div>
      </div>
    );
  }
}

export default SummaryPage;
