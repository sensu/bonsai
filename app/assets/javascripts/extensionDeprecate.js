$(document).ready(function() {
  var settings =  {
    placeholder: 'Search for replacement asset',
    minimumInputLength: 3,
    width: '100%',
    ajax: {
      url: $('.extension-deprecate').data('url'),
      dataType: 'json',
      processResults: function (data, page) {
        let results = data.items.map(o => {
          let id_vals = [o.extension_owner, o.extension_name];
          return {id: id_vals.join(','), text: id_vals.join('/')}
        })
        return { results: results };
      }
    }
  }

  $('.extension-deprecate').select2(settings);

  $('.extension-deprecate').on("select2:select", function(e) {
    $('.submit-deprecation').prop('disabled', false);
  });
});
