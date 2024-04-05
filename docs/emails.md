[< Back to Navigation](../README.md)

# Emails

Application is using GOV.uk [Notify](https://www.notifications.service.gov.uk/) system to send emails. Developers should
have Notify accounts created during the onboarding process.

## Adding new email

New mailer is a file in `app/mailers`. The example file would look like this:

```ruby

class SomeMailer < ApplicationMailer
    def some_mailer_email(to:, data1:, data1:)
        template_mail("template-uuid",
        to:,
        personalisation: {
          data1:,
          data2:,
        })
    end
end
```

To send the above email, run `SomeMailer.dome_mailer_email(to: "example@example.org", data1: "foo", data2: "bar")`

For the email to be sent, there need to be email template created in Notify, with template id `template-uuid` and example
content:

```text
Hello ((data1)),
your token is ((data2)).
```

There are already emails in the application that can be used as example. Notify documentation is also very good.