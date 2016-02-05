require 'spec_helper'

include Nudge

RSpec.describe Notification do
  it "can build a silent notification" do
    notif = Notification.silent
    expect(notif.payload).to eq({ aps: { content_available: 1 } })
  end

  it "can build a silent notification with custom content" do
    notif = Notification.silent(custom: { food: 'pizza' })
    expect(notif.payload).to eq({ aps: { content_available: 1 },
                                  food: 'pizza' })
  end

  it "can build an alert notification" do
    notif = Notification.alert('Wake up!')
    expect(notif.payload).to eq({ aps: { alert: 'Wake up!' } })
  end

  it "can build an alert notification with additional aps args" do
    notif = Notification.alert('Wake up!', badge: 23)
    expect(notif.payload).to eq({ aps: { alert: 'Wake up!',
                                         badge: 23 } })
  end

  it "can build an alert notification with custom content" do
    notif = Notification.alert('Wake up!', custom: { drink: 'tea' })
    expect(notif.payload).to eq({ aps: { alert: 'Wake up!' },
                                  drink: 'tea' })
  end
end
