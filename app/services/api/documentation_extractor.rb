# {"openapi"=>"3.0.3",
#  "info"=>{"title"=>"npq", "version"=>"1.0.0"},
#  "servers"=>[],
#  "paths"=>
#   {"/api/v1/npq-applications"=>
#     {"get"=>
#       {"summary"=>"List all applications",
#        "tags"=>["v1", "applications"],
#        "security"=>[{"SomeToken"=>"xyz"}],
#        "responses"=>
#         {"200"=>
#           {"description"=>
#             "Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit\nenim labore culpa sint ad nisi Lorem pariatur mollit ex esse\nexercitation amet. Nisi anim cupidatat excepteur officia. Reprehenderit\nnostrud nostrud ipsum
#  Lorem est aliquip amet voluptate voluptate dolor\nminim nulla est proident. Nostrud officia pariatur ut officia. Sit irure\nduis.\n",
#            "content"=>{"application/json"=>{"schema"=>{"type"=>"object", "properties"=>{"hello"=>{"type"=>"string"}}, "required"=>["hello"]}, "example"=>{"hello"=>"world"}}}}}}}}}
#
module Api
  class DocumentationExtractor
    attr_reader :schema, :paths

    def initialize(path: Rails.root.join("docs/schema.yaml"))
      @schema = YAML.load_file(path)

      @paths = @schema["paths"].map { |name, verb_hash| Path.new(name, verb_hash) }
    end

    def inspect
      paths.map(&:inspect).to_yaml
    end

    class Path
      attr_accessor :name, :verbs

      def initialize(name, verbs_hash)
        @name = name
        @verbs = verbs_hash.map { |verb_name, verb_hash| Verb.new(verb_name, verb_hash) }
      end

      def inspect
        { name => verbs.map(&:inspect) }
      end
    end

    class Verb
      attr_reader :name, :responses

      def initialize(name, verb_hash)
        @name = name
        @responses = verb_hash["responses"].map { |code, response_hash| Response.new(code, response_hash) }
      end

      def inspect
        { name => responses.map(&:inspect) }
      end
    end

    class Response
      attr_reader :code, :response

      def initialize(code, response_hash)
        @code = code
        @response_hash = response_hash
        @response = "todo"
      end

      def inspect
        { code => response }
      end
    end
  end
end
