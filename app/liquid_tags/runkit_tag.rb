class RunkitTag < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @preamble = sanitized_preamble(markup)
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text
    html = <<~HTML
      <div class="runkit-element">
        <code style="display: none">#{@preamble}</code>
        <code>#{parsed_content}</code>
      </div>
    HTML
    html
  end

  def self.special_script
    <<~JAVASCRIPT
      var targets = document.getElementsByClassName("runkit-element");
      for (var i = 0; i < targets.length; i++) {
        if (targets[i].children.length > 0) {
          var preamble = targets[i].children[0].textContent;
          var content = targets[i].children[1].textContent;
          targets[i].innerHTML = "";
          var notebook = RunKit.createNotebook({
            element: targets[i],
            source: content,
            preamble: preamble
          });
        }
      }
    JAVASCRIPT
  end

  def self.script
    <<~JAVASCRIPT
      var checkRunkit = setInterval(function() {
        try {
          if(typeof(RunKit) !== 'undefined') {
            var targets = document.getElementsByClassName("runkit-element");
            for (var i = 0; i < targets.length; i++) {
              var wrapperContent = targets[i].textContent;
              if(/^(\<iframe src)/.test(wrapperContent) === false) {
                if (targets[i].children.length > 0) {
                  var preamble = targets[i].children[0].textContent;
                  var content = targets[i].children[1].textContent;
                  targets[i].innerHTML = "";
                  var notebook = RunKit.createNotebook({
                    element: targets[i],
                    source: content,
                    preamble: preamble
                  });
                }
              }
            }
            clearInterval(checkRunkit);
          }
        } catch(e) {
          console.error(e);
          clearInterval(checkRunkit);
        }
      }, 200);
    JAVASCRIPT
  end

  def sanitized_preamble(markup)
    raise StandardError, "Runkit tag is invalid" if markup.ends_with? "\">"

    sanitized = ActionView::Base.full_sanitizer.sanitize(markup, tags: [])

    raise StandardError, "Runkit tag is invalid" if markup.starts_with? "\""

    sanitized
  end
end

Liquid::Template.register_tag("runkit", RunkitTag)
