import React from 'react';
import validatorHelper from '../helpers/ValidatorHelper.js';
import verified from '../media/images/icon-verified.png';

function ValidatorRow(props) {
  const {
    validators,
    validatorId,
    selectedValidator,
    onClick
  } = props;

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