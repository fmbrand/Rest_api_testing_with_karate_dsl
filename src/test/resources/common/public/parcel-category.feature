@common-public @parcel-category
Feature: Common / Parcel Category - GET /parcel-category (module-check)

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list parcel categories
    Given path 'parcel-category'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged

  @positive
  Scenario: the parcel module (if configured) is addressable through moduleId
    Given path 'module'
    When method get
    Then status 200
    * def parcel = karate.filter(response.content.data, function(m){ return m.module_type == 'parcel' })
    * if (parcel.length == 0) karate.abort()
    * configure headers = { Accept: 'application/json', moduleId: '#(parcel[0].id + "")', zoneId: '[1]' }
    Given path 'parcel-category'
    When method get
    Then status 200
    And match response.content == schema.paged
    And match each response.content.data contains { id: '#number', name: '#string' }
