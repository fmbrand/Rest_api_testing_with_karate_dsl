@common-public @zone
Feature: Common / Zone - GET /zone/list, /zone/check, /config/get-zone-id

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list zones
    Given path 'zone/list'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match response.content.data == '#[_ > 0]'
    And match each response.content.data contains
      """
      {
        id: '#number', name: '#string', formated_coordinates: '#array',
        coordinates: { type: '#string', coordinates: '#array' }, modules: '#array'
      }
      """

  @positive
  Scenario: zone 1 (the zone every other test relies on) exists
    Given path 'zone/list'
    When method get
    Then status 200
    * def ids = $response.content.data[*].id
    And match ids contains 1

  @positive
  Scenario: zone polygons have at least 3 vertices
    Given path 'zone/list'
    When method get
    Then status 200
    And match each response.content.data contains { formated_coordinates: '#[_ >= 3]' }
    And match each response.content.data[*].formated_coordinates[*] == { lat: '#number', lng: '#number' }

  @positive @smoke
  Scenario: a coordinate inside zone 1 is reported as served
    Given path 'zone/check'
    And params { lat: 23.8103, lng: 90.4125, zone_id: 1 }
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == true

  @positive
  Scenario: a coordinate checked against a zone that does not exist is reported as NOT served
    Given path 'zone/check'
    And params { lat: 23.8103, lng: 90.4125, zone_id: 99999 }
    When method get
    Then status 200
    And match response.content == false

  @positive @smoke
  Scenario: resolve the zone(s) for a coordinate
    Given path 'config/get-zone-id'
    And params { lat: 23.8103, lng: 90.4125 }
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content.zone_id == '#regex \\[\\d+(,\\d+)*\\]'
    And match response.content.zone_data == '#[_ > 0]'
    And match each response.content.zone_data contains
      """
      {
        id: '#number', status: '#number', cash_on_delivery: '#boolean', digital_payment: '#boolean',
        offline_payment: '#boolean', modules: '#array'
      }
      """

  @positive
  Scenario: zone_id string lists exactly the ids returned in zone_data
    Given path 'config/get-zone-id'
    And params { lat: 23.8103, lng: 90.4125 }
    When method get
    Then status 200
    * def idsFromString = karate.fromString(response.content.zone_id)
    * def idsFromData = $response.content.zone_data[*].id
    * def sorted = function(a){ var b = []; for (var i = 0; i < a.length; i++) b.push(a[i]); b.sort(function(x, y){ return x - y }); return b }
    And match sorted(idsFromString) == sorted(idsFromData)

  @negative
  Scenario Outline: zone/check - required params (<query>)
    Given path 'zone/check'
    And params <query>
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | query                      | field   |
      | { lng: 90.4, zone_id: 1 }  | lat     |
      | { lat: 23.8, zone_id: 1 }  | lng     |
      | { lat: 23.8, lng: 90.4 }   | zone_id |
      | {}                         | lat     |

  @negative
  Scenario Outline: zone/check - invalid coordinates (<query>)
    Given path 'zone/check'
    And params <query>
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | query                                | field |
      | { lat: 'abc', lng: 90, zone_id: 1 }  | lat   |
      | { lat: 91, lng: 90, zone_id: 1 }     | lat   |
      | { lat: -91, lng: 90, zone_id: 1 }    | lat   |
      | { lat: 23, lng: 'abc', zone_id: 1 }  | lng   |
      | { lat: 23, lng: 181, zone_id: 1 }    | lng   |
      | { lat: 23, lng: -181, zone_id: 1 }   | lng   |

  @negative
  Scenario Outline: get-zone-id - invalid input (<query>)
    Given path 'config/get-zone-id'
    And params <query>
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | query                 | field |
      | {}                    | lat   |
      | { lng: 90.4 }         | lat   |
      | { lat: 23.8 }         | lng   |
      | { lat: 91, lng: 90 }  | lat   |
      | { lat: 23, lng: 181 } | lng   |
      | { lat: 'x', lng: 90 } | lat   |
