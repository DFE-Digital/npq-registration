class StateDiagram
  def self.svg(machine:, only_from_state: nil, ignore_states: [])
    graph = GraphViz.new('G', rankdir: 'TB', ratio: 'fill')

    states_to_show = []

    states = machine.states.to_a.reject { |state| state.name.in?(ignore_states) }
    states.each do |state|
      next if only_from_state && state.name != only_from_state.to_sym

      machine.events.each do |event|
        states_to_show << state.name

        next unless event.transition_for(Statement.new, from: state.name).present?

        states_to_show << event.transition_for(Statement.new, from: state.name).to

        graph.add_edges(
          state.name.to_s,
          event.transition_for(Statement.new, from: state.name).to,
          label: I18n.t!("events.#{state.name}-#{event.name}.name"),
          fontname: 'GDS Transport", arial, sans-serif',
          color: '#0b0c0c',
          fontcolor: '#0b0c0c',
          fontsize: 12,
          tooltip: I18n.t!("events.#{state.name}-#{event.name}.description"),
        )
      end
    end

    states_to_show.compact!
    states_to_show.flatten!
    states_to_show.uniq!

    machine.states.to_a.each do |state|
      if only_from_state && !(only_from_state.to_sym == state.name || state.name.to_sym.in?(states_to_show))
        next
      end

      graph.add_nodes(
        state.name.to_s,
        label: I18n.t!("#{machine.owner_class.to_s.downcase}_states.#{state.name}.name"),
        width: '0.5',
        height: '0.5',
        shape: 'rect',
        style: 'filled',
        color: '#1d70b8',
        fontcolor: '#ffffff',
        fontname: 'GDS Transport", arial, sans-serif',
        fontsize: 15,
        margin: 0.2,
        tooltip: I18n.t!("#{machine.owner_class.to_s.downcase}_states.#{state.name}.description"),
        URL: "#{state.name}",
      )
    end

    if graph.node_count > 3 && only_from_state
      graph[:rankdir] = 'LR'
    end

    # Add negative tabindex to embedded links to prevent SVG generating illogical focus orders
    graph.output(svg: String).force_encoding('UTF-8').gsub('xlink:href', 'tabindex="-1" xlink:href').html_safe
  end
end
