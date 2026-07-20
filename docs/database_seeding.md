[< Back to Navigation](../README.md)

# Database seeding

All environments except production can be seeded using `db:seed` or `db:seed:replant`.
By default, this will create:

* locally: ~800 applications, ~1500 declarations, and ~800 users.
* on review apps: ~1300 applications, ~1500 declarations, and ~1200 users.

## Large-scale seeding

To seed a database with a large number of applications - approx ~18,000 applications, ~7,000 declarations, and ~17,000 users,
run the following rake task:

```bash
  rake 'large_seed:background'
```

This will set off a background job, to repeatedly run our application and declaration seeds.

To check on the progress of the background job, run the task `rake large_seed:check`.
