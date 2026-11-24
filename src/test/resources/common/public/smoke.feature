@common-public @smoke @positive
Feature: Smoke - every public GET endpoint answers 200 with the standard envelope, JSON and acceptable latency

  Background:
    * url baseUrl

  Scenario Outline: GET <path>
    Given path <path>
    And params <query>
    When method get
    Then status 200
    And match header Content-Type contains 'application/json'
    And match response == schema.ok
    And assert responseTime < 8000

    Examples:
      | path                                | query                                      |
      | 'addon-category/list'               | { module_id: 1 }                           |
      | 'brand'                             | {}                                         |
      | 'get-parcel-cancellation-reasons'   | {}                                         |
      | 'common-condition'                  | {}                                         |
      | 'common-condition/list'             | {}                                         |
      | 'config'                            | {}                                         |
      | 'config/get-analytic-scripts'       | {}                                         |
      | 'get-page-meta-data'                | {}                                         |
      | 'delivery-charge/coverage-list'     | { zone_id: 1 }                             |
      | 'parcel-dimension'                  | { zone_id: 1 }                             |
      | 'parcel-weight'                     | { zone_id: 1 }                             |
      | 'pro-customer/faqs'                 | {}                                         |
      | 'terms-and-conditions'              | {}                                         |
      | 'about-us'                          | {}                                         |
      | 'privacy-policy'                    | {}                                         |
      | 'refund-policy'                     | {}                                         |
      | 'shipping-policy'                   | {}                                         |
      | 'cancelation'                       | {}                                         |
      | 'react-landing-page'                | {}                                         |
      | 'flutter-landing-page'              | {}                                         |
      | 'app-download-section'              | {}                                         |
      | 'module'                            | {}                                         |
      | 'module/top-offer'                  | {}                                         |
      | 'item/get-generic-name-list'        | {}                                         |
      | 'item/get-allergy-name-list'        | {}                                         |
      | 'item/get-nutrition-name-list'      | {}                                         |
      | 'parcel-category'                   | {}                                         |
      | 'offline_payment_method_list'       | {}                                         |
      | 'pro-customer/plans'                | {}                                         |
      | 'pro-customer/terms-and-conditions' | {}                                         |
      | 'vehicle/extra_charge'              | { distance: 5 }                            |
      | 'get-vehicles'                      | {}                                         |
      | 'zone/list'                         | {}                                         |
      | 'zone/check'                        | { lat: 23.8103, lng: 90.4125, zone_id: 1 } |
      | 'config/get-zone-id'                | { lat: 23.8103, lng: 90.4125 }             |
