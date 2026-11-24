@ignore
Feature: STEP search items - GET /items/search
  args: name, storeId (optional), token (optional), expect (default 200)
  returns: items (array), status, response

  Scenario:
    * def a = __arg || {}
    * def auth = a.token ? 'Bearer ' + a.token : null
    Given url baseUrl
    And path 'items/search'
    And param name = a.name
    And param store_id = a.storeId
    And header Authorization = auth
    When method get
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
    * def items = response.content ? response.content.data : []
