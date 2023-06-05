[< Back to Navigation](../README.md)

# Manual validation lifecycle

This is for users that have entered their details but we could not automatically validate with the TRA database via API call. Instead we export these users for a human to validate then re-import the data.

- Export records as CSV for manual validation
```ruby
Services::Exporters::ManualValidation.new.call
```
- After manual validation is complete we need to import the data back into NPQ
```ruby
Services::Importers::ManualValidation.new(path_to_csv: "/PATH/TO.CSV").call
```
- The data will not be synced with ECF so must also be updated there too with the same CSV
- So inside a rails console in ECF
```ruby
Importers::NPQManualValidation.new(path_to_csv: "/PATH/TO.CSV").call
```
- Import is now complete and we need to generate the next batch of manual validation records from NPQ
```ruby
Services::Exporters::ManualValidation.new.call
```
