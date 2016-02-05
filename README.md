# Nudge

Nudge is a lightweight library for sending APNS messages, using the new HTTP/2
protocol.

## Status

This is a very early version, and is still a bit rough around the edges!

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

The `#send` method returns a `Nudge::Response`.  You can check the response's
`#success` to see if your message sent correctly.  If `#success` is `false`,
there should also be something in `#message` to tell you what happened.

Each `Nudge::Client` uses a single network connection, and sends one message at
a time, synchronously.  It connects when you initialize the instance, and it
keeps its connection open.  Currently if you want to send multiple messages at
once, you should create multiple `Client` instances.

