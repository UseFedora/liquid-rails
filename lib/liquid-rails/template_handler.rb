module Liquid
  module Rails
    class TemplateHandler

      def self.call(template)
        "Liquid::Rails::TemplateHandler.new(self).render(#{template.source.inspect},#{template.virtual_path.inspect}, local_assigns)"
      end

      def initialize(view)
        @view       = view
        @controller = @view.controller
        @helper     = ActionController::Base.helpers
      end

      def render(template_source, virtual_path, local_assigns={})
        @view.controller.headers['Content-Type'] ||= 'text/html; charset=utf-8'

        assigns = if @controller.respond_to?(:liquid_assigns, true)
          @controller.send(:liquid_assigns)
        else
          @view.assigns
        end
        assigns['content_for_layout'] = @view.content_for(:layout) if @view.content_for?(:layout)
        assigns.merge!(local_assigns.stringify_keys)
        template = assigns['custom_templates'][virtual_path] || template_source
        liquid = Liquid::Template.parse(template_source)
        render_method = (::Rails.env.development? || ::Rails.env.test?) ? :render! : :render
        liquid.send(render_method, assigns, filters: filters, registers: { view: @view, controller: @controller, helper: @helper })
      end

      def filters
        if @controller.respond_to?(:liquid_filters, true)
          @controller.send(:liquid_filters)
        else
          [@controller._helpers]
        end
      end

      def compilable?
        false
      end
    end
  end
end
