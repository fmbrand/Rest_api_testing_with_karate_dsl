@ignore
Feature: STEP cancel order - PUT /customer/order/cancel
  args: token (omit for a guest), guestId (default karate-guest), orderId, reason (default 'karate'), expect (default 200)

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    Given url baseUrl
    And path 'customer/order/cancel'
    And header Authorization = auth
    And request { guest_id: '#(a.guestId || "karate-guest")', order_id: '#(a.orderId)', reason: '#(a.reason || "karate")' }
    When method put
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
