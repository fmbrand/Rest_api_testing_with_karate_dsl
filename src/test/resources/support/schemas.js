// Reusable Karate match schemas shared by all features (loaded once in karate-config.js).
function() {
  var pagination = {
    current_page: '#number', last_page: '#number', per_page: '#number',
    total: '#number', from: '##number', to: '##number'
  };
  return {
    // every successful API response: { identical_code, message, content, errors: [] }
    ok: { identical_code: '#string', message: '#string', content: '#present', errors: '#[0]' },
    // every failed API response: content null + at least one { code, message }
    error: {
      identical_code: '#string', message: '#string', content: '#null',
      errors: '#[_ > 0]'
    },
    errorItem: { code: '#string', message: '#string' },
    pagination: pagination,
    paged: { data: '#array', pagination: pagination },
    // sub-schemas for common entities
    idName: { id: '#number', name: '#string' },
    unit: { type: '#string', unit: '#string', label: '#string', name: '#string', supported: '#[_ > 0]' }
  };
}
