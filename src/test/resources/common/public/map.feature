@common-public @map @external
Feature: Common / Map - Google-backed lookups (throttle:map-lookup)
  These hit an upstream provider, so they are kept to a minimum number of calls.

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: place autocomplete returns suggestions with a place id
    Given path 'config/place-api-autocomplete'
    And param search_text = 'dhaka'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content.suggestions == '#[_ > 0]'
    And match each response.content.suggestions contains deep { placePrediction: { placeId: '#string', place: '#string' } }

  @positive
  Scenario: place details can be fetched with a place id obtained from autocomplete
    Given path 'config/place-api-autocomplete'
    And param search_text = 'dhaka'
    When method get
    Then status 200
    * def placeId = response.content.suggestions[0].placePrediction.placeId
    Given path 'config/place-api-details'
    And param placeid = placeId
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == '#object'
    And match response.content.error == '#notpresent'

  @positive
  Scenario: optional session_token is accepted
    Given path 'config/place-api-autocomplete'
    And param search_text = 'dhaka'
    And param session_token = 'karate-session-token'
    When method get
    Then status 200
    And match response == schema.ok

  @positive @smoke
  Scenario: driving direction between two points
    Given path 'config/direction-api'
    And params { origin_lat: 23.8103, origin_lng: 90.4125, destination_lat: 23.9, destination_lng: 90.5 }
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content.routes == '#[_ > 0]'
    And match response.content.routes[0] contains deep { distanceMeters: '#number', duration: '#string', polyline: { encodedPolyline: '#string' } }
    And assert response.content.routes[0].distanceMeters > 0

  @positive @smoke
  Scenario Outline: distance matrix - mode <mode>
    Given path 'config/distance-api'
    And params { origin_lat: 23.8103, origin_lng: 90.4125, destination_lat: 23.9, destination_lng: 90.5 }
    And param mode = '<mode>'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains { distanceMeters: '#number', duration: '#string', localizedValues: '#object' }
    And assert response.content.distanceMeters > 0

    Examples:
      | mode  |
      | DRIVE |
      | WALK  |

  @positive @smoke
  Scenario: reverse geocoding a coordinate
    Given path 'config/geocode-api'
    And params { lat: 23.8103, lng: 90.4125 }
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content.status == 'OK'
    And match response.content.results == '#[_ > 0]'
    And match each response.content.results contains { formatted_address: '#string', place_id: '#string' }

  @negative
  Scenario Outline: required params missing - <path>
    Given path '<path>'
    And params <query>
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | path                          | query                                                                  | field           |
      | config/place-api-autocomplete | {}                                                                     | search_text     |
      | config/place-api-details      | {}                                                                     | placeid         |
      | config/geocode-api            | { lng: 90.4 }                                                          | lat             |
      | config/geocode-api            | { lat: 23.8 }                                                          | lng             |
      | config/direction-api          | { origin_lng: 90.4, destination_lat: 23.9, destination_lng: 90.5 }     | origin_lat      |
      | config/direction-api          | { origin_lat: 23.8, destination_lat: 23.9, destination_lng: 90.5 }     | origin_lng      |
      | config/direction-api          | { origin_lat: 23.8, origin_lng: 90.4, destination_lng: 90.5 }          | destination_lat |
      | config/direction-api          | { origin_lat: 23.8, origin_lng: 90.4, destination_lat: 23.9 }          | destination_lng |
      | config/distance-api           | { origin_lng: 90.4, destination_lat: 23.9, destination_lng: 90.5 }     | origin_lat      |
      | config/distance-api           | { origin_lat: 23.8, origin_lng: 90.4, destination_lat: 23.9 }          | destination_lng |

  @negative
  Scenario Outline: out-of-range coordinates are rejected - <path> <query>
    Given path '<path>'
    And params <query>
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: '<field>' }

    Examples:
      | path                 | query                                                                    | field           |
      | config/geocode-api   | { lat: 91, lng: 90 }                                                     | lat             |
      | config/geocode-api   | { lat: -91, lng: 90 }                                                    | lat             |
      | config/geocode-api   | { lat: 23, lng: 181 }                                                    | lng             |
      | config/geocode-api   | { lat: 23, lng: -181 }                                                   | lng             |
      | config/geocode-api   | { lat: 'abc', lng: 90 }                                                  | lat             |
      | config/direction-api | { origin_lat: 999, origin_lng: 90, destination_lat: 23, destination_lng: 90 } | origin_lat |
      | config/direction-api | { origin_lat: 23, origin_lng: 999, destination_lat: 23, destination_lng: 90 } | origin_lng |
      | config/direction-api | { origin_lat: 23, origin_lng: 90, destination_lat: -999, destination_lng: 90 } | destination_lat |
      | config/distance-api  | { origin_lat: 23, origin_lng: 'x', destination_lat: 23, destination_lng: 90 } | origin_lng |
      | config/distance-api  | { origin_lat: 23, origin_lng: 90, destination_lat: 23, destination_lng: 999 } | destination_lng |

  @negative
  Scenario: unsupported distance mode is rejected
    Given path 'config/distance-api'
    And params { origin_lat: 23.8, origin_lng: 90.4, destination_lat: 23.9, destination_lng: 90.5, mode: 'BIKE' }
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'mode' }

  @negative
  Scenario: session_token longer than 128 chars is rejected
    * def longToken = java.lang.String.join('', java.util.Collections.nCopies(129, 'a'))
    Given path 'config/place-api-autocomplete'
    And param search_text = 'dhaka'
    And param session_token = longToken
    When method get
    Then status 422
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'unprocessable_entity_422', field: 'session_token' }

  @known-issue @negative
  Scenario: DEFECT - an invalid place id should be a 4xx, but the API returns 200 with the upstream Google error in content
    Given path 'config/place-api-details'
    And param placeid = 'not-a-real-place-id'
    When method get
    Then assert responseStatus >= 400 && responseStatus < 500
