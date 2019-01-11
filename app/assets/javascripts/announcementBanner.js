$(function() {
  $(".announcement_banner_header .close-reveal-modal-x").click(function() {
    $(".announcement_banner_header").slideUp(240);
  });

  $(".announcement_banner_header.clickable").click(function() {
    if ($(".announcement_banner_content").is(":hidden")) {
      $(".announcement_banner_content").slideDown(300);
    } else {
      $(".announcement_banner_content").slideUp(240);
    }
  });
});
