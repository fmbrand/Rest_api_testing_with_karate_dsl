@common-public @landing-page
Feature: Common / Landing Page - GET /react-landing-page, /flutter-landing-page, /app-download-section

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: react landing page sections
    Given path 'react-landing-page'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains deep
      """
      {
        hero_section: { header_title: '#string', header_sub_title: '#string' },
        trust_section: { trust_section_status: '#number', cards: '#array' },
        available_zone_section: { available_zone_status: '#number', available_zone_list: '#array' },
        promotional_banner_section: '#object',
        user_app_download_section: { download_user_app_section_status: '#number' }
      }
      """
    And match each response.content.available_zone_section.available_zone_list contains { id: '#number', name: '#string', modules: '#array' }

  @positive @smoke
  Scenario: flutter landing page exposes asset base urls
    Given path 'flutter-landing-page'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content.base_urls == '#object'

  @positive @smoke
  Scenario: app download section
    Given path 'app-download-section'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains { download_user_app_section_status: '#number', download_user_app_title: '#string' }
    And match response.content.download_user_app_links contains { playstore_url: '#string', apple_store_url: '#string' }

  @negative
  Scenario Outline: landing endpoints are read-only - POST <path> returns 405
    Given path '<path>'
    When method post
    Then status 405

    Examples:
      | path                 |
      | react-landing-page   |
      | flutter-landing-page |
      | app-download-section |
