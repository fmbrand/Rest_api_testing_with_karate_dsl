@common-public @brand
Feature: Common / Brand - GET /brand, GET /brand/items/{brand_id}

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list brands
    Given path 'brand'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match response.content.data == '#[_ > 0]'
    And match each response.content.data contains { id: '#number', name: '#string', slug: '#string' }

  @positive
  Scenario: pagination - limit controls page size, offset is the page number
    Given path 'brand'
    And param limit = 2
    When method get
    Then status 200
    And match response.content.pagination.per_page == 2
    And match response.content.data == '#[2]'
    And match response.content.pagination.current_page == 1
    * def total = response.content.pagination.total
    Given path 'brand'
    And param limit = 2
    And param offset = 2
    When method get
    Then status 200
    And match response.content.pagination.current_page == 2
    And match response.content.pagination.total == total

  @positive
  Scenario: an offset beyond the last page returns an empty data array
    Given path 'brand'
    And param limit = 2
    And param offset = 9999
    When method get
    Then status 200
    And match response.content.data == '#[0]'
    And match response.content.pagination.from == null

  @positive
  Scenario: items of a brand that has items
    * def found = call read('classpath:support/first-brand-item.feature')
    Given path 'brand/items', found.brandId
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match response.content.data == '#[_ > 0]'
    And match each response.content.data contains { id: '#number', name: '#string', price: '#number', module_id: '#number' }
    * def ids = $response.content.data[*].id
    And match ids contains found.itemId

  @positive
  Scenario: items of a brand with no items are an empty page
    Given path 'brand'
    And param limit = 100
    When method get
    Then status 200
    * def empty = karate.filter(response.content.data, function(b){ return karate.call('classpath:support/brand-items.feature', { brandId: b.id }).items.length == 0 })
    * if (empty.length == 0) karate.abort()
    Given path 'brand/items', empty[0].id
    When method get
    Then status 200
    And match response.content.data == '#[0]'
    And match response.content.pagination.total == 0

  @positive
  Scenario: items of an unknown brand return an empty page
    Given path 'brand/items', 999999
    When method get
    Then status 200
    And match response.content.data == '#[0]'

  @negative
  Scenario Outline: brand items with a malformed id (<id>) never produce a server error
    Given path 'brand/items', '<id>'
    When method get
    Then assert responseStatus < 500

    Examples:
      | id  |
      | abc |
      | -1  |
      | 0   |
      | 1.5 |
