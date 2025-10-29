import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  go() {
    this.element.form.requestSubmit();
  }
}
