import React, { PureComponent } from 'react';
import logo from './media/images/icon-large.png';
import githubLogo from './media/images/GitHub-Mark-Light-120px-plus.png';
import './App.css';
import validatorHelpers from './helpers/ValidatorHelpers.js';
import clusterHelpers from './helpers/ClusterHelpers.js';
import update from 'immutability-helper';
import { SegmentedControl } from 'segmented-control';
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

const stellarbeat = 'stellarbeat';
const quorumexplorer = 'quorumexplorer';
const stellarbeatURL = 'https://uk2bk82620.execute-api.us-east-2.amazonaws.com/prod/stellarbeat';
const quorumexplorerURL = 'https://uk2bk82620.execute-api.us-east-2.amazonaws.com/prod/quorumexplorer';

class Root extends PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      datasource: 'stellarbeat',
      validators: [],
      clusters: []
    };
    this.routes= {
      'datasource': 'quorumexplorer',
      'validators': '/validators',
      'clusters': '/clusters'
    };
    this.data= {
      stellarbeat: {
        validators: [],
        clusters: []
      },
      quorumexplorer: {
        validators: [],
        clusters: []
      }
    }
  }

  updateRoutes() {
    if (this.props.location.pathname.startsWith('/validators')) {
      this.routes.validators = this.props.location.pathname;
    }
    if (this.props.location.pathname.startsWith('/clusters')) {
      this.routes.clusters = this.props.location.pathname;
    }
  }


  datasourceToggle(isStellarbeat) {
    let data = null;
    let datasource = null;
    if ( isStellarbeat ) {
      data = this.data.stellarbeat;
      datasource = stellarbeat;
    }
    else {
      data = this.data.quorumexplorer;
      datasource = quorumexplorer;
    }

    this.setState(
      update(this.state, {
        datasource: {$set: datasource},
        validators: {$set: data.validators},
        clusters: {$set: data.clusters},
      })
    );

    if ( data.validators.length <= 0 ) {
      this.getData(datasource);
    }
  }

  getData(datasource) {
    let url = stellarbeatURL;
    if ( datasource === quorumexplorer ) {
      url = quorumexplorerURL;
    }
    console.log('getting data ' + datasource);
    fetch(url)
    .then( (response) => {
      console.log('got response ' + datasource);
      return response.json();
    })
    .then( (json) => {
      console.log('parsed json ' + datasource);
      if ( datasource === quorumexplorer ) {
        json = validatorHelpers.translatedJsonFromQuorumExplorer(json);
      }
      let validators = validatorHelpers.calculateValidators(json);
      let clusters = clusterHelpers.calculateClusters(validators);
      this.data[datasource].validators = validators;
      this.data[datasource].clusters = clusters;
      if ( datasource === this.state.datasource ) {
        this.setState(update(this.state, {
          validators: {$set: validators},
          clusters: {$set: clusters}
        }));
      }
    });
  }

  componentDidMount() {
    console.log('mounted app');
    this.getData(stellarbeat);
  }

  render() {
    console.log('render App');
    this.updateRoutes();

    return (
        <div className="App">

          <header className="header">
          
          <div className="header-left">
            <span className="header-datasource-text">data source</span>
            <SegmentedControl
              name="datasourceToggle"
              options={[
                { label: "stellarbeat", value: true, default: true },
                { label: "quorumexplorer", value: false }
              ]}
              setValue={newValue => this.datasourceToggle(newValue)}
              style={{ width: '230px', color: '#0099FF', margin: '0px' }}
            />
          </div>


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
              <li><NavLink to={this.routes['validators']}>Validators</NavLink></li>
              <li><NavLink to={this.routes['clusters']}>Clusters</NavLink></li>
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
                  datasource={this.state.datasource}
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

