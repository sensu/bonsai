$(function() {
  if (getCookie("no_announcement_banner") == "beta_launch") {
    $(".announcement_banner_header").hide();
  }
  $(".announcement_banner_header .close-reveal-modal-x").click(function() {
    $(".announcement_banner_header").slideUp(240);
    document.cookie = "no_announcement_banner=beta_launch; max_age=31536000; path=/"
  });

  $(".announcement_banner_header.clickable").click(function() {
    if ($(".announcement_banner_content").is(":hidden")) {
      $(".announcement_banner_content").slideDown(300);
    } else {
      $(".announcement_banner_content").slideUp(240);
    }
  });
});

function getCookie(cname) {
  var name = cname + "=";
  var decodedCookie = decodeURIComponent(document.cookie);
  var ca = decodedCookie.split(';');
  for(var i = 0; i <ca.length; i++) {
    var c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}
