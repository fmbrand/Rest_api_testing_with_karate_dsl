@ignore
Feature: helper - returns the localized message of GET /module for a language (arg: lang)

  Scenario:
    * def a = __arg
    * configure headers = { Accept: 'application/json', 'X-localization': '#(a.lang)', moduleId: '1', zoneId: '[1]' }
    Given url baseUrl
    And path 'module'
    When method get
    Then status 200
    * def msg = response.message
