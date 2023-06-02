[< Back to Navigation](../README.md)

# Admins and Superadmins

1. [Admins](#admins)
1. [Super Admins](#super-admins)

The NPQ app supports two types of admin users: `admin` and `superadmin`. Admins can perform most actions in the app, but superadmins have additional permissions, such as being able to create and edit other admin users along with managing feature flags.

The admin console can be accessed by navigating to `/admin` and logging in. The panel itself can be found by cliking "Admin" once logged in.

## Admins 

Admins have the ability to access the admin panel and view/manage information regarding users and applications. They are able to retrigger syncs between NPQ and ECF for data that has failed to sync.

Admin permissions are controlled by the `admin` boolean flag on the `users` table.

### Removing an admin

Super admins can remove admin status from any other user by visiting `/admin/admins`, finding the user in the interface and clicking "Remove as admin".

## Super Admins

Superadmins have the same permissions as admins, but also have the ability to manage other admin users and feature flags.

They can elevate existing admins to super admin status.

Super admin permissions are controlled by the `super_admin` boolean flag on the `users` table. Both it and admin must be set to true.

### Removing a superadmin

Super admins cannot have their permissions removed from the interface, the only way to do this is to remove the `super_admin` flag from the user in the database.
