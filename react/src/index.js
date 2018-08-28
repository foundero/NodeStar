import React from 'react';
import ReactDOM from 'react-dom';
import AppWithRouter from './AppWithRouter';
import registerServiceWorker from './registerServiceWorker';

ReactDOM.render(<AppWithRouter />, document.getElementById('root'));
registerServiceWorker();
