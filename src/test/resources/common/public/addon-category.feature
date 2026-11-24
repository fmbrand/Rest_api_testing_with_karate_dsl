@common-public @addon-category
Feature: Common / Addon Category - GET /addon-category/list

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: list addon categories for a module
    Given path 'addon-category/list'
    And param module_id = 1
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    * def chk = call read('classpath:support/each-contains.feature') { list: '#(response.content.data)', shape: { id: '#number', name: '#string' } }

  @positive
  Scenario: an unknown module returns an empty page, not an error
    Given path 'addon-category/list'
    And param module_id = 999999
    When method get
    Then status 200
    And match response.content.data == '#[0]'
    And match response.content.pagination.total == 0

  @negative
  Scenario: module_id is required
    Given path 'addon-category/list'
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'module_id' }
