@ignore
Feature: STEP discover a real, orderable catalogue item (no hard-coded ids)
  Walks the brands until one has items and picks the first in-stock one.
  returns: item { id, name, price, storeId, storeName }

  Scenario:
    Given url baseUrl
    And path 'brand'
    And param limit = 50
    When method get
    Then status 200
    * def brands = response.content.data
    * def found = { item: null }
    * def search =
      """
      function() {
        for (var i = 0; i < brands.length && found.item == null; i++) {
          var r = karate.call('classpath:support/brand-items.feature', { brandId: brands[i].id });
          for (var j = 0; j < r.items.length; j++) {
            var it = r.items[j];
            if (it.store_id && it.price > 0 && (it.stock == null || it.stock > 0)) {
              found.item = { id: it.id, name: it.name, price: it.price, storeId: it.store_id, storeName: it.store_name };
              return;
            }
          }
        }
      }
      """
    * eval search()
    * if (found.item == null) karate.fail('no orderable catalogue item found on this environment')
    * def item = found.item
