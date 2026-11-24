// Global Karate config. Select environment with -Dkarate.env=<name>; override anything with -D / env vars.
function fn() {
  var env = karate.env || 'test';

  var urls = {
    test: 'https://6ammart-test.6amdev.xyz'
  };

  var baseUrl = karate.properties['baseUrl'] || java.lang.System.getenv('SIXAM_BASE_URL') || urls[env];
  if (!baseUrl) {
    karate.fail('Unknown env "' + env + '" and no -DbaseUrl provided');
  }

  var config = {
    env: env,
    baseUrl: baseUrl.replace(/\/+$/, '') + '/api/v1',
    // defaults sent with every request; features can override per scenario
    lang: 'en',
    zoneId: '[1]',
    moduleId: '1',
    schema: karate.call('classpath:support/schemas.js'),
    // credentials are only needed by authenticated folders; supply via env vars / -D, never commit them
    creds: {
      customer: { email: karate.properties['customerEmail'] || java.lang.System.getenv('SIXAM_CUSTOMER_EMAIL'),
                  password: karate.properties['customerPassword'] || java.lang.System.getenv('SIXAM_CUSTOMER_PASSWORD') },
      admin: { email: karate.properties['adminEmail'] || java.lang.System.getenv('SIXAM_ADMIN_EMAIL'),
               password: karate.properties['adminPassword'] || java.lang.System.getenv('SIXAM_ADMIN_PASSWORD') }
    }
  };

  // ---- scenario engine helpers -------------------------------------------------------------
  // NOTE: Karate re-evaluates functions stored in variables in the scenario's own JS context, so every
  // function below must be self-contained (no references to other config locals).
  // unique, recognisable test data: every created record carries "karate" so leftovers can be swept
  config.rnd = {
    digits: function(n) {
      var R = Java.type('java.util.concurrent.ThreadLocalRandom'), s = '';
      for (var i = 0; i < n; i++) s += R.current().nextInt(10);
      return s;
    },
    uid: function() {
      var R = Java.type('java.util.concurrent.ThreadLocalRandom');
      return java.lang.Long.toString(java.lang.System.currentTimeMillis(), 36) + R.current().nextInt(1000, 9999);
    },
    phone: function() {
      var R = Java.type('java.util.concurrent.ThreadLocalRandom'), s = '';
      for (var i = 0; i < 8; i++) s += R.current().nextInt(10);
      return '+88017' + s;
    },
    email: function(prefix) {
      var R = Java.type('java.util.concurrent.ThreadLocalRandom');
      var id = java.lang.Long.toString(java.lang.System.currentTimeMillis(), 36) + R.current().nextInt(1000, 9999);
      return 'karate.' + (prefix || 'user') + '.' + id + '@example.com';
    }
  };

  // one status assertion shared by every step feature: expected = number | 'any'
  config.expectStatus = function(actual, expected, response) {
    if (expected == 'any') return;
    var ok = (expected instanceof Array) ? expected.indexOf(actual) >= 0 : actual == expected;
    if (!ok) {
      karate.fail('expected HTTP ' + expected + ' but got ' + actual + ' - ' + karate.pretty(response));
    }
  };

  // Scenario context: carries ids between steps and owns the cleanup stack.
  //   ctx.defer(name, feature, args)  register a best-effort cleanup action (runs LIFO)
  //   ctx.done(name)                  mark it as already performed by the scenario itself
  //   ctx.teardown()                  run everything still pending - wired to afterScenario, so it
  //                                   executes even when an assertion failed half-way through the flow
  config.newCtx = function() {
    var ctx = { data: {}, cleanup: [], errors: [] };
    ctx.defer = function(name, feature, args) {
      ctx.cleanup.push({ name: name, feature: feature, args: args || {}, done: false });
    };
    ctx.done = function(name) {
      for (var i = 0; i < ctx.cleanup.length; i++) if (ctx.cleanup[i].name == name) ctx.cleanup[i].done = true;
    };
    ctx.teardown = function() {
      for (var i = ctx.cleanup.length - 1; i >= 0; i--) {
        var c = ctx.cleanup[i];
        if (c.done) continue;
        try {
          karate.call(c.feature, c.args);
          c.done = true;
          karate.log('cleanup ok: ' + c.name);
        } catch (e) {
          ctx.errors.push(c.name);
          karate.log('CLEANUP FAILED: ' + c.name + ' - ' + e);
        }
      }
    };
    return ctx;
  };

  karate.configure('connectTimeout', 15000);
  karate.configure('readTimeout', 45000);
  karate.configure('headers', {
    'Accept': 'application/json',
    'X-localization': config.lang,
    'zoneId': config.zoneId,
    'moduleId': config.moduleId
  });
  return config;
}
