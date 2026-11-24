@ignore
Feature: STEP list cart - GET /customer/cart/list
  args: token (omit for a guest), guestId (default karate-guest), storeId, expect (default 200)
  returns: lines (cart rows), status, response

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    Given url baseUrl
    And path 'customer/cart/list'
    And param guest_id = a.guestId || 'karate-guest'
    And param store_id = a.storeId
    And header Authorization = auth
    When method get
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
    * def lines = response.content ? response.content.data : []
