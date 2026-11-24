@ignore
Feature: helper - items of one brand (arg: brandId)

  Scenario:
    * def a = __arg
    Given url baseUrl
    And path 'brand/items', a.brandId
    When method get
    Then status 200
    * def items = response.content.data
