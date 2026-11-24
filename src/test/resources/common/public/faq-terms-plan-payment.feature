@common-public @faq @terms @plan @payment-method
Feature: Common / Faq, Terms, Plan, Payment Method - static pro-customer and payment catalogue endpoints

  Background:
    * url baseUrl

  @positive @smoke
  Scenario: pro-customer FAQs
    Given path 'pro-customer/faqs'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match each response.content.data == { id: '#number', question: '#string', answer: '#string' }

  @positive @smoke
  Scenario: pro-customer terms and conditions page
    Given path 'pro-customer/terms-and-conditions'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains { page_status: '#number', page_title: '#string', page_description: '#string' }

  @positive @smoke
  Scenario: pro-customer subscription plans
    Given path 'pro-customer/plans'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content contains { pro_member_status: '#number', pro_brand: '#string', plans: '#array', pagination: '#object', benefits: '#object' }
    And match each response.content.plans contains { id: '#number', plan_name: '#string', plan_type: '#string', price: '#number', duration: '#number', status: '#number' }
    And match response.content.pagination == schema.pagination

  @positive
  Scenario: plan prices and durations are never negative
    Given path 'pro-customer/plans'
    When method get
    Then status 200
    And match each response.content.plans contains { price: '#? _ >= 0', duration: '#? _ > 0' }

  @positive @smoke
  Scenario: offline payment methods describe their input fields
    Given path 'offline_payment_method_list'
    When method get
    Then status 200
    And match response == schema.ok
    And match response.content == schema.paged
    And match each response.content.data contains { id: '#number', method_name: '#string', method_fields: '#array', method_informations: '#array' }
