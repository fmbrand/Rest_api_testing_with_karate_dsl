@common-public @name-list
Feature: Common / Name List - GET /item/get-generic-name-list, /get-allergy-name-list, /get-nutrition-name-list

  Background:
    * url baseUrl

  @positive @smoke
  Scenario Outline: <path> returns id + name pairs
    Given path 'item/<path>'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match each response.content.data == schema.idName

    Examples:
      | path                    |
      | get-generic-name-list   |
      | get-allergy-name-list   |
      | get-nutrition-name-list |

  @positive
  Scenario Outline: <path> pagination honours limit
    Given path 'item/<path>'
    And param limit = 1
    When method get
    Then status 200
    And match response.content.pagination.per_page == 1
    And match response.content.data == '#[_ <= 1]'

    Examples:
      | path                    |
      | get-generic-name-list   |
      | get-allergy-name-list   |
      | get-nutrition-name-list |

  @negative
  Scenario Outline: <path> is read-only (POST -> 405)
    Given path 'item/<path>'
    When method post
    Then status 405

    Examples:
      | path                    |
      | get-generic-name-list   |
      | get-allergy-name-list   |
      | get-nutrition-name-list |
