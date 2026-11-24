@ignore
Feature: STEP customer-side deletes - choose with arg `what`: order | cart | account
  args: what, token (omit for a guest), guestId (default karate-guest), orderId (order), expect (default 200; 'any' for best-effort cleanup)

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    * def paths = { order: 'customer/order/delete', cart: 'customer/cart/remove', account: 'customer/remove-account' }
    Given url baseUrl
    And path paths[a.what]
    And param guest_id = a.what == 'account' ? null : (a.guestId || 'karate-guest')
    And param order_id = a.what == 'order' ? a.orderId : null
    And header Authorization = auth
    When method delete
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
