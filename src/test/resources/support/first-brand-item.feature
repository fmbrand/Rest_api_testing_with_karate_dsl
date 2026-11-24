@ignore
Feature: helper - discover a real catalogue item (first item of the first brand that has items)
  Returns: brandId, itemId, item

  Scenario:
    Given url baseUrl
    And path 'brand'
    When method get
    Then status 200
    * def brands = response.content.data
    * def found = { brandId: null, itemId: null, item: null }
    * def search =
      """
      function() {
        for (var i = 0; i < brands.length && found.itemId == null; i++) {
          var r = karate.call('classpath:support/brand-items.feature', { brandId: brands[i].id });
          if (r.items.length > 0) { found.brandId = brands[i].id; found.item = r.items[0]; found.itemId = r.items[0].id; }
        }
      }
      """
    * eval search()
    * if (found.itemId == null) karate.fail('no catalogue item found - cannot run item based tests')
    * def brandId = found.brandId
    * def itemId = found.itemId
    * def item = found.item
