module Operations
  # Operations can be inherited so we encapsulates our 
  # "messages store" server side in the ServerBase class.
  
  # ServerBase provides the common parameters, 
  # two methods "messages" and "add_message",
  # and the common dispatch step.
  
  class ServerBase < Hyperloop::ServerOp
    # for an Operation to be run remotely it must take
    # an acting_user param.  However we will allow it to
    # be nil, thus no login is required.
    # In a real app we would use a validation step to insure
    # the acting_user had authorization to run the operation.
    param :acting_user, nils: true
    # because this is a toy app we are also going to provide a simple
    # user name as a string normally this would be an attribute of the 
    # acting user.
    param :user_name

    # the base behavior is simply to dispatch the parameters back to entire
    # application.  Subclasses will add more data.
    dispatch_to { Hyperloop::Application }

    # we also provide a couple of methods that encapsulate the server side
    # persistance.  In this case we just use the Rails cache.
    def messages
      Rails.cache.fetch('messages') { [] }
    end

    def add_message 
      # add_message expects a message param to be present 
      # this is done this way just to show how steps can be simple
      # method calls.
      params.message = {
        message: params.message,
        time: Time.now,
        from: params.user_name
      }
      Rails.cache.write('messages', messages << params.message)
    end
  end

  # We now build two runnable Operations
  
  # GetMessages simply adds an "outbound" param called messages
  # which it will set.
  class GetMessages < ServerBase
    outbound :messages

    # the only added step is to get the messages and place it in the 
    # messages param which will be dispatched
    step { params.messages = messages }

    # currently the deserializer (run on the client) does not 
    # handle Time conversion properly due to the differences in the way
    # JS and Opal represent time.  So we will add our own custom 
    # deserializer.
    def self.deserialize_dispatch(messages)
      # convert the time string back to time
      messages[:messages].each do |message|
        message[:time] = Time.parse(message[:time])
      end
      messages
    end
  end

  # The Send operation just sends a message to everybody.
  # We just add a param called message to the ServerBase
  class Send < ServerBase
    param :message

    # the only step is simply to run add_message
    step :add_message

    def self.deserialize_dispatch(message)
      # convert time strings back to time
      message[:message][:time] = Time.parse(message[:message][:time])
      message
    end
  end

  # client side only: registers user_name and then gets the messages
  # notice how steps can invoke other Operations.  steps will automatically
  # deal with promises, chaining them together as necessary.
  class Join < Hyperloop::Operation
    param :user_name
    step GetMessages
  end
end
