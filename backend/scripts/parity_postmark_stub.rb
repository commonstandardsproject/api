# Loaded into the Ruby app before puma boots when running POST-endpoint
# parity diffs (`backend/scripts/post_parity_diff.sh`). Replaces
# `Postmark::ApiClient#deliver_with_template` with a no-op so the
# `change_status`/`submit`/`comment` routes don't crash on missing
# Postmark credentials.
#
# Usage:
#   docker run --entrypoint bundle … csp-api-web exec \
#     ruby -r/home/app/elixir/scripts/parity_postmark_stub.rb \
#     -S puma -C puma.rb
require "postmark"

module Postmark
  class ApiClient
    def deliver_with_template(*_args)
      # Mirror the test adapter in `lib/csp_api/email/test_adapter.ex` —
      # capture the call instead of hitting the network. Visible in the
      # container log so parity tests can grep it if they care.
      warn "[parity-stub] suppressed Postmark deliver_with_template"
      { "ErrorCode" => 0, "Message" => "OK (parity stub)" }
    end
  end
end
