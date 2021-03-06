// @flow
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


type Data = {
  validators: Array<any>,
  clusters: Array<any>
};

type Props = any;

type State = {
  quorumexplorer: Data,
  stellarbeat: Data
};

class Root extends PureComponent<Props, State> {
  state: any;
  props: any;
  routes: any;

  constructor(props: Props) {
    super(props);
    this.state = {
      'quorumexplorer': {
        validators: [],
        clusters: []
      },
      'stellarbeat': {
        validators: [],
        clusters: []
      }
    };
    this.routes = {
      'validators': '/validators',
      'clusters': '/clusters'
    };
  }

  data(): Data {
    if (this.datasource()===quorumexplorer) {
      return this.state.quorumexplorer;
    }
    return this.state.stellarbeat;
  }

  updateRoutes() {
    if (this.props.location.pathname.startsWith('/validators')) {
      this.routes.validators = this.props.location.pathname;
    }
    if (this.props.location.pathname.startsWith('/clusters')) {
      this.routes.clusters = this.props.location.pathname;
    }
  }

  datasource(): string {
    if (this.props.location.search === this.datasourceQueryString(stellarbeat)) {
      return stellarbeat;
    }
    return quorumexplorer;
  }
  datasourceQueryString(datasource: string): string {
    if (datasource === quorumexplorer) {
      return '?ds=qe';
    }
    else {
      return '?ds=sb';
    }
  }

  datasourceToggle(isStellarbeat: boolean) {
    console.log('datasource toggle');
    let desiredQueryString = this.datasourceQueryString(stellarbeat);
    if (!isStellarbeat) {
      desiredQueryString = this.datasourceQueryString(quorumexplorer);
    }

    if ( desiredQueryString !== this.props.location.search ) {
      console.log('push querystring');
      this.props.history.push({search: desiredQueryString});
    }
  }

  getData(datasource: string) {
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
      this.setState(update(this.state, {
        [datasource] : {
          validators: {$set: validators},
          clusters: {$set: clusters}
        }
      }));
    });
  }

  componentDidMount() {
    console.log('did mount');
    if ( this.data().validators.length <= 0 ) {
      this.getData(this.datasource());
    }
  }
  componentDidUpdate() {
    console.log('did update');
    if ( this.data().validators.length <= 0 ) {
      this.getData(this.datasource());
    }
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
                { label: "quorumexplorer", value: false, default: this.datasource()===quorumexplorer },
                { label: "stellarbeat", value: true, default: this.datasource()===stellarbeat }
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
              <li>
                <NavLink
                  to={this.routes['validators']+this.props.location.search}
                  isActive={(match, location) => location.pathname + location.search === this.routes['validators']+this.props.location.search}
                >
                  Validators
                </NavLink>
              </li>
              <li>
                <NavLink
                  to={this.routes['clusters']+this.props.location.search}
                  isActive={(match, location) => location.pathname + location.search === this.routes['clusters']+this.props.location.search}
                >
                  Clusters
                </NavLink>
              </li>
              <li>
                <NavLink
                  to={'/summary'+this.props.location.search}
                  isActive={(match, location) => location.pathname + location.search === 'summary'+this.props.location.search}
                >
                  Summary
                </NavLink>
              </li>
              <li>
                <NavLink
                  to={'/math'+this.props.location.search}
                  isActive={(match, location) => location.pathname + location.search === 'math'+this.props.location.search}
                >
                  Math
                </NavLink>
              </li>
            </ul>
          </div>
                
                
          </header>

          <div className="content">
            <Switch>
            <Route
              path="/summary"
              render={(props) =>
                <SummaryPage {...props}
                  datasource={this.datasource()}
                  validators={this.data().validators}
                  clusters={this.data().clusters}
                />
              } />
            <Route
              path="/validators/:publicKey?/:static?/:quorumNodeId?"
              render={(props) =>
                <ValidatorPage {...props}
                  validators={this.data().validators}
                />
              } />
            <Route
              path="/clusters/:clusterId?"
              render={(props) =>
                <ClusterPage {...props}
                  validators={this.data().validators}
                  clusters={this.data().clusters}
                />
              } />
            <Route path="/math" component={MathPage}/>
            <Redirect to={"/validators"+this.datasourceQueryString(this.datasource())}/>
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

