# frozen_string_literal: true

require "json"
require "openssl"
require "base64"

module Tlog
  class PayloadBuilder
    def self.build(json_payload)
      raw       = JSON.dump(json_payload)
      key       = load_private_key
      signature = sign(key, raw)
      pub_der   = key.public_to_der

      {
        "hashedRekordRequestV002" => {
          "digest"    => base64_encode(hex_digest_raw(raw)),
          "signature" => {
            "content"  => base64_encode(signature),
            "verifier" => {
              "publicKey" => {
                "rawBytes" => base64_encode(pub_der)
              },
              "keyDetails" => "PKIX_ECDSA_P256_SHA_256"
            }
          }
        }
      }
    end

    private

    def self.load_private_key
      OpenSSL::PKey::EC.generate("prime256v1")
    end

    def self.sign(key, data)
      key.sign(OpenSSL::Digest::SHA256.new, data)
    end

    def self.hex_digest_raw(data)
      OpenSSL::Digest::SHA256.digest(data)
    end

    def self.base64_encode(data)
      Base64.strict_encode64(data)
    end
  end
end