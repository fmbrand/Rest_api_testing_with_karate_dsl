@common-public @cancellation-reason
Feature: Common / Cancellation Reason - GET /get-parcel-cancellation-reasons

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list parcel cancellation reasons
    Given path 'get-parcel-cancellation-reasons'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match each response.content.data contains { id: '#number', reason: '#string' }

  @positive
  Scenario: reason ids are unique
    Given path 'get-parcel-cancellation-reasons'
    When method get
    Then status 200
    * def ids = $response.content.data[*].id
    * assert ids.length == new Set(ids).size
