import React from 'react';
import validatorHelper from '../ValidatorHelper.js';
import verified from '../media/images/icon-verified.png';

function ValidatorDetail(props) {
  const validators = props.validators;
  const validator = props.validator;

  if (!validator) {
    return (
      <ul>
        <li className='bold'>...</li>
      </ul>
    );
  }

  const {handle} = validatorHelper.validatorAndHandleForPublicKey(validators, validator.publicKey);
  return (
    <ul>
      <li className='bold'>
        {handle}. {validator.name ? validator.name : "[name]"}
        {validator.verified ? <img src={verified} className="verified-icon" alt="Verified Icon" /> : '' }
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