module JargonJuggler
    module Game
        @@modes = {} # game name : game class
        @@channels = {} # channel name : game instance
        class << self
            def modes
                @@modes.keys
            end

            def channels
                @@channels
            end

            def [](name)
                @@modes[name]
            end

            def []=(name, impl)
                @@modes[name] ||= impl
            end
        end
    end
end
