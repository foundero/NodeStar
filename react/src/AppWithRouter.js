import React, { Component } from 'react';
import logo from './media/images/icon-large.png';
import githubLogo from './media/images/GitHub-Mark-Light-120px-plus.png';
import './App.css';
import validatorHelpers from './helpers/ValidatorHelpers.js';
import clusterHelpers from './helpers/ClusterHelpers.js';
import update from 'immutability-helper';
import withAnalytics, { initAnalytics } from 'react-with-analytics';
import {
  Route,
  NavLink,
  HashRouter,
  Switch,
  Redirect,
  withRouter
} from "react-router-dom";
import ClusterPage from "./pages/ClusterPage";
import SummaryPage from "./pages/SummaryPage";
import ValidatorPage from "./pages/ValidatorPage";
import MathPage from "./pages/MathPage";

initAnalytics('UA-124733101-1');

class Root extends Component {
  constructor(props) {
    super(props);
    this.state = {
      validators: [],
      clusters: []
    };
  }

  getQuorumData() {
    console.log('getting data');
    fetch('https://3jp78txn9h.execute-api.us-east-2.amazonaws.com/prod/stellar-beat-data')
   	.then( (response) => {
      console.log('got response');
      return response.json();
    })
    .then( (json) => {
      console.log('parsed json');
      let validators = validatorHelpers.calculateValidators(json);
      let clusters = clusterHelpers.calculateClusters(validators);
      this.setState(update(this.state, {
        validators: {$set: validators},
        clusters: {$set: clusters}
      }));
    });
  }

  componentDidMount() {
    console.log('mounted app');
    this.getQuorumData();
  }

  render() {
    return (
        <div className="App">

          <header className="header">
          
          <div className="header-right">
            <ul>
              <li>
                <a href="https://github.com/foundero/NodeStar">
                  <span>View on GitHub</span>
                  <img className='github' src={githubLogo} alt="NodeStar on GitHub" />
                </a>
              </li>
              <li>
                <a className='appstore' href="https://itunes.apple.com/us/app/nodestar-for-stellar/id1425168670?mt=8">
                </a>
              </li>
            </ul>
          </div>
      
      
          <div className='header-middle'>
      
            <img src={logo} className="logo" alt="NodeStar Logo" />
            <h1 className="title">NodeStar</h1>
            <h2 className="subtitle">A Stellar Quorum Explorer</h2>
            <ul className="header">
              <li><NavLink to="/validators">Validators</NavLink></li>
              <li><NavLink to="/clusters">Clusters</NavLink></li>
              <li><NavLink to="/summary">Summary</NavLink></li>
              <li><NavLink to="/math">Math</NavLink></li>
            </ul>
          </div>
                
                
          </header>

          <div className="content">
            <Switch>
            <Route
              path="/summary"
              render={(props) =>
                <SummaryPage {...props}
                  validators={this.state.validators}
                  clusters={this.state.clusters}
                />
              } />
            <Route
              path="/validators/:publicKey?/:static?/:quorumNodeId?"
              render={(props) =>
                <ValidatorPage {...props}
                  validators={this.state.validators}
                />
              } />
            <Route
              path="/clusters/:clusterId?"
              render={(props) =>
                <ClusterPage {...props}
                  validators={this.state.validators}
                  clusters={this.state.clusters}
                />
              } />
            <Route path="/math" component={MathPage}/>
            <Redirect to="/validators"/>
            </Switch>
          </div>
        </div>
    );
  }
}

const App = withRouter(withAnalytics(Root));

const AppWithRouter = () => (
  <HashRouter>
    <App />
  </HashRouter>
)

export default AppWithRouter;

