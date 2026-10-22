/* Progressive enhancements: navigation toggle and copy buttons. */
(function () {
  "use strict";

  var toggle = document.querySelector(".nav-toggle");
  var nav = document.getElementById("site-nav");

  if (toggle && nav) {
    var setOpen = function (open) {
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      nav.classList.toggle("is-open", open);
    };

    toggle.addEventListener("click", function () {
      setOpen(toggle.getAttribute("aria-expanded") !== "true");
    });

    nav.addEventListener("click", function (event) {
      if (event.target.closest("a")) {
        setOpen(false);
      }
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && toggle.getAttribute("aria-expanded") === "true") {
        setOpen(false);
        toggle.focus();
      }
    });

    document.addEventListener("click", function (event) {
      if (!nav.contains(event.target) && !toggle.contains(event.target)) {
        setOpen(false);
      }
    });
  }

  var blocks = document.querySelectorAll(".codeblock");
  blocks.forEach(function (block, index) {
    var pre = block.querySelector("pre");
    if (!pre) {
      return;
    }
    var button = document.createElement("button");
    button.type = "button";
    button.className = "copy-btn";
    button.textContent = "copy";
    button.setAttribute("aria-label", "Copy code block " + (index + 1));
    block.appendChild(button);

    button.addEventListener("click", function () {
      var text = pre.innerText;
      var done = function () {
        button.textContent = "copied";
        button.classList.add("is-copied");
        window.setTimeout(function () {
          button.textContent = "copy";
          button.classList.remove("is-copied");
        }, 1800);
      };
      var fallback = function () {
        var area = document.createElement("textarea");
        area.value = text;
        area.setAttribute("readonly", "");
        area.style.position = "fixed";
        area.style.opacity = "0";
        document.body.appendChild(area);
        area.select();
        try {
          document.execCommand("copy");
          done();
        } catch (error) {
          button.textContent = "select";
        }
        document.body.removeChild(area);
      };

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, fallback);
      } else {
        fallback();
      }
    });
  });
})();
