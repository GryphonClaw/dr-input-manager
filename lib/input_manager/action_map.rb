# frozen_string_literal: true

module InputManager
  class ActionMap
    attr_reader :name, :actions_registry
    attr_accessor :enabled

    def initialize(name)
      @name = name
      reset
    end

    def reset
      @actions_registry = {}
      @enabled = true
      @actions = nil
      @devices = nil
    end

    def enabled?
      !!enabled
    end

    def devices
      @devices ||= InputManager.devices
    end

    def devices=(list)
      @devices = list
      actions.each(&:reset_controls)
    end

    # @param action [String, Action] the action to register or its name
    # @param bindings [Array<Binding>] the bindings for this action. Optional, defaults to [].
    def register_action(action, bindings = [])
      if action.is_a?(String) || action.is_a?(Symbol)
        action = Action.new(action.to_s, bindings: bindings, action_map: self)
      end
      actions_registry[action.name] = action
      action.action_map = self
      @actions = nil
    end

    def actions
      @actions ||= actions_registry.values
    end

    def update
      @consumed_controls = []
      bindings.each do |binding|
        control = binding.resolve
        next unless control

        @consumed_controls << control
        binding.action.active_control = control
      end

      actions.each(&:update)
    end

    def consumed?(control)
      @consumed_controls.include?(control)
    end

    def bindings
      actions.flat_map(&:bindings).sort_by(&:complexity)
    end
  end
end
