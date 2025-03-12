# from: https://github.com/dequelabs/axe-core-gems/issues/418
# can be removed when official support of cuprite is available: https://github.com/dequelabs/axe-core-gems/issues/243
module Capybara
  class Session
    alias_method :execute_async_script, :evaluate_async_script
  end

  module Cuprite
    class Browser
      alias_method :execute_async_script, :evaluate_async
      alias_method :execute_script, :evaluate
      alias_method :get, :goto

      def manage
        @manage ||= FakeManager.new(self)
      end

      def switch_to
        @switch_to ||= FakeSwitcher.new(self)
      end

      def close
        close_window(page.target_id)
      end

      class FakeSwitcher
        def initialize(browser)
          @browser = browser
        end

        def window(handle)
          @browser.switch_to_window(handle)
        end
      end

      class FakeManager
        def initialize(browser)
          @browser = browser
        end

        def timeouts
          @timeouts ||= FakeTimeouts.new(@browser)
        end
      end

      class FakeTimeouts
        def initialize(browser)
          @browser = browser
        end

        def page_load
          @browser.timeout
        end

        def page_load=(t)
          @browser.timeout = t
        end
      end
    end
  end
end

module Ferrum
  class Frame
    module Runtime
      prepend(Module.new do
        def evaluate_async(expression, *args)
          # second argument is a timeout in milliseconds
          super(expression, 10 * 1000, *args)
        end
      end)
    end
  end
end

module Axe
  module API
    class Run
      def get_frame_context_script(page)
        script = <<-JS
        (function(context){
          try {
            return window.axe.utils.getFrameContexts(context);
          } catch (err) {
            return {
              violations: [],
              passes: [],
              url: '',
              timestamp: new Date().toString(),
              errorMessage: err.message
            };
          }
        })(arguments[0])
        JS
        page.execute_script_fixed script, @context
      end

      def store_chunk(page, chunk)
        script = <<-JS
        (function(chunk){
          window.partialResults ??= '';
          window.partialResults += chunk;
        })(arguments[0])
        JS
        page.execute_script_fixed script, chunk
      end

      def axe_finish_run(page)
        script = <<-JS
        (function(){
          const partialResults = JSON.parse(window.partialResults || '[]');
          return axe.finishRun(partialResults);
        })()
        JS
        page.execute_script_fixed script
      end
    end
  end
end
