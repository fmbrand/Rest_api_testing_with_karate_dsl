@common-public @review
Feature: Common / Review - GET /items/reviews/{item_id}, /items/rating/{item_id}, POST /items/reviews/submit

  Background:
    * url baseUrl
    # discover a real item id from the catalogue instead of hard-coding one
    * def firstBrand = call read('classpath:support/first-brand-item.feature')
    * def itemId = firstBrand.itemId

  @positive @smoke
  Scenario: reviews of an item include a rating summary
    Given path 'items/reviews', itemId
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains { rating_summary: '#object', data: '#array', pagination: '#object' }
    And match response.content.pagination == schema.pagination
    And match response.content.rating_summary contains { avg_rating: '#number', total_reviews: '#number', breakdown: '#[5]' }
    And match each response.content.rating_summary.breakdown == { label: '#string', star: '#number', count: '#number' }

  @positive
  Scenario: rating summary is internally consistent
    Given path 'items/reviews', itemId
    When method get
    Then status 200
    * def s = response.content.rating_summary
    * def sum = 0
    * eval karate.forEach(s.breakdown, function(b){ sum += b.count })
    And assert sum == s.total_reviews
    And assert s.avg_rating >= 0 && s.avg_rating <= 5

  @positive
  Scenario: every listed review has the documented shape
    Given path 'items/reviews', itemId
    When method get
    Then status 200
    * def shape = { id: '#number', rating: '#number', created_at: '#string', customer: { id: '#number', f_name: '#string' } }
    * def chk = call read('classpath:support/each-contains.feature') { list: '#(response.content.data)', shape: '#(shape)' }

  @positive
  Scenario: reviews of an unknown item are an empty list, not an error
    Given path 'items/reviews', 999999
    When method get
    Then status 200
    And match response.content.data == '#[0]'
    And match response.content.rating_summary.total_reviews == 0

  @positive @smoke
  Scenario: average rating of an item
    Given path 'items/rating', itemId
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == { rating: '#number' }
    And assert response.content.rating >= 0 && response.content.rating <= 5

  @negative
  Scenario Outline: rating of a non-existent item (<id>) is 404
    Given path 'items/rating', '<id>'
    When method get
    Then status 404
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'default_404', field: 'item' }

    Examples:
      | id     |
      | 999999 |
      | abc    |
      | 0      |

  @negative
  Scenario: submitting a review requires authentication
    Given path 'items/reviews/submit'
    And request { item_id: 1, order_id: 1, rating: 5 }
    When method post
    Then status 401
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unauthorized_401', field: 'auth-001' }

  @negative
  Scenario Outline: submitting a review with an invalid bearer token (<token>) is rejected
    Given path 'items/reviews/submit'
    And header Authorization = 'Bearer <token>'
    And request { item_id: 1, order_id: 1, rating: 5 }
    When method post
    Then status 401
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unauthorized_401', field: 'auth-001' }

    Examples:
      | token                                   |
      | invalid.token.value                     |
      | 0                                       |
      | eyJhbGciOiJub25lIn0.e30.                |
