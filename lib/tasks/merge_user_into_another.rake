# Moves all applications and declarations from one user to another user, then archives the first user
# If both users have a uid, then the uid of the user being kept is used
# usage:
# rake 'merge_user_into_another[<user_to_merge_and_archive>,<user_to_keep>,<dry_run>]'
# e.g.
# for dry run: rake 'merge_user_into_another[d43d7f28-aa93-45b9-b641-dd7dfd63516e,542657a1-28a4-4d7d-bb1b-0beb8ca3abe2]'
# for real run: rake 'merge_user_into_another[d43d7f28-aa93-45b9-b641-dd7dfd63516e,542657a1-28a4-4d7d-bb1b-0beb8ca3abe2,false]'
desc "Merge a user into another user"
task :merge_user_into_another, %i[user_ecf_id_to_merge user_ecf_id_to_keep dry_run] => :environment do |_task, args|
  logger = Logger.new($stdout)
  dry_run = args[:dry_run] != "false"
  user_ecf_id_to_merge = args[:user_ecf_id_to_merge]
  user_ecf_id_to_keep = args[:user_ecf_id_to_keep]

  Users::MergeAndArchive.new(user_ecf_id_to_merge:, user_ecf_id_to_keep:, set_uid: true, logger:).call(dry_run:)
end
