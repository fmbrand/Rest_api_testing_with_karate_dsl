@common-public @middleware
Feature: Cross-cutting behaviour - module-check middleware, HTTP verbs, unknown routes, localization

  Background:
    * url baseUrl

  @negative
  Scenario Outline: module-check endpoints reject requests with NO moduleId header - <path>
    * configure headers = { Accept: 'application/json' }
    Given path <path>
    And params <query>
    When method get
    Then status 403
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'forbidden_403', field: 'moduleId' }

    Examples:
      | path                       | query          |
      | 'brand'                    | {}             |
      | 'brand/items/1'            | {}             |
      | 'common-condition'         | {}             |
      | 'common-condition/list'    | {}             |
      | 'common-condition/items/1' | {}             |
      | 'parcel-category'          | {}             |
      | 'parcel-dimension'         | { zone_id: 1 } |
      | 'parcel-weight'            | { zone_id: 1 } |
      | 'items/reviews/1'          | {}             |
      | 'items/rating/1'           | {}             |

  @negative
  Scenario Outline: module-check endpoints reject an invalid moduleId (<moduleId>) - <path>
    * configure headers = { Accept: 'application/json', moduleId: '<moduleId>', zoneId: '[1]' }
    Given path <path>
    When method get
    Then status 403
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'forbidden_403', field: 'moduleId' }

    Examples:
      | path              | moduleId |
      | 'brand'           | 999999   |
      | 'brand'           | abc      |
      | 'brand'           | -1       |
      | 'parcel-category' | 999999   |
      | 'items/reviews/1' | 0        |

  @positive
  Scenario Outline: endpoints WITHOUT module-check work without a moduleId header - <path>
    * configure headers = { Accept: 'application/json' }
    Given path <path>
    When method get
    Then status 200
    And match response == schema.ok

    Examples:
      | path                 |
      | 'config'             |
      | 'module'             |
      | 'zone/list'          |
      | 'get-vehicles'       |
      | 'about-us'           |
      | 'pro-customer/faqs'  |
      | 'react-landing-page' |

  @negative
  Scenario Outline: unsupported HTTP verb <verb> on <path> returns 405
    Given path <path>
    When method <verb>
    Then status 405
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'method_not_allowed_405', field: 'method' }

    Examples:
      | verb   | path        |
      | post   | 'config'    |
      | put    | 'config'    |
      | delete | 'config'    |
      | post   | 'module'    |
      | delete | 'zone/list' |
      | post   | 'about-us'  |

  @negative
  Scenario Outline: unknown route <path> returns the standard 404 envelope
    Given path <path>
    When method get
    Then status 404
    * def chk = call read('classpath:support/assert-error.feature') { body: '#(response)', code: 'default_404', field: 'not-found' }

    Examples:
      | path                |
      | 'does-not-exist'    |
      | 'config/nope'       |
      | 'brand/items/1/2/3' |

  @positive
  Scenario: X-localization changes the translated message
    * def en = call read('classpath:support/message.feature') { lang: 'en' }
    * def bn = call read('classpath:support/message.feature') { lang: 'bn' }
    * assert en.msg != bn.msg

  @positive
  Scenario: unsupported X-localization falls back gracefully (no 5xx)
    * configure headers = { Accept: 'application/json', 'X-localization': 'zz', moduleId: '1', zoneId: '[1]' }
    Given path 'module'
    When method get
    Then status 200
    And match response == schema.ok
