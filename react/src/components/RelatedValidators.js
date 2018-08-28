import React, { PureComponent } from 'react';
import validatorHelpers from '../helpers/ValidatorHelpers.js';
import ValidatorRow from '../components/ValidatorRow.js';
import update from 'immutability-helper';
import { SegmentedControl } from 'segmented-control';

class RelatedValidators extends PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      directToggle: true,
      outgoingToggle: true
    };
  }
  directToggle(isDirect) {
    this.setState(
      update(this.state, {
        directToggle: {$set: isDirect}
      })
    );
  }
  outgoingToggle(isOutgoing) {
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
      forCluster
    } = this.props;

    let relatedValidators = [];
    let selectedValidator = validator;
    if ( forCluster===true) {
      selectedValidator = null;
    }
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
              selectedValidator={selectedValidator} />
          )}
        </ul>
      </div>
    );
  }
}

export default RelatedValidators;
