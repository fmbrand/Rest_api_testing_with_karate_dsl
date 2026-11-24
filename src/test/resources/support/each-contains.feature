@ignore
Feature: Reusable "each element contains shape" check that tolerates an empty list
  args: list (array), shape (map). Use when the data set may legitimately be empty on the target environment.

  Scenario: validate every element when there are any
    * def a = __arg
    * def list = a.list
    * def shape = a.shape
    * def res = list.length == 0 ? { pass: true } : karate.match('each list contains deep shape')
    * if (!res.pass) karate.fail(res.message)
