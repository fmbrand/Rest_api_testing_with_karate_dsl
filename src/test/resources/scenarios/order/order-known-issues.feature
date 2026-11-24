@e2e @order @known-issue
Feature: Order journey - documented server defects (excluded from the default run; run with --tags @known-issue)
  Each scenario states the CORRECT behaviour and therefore fails today.

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

  Scenario: DEFECT - a wallet order without balance must be a 4xx; today it is HTTP 201 with the error hidden in content
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def r = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)', payment: 'wallet', expect: 'any' }
    * assert r.status >= 400 && r.status < 500

  Scenario: DEFECT - cancelling an already cancelled order must be rejected; today it is HTTP 200 again
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def placed = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)' }
    * eval ctx.defer('order delete', 'classpath:steps/customer/cleanup.feature', { what: 'order', token: token, orderId: placed.orderId, expect: 'any' })
    * def chk = call read('classpath:steps/customer/cancel-order.feature') { token: '#(token)', orderId: '#(placed.orderId)' }
    * def again = call read('classpath:steps/customer/cancel-order.feature') { token: '#(token)', orderId: '#(placed.orderId)', expect: 'any' }
    * assert again.status >= 400 && again.status < 500

  Scenario: DEFECT (intermittent) - deleting an already deleted order should always be 404; the server answers 404 on some runs and 200 on others
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def placed = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)' }
    * def chk = call read('classpath:steps/customer/cancel-order.feature') { token: '#(token)', orderId: '#(placed.orderId)' }
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(token)', what: 'order', orderId: '#(placed.orderId)' }
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(token)', what: 'order', orderId: '#(placed.orderId)', expect: 404 }

  Scenario: DEFECT - adding to the cart with a store that does not exist must be refused; today it is HTTP 201
    * def r = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: 999999, price: '#(item.price)', quantity: 1, expect: 'any' }
    * assert r.status >= 400 && r.status < 500
