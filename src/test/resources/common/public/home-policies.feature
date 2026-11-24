@common-public @home
Feature: Common / Home - policy pages and newsletter subscription

  Background:
    * url baseUrl

  @positive @smoke
  Scenario Outline: <path> returns a non-empty HTML document
    Given path '<path>'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == '#string'
    And assert response.content.trim().length() > 0

    Examples:
      | path                 |
      | terms-and-conditions |
      | about-us             |
      | privacy-policy       |
      | refund-policy        |
      | shipping-policy      |
      | cancelation          |

  @writes @positive @smoke
  Scenario: subscribe a brand-new email address
    * def email = 'karate.' + java.util.UUID.randomUUID() + '@example.com'
    Given path 'newsletter/subscribe'
    And request { email: '#(email)' }
    When method post
    Then status 201
    And match response == schema.ok
    And match response.identical_code == 'default_store_201'

  @writes @negative
  Scenario: subscribing the same email twice is rejected
    * def email = 'karate.' + java.util.UUID.randomUUID() + '@example.com'
    Given path 'newsletter/subscribe'
    And request { email: '#(email)' }
    When method post
    Then status 201
    Given path 'newsletter/subscribe'
    And request { email: '#(email)' }
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'email' }

  @negative
  Scenario: email is required (empty body)
    Given path 'newsletter/subscribe'
    And request {}
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'email' }

  @negative
  Scenario: email is required (blank string)
    Given path 'newsletter/subscribe'
    And request { email: '' }
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'email' }

  @negative
  Scenario Outline: malformed email (<email>) is rejected and never reaches the DB
    Given path 'newsletter/subscribe'
    And request { email: '<email>' }
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'email' }

    Examples:
      | email                     |
      | not-an-email              |
      | plainaddress              |
      | @no-local-part.com        |
      | user@                     |
      | user@@double.com          |
      | user name@example.com     |
      | <script>alert(1)</script> |

  @negative
  Scenario: wrong type for email (number)
    Given path 'newsletter/subscribe'
    And request { email: 12345 }
    When method post
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'email' }

  @negative
  Scenario: wrong type for email (array)
    Given path 'newsletter/subscribe'
    And request { email: ['a@b.com'] }
    When method post
    Then assert responseStatus >= 400 && responseStatus < 500

  @negative
  Scenario: GET is not allowed on /newsletter/subscribe
    Given path 'newsletter/subscribe'
    When method get
    Then status 405
