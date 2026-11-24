@common-public @common-condition
Feature: Common / Common Condition - GET /common-condition, /common-condition/list, /common-condition/items/{id}

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: index returns a paged envelope
    Given path 'common-condition'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged

  @positive @smoke
  Scenario: options list returns id + name pairs
    Given path 'common-condition/list'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match response.content.data == '#[_ > 0]'
    And match each response.content.data == schema.idName

  @positive
  Scenario: items of an existing condition
    Given path 'common-condition/list'
    When method get
    Then status 200
    * def conditionId = response.content.data[0].id
    Given path 'common-condition/items', conditionId
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged

  @positive
  Scenario: items of an unknown condition return an empty page
    Given path 'common-condition/items', 999999
    When method get
    Then status 200
    And match response.content.data == '#[0]'

  @negative
  Scenario Outline: condition items with a malformed id (<id>) never produce a server error
    Given path 'common-condition/items', '<id>'
    When method get
    Then assert responseStatus < 500

    Examples:
      | id  |
      | abc |
      | -1  |
      | 0   |
