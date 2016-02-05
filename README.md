# Nudge

Nudge is a lightweight library for sending APNS messages.

## Quick start

Add the gem to your Gemfile, and then:

```ruby
cert = Nudge::Certificate.new('/path/to/certificate.pem', 'passphrase')
client = Nudge::Client.new(cert)

token = 'e8e39....'
notif = Nudge::Notification.alert('Hello')

client.send(token, notif)
```

The `Nudge::Notification` class is a helper to format the APNS payload.  If you
prefer, you can format the payload yourself.  In that case, just pass the
payload hash directly to `#send`:

```ruby
client.send(token, { aps: { alert: 'Hello' } })
```

Each `Nudge::Client` uses a single network connection, and sends one message at
a time, synchronously.  It connects when you initialize the instance, and it
keeps its connection open.
