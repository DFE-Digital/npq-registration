class Services::Exporters::UsersWithTrn
  def call
    puts "participant_id,user_id,trn"
    users.each do |user|
      puts "#{user.ecf_id},#{user.id},#{user.trn}"
    end
    nil
  end

private

  def users
    @users ||= User.joins(:applications).where("trn IS NOT NULL").distinct
  end
end
