@common-public @dimension @weight
Feature: Common / Dimension + Weight - GET /parcel-dimension, GET /parcel-weight (zone scoped, module-check)

  Background:
    * url baseUrl

  @positive @smoke
  Scenario Outline: <path> for a zone returns unit info and tiers
    Given path '<path>'
    And param zone_id = 1
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains { status: '#boolean', unit: '#object', data: '#array' }
    And match response.content.unit == schema.unit
    And match response.content.unit.supported contains response.content.unit.unit
    And match each response.content.data contains { id: '#number', name: '#string', charge: '#number' }

    Examples:
      | path             |
      | parcel-dimension |
      | parcel-weight    |

  @positive
  Scenario: weight tiers are well-formed (from_weight <= to_weight)
    Given path 'parcel-weight'
    And param zone_id = 1
    When method get
    Then status 200
    And match each response.content.data contains { from_weight: '#number', to_weight: '#number' }
    * def bad = karate.filter(response.content.data, function(w){ return w.from_weight > w.to_weight })
    And match bad == '#[0]'

  @positive
  Scenario: dimension tiers have positive limits
    Given path 'parcel-dimension'
    And param zone_id = 1
    When method get
    Then status 200
    And match each response.content.data contains { max_length: '#number', max_width: '#number', max_height: '#number' }

  @positive
  Scenario Outline: optional module_id is accepted - <path>
    Given path '<path>'
    And param zone_id = 1
    And param module_id = 1
    When method get
    Then status 200
    And match response == schema.ok

    Examples:
      | path             |
      | parcel-dimension |
      | parcel-weight    |

  @negative
  Scenario Outline: zone_id is required - <path>
    Given path '<path>'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'zone_id' }

    Examples:
      | path             |
      | parcel-dimension |
      | parcel-weight    |

  @negative
  Scenario Outline: invalid zone_id (<zone_id>) is rejected - <path>
    Given path '<path>'
    And param zone_id = '<zone_id>'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'zone_id' }

    Examples:
      | path             | zone_id |
      | parcel-dimension | abc     |
      | parcel-dimension | 99999   |
      | parcel-weight    | abc     |
      | parcel-weight    | 99999   |
      | parcel-weight    | -1      |

  @negative
  Scenario Outline: invalid module_id is rejected - <path>
    Given path '<path>'
    And param zone_id = 1
    And param module_id = 'abc'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'module_id' }

    Examples:
      | path             |
      | parcel-dimension |
      | parcel-weight    |
