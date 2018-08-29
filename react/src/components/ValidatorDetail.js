import React from 'react';
import validatorHelpers from '../helpers/ValidatorHelpers.js';
import verified from '../media/images/icon-verified.png';
import { NavLink } from "react-router-dom";

function ValidatorDetail(props) {
  const {
    validators,
    validator
  } = props;

  if (!validator) {
    return (
      <ul>
        <li className='bold'>...</li>
      </ul>
    );
  }

  const {handle} = validatorHelpers.validatorAndHandleForPublicKey(validators, validator.publicKey);
  return (
    <ul>
      <li className='bold'>
        {handle}. {validator.name ? validator.name : "[name]"}
        {!!validator.verified && <img src={verified} className="verified-icon" alt="Verified Icon" />}
        {' - '}
        <NavLink to={'/clusters/'+validator.clusterId}>cluster</NavLink>
      </li>
      <li>
        {validator.city ? validator.city : "[city]"}
        {", "}
        {validator.country ? validator.country : "[country]"}</li>
      <li>
        {validator.latitude}, {validator.longitude}
      </li>
      <li>
        {validator.ip}
        {validator.host ? ", " + validator.host : ""}
      </li>
      <li className='small'>{validator.version}</li>
      <li className='small'>PK: {validator.publicKey}</li>
    </ul>
  );
}

export default ValidatorDetail;