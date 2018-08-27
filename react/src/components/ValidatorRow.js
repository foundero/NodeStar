import React from 'react';
import validatorHelper from '../ValidatorHelper.js';
import verified from '../media/images/icon-verified.png';

function ValidatorRow(props) {
  const validators = props.validators;
  const validatorId = props.validatorId;
  const selectedValidator = props.selectedValidator
  const onClick = props.onClick;

  const selectedValidatorId = selectedValidator ? selectedValidator.publicKey : null;
  const {validator, handle} = validatorHelper.validatorAndHandleForPublicKey(validators, validatorId);
  return (
    <li className={selectedValidatorId === validatorId ? 'active' : 'not-active'}
        onClick={onClick}
    >
      {handle}. {validator && validator.name ? validator.name : '[name]'}
      {validator && validator.verified ?
        <img src={verified} className="verified-icon-list" alt="Verified Icon" />
          :
        ''
      }
    </li>
  );
}

export default ValidatorRow;