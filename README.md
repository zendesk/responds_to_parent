![repo-checks](https://github.com/zendesk/responds_to_parent/workflows/repo-checks/badge.svg)
# RespondsToParent

---

Adds responds_to_parent to your controller to respond to the parent document of your page.
Make Ajaxy file uploads by posting the form to a hidden iframe, and respond with
RJS to the parent window.

## Example

---

### Controller

```ruby
  class Test < ActionController::Base
    def main
    end

    def form_action
      # Do stuff with params[:uploaded_file]

      responds_to_parent do
        render :update do |page|
          page << "alert($('stuff').innerHTML)"
        end
      end
    end
  end
```

### main.rhtml

```html
  <html>
    <body>
      <div id="stuff">Here is some stuff</div>

      <form target="frame" action="form_action">
        <input type="file" name="uploaded_file"/>
        <input type="submit"/>
      </form>

      <iframe id='frame' name="frame"></iframe>
    </body>
  </html>
```
