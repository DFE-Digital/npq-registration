// Nested radio options.
//
// GOV.UK decides whether a conditional reveal is open purely from the state of
// the radio that controls it. Our nested school types share the parent's input
// name, so picking one unchecks the parent and the reveal would close the option
// the user just chose. This keeps it open instead.
//
import { Radios } from 'govuk-frontend';

const syncWithInputState = Radios.prototype.syncConditionalRevealWithInputState;

Radios.prototype.syncConditionalRevealWithInputState = function ($input) {
  const $target = document.getElementById($input.getAttribute('aria-controls'));

  if ($target && $target.querySelector('input[type="radio"]:checked')) {
    $input.setAttribute('aria-expanded', 'true');
    $target.classList.remove('govuk-radios__conditional--hidden');
    return;
  }

  syncWithInputState.call(this, $input);
};
