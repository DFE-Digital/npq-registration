class UpdateApprovedIttProvider < ActiveRecord::Migration[6.1]
  def change
    itt_provider = IttProvider.unscoped.find_by(legal_name: "St Michael’s Church of England Primary School")
    itt_provider.presence&.update!(legal_name: "Christ Church Primary School Hampstead")
  end
end
