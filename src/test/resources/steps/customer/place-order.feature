@ignore
Feature: STEP place order - POST /customer/order/place
  args: token (omit for a guest), guestId (default karate-guest), storeId, customer { name, phone, email }
        orderType (delivery | take_away, default delivery), payment (default cash_on_delivery)
        override {map merged into the body}, omit [fields removed from the body], expect (default 201)
  returns: orderId (null on failure), status, response

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    * def orderType = a.orderType || 'delivery'
    * def base =
      """
      {
        guest_id: '#(a.guestId || "karate-guest")', payment_method: '#(a.payment || "cash_on_delivery")',
        order_type: '#(orderType)', store_id: '#(a.storeId)',
        contact_person_name: '#(a.customer.name)', contact_person_number: '#(a.customer.phone)', contact_person_email: '#(a.customer.email)'
      }
      """
    * def geo = { distance: 3, address: 'Karate test address, Dhaka', latitude: '23.8103', longitude: '90.4125' }
    * def body = orderType == 'take_away' ? base : karate.merge(base, geo)
    * def body = karate.merge(body, a.override || {})
    * eval karate.forEach(a.omit || [], function(k){ delete body[k] })
    Given url baseUrl
    And path 'customer/order/place'
    And header Authorization = auth
    And request body
    When method post
    * eval expectStatus(responseStatus, a.expect == null ? 201 : a.expect, response)
    * def status = responseStatus
    * def orderId = response.content && response.content.order_id ? response.content.order_id : null
