# The MessageStore provides three class level methods all of which are reactive:
# MessageStore.all - returns all messages 
# MessageStore.user_name - return current user name 
# MessageStore.online? - is the application connected

class MessageStore < Hyperloop::Store
  state :messages, scope: :class, reader: :all
  state :user_name, scope: :class, reader: true

  def self.online? 
    # for purposes of our toy app we are online once messages gets set
    state.messages
  end

  # The store listens for dispatches from our operations and updates
  # state accordingly.  Notice that the Operation interface works the
  # same regardless if the Operation is running remotely or locally.

  receives Operations::Join do |params|
    puts "receiving Operations::Join.run(#{params})"
    mutate.user_name params.user_name
  end

  receives Operations::GetMessages do |params|
    puts "receiving Operations::GetMessages.run(#{params})"
    mutate.messages params.messages
  end

  receives Operations::Send do |params|
    puts "receiving Operations::Send.run(#{params})"
    mutate.messages << params.message
  end
end
