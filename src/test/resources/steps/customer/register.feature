@ignore
Feature: STEP customer sign-up - POST /auth/sign-up
  args (all optional): name, phone, email, password, expect (default 200)
  returns: customer { name, phone, email, password }, status, response
  NOTE: steps read ONLY their own call argument (__arg), never ambient variables of the calling scenario.

  Scenario:
    * def a = __arg || {}
    * def customer =
      """
      {
        name: '#(a.name || "Karate Customer")',
        phone: '#(a.phone || rnd.phone())',
        email: '#(a.email || rnd.email("cust"))',
        password: '#(a.password || "Karate@1234")'
      }
      """
    Given url baseUrl
    And path 'auth/sign-up'
    And request customer
    When method post
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
