@common-public @vehicle
Feature: Common / Vehicle - GET /get-vehicles, GET /vehicle/extra_charge

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list delivery vehicles
    Given path 'get-vehicles'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match response.content.data == '#[_ > 0]'
    And match each response.content.data contains { id: '#number', type: '#string' }

  @positive @smoke
  Scenario: extra charge for a distance is a non-negative number
    Given path 'vehicle/extra_charge'
    And param distance = 5
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == '#number'
    And assert response.content >= 0

  @positive
  Scenario Outline: extra charge accepts distance <distance>
    Given path 'vehicle/extra_charge'
    And param distance = <distance>
    When method get
    Then status 200
    And match response.content == '#number'

    Examples:
      | distance |
      | 0        |
      | 0.5      |
      | 100      |
      | 99999    |

  @negative
  Scenario: distance is required
    Given path 'vehicle/extra_charge'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'distance' }

  @known-issue @negative
  Scenario: DEFECT - a non-numeric distance should be rejected with 422 but is accepted with 200
    Given path 'vehicle/extra_charge'
    And param distance = 'abc'
    When method get
    Then status 422
