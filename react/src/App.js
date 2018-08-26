import React, { Component } from 'react';
import logo from './media/images/icon-large.png';
import githubLogo from './media/images/GitHub-Mark-Light-120px-plus.png';
import './App.css';

import {
  Route,
  NavLink,
  HashRouter,
  Switch,
  Redirect
} from "react-router-dom";
import ClusterPage from "./pages/ClusterPage";
import SummaryPage from "./pages/SummaryPage";
import ValidatorPage from "./pages/ValidatorPage";
import MathPage from "./pages/MathPage";

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      validators: [],
      routes: {
        validators: "/validators"
      }
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
      this.setState({
        'validators': json,
        'routes': this.state.routes
      });
    });
  }

  componentDidMount() {
    console.log('mounted app');
    this.getQuorumData();
  }

  storeRoutePath(routeKey, path) {
    if ( path === this.state.routes[routeKey] ) { return; }
          
    var routes = this.state.routes;
    routes[routeKey] = path;
    this.setState({
      'validators': this.state.validators,
      'routes': routes
    });
  }

  render() {
    return (
      <HashRouter>
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
              <li><NavLink to="/summary">Summary</NavLink></li>
              <li><NavLink to={this.state.routes.validators}>Validators</NavLink></li>
              <li><NavLink to="/clusters">Clusters</NavLink></li>
              <li><NavLink to="/math">Math</NavLink></li>
            </ul>
          </div>
                
                
          </header>

          <div className="content">
            <Switch>
            <Route path="/summary" component={SummaryPage}/>
            <Route
              path="/validators/:publicKey?/:blah?/:quorumNodeId?"
              render={(props) =>
                <ValidatorPage {...props}
                  validators={this.state.validators}
                  onStoreRoutePath={ (routeKey, path) =>
                    this.storeRoutePath(routeKey, path)
                  } />
              } />
            <Route path="/clusters" component={ClusterPage}/>
            <Route path="/math" component={MathPage}/>
            <Redirect to="/validators"/>
            </Switch>
          </div>
        </div>
      </HashRouter>
    );
  }
}

export default App;

