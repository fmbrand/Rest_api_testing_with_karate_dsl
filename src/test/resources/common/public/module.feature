@common-public @module
Feature: Common / Module - GET /module, GET /module/top-offer

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list modules
    Given path 'module'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match response.content.data == '#[_ > 0]'
    And match each response.content.data contains
      """
      { id: '#number', module_name: '#string', module_type: '#string', slug: '#string', stores_count: '#number', top_offer: '#object' }
      """

  @positive
  Scenario: the module used by every other test (id 1) exists and is active
    Given path 'module'
    When method get
    Then status 200
    * def ids = $response.content.data[*].id
    And match ids contains 1

  @positive
  Scenario: module ids and slugs are unique
    Given path 'module'
    When method get
    Then status 200
    * def ids = $response.content.data[*].id
    * def slugs = $response.content.data[*].slug
    * assert ids.length == new Set(ids).size
    * assert slugs.length == new Set(slugs).size

  @positive
  Scenario: module_type values are one of the known business types
    Given path 'module'
    When method get
    Then status 200
    * def types = $response.content.data[*].module_type
    * def allowed = ['grocery', 'pharmacy', 'ecommerce', 'food', 'parcel', 'rental', 'service', 'ride-share']
    * def unknown = karate.filter(types, function(t){ return allowed.indexOf(t) < 0 })
    And match unknown == '#[0]'

  @positive @smoke
  Scenario: top offer
    Given path 'module/top-offer'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == { discount: '#number', discount_type: '#string' }
    And match response.content.discount_type == '#regex percent|amount'
    And assert response.content.discount >= 0
