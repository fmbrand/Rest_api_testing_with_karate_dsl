@ignore
Feature: STEP find a store different from notStoreId
  args: notStoreId
  returns: storeId

  Scenario:
    * def a = __arg || {}
    Given url baseUrl
    And path 'stores/get-stores/all'
    When method get
    Then status 200
    * def stores = response.content.data || response.content.stores || []
    * def others = karate.filter(stores, function(s){ return s.id != a.notStoreId })
    * if (others.length == 0) karate.fail('no second store available on this environment')
    * def storeId = others[0].id
