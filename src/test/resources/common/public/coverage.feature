@common-public @coverage
Feature: Common / Coverage - GET /delivery-charge/coverage-list

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: coverage list of a zone
    Given path 'delivery-charge/coverage-list'
    And param zone_id = 1
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == { type: '#string', coverage: '#array' }
    And match each response.content.coverage == schema.idName

  @positive
  Scenario: optional module_id filter is accepted
    Given path 'delivery-charge/coverage-list'
    And param zone_id = 1
    And param module_id = 1
    When method get
    Then status 200
    And match response == schema.ok

  @negative
  Scenario: zone_id is required
    Given path 'delivery-charge/coverage-list'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'zone_id' }

  @negative
  Scenario Outline: invalid zone_id (<zone_id>) is rejected
    Given path 'delivery-charge/coverage-list'
    And param zone_id = '<zone_id>'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'zone_id' }

    Examples:
      | zone_id |
      | abc     |
      | 99999   |
      | -1      |
      | 0       |
      | 1.5     |

  @negative
  Scenario: module_id must be an integer when supplied
    Given path 'delivery-charge/coverage-list'
    And param zone_id = 1
    And param module_id = 'abc'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'module_id' }
