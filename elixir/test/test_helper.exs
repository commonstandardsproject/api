ExUnit.start()

# Use the in-process TestAdapter so we can assert on outgoing emails.
Application.put_env(:csp_api, :email_adapter, CspApi.Email.TestAdapter)

# Some tests want the JWT bypass; in test mode `Authorization: TEST` always
# passes the JWT plug. Anything else requires a real token.
Application.put_env(:csp_api, :environment, :test)
