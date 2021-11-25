module JargonJuggler
    module Game
        @@modes = {} # name : class
        class << self
            def modes
                @@modes.keys
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
