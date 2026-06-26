# frozen_string_literal: true

class TransparencyLog::Tlog
  def initialize
    pem = ENV.fetch("TRANSPARENCY_LOG_PRIVATE_KEY").gsub("\\n", "\n")
    passphrase = ENV.fetch("TRANSPARNECY_LOG_PRIVATE_KEY_PASSPHRASE", nil)

    @entry_builder = TransparencyLog::EntryBuilder.new(OpenSSL::PKey.read(pem, passphrase))
    @client = TransparencyLog::Client.new(ENV.fetch("TRANSAPRENCY_LOG_REKOR_URL", "http://localhost:3004"))
  end

  def create_entry(json_payload)
    entry = @entry_builder.build(json_payload)
    response = @client.post(entry)
  end
end
