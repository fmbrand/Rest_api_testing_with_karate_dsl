@common-public @config
Feature: Common / Config - GET /config, /config/get-analytic-scripts, /get-page-meta-data

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: system configuration exposes the business profile
    Given path 'config'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains
      """
      {
        business_name: '#string', address: '#string', phone: '#string', email: '#string',
        country: '#string', currency_symbol: '#string', default_location: { lat: '#string', lng: '#string' },
        cash_on_delivery: '#present', digital_payment: '#present', maintenance_mode: '#present'
      }
      """

  @positive
  Scenario: app-version info is published for every client app
    Given path 'config'
    When method get
    Then status 200
    And match response.content contains
      """
      {
        app_minimum_version_android: '#present', app_url_android: '#present',
        app_minimum_version_ios: '#present',
        app_minimum_version_android_deliveryman: '#present',
        app_minimum_version_android_store: '#present'
      }
      """

  @positive
  Scenario: config is identical for repeated calls (idempotent GET)
    Given path 'config'
    When method get
    Then status 200
    * def first = response.content
    Given path 'config'
    When method get
    Then status 200
    And match response.content == first

  @positive
  Scenario: analytic scripts
    Given path 'config/get-analytic-scripts'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content.data == '#array'
    And match each response.content.data contains { type: '#string', script_id: '#string' }

  @positive
  Scenario: page meta data answers with the standard envelope
    Given path 'get-page-meta-data'
    When method get
    Then status 200
    And match response == schema.ok
