@ignore
Feature: STEP read orders - choose with arg `view`: details | running | list | track
  args: token (omit for a guest), guestId (default karate-guest), view, orderId (details/track), contactNumber (track), expect (default 200)
  returns: status, response, data (details -> order lines, running/list -> orders), order (the order with orderId, running/list)

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    * def paths = { details: 'customer/order/details', running: 'customer/order/running-orders', list: 'customer/order/list', track: 'customer/order/track' }
    * def view = a.view
    Given url baseUrl
    And path paths[view]
    And param guest_id = a.guestId || 'karate-guest'
    And param order_id = view == 'details' || view == 'track' ? a.orderId : null
    And param contact_number = view == 'track' ? a.contactNumber : null
    And header Authorization = auth
    When method get
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
    * def data = response.content ? (view == 'details' ? response.content : (response.content.data || response.content)) : null
    * def pick = function(rows, id){ if (!rows || !rows.length) return null; for (var i = 0; i < rows.length; i++) if (rows[i].id == id) return rows[i]; return null }
    * def order = view == 'running' || view == 'list' ? pick(data, a.orderId) : null
