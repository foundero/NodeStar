// @flow
import React, { PureComponent } from 'react';
import validatorHelpers from '../helpers/ValidatorHelpers.js';
import ValidatorRow from '../components/ValidatorRow.js';
import update from 'immutability-helper';
import { SegmentedControl } from 'segmented-control';

import type {Validator} from '../helpers/ValidatorHelpers.js';

type Props = {
  validators: Array<Validator>,
  validator: ?Validator,
  forCluster: boolean,
  location: any
};
type State = {
  directToggle: boolean,
  outgoingToggle: boolean
};

class RelatedValidators extends PureComponent<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      directToggle: true,
      outgoingToggle: true
    };
  }
  directToggle(isDirect: boolean) {
    this.setState(
      update(this.state, {
        directToggle: {$set: isDirect}
      })
    );
  }
  outgoingToggle(isOutgoing: boolean) {
    this.setState(
      update(this.state, {
        outgoingToggle: {$set: isOutgoing}
      })
    );
  }

  render() {
    console.log('render RelatedValidators');
    const {
      validators,
      validator,
      forCluster,
      location
    } = this.props;

    let relatedValidators = [];
    if (validator) {
      let set = null;
      if (this.state.directToggle && forCluster!==true) {
        if (this.state.outgoingToggle) {
          set = validator.directValidatorSet;
        }
        else {
          set = validator.directIncomingValidatorSet;
        }
      }
      else {
        if (this.state.outgoingToggle) {
          set = validator.indirectValidatorSet;
        }
        else {
          set = validator.indirectIncomingValidatorSet;
        }
      }
      relatedValidators = validatorHelpers.sortSet(this.props.validators, set);
    }


    return (
      <div className="right">
        <h3>Related Validators</h3>
        { forCluster!==true &&
        <SegmentedControl
          name="directToggle"
          options={[
            { label: "indirect", value: false },
            { label: "direct", value: true, default: true}
          ]}
          setValue={newValue => this.directToggle(newValue)}
          style={{ width: '200px', color: '#0099FF', margin: '0px' }}
        />
        }
        <SegmentedControl
          name="outgoingToggle"
          options={[
            { label: "incoming", value: false},
            { label: "outgoing", value: true, default: true }
          ]}
          setValue={newValue => this.outgoingToggle(newValue)}
          style={{ width: '200px', color: '#0099FF', margin: '0px' }}
        />

        <ul>
          { relatedValidators.map( (validatorId) =>
            <ValidatorRow
              key={validatorId}
              validators={validators}
              validatorId={validatorId}
              location={location} />
          )}
        </ul>
      </div>
    );
  }
}

export default RelatedValidators;

