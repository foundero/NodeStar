// @flow
import React from 'react';
import validatorHelpers from '../helpers/ValidatorHelpers.js';
import verified from '../media/images/icon-verified.png';
import { NavLink } from "react-router-dom";

import type {Validator} from '../helpers/ValidatorHelpers.js';

type Props = {
  validators: Array<Validator>,
  validator: ?Validator,
  location: any
};

function ValidatorDetail(props: Props) {
  const {
    validators,
    validator,
    location
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
    <div className='self-clear'>
    
    <div style={{float:'left', width:'350px'}}>
    <ul>
      <li className='bold'>
        {handle}. {validator.name ? validator.name : "[name]"}
        {!!validator.verified && <img src={verified} className="verified-icon" alt="Verified Icon" />}
        {' - '}
        <NavLink to={'/clusters/'+validator.clusterId+location.search}>cluster</NavLink>
      </li>
      { validator.city && validator.country &&
        <li>
          {validator.city ? validator.city : "[city]"}
          {", "}
          {validator.country ? validator.country : "[country]"}
        </li>
      }
      { validator.latitude && validator.longitude &&
        <li>
          {validator.latitude}, {validator.longitude}
        </li>
      }
      { validator.ip && validator.port &&
        <li className='small'>
          {validator.ip + ':' + validator.port}
          {validator.host ? ", " + validator.host : ""}
        </li>
      }
      <li className='small'>{validator.version}</li>
      <li className='small'>PK: {validator.publicKey}</li>
    </ul>
    </div>

    <div style={{float:'right'}}>
      <ul>
        <li className='small'>incoming direct: {validator.directIncomingValidatorSet.size}</li>
        <li className='small'>incoming indirect: {validator.indirectIncomingValidatorSet.size}</li>
        <li className='small'>outgoing direct: {validator.directValidatorSet.size}</li>
        <li className='small'>outgoing indirect: {validator.indirectValidatorSet.size}</li>
      </ul>
    </div>
    
    </div>
  );
}

export default ValidatorDetail;