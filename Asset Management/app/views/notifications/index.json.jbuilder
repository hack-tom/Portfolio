
json.array! @notifications do |notification|
    json.recipient "#{notification.recipient.givenname} #{notification.recipient.sn}"
    json.action notification.action
    json.context notification.context
    json.read !notification.read_at.blank?
    json.notifiable do
      if notification.notifiable.class == Booking
        json.type "#{notification.notifiable.class.to_s.underscore.humanize.downcase}"
        json.itemname "#{notification.notifiable.item.name.to_s}"
        json.booker "#{notification.notifiable.user.givenname.to_s} #{notification.notifiable.user.sn.to_s}"
      elsif notification.notifiable.class == Item
        json.itemname "#{notification.notifiable.name.to_s}"
      end
    end
end
