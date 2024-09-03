desc 'Generate a graph for the application states'
task generate_state_diagram: :environment do
  require 'state_machines/graphviz'

  ["Declaration", "Statement", "StatementItem"].each do |class_name|
    StateMachines::Machine.draw(class_name, { path: "docs/" })
  end
end
