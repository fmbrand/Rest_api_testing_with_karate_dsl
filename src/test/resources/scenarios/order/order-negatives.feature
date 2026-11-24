@e2e @order @negative
Feature: Order journey - negative and edge cases (cart + place order + order access)

  Background:
    * def ctx = newCtx()
    * configure afterScenario = function(){ ctx.teardown() }
    * def item = karate.callSingle('classpath:steps/catalog/find-item.feature').item
    * def me = call read('classpath:steps/customer/new-customer.feature')
    * def token = me.token
    * def customer = me.customer
    * eval ctx.defer('customer account', 'classpath:steps/customer/cleanup.feature', { what: 'account', token: token, expect: 'any' })
    # runs BEFORE the account removal (LIFO): cancels + deletes every order and clears the cart, even unexpected ones
    * eval ctx.defer('order sweep', 'classpath:steps/customer/sweep.feature', { token: token })
    * def errorCodes = function(res){ return karate.jsonPath(res, '$.errors[*].code') }

  # ---------------------------------------------------------------- cart
  Scenario Outline: cart rejects quantity <quantity>
    * def r = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: <quantity>, expect: 422 }
    * match errorCodes(r.response) contains 'quantity'

    Examples:
      | quantity |
      | 0        |
      | -1       |
      | -999     |

  Scenario: cart rejects a quantity above the available stock
    * def r = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 99999999, expect: 422 }
    * match errorCodes(r.response) contains 'stock'

  Scenario: cart rejects an unknown model
    * def r = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', model: 'Bogus', expect: 422 }
    * match errorCodes(r.response) contains 'model'

  Scenario: cart rejects an item that does not exist
    * def r = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: 99999999, storeId: '#(item.storeId)', price: 10, expect: 404 }
    * match errorCodes(r.response) contains 'cart_item'

  Scenario Outline: cart add requires <field>
    * def body = { guest_id: 'karate-guest', item_id: '#(item.id)', model: 'Item', price: '#(item.price)', quantity: 1, store_id: '#(item.storeId)' }
    * eval delete body['<field>']
    Given url baseUrl
    And path 'customer/cart/add'
    And header Authorization = 'Bearer ' + token
    And request body
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | field    |
      | item_id  |
      | model    |
      | price    |
      | quantity |
      | store_id |

  # ---- guest checkout (no token): the caller is identified by guest_id only
  Scenario: guest cart add without a guest_id cannot identify the caller - 401
    * def body = { item_id: '#(item.id)', model: 'Item', price: '#(item.price)', quantity: 1, store_id: '#(item.storeId)' }
    Given url baseUrl
    And path 'customer/cart/add'
    And request body
    When method post
    Then status 401
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unauthorized_401', field: 'auth-001' }

  Scenario Outline: guest cart add requires <field>
    * def guestId = 'karate-g-' + rnd.uid()
    * eval ctx.defer('guest sweep', 'classpath:steps/customer/sweep.feature', { guestId: guestId })
    * def body = { guest_id: '#(guestId)', item_id: '#(item.id)', model: 'Item', price: '#(item.price)', quantity: 1, store_id: '#(item.storeId)' }
    * eval delete body['<field>']
    Given url baseUrl
    And path 'customer/cart/add'
    And request body
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | field    |
      | item_id  |
      | quantity |
      | price    |

  # ---------------------------------------------------------------- place order
  Scenario: placing an order with an empty cart is refused
    * def r = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)', expect: 403 }
    * match errorCodes(r.response) contains 'empty_cart'

  Scenario Outline: place order requires <field>
    * def r = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)', omit: ['<field>'], expect: 422 }
    * match errorCodes(r.response) contains '<field>'

    Examples:
      | field          |
      | payment_method |
      | order_type     |
      | store_id       |
      | distance       |
      | address        |
      | latitude       |
      | longitude      |

  # guest checkout: no token, so contact details must come in the request
  Scenario Outline: guest place order requires <field>
    * def guestId = 'karate-g-' + rnd.uid()
    * eval ctx.defer('guest sweep', 'classpath:steps/customer/sweep.feature', { guestId: guestId })
    * def chk = call read('classpath:steps/customer/cart-add.feature') { itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', guestId: '#(guestId)' }
    * def r = call read('classpath:steps/customer/place-order.feature') { storeId: '#(item.storeId)', customer: '#(customer)', guestId: '#(guestId)', omit: ['<field>'], expect: 422 }
    * match errorCodes(r.response) contains '<field>'

    Examples:
      | field                 |
      | contact_person_name   |
      | contact_person_number |
      | contact_person_email  |

  Scenario: guest place order without a guest_id cannot identify the caller - 401
    * def r = call read('classpath:steps/customer/place-order.feature') { storeId: '#(item.storeId)', customer: '#(customer)', omit: ['guest_id'], expect: 401 }
    * match errorCodes(r.response) contains 'auth-001'

  Scenario Outline: place order rejects <field>=<value>
    * def r = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)', override: { <field>: '<value>' }, expect: 422 }
    * match errorCodes(r.response) contains '<field>'

    Examples:
      | field                | value        |
      | payment_method       | bitcoin      |
      | payment_method       | CASH         |
      | order_type           | drone        |
      | contact_person_email | not-an-email |
      | contact_person_number| abc          |

  Scenario Outline: place order for store <store> is refused and no order is created
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def r = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '<store>', customer: '#(customer)', expect: [403, 404, 422] }
    * match r.orderId == null

    Examples:
      | store  |
      | 999999 |
      | 0      |
      | -1     |
      | abc    |

  Scenario: a cart is bound to its store - ordering the same cart from another store is refused
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def otherStore = call read('classpath:steps/customer/other-store.feature') { notStoreId: '#(item.storeId)' }
    * def r = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(otherStore.storeId)', customer: '#(customer)', expect: 403 }
    * match errorCodes(r.response) contains 'empty_cart'

  # ---------------------------------------------------------------- order access
  Scenario Outline: <view> of an order that does not exist is 404
    * def chk = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: '<view>', orderId: 99999999, contactNumber: '#(customer.phone)', expect: 404 }

    Examples:
      | view    |
      | details |
      | track   |

  Scenario: cancelling an order that does not exist is 404
    * def chk = call read('classpath:steps/customer/cancel-order.feature') { token: '#(token)', orderId: 99999999, expect: 404 }

  Scenario: deleting an order that does not exist is 404
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(token)', what: 'order', orderId: 99999999, expect: 404 }

  # a forged token is not rejected with 401 - the API silently treats the caller as a guest.
  # What must hold is that no order data is ever exposed.
  Scenario Outline: a forged bearer token never exposes order data - <view>
    * def r = call read('classpath:steps/customer/order-queries.feature') { token: 'forged.token.value', view: '<view>', orderId: 1, guestId: 'karate-forged-guest', expect: [200, 401, 403] }
    * assert r.status != 200 || r.data.length == 0

    Examples:
      | view    |
      | running |
      | list    |
