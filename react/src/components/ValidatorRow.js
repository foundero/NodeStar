import React, { PureComponent } from 'react';
import validatorHelpers from '../helpers/ValidatorHelpers.js';
import verified from '../media/images/icon-verified.png';
import { NavLink } from "react-router-dom";

class ValidatorRow extends PureComponent {

  isActive() {
    let validatorURLId = validatorHelpers.validatorToURLId(this.props.validatorId);
    return (
      this.props.location.pathname.startsWith('/validators/'+validatorURLId) ||
      this.props.location.pathname.startsWith('/validators/'+this.props.validatorId)
      );
  }

  render() {
    const {
      validators,
      validatorId,
      location
    } = this.props;
    const {validator, handle} = validatorHelpers.validatorAndHandleForPublicKey(validators, validatorId);


    if ( !validator ) {
      return (<li>?</li>);
    }

    let path = "/validators/"+validatorHelpers.validatorToURLId(validatorId)+location.search;
    return (
      <li>
        <NavLink to={path} isActive={() => this.isActive()}>
          { handle + '. ' + (validator.name ? validator.name : '[name]') }
          { (!!validator.verified) &&
            <img src={verified} className="verified-icon-list" alt="Verified Icon" />
          }
        </NavLink>


      </li>
    );
  }
}

export default ValidatorRow;