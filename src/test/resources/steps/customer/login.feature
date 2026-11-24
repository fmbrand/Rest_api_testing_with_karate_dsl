@ignore
Feature: STEP customer login - POST /auth/login (manual, by e-mail or phone)
  args: email (or phone), password, expect (default 200)
  returns: token (null when login is rejected), status, response

  Scenario:
    * def a = __arg || {}
    * def identity = a.email || a.phone
    * def fieldType = a.email ? 'email' : 'phone'
    Given url baseUrl
    And path 'auth/login'
    And request { login_type: 'manual', email_or_phone: '#(identity)', password: '#(a.password)', field_type: '#(fieldType)' }
    When method post
    * eval expectStatus(responseStatus, a.expect == null ? 200 : a.expect, response)
    * def status = responseStatus
    * def token = response.content ? response.content.token : null
