require 'optparse'
require 'singleton'

module DSCConnect
  class CommandExec
    include Singleton

    def initialize
      @process_threads = []
    end

    def run!(command, *args)
      options = {}
      OptionParser.new do |opts|
        args.each do |arg|
          opt_name = arg[/^--([^=]+)(?:=(.*))?$/, 1]
          opt_value = arg[/^--([^=]+)(?:=(.*))?$/, 2]
          if opt_value
            opts.on("--#{opt_name}=VALUE") do |v|
              options[opt_name.tr('-', '_').to_sym] = v
            end
          else
            opts.on("--#{opt_name}") do
              options[opt_name.tr('-', '_').to_sym] = true
            end
          end
        end
      end.parse!

      # Start the logger loop
      @process_threads << ConsoleLogger.instance.tap(&:start!)

      # Start the IT-100 event listener loop
      @process_threads << SocketClient.instance.tap(&:start!)

      # Execute the command
      if options.size.positive?
        SocketClient.instance.send(command, **options)
      else
        SocketClient.instance.send(command)
      end

      # Exit threads
      @process_threads.reverse_each(&:quit!)
      @process_threads.each(&:wait!)
    end
  end
end
