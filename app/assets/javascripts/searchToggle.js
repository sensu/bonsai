$(function() {
  $('.search_toggle .f-dropdown a').click(function(e) {
    e.preventDefault();
    $(".search_form #supported_platform_id").val($(this).data("supported-platform-id"))
    $('.search_form').attr('action', $(this).data('url'));
    $('.search_toggle .button span').text($(this).text());
    $('.search_form input[type=search]').focus();
    $('#search-types').foundation('dropdown', 'close', $('#search-types'));
  });
});

$(function() {
  $(".advanced_search_toggle span").click(function() {
    if ($(".advanced_search_body").is(":hidden")) {
      $(".advanced_search_body").slideDown(300);
      $.cookie('advancedSearch' ,'on')
      $("#toggle-arrow").removeClass("fa-chevron-down");
      $("#toggle-arrow").addClass("fa-chevron-up");
    } else {
      $(".advanced_search_body").slideUp(240);
      $.cookie('advancedSearch', 'off');
      $('input:checkbox').removeAttr('checked');
      $("#toggle-arrow").removeClass("fa-chevron-up");
      $("#toggle-arrow").addClass("fa-chevron-down");
    }
  });
});

$(".advanced_search_toggle span").ready(function(){
  if ($('.search_toggle .button span').text() == 'Tools') {
    $('.advanced_search_toggle span').hide();
    $('.advanced_search_body').hide();
  }
});
