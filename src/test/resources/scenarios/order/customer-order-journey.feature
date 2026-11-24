@e2e @order
Feature: Order journey - customer side
  A customer is created, finds a product, orders it, follows the order, cancels it and everything is removed again.
  The vendor / admin / delivery-man stages plug into the marked extension point once their access is available.

  Background:
    * def ctx = newCtx()
    # safety net: whatever is still pending is cleaned even if an assertion fails half-way
    * configure afterScenario = function(){ ctx.teardown() }
    * def item = karate.callSingle('classpath:steps/catalog/find-item.feature').item

  @positive @journey
  Scenario: Cash-on-delivery order - search, cart, place, track, cancel, clean up
    # ---- 1. actor: a brand-new customer ------------------------------------------------------
    * def me = call read('classpath:steps/customer/new-customer.feature')
    * def customer = me.customer
    * def token = me.token
    * eval ctx.defer('customer account', 'classpath:steps/customer/cleanup.feature', { what: 'account', token: token, expect: 'any' })

    # ---- 2. discover the product through search ------------------------------------------------
    * def found = call read('classpath:steps/customer/search-items.feature') { name: '#(item.name)', token: '#(token)' }
    * def foundIds = karate.map(found.items, function(i){ return i.id })
    * match foundIds contains item.id

    # ---- 3. cart -------------------------------------------------------------------------------
    * eval ctx.defer('cart', 'classpath:steps/customer/cleanup.feature', { what: 'cart', token: token, expect: 'any' })
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def cart = call read('classpath:steps/customer/cart-list.feature') { token: '#(token)', storeId: '#(item.storeId)' }
    * def line = karate.filter(cart.lines, function(l){ return l.item.id == item.id })[0]
    * match line contains { quantity: 1, store_id: '#(item.storeId)' }

    # ---- 4. place the order --------------------------------------------------------------------
    * def placed = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)' }
    * def orderId = placed.orderId
    * eval ctx.defer('order delete', 'classpath:steps/customer/cleanup.feature', { what: 'order', token: token, orderId: orderId, expect: 'any' })
    * eval ctx.defer('order cancel', 'classpath:steps/customer/cancel-order.feature', { token: token, orderId: orderId, expect: 'any' })
    * match placed.response.identical_code == 'default_store_201'
    * match placed.response.content contains { order_id: '#number', status: 'pending', user_id: '#number', total_ammount: '#number', created_at: '#string' }

    # ---- 5. the order is visible and correct ---------------------------------------------------
    * def details = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: 'details', orderId: '#(orderId)' }
    * match details.data == '#[1]'
    * match details.data[0] contains { order_id: '#(orderId)', item_id: '#(item.id)', quantity: 1, price: '#number' }
    * def running = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: 'running', orderId: '#(orderId)' }
    * match running.order contains { id: '#(orderId)', order_status: 'pending', payment_method: 'cash_on_delivery', payment_status: 'unpaid', order_type: 'delivery' }
    * match running.order.store.id == item.storeId
    * match running.order.delivery_address contains { contact_person_name: '#(customer.name)', contact_person_number: '#(customer.phone)' }
    * def track = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: 'track', orderId: '#(orderId)', contactNumber: '#(customer.phone)' }
    * match track.response.content.id == orderId

    # ---- >>> EXTENSION POINT: vendor confirms -> (admin) -> delivery man delivers --------------
    # steps/vendor/*.feature and steps/deliveryman/*.feature are called here once vendor / DM access exists.

    # ---- 6. customer cancels while still pending -----------------------------------------------
    * def chk = call read('classpath:steps/customer/cancel-order.feature') { token: '#(token)', orderId: '#(orderId)', reason: 'Karate order journey' }
    * eval ctx.done('order cancel')
    * def runningAfter = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: 'running', orderId: '#(orderId)' }
    * match runningAfter.order == null

    # ---- 7. delete all data and prove it is gone -----------------------------------------------
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(token)', what: 'order', orderId: '#(orderId)' }
    * eval ctx.done('order delete')
    * def chk = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: 'details', orderId: '#(orderId)', expect: 404 }
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(token)', what: 'cart' }
    * eval ctx.done('cart')
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(token)', what: 'account' }
    * eval ctx.done('customer account')
    * def relogin = call read('classpath:steps/customer/login.feature') { email: '#(customer.email)', password: '#(customer.password)', expect: 401 }
    * match relogin.token == null

  @positive @order-type
  Scenario: Take-away order has no delivery charge; delivery order adds exactly the delivery charge
    * def me = call read('classpath:steps/customer/new-customer.feature')
    * def token = me.token
    * def customer = me.customer
    * eval ctx.defer('customer account', 'classpath:steps/customer/cleanup.feature', { what: 'account', token: token, expect: 'any' })
    * eval ctx.defer('cart', 'classpath:steps/customer/cleanup.feature', { what: 'cart', token: token, expect: 'any' })
    * def addToCart = function(){ karate.call('classpath:steps/customer/cart-add.feature', { token: token, itemId: item.id, storeId: item.storeId, price: item.price, quantity: 1 }) }
    * def placeAs = function(type){ return karate.call('classpath:steps/customer/place-order.feature', { token: token, storeId: item.storeId, customer: customer, orderType: type }).orderId }
    * def cleanupOrder = function(id){ ctx.defer('order ' + id + ' delete', 'classpath:steps/customer/cleanup.feature', { what: 'order', token: token, orderId: id, expect: 'any' }); ctx.defer('order ' + id + ' cancel', 'classpath:steps/customer/cancel-order.feature', { token: token, orderId: id, expect: 'any' }) }

    * eval addToCart()
    * def takeAwayId = placeAs('take_away')
    * eval cleanupOrder(takeAwayId)
    * eval addToCart()
    * def deliveryId = placeAs('delivery')
    * eval cleanupOrder(deliveryId)

    * def running = call read('classpath:steps/customer/order-queries.feature') { token: '#(token)', view: 'running', orderId: '#(takeAwayId)' }
    * def takeAway = running.order
    * def delivery = karate.call('classpath:steps/customer/order-queries.feature', { token: token, view: 'running', orderId: deliveryId }).order
    * match takeAway contains { order_type: 'take_away', delivery_charge: 0 }
    * match delivery contains { order_type: 'delivery', delivery_charge: '#? _ > 0' }
    # same product, same quantity -> the totals differ by exactly the delivery charge
    * assert Math.abs(delivery.order_amount - takeAway.order_amount - delivery.delivery_charge) < 0.005

  @positive @security
  Scenario: The server prices the order itself - a tampered cart price is ignored
    * def me = call read('classpath:steps/customer/new-customer.feature')
    * def token = me.token
    * def customer = me.customer
    * eval ctx.defer('customer account', 'classpath:steps/customer/cleanup.feature', { what: 'account', token: token, expect: 'any' })
    * eval ctx.defer('cart', 'classpath:steps/customer/cleanup.feature', { what: 'cart', token: token, expect: 'any' })
    # honest order first (reference amount) ...
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def honest = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)', orderType: 'take_away' }
    * eval ctx.defer('honest order delete', 'classpath:steps/customer/cleanup.feature', { what: 'order', token: token, orderId: honest.orderId, expect: 'any' })
    * eval ctx.defer('honest order cancel', 'classpath:steps/customer/cancel-order.feature', { token: token, orderId: honest.orderId, expect: 'any' })
    # ... then the same product with the price forged down to 1
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: 1, quantity: 1 }
    * def forged = call read('classpath:steps/customer/place-order.feature') { token: '#(token)', storeId: '#(item.storeId)', customer: '#(customer)', orderType: 'take_away' }
    * eval ctx.defer('forged order delete', 'classpath:steps/customer/cleanup.feature', { what: 'order', token: token, orderId: forged.orderId, expect: 'any' })
    * eval ctx.defer('forged order cancel', 'classpath:steps/customer/cancel-order.feature', { token: token, orderId: forged.orderId, expect: 'any' })
    * match forged.response.content.total_ammount == honest.response.content.total_ammount
    * assert forged.response.content.total_ammount > 1

  @positive @security
  Scenario: Another customer can neither see, track, cancel nor delete my order
    * def owner = call read('classpath:steps/customer/new-customer.feature')
    * def intruder = call read('classpath:steps/customer/new-customer.feature')
    * eval ctx.defer('owner account', 'classpath:steps/customer/cleanup.feature', { what: 'account', token: owner.token, expect: 'any' })
    * eval ctx.defer('intruder account', 'classpath:steps/customer/cleanup.feature', { what: 'account', token: intruder.token, expect: 'any' })
    * eval ctx.defer('owner cart', 'classpath:steps/customer/cleanup.feature', { what: 'cart', token: owner.token, expect: 'any' })
    * def chk = call read('classpath:steps/customer/cart-add.feature') { token: '#(owner.token)', itemId: '#(item.id)', storeId: '#(item.storeId)', price: '#(item.price)', quantity: 1 }
    * def placed = call read('classpath:steps/customer/place-order.feature') { token: '#(owner.token)', storeId: '#(item.storeId)', customer: '#(owner.customer)' }
    * def orderId = placed.orderId
    * eval ctx.defer('order delete', 'classpath:steps/customer/cleanup.feature', { what: 'order', token: owner.token, orderId: orderId, expect: 'any' })
    * eval ctx.defer('order cancel', 'classpath:steps/customer/cancel-order.feature', { token: owner.token, orderId: orderId, expect: 'any' })

    * def chk = call read('classpath:steps/customer/order-queries.feature') { token: '#(intruder.token)', view: 'details', orderId: '#(orderId)', expect: 404 }
    * def chk = call read('classpath:steps/customer/order-queries.feature') { token: '#(intruder.token)', view: 'track', orderId: '#(orderId)', contactNumber: '#(owner.customer.phone)', expect: 404 }
    * def chk = call read('classpath:steps/customer/cancel-order.feature') { token: '#(intruder.token)', orderId: '#(orderId)', expect: 404 }
    * def chk = call read('classpath:steps/customer/cleanup.feature') { token: '#(intruder.token)', what: 'order', orderId: '#(orderId)', expect: 404 }
    # ... and the order is untouched for its owner
    * def still = call read('classpath:steps/customer/order-queries.feature') { token: '#(owner.token)', view: 'running', orderId: '#(orderId)' }
    * match still.order.order_status == 'pending'
