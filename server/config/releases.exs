import Config

# These defaults mirror the ones in config.exs, remember not to change one
# without changing the other.
app_hostname = System.get_env("HOSTNAME", "localhost")
app_port = String.to_integer(System.get_env("PORT", "4000"))
db_host = System.get_env("DB_HOST", "localhost")
db_port = String.to_integer(System.get_env("DB_PORT", "5432"))
db_name = System.get_env("DB_NAME", "postgres")
db_user = System.get_env("DB_USER", "postgres")
db_password = System.get_env("DB_PASSWORD", "postgres")
# HACK: There's probably a better way to set boolean from env
db_ssl = System.get_env("DB_SSL", "true") === "true"
slot_name = System.get_env("SLOT_NAME") || :temporary
configuration_file = System.get_env("CONFIGURATION_FILE")

# Initial delay defaults to half a second
db_retry_initial_delay = System.get_env("DB_RETRY_INITIAL_DELAY", "500")
# Maximum delay defaults to five minutes
db_retry_maximum_delay = System.get_env("DB_RETRY_MAXIMUM_DELAY", "300000")
# Jitter will randomly adjust each delay within 10% of its value
db_retry_jitter = System.get_env("DB_RETRY_JITTER", "10")

# Workflows database connection settings
workflows_db_host = System.get_env("WORKFLOWS_DB_HOST", db_host)
workflows_db_port = String.to_integer(System.get_env("WORKFLOWS_DB_PORT", inspect db_port))
workflows_db_name = System.get_env("WORKFLOWS_DB_NAME", db_name)
workflows_db_user = System.get_env("WORKFLOWS_DB_USER", db_user)
workflows_db_password = System.get_env("WORKFLOWS_DB_PASSWORD", db_password)
workflows_db_schema = System.get_env("WORKFLOWS_DB_SCHEMA", "public")
workflows_db_ssl = System.get_env("WORKFLOWS_DB_SSL", inspect db_ssl) === "true"

# Channels are not secured by default in development and
# are secured by default in production.
secure_channels = System.get_env("SECURE_CHANNELS", "true") != "false"

# Supports HS algorithm octet keys
# e.g. "95x0oR8jq9unl9pOIx"
jwt_secret = System.get_env("JWT_SECRET", "")

# Every JWT's claims will be compared (equality checks) to the expected
# claims set in the JSON object.
# e.g.
# Set JWT_CLAIM_VALIDATORS="{'iss': 'Issuer', 'nbf': 1610078130}"
# Then JWT's "iss" value must equal "Issuer" and "nbf" value
# must equal 1610078130.
jwt_claim_validators = System.get_env("JWT_CLAIM_VALIDATORS", "{}")

config :realtime,
  app_hostname: app_hostname,
  app_port: app_port,
  db_host: db_host,
  db_port: db_port,
  db_name: db_name,
  db_user: db_user,
  db_password: db_password,
  db_ssl: db_ssl,
  db_retry_initial_delay: db_retry_initial_delay,
  db_retry_maximum_delay: db_retry_maximum_delay,
  db_retry_jitter: db_retry_jitter,
  slot_name: slot_name,
  configuration_file: configuration_file,
  workflows_db_host: workflows_db_host,
  workflows_db_port: workflows_db_port,
  workflows_db_name: workflows_db_name,
  workflows_db_user: workflows_db_user,
  workflows_db_password: workflows_db_password,
  workflows_db_schema: workflows_db_schema,
  workflows_db_ssl: workflows_db_ssl,
  secure_channels: secure_channels,
  jwt_secret: jwt_secret,
  jwt_claim_validators: jwt_claim_validators

config :realtime, RealtimeWeb.Endpoint, http: [:inet6, port: app_port]
