[< Back to Navigation](../README.md)

# Admins and Super Admins

The admin console can be accessed by navigating to `/admin` and logging in.

`Admin` is a totally separate model to `User` and does not use DfE Identity sign-in. Unlike `User`s, `Admin`s are authenticated locally by our app.

There are two types of admin users:
- Admins can perform most actions in the admin console
- Super Admins have additional permissions, such as being able to manage other admins and feature flags

The "Admins" screen itself can be found in the top navigation once logged in.

> n.b. the Admins screen is not visible or accessible to regular Admins.

## Creating and removing admins

Super Admins can create and remove Admin logins using the "Admins" section of the admin console.

## Creating and removing Super Admins

An existing Admin can be elevated to a Super Admin using the "Make Super Admin" link in the "Admins" section of the admin console.

This can also be done by a developer updating the `Admin#super_admin` boolean to `true` in a Rails console.

## Removing a Super Admin

Super Admins can be deleted (but not demoted) from the admin console.

The only way to demote a Super Admin to a regular Admin is for a developer to update the `Admin#super_admin` boolean to `false` using a Rails console.
