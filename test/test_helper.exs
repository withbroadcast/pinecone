ExUnit.start()

# Define mock for Tesla adapter
Mox.defmock(Tesla.MockAdapter, for: Tesla.Adapter)

# Configure Tesla to use the mock adapter in test environment
Application.put_env(:tesla, :adapter, Tesla.MockAdapter)
