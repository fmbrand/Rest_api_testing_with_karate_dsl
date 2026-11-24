@ignore
Feature: STEP sweep - best-effort removal of EVERYTHING one customer/guest owns (orders + cart)
  Registered as a cleanup safety net so an unexpected "success" in a negative test can never leak data.
  args: token (omit for a guest), guestId (default karate-guest)

  Scenario:
    * def a = __arg || {}
    * def collect =
      """
      function(view) {
        var r = karate.call('classpath:steps/customer/order-queries.feature', { token: a.token, guestId: a.guestId, view: view, expect: 'any' });
        return (r.response && r.response.content && r.response.content.data) || [];
      }
      """
    * def purge =
      """
      function(o) {
        karate.call('classpath:steps/customer/cancel-order.feature', { token: a.token, guestId: a.guestId, orderId: o.id, expect: 'any' });
        karate.call('classpath:steps/customer/cleanup.feature', { what: 'order', token: a.token, guestId: a.guestId, orderId: o.id, expect: 'any' });
      }
      """
    * def orders = collect('running').concat(collect('list'))
    * eval karate.forEach(orders, purge)
    * def cleared = call read('classpath:steps/customer/cleanup.feature') { what: 'cart', token: '#(a.token)', guestId: '#(a.guestId)', expect: 'any' }
