# app/views/api/v3/statements/index.json.jbuilder

json.array! @statements, partial: 'api/v3/statements/statement', as: :statement