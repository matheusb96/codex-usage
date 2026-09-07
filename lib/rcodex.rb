# frozen_string_literal: true

require "time"

require_relative "rcodex/version"
require_relative "rcodex/errors"
require_relative "rcodex/color"
require_relative "rcodex/format"

require_relative "rcodex/domain/account"
require_relative "rcodex/domain/credits_balance"
require_relative "rcodex/domain/rate_limit_window"
require_relative "rcodex/domain/usage_snapshot"

require_relative "rcodex/app_server/connection"
require_relative "rcodex/app_server/client"
require_relative "rcodex/app_server/usage_mapper"

require_relative "rcodex/presenters/aligned_rows"
require_relative "rcodex/presenters/human_presenter"
require_relative "rcodex/presenters/simple_presenter"
require_relative "rcodex/presenters/json_presenter"
require_relative "rcodex/presenters/raw_presenter"

require_relative "rcodex/commands/usage_command"
require_relative "rcodex/cli"

module RCodex
end
