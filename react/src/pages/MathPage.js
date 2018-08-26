import React, { Component } from 'react';
import math1 from '../media/images/math1.tex.png';
import math2 from '../media/images/math2.tex.png';
import math3 from '../media/images/math3.tex.png';

class MathPage extends Component {

  render() {
    return (
      <div className="page">
        <h3>NodeStar Math</h3>
          <img src={math1} alt="NodeStar Math - General Quorum" />
          <img src={math2} alt="NodeStar Math - Simple Quorum" />
          <img src={math3} alt="NodeStar Math - Recursive Quorum" />
      </div>
    );
  }
}

export default MathPage;

