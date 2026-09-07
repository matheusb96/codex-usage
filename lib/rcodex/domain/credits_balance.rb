# frozen_string_literal: true

module RCodex
  module Domain
    CreditsBalance = Struct.new(:has_credits, :unlimited, :balance, keyword_init: true) do
      def unlimited?
        unlimited == true
      end

      def has_credits? # rubocop:disable Naming/PredicateName -- mirrors backend field name
        has_credits == true
      end

      def description
        return "unlimited" if unlimited?
        return "balance #{balance}" if has_credits?

        "none"
      end

      def to_h
        { "hasCredits" => has_credits, "unlimited" => unlimited, "balance" => balance }
      end
    end
  end
end
