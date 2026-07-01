[< Back to Navigation](../README.md)

# Database seeding

All environments except production can be seeded using `db:seed` or `db:seed:replant`.
By default, this will create ~1300 applications, ~1500 declarations, and ~1200 users.

## Large-scale seeding

To seed a database iwth a large number of applications - approx ~? applications, ~? declarations, and ~? users.

Run the following rake task using the web pod (`make review aks-web-ssh`)(the worker pod does not have enough memory):

```bash
  rake 'large_seed:background'
```

This will set off a background job, to repeatedly run our application and declaration seeds,
which should result in ~20,000 applications and ~20,000 declarations, and ~? users being created in the database.

To check on the progress of the background job, run the task `rake large_seed:check`.
