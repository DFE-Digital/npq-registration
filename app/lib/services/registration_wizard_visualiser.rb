module Services
  class RegistrationWizardVisualiser
    class << self
      def call
        new.call
      end
    end

    Node = Struct.new(:name, :next_steps, keyword_init: true)

    COLORS = {
      red: "#ff9a8b",
      blue: "#6aa4cf",
      green: "#96d37d",
      purple: "#d7b2d8",
      light_purple: "#beb9db",
      orange: "#ffb55a",
      grey: "#3d3d3d",
    }.freeze

    NODE_COLOR = COLORS[:purple]
    HELPER_COLOR = COLORS[:blue]
    END_STATE_COLOR = COLORS[:red]
    CONFIRMATION_COLOR = COLORS[:green]
    NODE_COLOR_GRADIENT = COLORS[:light_purple]
    EDGE_COLOR = COLORS[:orange]
    WHITE = "white".freeze
    NODE_TEXT_COLOR = "#444444".freeze
    CONTRAST_TEXT_COLOR = COLORS[:grey]
    BACKGROUND_EDGE_COLOR = "#121418".freeze
    BACKGROUND_CENTER_COLOR = "#676783".freeze

    FONT = "Helvetica Neue".freeze
    FONT_SIZE = "25".freeze

    GRAPH_STYLES = {
      label: "NPQ Registration Wizard Flowchart",

      layout: "dot",
      rankdir: "TB",

      size: "30,30!",
      pad: "2",

      fontcolor: "white",
      fontname: FONT,
      fontsize: FONT_SIZE,

      style: "radial",
      gradientangle: "0",
      bgcolor: "#{BACKGROUND_CENTER_COLOR}:#{BACKGROUND_EDGE_COLOR}",

      splines: true,
      overlap: "false",
      nodesep: "1",
      ranksep: "1",
    }.freeze

    NODE_STYLES = {
      style: "rounded,filled",
      gradientangle: "0",
      penwidth: "0",
      height: "0.75",
      margin: "0.25",

      fontname: FONT,
      fontsize: FONT_SIZE,
    }.freeze

    EDGE_STYLES = {
      penwidth: "7",
    }.freeze

    INFORMATION_CLUSTER_STYLES = {
      color: NODE_COLOR,
      label: "Key",
      style: "solid",
      fontcolor: "white",
      bgcolor: "transparent",
      fontsize: "50",
      shape: "box",
      margin: "25,15",
    }.freeze

    def call
      Rails.logger.debug("Generating .dot file")
      digraph_output = generate_digraph_output
      generate_and_save_graph(digraph_output)
    end

  private

    # Image Generation

    def generate_and_save_graph(digraph_output)
      output_digraph_filename = "tmp/visualisations/registration_wizard_visualisation.dot"
      output_graph_filename = "tmp/visualisations/registration_wizard_visualisation.png"

      save_file(output_digraph_filename, digraph_output)

      Rails.logger.debug("Generating #{output_graph_filename}")

      generate_graph_command = "dot -Tpng #{output_digraph_filename} -o #{output_graph_filename}"
      Rails.logger.debug(generate_graph_command)

      system(generate_graph_command)
    end

    def save_file(name, content)
      Rails.logger.debug("Saving #{name}")
      File.open(name, "w") do |f|
        f.write(content)
      end
    end

    # Graph String Generation

    def generate_digraph_output
      <<~DOT
        digraph "Registration Wizard Flow" {
          #{digraph_settings}

          #{information_key}

          #{all_valid_step_nodes.join("\n  ")}

          #{step_nodes.join("\n  ")}

          #{flow_helper_nodes.join("\n  ")}

          #{end_nodes.join("\n  ")}

          #{edges.join("\n  ")}
        }
      DOT
    end

    ## Information Key

    def information_nodes
      [
        { name: "questionnaire_step", color: NODE_COLOR },
        { name: "step_redirection_helper_method", color: HELPER_COLOR },
        { name: "completion_end_step", color: CONFIRMATION_COLOR },
        { name: "end_state_preventing_completion", color: END_STATE_COLOR },
      ]
    end

    def information_cluster_settings_string
      build_settings_string(INFORMATION_CLUSTER_STYLES, joiner: "\n    ")
    end

    def information_key
      node_strings = information_nodes.map do |key_node_info|
        build_node_string(
          name: key_node_info[:name],
          settings: node_settings(
            key_node_info[:name],
            key_node_info[:color],
          ),
        )
      end
      node_names = information_nodes.map { |n| n[:name] }

      <<~DOT
        subgraph cluster_color_key {
            #{information_cluster_settings_string}

            #{node_names.join(' -> ')} [style=invis]

            #{node_strings.join("\n    ")}
          }
      DOT
    end

    ## Step Nodes

    def step_nodes
      step_node_structs.map do |node|
        build_node_string(
          name: node.name,
          settings: node_settings(
            node.name,
            NODE_COLOR,
            gradient: NODE_COLOR_GRADIENT,
            description: node_path(node.name)
          ),
        )
      end
    end

    def step_node_structs
      @step_node_structs ||= step_options.map do |f|
        next_steps = extract_steps_from_source(f.new.method(:next_step).source)

        Node.new(
          name: f.to_s.underscore.split("/").last,
          next_steps:,
        )
      end
    end

    def flow_helper_nodes
      flow_helper_method_node_structs.map do |node|
        build_node_string(
          name: node.name,
          settings: node_settings(node.name, HELPER_COLOR, description: "Forms::FlowHelper"),
        )
      end
    end

    def flow_helper_method_node_structs
      flow_helper_methods.map do |method_name|
        helper_method_source = flow_helper_method_source(method_name)
        # Remove the method name from the source to avoid infinite loops
        helper_method_source.slice!(method_name.to_s)

        Node.new(
          name: method_name,
          next_steps: extract_steps_from_source(helper_method_source),
        )
      end
    end

    def end_nodes
      all_nodes = step_node_structs + flow_helper_method_node_structs
      end_nodes = all_nodes.select { |n| n.next_steps.empty? }

      end_nodes.map do |node|
        color = if %w[confirmation sign_in_code].include?(node.name)
                  CONFIRMATION_COLOR
                else
                  END_STATE_COLOR
                end


        build_node_string(
          name: node.name,
          settings: node_settings(
            node.name,
            color,
            text_color: CONTRAST_TEXT_COLOR,
            description: node_path(node.name)
          ),
        )
      end
    end

    def all_valid_step_nodes
      RegistrationWizard::VALID_REGISTRATION_STEPS
    end

    def edges
      [
        step_node_structs.map { |node| edges_for(node, edge_settings(EDGE_COLOR)) },
        flow_helper_method_node_structs.map { |node| edges_for(node, edge_settings(EDGE_COLOR)) },
      ].flatten.uniq
    end

    # Helpers

    ## Source helpers

    def step_options
      Forms.constants
           .sort
           .map { |f| "Forms::#{f}".constantize }
           .select { |f| f < Forms::Base }
    end

    def flow_helper_methods
      Forms::FlowHelper.instance_methods
    end

    def flow_helper_method_source(method_name)
      Forms::FlowHelper.instance_method(method_name).source
    end

    def extract_steps_from_source(method_source)
      steps = method_source.scan(/[^:]:\w+/).map(&:strip).map { |s| s.delete_prefix(":") }

      helper_step_methods = method_source.scan(/(#{flow_helper_methods.join("|")})/).flatten

      steps + helper_step_methods
    end

    ## Graph builder helpers

    def edges_for(node, settings = nil)
      node.next_steps.map do |next_step|
        "#{node.name} -> #{next_step} [#{settings}]"
      end
    end

    def build_node_string(name:, settings:)
      "#{name} [#{settings}]"
    end

    ## Href helpers

    def node_path(node_name)
      "/registration/#{node_name}"
    end

    ## Setting helpers

    def build_settings_string(settings, joiner: " ")
      settings.map { |k, v| "#{k}=\"#{v}\"" }.join(joiner)
    end

    def left_justify_string(string)
      "#{string}\\l"
    end

    def digraph_settings
      last_updated_at = Time.zone.now.to_s(:govuk_short)
      title_with_version = "#{GRAPH_STYLES[:label]}\nLast Updated: #{last_updated_at}"

      settings = GRAPH_STYLES.merge(label: title_with_version)

      build_settings_string(settings, joiner: "\n  ")
    end

    def node_settings(node_name, color, text_color: NODE_TEXT_COLOR, gradient: nil, description: nil)
      node_title = left_justify_string(node_name.to_s.humanize)

      options = NODE_STYLES.merge(
        color:,
        fillcolor: "#{color}:#{gradient}",
        fontcolor: text_color,
      )

      if description.present?
        options.merge!(
          shape: "record",
          label: "{ #{node_title} | #{left_justify_string(description)} }",
        )
      else
        options.merge!(
          shape: "box",
          label: node_title,
        )
      end

      build_settings_string(options)
    end

    def edge_settings(color)
      build_settings_string(EDGE_STYLES.merge(
                              color:,
                              fillcolor: color,
                            ))
    end
  end
end
