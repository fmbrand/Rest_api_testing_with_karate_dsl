@ignore
Feature: Reusable assertion for the standard 6amMart error envelope
  args: body (response json), code (identical_code), field (an errors[].code that must be present)

  Scenario: validate error envelope
    * def a = __arg
    * match a.body == schema.error
    * match each a.body.errors == schema.errorItem
    * match a.body.identical_code == a.code
    * def codes = karate.jsonPath(a.body, '$.errors[*].code')
    * match codes contains a.field
