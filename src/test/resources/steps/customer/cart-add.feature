@ignore
Feature: STEP add to cart - POST /customer/cart/add
  args: token (omit for a guest), guestId (default karate-guest), itemId, storeId, price, quantity (default 1), model (default Item), expect (default 201)
  returns: status, response

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    * def guestId = a.guestId || 'karate-guest'
    * def quantity = a.quantity == null ? 1 : a.quantity
    * def model = a.model || 'Item'
    Given url baseUrl
    And path 'customer/cart/add'
    And header Authorization = auth
    And request { guest_id: '#(guestId)', item_id: '#(a.itemId)', model: '#(model)', price: '#(a.price)', quantity: '#(quantity)', store_id: '#(a.storeId)' }
    When method post
    * eval expectStatus(responseStatus, a.expect == null ? 201 : a.expect, response)
    * def status = responseStatus
