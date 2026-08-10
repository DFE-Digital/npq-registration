# Create admin user
Admin.find_or_create_by!(
  email: "admin@example.com",
  full_name: "example admin",
  super_admin: false,
)

# Create admin user
Admin.find_or_create_by!(
  email: "superadmin@example.com",
  full_name: "example super admin",
  super_admin: true,
)
