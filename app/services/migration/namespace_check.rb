module Migration
  class NamespaceCheck
    class << self
      def ecf?(obj)
        obj.class.to_s.include?("Ecf")
      end

      def npq?(obj)
        !ecf?(obj)
      end
    end
  end
end
