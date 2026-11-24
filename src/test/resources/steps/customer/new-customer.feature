@ignore
Feature: STEP create a fresh customer and sign in (register + login)
  returns: customer { name, phone, email, password }, token

  Scenario:
    * def reg = call read('classpath:steps/customer/register.feature') {}
    * def customer = reg.customer
    * def login = call read('classpath:steps/customer/login.feature') { email: '#(customer.email)', password: '#(customer.password)' }
    * def token = login.token
    * match token == '#string'
