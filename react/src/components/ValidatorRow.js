import React from 'react';
import validatorHelpers from '../helpers/ValidatorHelpers.js';
import verified from '../media/images/icon-verified.png';
import { NavLink } from "react-router-dom";

function ValidatorRow(props) {
  const {
    validators,
    validatorId,
    selectedValidator
  } = props;
  const {validator, handle} = validatorHelpers.validatorAndHandleForPublicKey(validators, validatorId);
  
  if ( !validator ) {
    return (<li>?</li>);
  }
  return (
    <li>
      <NavLink to={"/validators/"+validatorId}>
        { handle + '. ' + (validator.name ? validator.name : '[name]') }
        { (!!validator.verified) &&
          <img src={verified} className="verified-icon-list" alt="Verified Icon" />
        }
      </NavLink>
    </li>
  );
}

export default ValidatorRow;